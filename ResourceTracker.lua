local addonName, addon = ...
local frame = nil
local points = {}
local counterText = nil

-- Ensure Enum exists
if not Enum.EditModeSystem.BUII_ResourceTracker then
  Enum.EditModeSystem.BUII_ResourceTracker = 9004
end

_G["BUII_HUD_EDIT_MODE_RESOURCE_TRACKER_LABEL"] = "Resource Tracker"

-- Configuration
local CONFIG = {
  SHAMAN = {
    spec = 263, -- Enhancement
    buffs = { 344179, 384088 }, -- Maelstrom Weapon
    name = "Maelstrom Weapon",
    maxPoints = 10, -- Maelstrom goes up to 10
    color = { r = 0.447, g = 0.780, b = 1.0 }, -- Light Blue #72C7FF
    color2 = { r = 1.0, g = 0.4, b = 0.4 }, -- Red #FF6666
    layered = true, -- Stack count > 5 changes color
  },
  DEMONHUNTER = {
    spec = 581, -- Vengeance
    buffs = { 203981 }, -- Soul Fragments
    name = "Soul Fragments",
    maxPoints = 5,
    color = { r = 0.8, g = 0.2, b = 0.8 }, -- Soul Purple
  },
  WARLOCK = {
    powerType = Enum.PowerType.SoulShards,
    name = "Soul Shards",
    color = { r = 0.64, g = 0.00, b = 0.94 }, -- Warlock Purple
    progressFill = true,
    nativeFrame = "WarlockPowerFrame",
  },
  PALADIN = {
    powerType = Enum.PowerType.HolyPower,
    name = "Holy Power",
    color = { r = 0.95, g = 0.9, b = 0.1 }, -- Holy Power Gold
    nativeFrame = "PaladinPowerBarFrame",
  },
  MONK = {
    powerType = Enum.PowerType.Chi,
    name = "Chi",
    color = { r = 0.0, g = 0.78, b = 0.86 }, -- Monk Chi
    nativeFrame = "MonkHarmonyBarFrame",
  },
  DEATHKNIGHT = {
    powerType = Enum.PowerType.Runes,
    name = "Runes",
    color = { r = 0.77, g = 0.12, b = 0.23 }, -- Death Knight Red
    progressFill = true,
    nativeFrame = "RuneFrame",
    specs = {
      [250] = { r = 0.77, g = 0.12, b = 0.23 }, -- Blood: Red
      [251] = { r = 0.0, g = 0.8, b = 1.0 }, -- Frost: Cyan
      [252] = { r = 0.2, g = 0.8, b = 0.2 }, -- Unholy: Green
    },
  },
  EVOKER = {
    powerType = Enum.PowerType.Essence,
    name = "Essence",
    color = { r = 0.4, g = 0.8, b = 1.0 }, -- Evoker Essence Blue/Cyan
    progressFill = true,
    nativeFrame = "EssencePlayerFrame",
  },
  ROGUE = {
    powerType = Enum.PowerType.ComboPoints,
    name = "Combo Points",
    color = { r = 1.0, g = 0.1, b = 0.1 }, -- Rogue Combo Red
    colorCharged = { r = 0.0, g = 0.8, b = 1.0 }, -- Anima Blue/Cyan
    nativeFrame = "RogueComboPointBarFrame",
  },
  DRUID = {
    powerType = Enum.PowerType.ComboPoints,
    name = "Combo Points",
    color = { r = 1.0, g = 0.1, b = 0.1 }, -- Druid Combo Red
    nativeFrame = "DruidComboPointBarFrame",
  },
  MAGE = {
    spec = 62, -- Arcane
    powerType = Enum.PowerType.ArcaneCharges,
    name = "Arcane Charges",
    color = { r = 0.56, g = 0.24, b = 0.85 }, -- Arcane Purple/Magenta
    nativeFrame = "MageArcaneChargesFrame",
  },
}

-- Settings Constants
local enum_ResourceTrackerSetting_UseCharSettings = 60
local enum_ResourceTrackerSetting_Scale = 61
local enum_ResourceTrackerSetting_TotalWidth = 62
local enum_ResourceTrackerSetting_Spacing = 63
local enum_ResourceTrackerSetting_Height = 64
local enum_ResourceTrackerSetting_ShowText = 65
local enum_ResourceTrackerSetting_FontSize = 66
local enum_ResourceTrackerSetting_ShowBorder = 67
local enum_ResourceTrackerSetting_UseClassColor = 68
local enum_ResourceTrackerSetting_ResourceOpacity = 69
local enum_ResourceTrackerSetting_BackgroundOpacity = 70
local enum_ResourceTrackerSetting_FrameStrata = 71
local enum_ResourceTrackerSetting_HideNativeFrame = 72

-- Frame Strata Options
local FRAME_STRATA_OPTIONS = {
  { text = "Background", value = 1 },
  { text = "Low", value = 2 },
  { text = "Medium", value = 3 },
  { text = "High", value = 4 },
  { text = "Dialog", value = 5 },
}

local FRAME_STRATA_VALUES = {
  [1] = "BACKGROUND",
  [2] = "LOW",
  [3] = "MEDIUM",
  [4] = "HIGH",
  [5] = "DIALOG",
}

local function GetResourceTrackerDB()
  if BUIICharacterDatabase and BUIICharacterDatabase["resource_tracker_use_char_settings"] then
    return BUIICharacterDatabase
  end
  return BUIIDatabase
end

local function GetActiveConfig()
  local db = GetResourceTrackerDB()
  local _, classFilename = UnitClass("player")
  local specId = PlayerUtil.GetCurrentSpecID()

  -- Check if class is disabled in settings
  local settingKey = "resource_tracker_" .. string.lower(classFilename)
  if db and db[settingKey] == false then
    return nil
  end

  local config = CONFIG[classFilename]
  if not config then
    return nil
  end

  -- If config has a spec requirement, check if we're in that spec
  if config.spec and config.spec ~= specId then
    return nil
  end

  -- Inject class filename for helper usage
  config.class = classFilename

  -- Apply Spec Specific Colors (e.g. DK Runes)
  if classFilename == "DEATHKNIGHT" and config.specs and config.specs[specId] then
    config.color = config.specs[specId]
  end

  return config
end

-- Helper to get resource state (current whole points, partial progress 0-1, charged points table)
local function GetResourceState(config)
  if not config then
    return 0, 0, nil
  end

  -- Death Knight Runes
  if config.class == "DEATHKNIGHT" and config.powerType == Enum.PowerType.Runes then
    local ready = 0
    local progressList = {}
    local time = GetTime()
    local maxRunes = UnitPowerMax("player", config.powerType) or 6

    for i = 1, maxRunes do
      local start, duration, runeReady = GetRuneCooldown(i)
      if not start then
        break
      end

      if runeReady then
        ready = ready + 1
      else
        if duration > 0 then
          local prog = (time - start) / duration
          table.insert(progressList, math.max(0, math.min(1, prog)))
        else
          table.insert(progressList, 0)
        end
      end
    end
    -- Sort progress descending so the most complete runes fill the first empty slots
    table.sort(progressList, function(a, b)
      return a > b
    end)

    return ready, progressList, nil

    -- Evoker Essence
  elseif config.class == "EVOKER" and config.powerType == Enum.PowerType.Essence then
    local power = UnitPower("player", config.powerType)
    -- EssenceFramePlayer.lua uses UnitPartialPower / 1000
    local partial = (UnitPartialPower("player", config.powerType) or 0) / 1000
    return power, partial, nil

    -- Warlock Soul Shards
  elseif config.class == "WARLOCK" and config.powerType == Enum.PowerType.SoulShards then
    local power = UnitPower("player", config.powerType, true)
    local mod = UnitPowerDisplayMod(config.powerType)
    local val = (mod ~= 0) and (power / mod) or 0
    local whole = math.floor(val)
    return whole, (val - whole), nil

    -- Rogue Combo Points
  elseif config.class == "ROGUE" and config.powerType == Enum.PowerType.ComboPoints then
    local power = UnitPower("player", config.powerType)
    local chargedPoints = GetUnitChargedPowerPoints("player")
    return power, 0, chargedPoints

    -- Generic Power (Holy Power, Chi, etc.)
  elseif config.powerType then
    return UnitPower("player", config.powerType), 0, nil

    -- Buff Tracking (Shaman, DH)
  elseif config.buffs then
    local count = 0
    for _, buffId in ipairs(config.buffs) do
      local aura = C_UnitAuras.GetPlayerAuraBySpellID(buffId)
      if aura then
        count = aura.applications
        break
      end
    end
    return count, 0, nil
  end

  return 0, 0, nil
end

-- Handle hiding/showing native resource frames
local nativeFrameHideHook = nil

local function UpdateNativeFrameVisibility()
  local db = GetResourceTrackerDB()
  local config = GetActiveConfig()

  if not config then
    -- If disabled, ensure native frame is shown
    local _, classFilename = UnitClass("player")
    local rawConfig = CONFIG[classFilename]
    if rawConfig and rawConfig.nativeFrame then
      local nativeFrame = _G[rawConfig.nativeFrame]
      if nativeFrame then
        nativeFrame:Show()
      end
    end
    return
  end

  if not config.nativeFrame then
    return
  end

  local shouldHide = db.resource_tracker_hide_native or false
  local nativeFrame = _G[config.nativeFrame]

  if nativeFrame then
    if shouldHide then
      nativeFrame:Hide()
      -- Hook the Show method to keep it hidden
      if not nativeFrameHideHook then
        nativeFrameHideHook = true
        hooksecurefunc(nativeFrame, "Show", function(self)
          local currentDb = GetResourceTrackerDB()
          if currentDb.resource_tracker_hide_native and GetActiveConfig() then
            self:Hide()
          end
        end)
      end
    else
      -- Let it show normally
      nativeFrame:Show()
    end
  end
end

-- Main update function
local function UpdatePoints()
  if not frame then
    return
  end

  local db = GetResourceTrackerDB()
  local config = GetActiveConfig()
  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()

  -- Apply frame strata
  local strataIndex = db.resource_tracker_frame_strata or 2 -- Default to LOW
  local strataValue = FRAME_STRATA_VALUES[strataIndex] or "LOW"
  frame:SetFrameStrata(strataValue)

  if not config and not isEditMode then
    frame:Hide()
    -- Ensure OnUpdate is off if hidden
    frame:SetScript("OnUpdate", nil)
    return
  end

  local currentStacks = 0
  local partialFill = 0
  local chargedPoints = nil
  local maxPoints = 5
  local color = { r = 1, g = 1, b = 1 }
  local color2 = nil
  local layered = false

  if isEditMode then
    -- Mock data for Edit Mode
    currentStacks = 3
    partialFill = 0.5
    maxPoints = 5
    if config then
      if config.powerType then
        maxPoints = UnitPowerMax("player", config.powerType) or config.maxPoints or 5
      else
        maxPoints = config.maxPoints or 5
      end
      color = config.color
      color2 = config.color2
      layered = config.layered
      -- Show "Overcharge" effect in Edit Mode if applicable
      if layered then
        currentStacks = 7
      end
      if config.class == "ROGUE" then
        chargedPoints = { 2, 4 } -- Mock charged points
      end
    else
      color = { r = 1, g = 1, b = 0 } -- Default Yellow
    end
    frame:Show()
    -- No OnUpdate in Edit Mode
    frame:SetScript("OnUpdate", nil)
  elseif config then
    -- Determine max points dynamically if possible
    if config.powerType then
      maxPoints = UnitPowerMax("player", config.powerType) or 0
    else
      maxPoints = config.maxPoints or 5
    end

    -- If we have no max points (e.g. Druid not in cat form), hide unless in Edit Mode
    -- Also specific check for Druid: must have Energy power type (Cat Form)
    local shouldShow = true
    if maxPoints == 0 then
      shouldShow = false
    end
    if config.class == "DRUID" then
      local powerType = UnitPowerType("player")
      if powerType ~= Enum.PowerType.Energy then
        shouldShow = false
      end
    end

    if not shouldShow and not isEditMode then
      frame:Hide()
      return
    end

    -- Safety check for maxPoints after we've confirmed we should be showing
    if maxPoints == 0 then
      maxPoints = 5
    end

    color = config.color
    color2 = config.color2
    layered = config.layered

    currentStacks, partialFill, chargedPoints = GetResourceState(config)

    frame:Show()
    UpdateNativeFrameVisibility()
  end

  -- Safety check for maxPoints
  if maxPoints == 0 then
    maxPoints = 5
  end

  -- Ensure we have enough points created
  for i = 1, maxPoints do
    if not points[i] then
      points[i] = CreateFrame("Frame", nil, frame, "BUII_ResourcePointTemplate")
    end
  end

  -- Update Points Visibility and Color
  local spacing = db.currentSpacing or 2
  local totalWidth = db.currentTotalWidth or 170
  local height = db.currentHeight or 12
  local showBorder = db.resource_tracker_show_border or false
  local useClassColor = db.resource_tracker_use_class_color or false
  local bgOpacity = tonumber(db.resource_tracker_background_opacity) or 0.5

  -- Get class color if needed
  local classColor = nil
  if useClassColor then
    local _, classFilename = UnitClass("player")
    local classColorTable = C_ClassColor.GetClassColor(classFilename)
    if classColorTable then
      classColor = { r = classColorTable.r, g = classColorTable.g, b = classColorTable.b }
    end
  end

  -- Calculate dynamic width for each point
  local pointWidth = (totalWidth - (spacing * (maxPoints - 1))) / maxPoints
  if pointWidth < 1 then
    pointWidth = 1
  end

  for i = 1, #points do
    local point = points[i]
    if i <= maxPoints then
      point:Show()
      point:SetSize(pointWidth, height)
      point:ClearAllPoints()

      -- Simple horizontal layout
      if i == 1 then
        point:SetPoint("LEFT", frame, "LEFT", 0, 0)
      else
        point:SetPoint("LEFT", points[i - 1], "RIGHT", spacing, 0)
      end

      -- Check if point is charged
      local isCharged = false
      if chargedPoints then
        for _, cpIndex in ipairs(chargedPoints) do
          if cpIndex == i then
            isCharged = true
            break
          end
        end
      end

      -- Update State
      local drawColor = color
      local isOvercharge = false
      if layered and currentStacks > maxPoints and i <= (currentStacks - maxPoints) then
        drawColor = color2
        isOvercharge = true
      end

      -- Use class color if enabled (but not for overcharge layer)
      if classColor and not isOvercharge then
        drawColor = classColor
      end

      -- Apply Charged Color override
      if isCharged and config and config.colorCharged then
        drawColor = config.colorCharged
      end

      -- Update Border visibility and color
      local borderColor = { r = 0, g = 0, b = 0, a = 0 }
      if isCharged and config and config.colorCharged then
        -- Always show border for charged points to make them distinct even when empty
        borderColor = { r = config.colorCharged.r, g = config.colorCharged.g, b = config.colorCharged.b, a = 1 }
      elseif showBorder then
        borderColor = { r = 0, g = 0, b = 0, a = 1 }
      end

      point:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

      local myPartial = 0
      if type(partialFill) == "table" then
        myPartial = partialFill[i - currentStacks] or 0
      elseif i == currentStacks + 1 then
        myPartial = partialFill
      end

      if i <= currentStacks then
        -- Full point - reset to default anchors
        point.Fill:ClearAllPoints()
        point.Fill:SetPoint("TOPLEFT", point, "TOPLEFT", 1, -1)
        point.Fill:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -1, 1)
        point.Fill:SetTexture(BUII_GetTexturePath())
        point.Fill:SetVertexColor(drawColor.r, drawColor.g, drawColor.b, db.currentOpacity or 1)
        point.Fill:Show()
      elseif myPartial > 0 then
        -- Partial point - resize to show only partial width
        point.Fill:ClearAllPoints()
        point.Fill:SetPoint("TOPLEFT", point, "TOPLEFT", 1, -1)
        point.Fill:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", 1, 1)
        local fillWidth = (pointWidth - 2) * myPartial -- -2 for borders
        point.Fill:SetWidth(fillWidth)
        point.Fill:SetTexture(BUII_GetTexturePath())
        point.Fill:SetVertexColor(drawColor.r, drawColor.g, drawColor.b, (db.currentOpacity or 1) * 0.7)
        point.Fill:Show()
      else
        point.Fill:Hide()
      end

      point.Background:SetTexture(BUII_GetTexturePath())
      point.Background:SetVertexColor(0.1, 0.1, 0.1, bgOpacity)
    else
      point:Hide()
    end
  end

  frame:SetSize(totalWidth, height)

  -- Update Counter Text
  if db.showText then
    counterText:Show()
    counterText:SetText(currentStacks)
    counterText:SetFont(BUII_GetFontPath(), db.currentFontSize or 12, BUII_GetFontFlags())
    counterText:SetShadowOffset(BUII_GetFontShadow())
  else
    counterText:Hide()
  end
end

local function onEvent(self, event, ...)
  if event == "EDIT_MODE_LAYOUTS_UPDATED" then
    BUII_EditModeUtils:ApplySavedPosition(frame, "resource_tracker")
    return
  end

  UpdatePoints()
end

local function BUII_ResourceTracker_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_ResourceTrackerFrame", UIParent, "BUII_ResourceTrackerEditModeTemplate")
  frame:SetSize(170, 20)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  -- Expose DB selector for EditModeUtils
  frame.GetSettingsDB = GetResourceTrackerDB

  -- Create a container frame for text to ensure it stays on top of points
  local textFrame = CreateFrame("Frame", nil, frame)
  textFrame:SetAllPoints(frame)
  textFrame:SetFrameLevel(frame:GetFrameLevel() + 10)

  counterText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  counterText:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
  counterText:SetText("0")

  -- Register System
  local settingsConfig = {
    {
      setting = enum_ResourceTrackerSetting_UseCharSettings,
      name = "Character Specific",
      key = "resource_tracker_use_char_settings",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      notSaved = true,
      getter = function(f)
        return BUIICharacterDatabase["resource_tracker_use_char_settings"] and 1 or 0
      end,
      setter = function(f, val)
        BUIICharacterDatabase["resource_tracker_use_char_settings"] = (val == 1)
        if f.UpdateSystem then
          f:UpdateSystem()
        end
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_Scale,
      name = "Scale",
      key = "resource_tracker_scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 2.0,
      stepSize = 0.05,
      formatter = BUII_EditModeUtils.FormatPercentage,
      getter = function(f)
        return f:GetScale()
      end,
      setter = function(f, val)
        f:SetScale(val)
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_TotalWidth,
      name = "Total Width",
      key = "resource_tracker_total_width",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 50,
      maxValue = 500,
      stepSize = 1,
      defaultValue = 170,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentTotalWidth or 170
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentTotalWidth = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_Height,
      name = "Height",
      key = "resource_tracker_height",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 5,
      maxValue = 50,
      stepSize = 1,
      defaultValue = 12,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentHeight or 12
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentHeight = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_Spacing,
      name = "Spacing",
      key = "resource_tracker_spacing",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 10,
      stepSize = 1,
      defaultValue = 2,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentSpacing or 2
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentSpacing = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_ResourceOpacity,
      name = "Resource Opacity",
      key = "resource_tracker_opacity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.1,
      maxValue = 1.0,
      stepSize = 0.1,
      formatter = BUII_EditModeUtils.FormatPercentage,
      defaultValue = 1.0,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentOpacity or 1.0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentOpacity = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_BackgroundOpacity,
      name = "Background Opacity",
      key = "resource_tracker_background_opacity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.0,
      maxValue = 1.0,
      stepSize = 0.1,
      formatter = BUII_EditModeUtils.FormatPercentage,
      defaultValue = 0.5,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_background_opacity or 0.5
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_background_opacity = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_ShowText,
      name = "Show Stack Counter",
      key = "resource_tracker_show_stacks",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.showText and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.showText = (val == 1)
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_FontSize,
      name = "Font Size",
      key = "resource_tracker_stacks_font_size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 32,
      stepSize = 1,
      defaultValue = 12,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentFontSize or 12
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentFontSize = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_ShowBorder,
      name = "Show Border",
      key = "resource_tracker_show_border",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_show_border and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_show_border = (val == 1)
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_UseClassColor,
      name = "Use Class Color",
      key = "resource_tracker_use_class_color",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_use_class_color and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_use_class_color = (val == 1)
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_HideNativeFrame,
      name = "Hide Native Frame",
      key = "resource_tracker_hide_native",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_hide_native and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_hide_native = (val == 1)
        UpdateNativeFrameVisibility()
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_FrameStrata,
      name = "Frame Strata",
      key = "resource_tracker_frame_strata",
      type = Enum.EditModeSettingDisplayType.Dropdown,
      defaultValue = 2, -- LOW
      options = FRAME_STRATA_OPTIONS,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_frame_strata or 2
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_frame_strata = val
        UpdatePoints()
      end,
    },
  }

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_ResourceTracker,
    "Resource Tracker",
    settingsConfig,
    "resource_tracker",
    {
      OnReset = function(f)
        local db = GetResourceTrackerDB()
        db.currentSpacing = 2
        db.currentOpacity = 1.0
        db.currentTotalWidth = 170
        db.currentHeight = 12
        db.showText = false
        db.currentFontSize = 12
        db.resource_tracker_show_border = false
        db.resource_tracker_use_class_color = false
        db.resource_tracker_frame_strata = 2 -- LOW
        db.resource_tracker_background_opacity = 0.5
        UpdatePoints()
      end,

      OnApplySettings = function(f)
        UpdatePoints()
      end,
    }
  )
end

-- Edit Mode Integration
local function editMode_OnEnter()
  frame:EnableMouse(true)
  UpdatePoints()
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  -- Don't update during combat to avoid taint when Edit Mode system calls SelectSystem
  if not InCombatLockdown() then
    UpdatePoints()
  end
end

function BUII_ResourceTracker_Enable()
  BUII_ResourceTracker_Initialize()

  frame:RegisterEvent("UNIT_AURA")
  frame:RegisterEvent("UNIT_POWER_UPDATE")
  frame:RegisterEvent("UNIT_POWER_FREQUENT")
  frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)
  frame:SetScript("OnUpdate", UpdatePoints)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_ResourceTracker_Custom_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_ResourceTracker_Custom_OnExit")

  BUII_EditModeUtils:ApplySavedPosition(frame, "resource_tracker")
  UpdatePoints()
  UpdateNativeFrameVisibility()
end

function BUII_ResourceTracker_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)
  frame:SetScript("OnUpdate", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_ResourceTracker_Custom_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_ResourceTracker_Custom_OnExit")

  frame:Hide()

  -- Restore native frame if it exists
  local _, classFilename = UnitClass("player")
  local config = CONFIG[classFilename]
  if config and config.nativeFrame then
    local nativeFrame = _G[config.nativeFrame]
    if nativeFrame then
      nativeFrame:Show()
    end
  end
end

function BUII_ResourceTracker_Refresh()
  if frame then
    UpdatePoints()
  end
end

function BUII_ResourceTracker_InitDB()
  -- BUIIDatabase initialization
  if BUIIDatabase["resource_tracker"] == nil then
    BUIIDatabase["resource_tracker"] = false
  end
  if BUIIDatabase["resource_tracker_shaman"] == nil then
    BUIIDatabase["resource_tracker_shaman"] = true
  end
  if BUIIDatabase["resource_tracker_demonhunter"] == nil then
    BUIIDatabase["resource_tracker_demonhunter"] = true
  end
  if BUIIDatabase["resource_tracker_warlock"] == nil then
    BUIIDatabase["resource_tracker_warlock"] = true
  end
  if BUIIDatabase["resource_tracker_paladin"] == nil then
    BUIIDatabase["resource_tracker_paladin"] = true
  end
  if BUIIDatabase["resource_tracker_monk"] == nil then
    BUIIDatabase["resource_tracker_monk"] = true
  end
  if BUIIDatabase["resource_tracker_deathknight"] == nil then
    BUIIDatabase["resource_tracker_deathknight"] = true
  end
  if BUIIDatabase["resource_tracker_evoker"] == nil then
    BUIIDatabase["resource_tracker_evoker"] = true
  end
  if BUIIDatabase["resource_tracker_rogue"] == nil then
    BUIIDatabase["resource_tracker_rogue"] = true
  end
  if BUIIDatabase["resource_tracker_druid"] == nil then
    BUIIDatabase["resource_tracker_druid"] = true
  end
  if BUIIDatabase["resource_tracker_mage"] == nil then
    BUIIDatabase["resource_tracker_mage"] = true
  end
  if BUIIDatabase["resource_tracker_show_border"] == nil then
    BUIIDatabase["resource_tracker_show_border"] = false
  end
  if BUIIDatabase["resource_tracker_use_class_color"] == nil then
    BUIIDatabase["resource_tracker_use_class_color"] = false
  end
  if BUIIDatabase["resource_tracker_hide_native"] == nil then
    BUIIDatabase["resource_tracker_hide_native"] = false
  end
  if BUIIDatabase["resource_tracker_frame_strata"] == nil then
    BUIIDatabase["resource_tracker_frame_strata"] = 2 -- LOW
  end

  -- BUIICharacterDatabase initialization
  if BUIICharacterDatabase["resource_tracker_use_char_settings"] == nil then
    BUIICharacterDatabase["resource_tracker_use_char_settings"] = false
  end
  if BUIICharacterDatabase["resource_tracker_show_border"] == nil then
    BUIICharacterDatabase["resource_tracker_show_border"] = false
  end
  if BUIICharacterDatabase["resource_tracker_use_class_color"] == nil then
    BUIICharacterDatabase["resource_tracker_use_class_color"] = false
  end
  if BUIICharacterDatabase["resource_tracker_hide_native"] == nil then
    BUIICharacterDatabase["resource_tracker_hide_native"] = false
  end
  if BUIICharacterDatabase["resource_tracker_frame_strata"] == nil then
    BUIICharacterDatabase["resource_tracker_frame_strata"] = 2 -- LOW
  end
end
