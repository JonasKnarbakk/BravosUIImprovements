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
    maxPoints = 5,
    color = { r = 0.447, g = 0.780, b = 1.0 }, -- Light Blue #72C7FF
    color2 = { r = 1.0, g = 0.4, b = 0.4 }, -- Red #FF6666
    layered = true,
  },
  DEMONHUNTER = {
    spec = 581, -- Vengeance
    buffs = { 203981 }, -- Soul Fragments
    name = "Soul Fragments",
    maxPoints = 5,
    color = { r = 0.8, g = 0.2, b = 0.8 }, -- Soul Purple
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

  if classFilename == "SHAMAN" and db and db["resource_tracker_shaman"] == false then
    return nil
  elseif classFilename == "DEMONHUNTER" and db and db["resource_tracker_demonhunter"] == false then
    return nil
  end

  if CONFIG[classFilename] and CONFIG[classFilename].spec == specId then
    return CONFIG[classFilename]
  end
  return nil
end

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
    return
  end

  local currentStacks = 0
  local maxPoints = 5
  local color = { r = 1, g = 1, b = 1 }
  local color2 = nil
  local layered = false

  if isEditMode then
    -- Mock data for Edit Mode
    currentStacks = 3
    maxPoints = 5
    if config then
      maxPoints = config.maxPoints
      color = config.color
      color2 = config.color2
      layered = config.layered
      -- Show "Overcharge" effect in Edit Mode if applicable
      if layered then
        currentStacks = 7
      end
    else
      color = { r = 1, g = 1, b = 0 } -- Default Yellow
    end
    frame:Show()
  elseif config then
    maxPoints = config.maxPoints
    color = config.color
    color2 = config.color2
    layered = config.layered

    for _, buffId in ipairs(config.buffs) do
      local aura = C_UnitAuras.GetPlayerAuraBySpellID(buffId)
      if aura then
        currentStacks = aura.applications
        break
      end
    end

    frame:Show()
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

      -- Update Border visibility
      if showBorder then
        point:SetBackdropBorderColor(0, 0, 0, 1)
      else
        point:SetBackdropBorderColor(0, 0, 0, 0)
      end

      -- Update State
      local drawColor = color
      if layered and currentStacks > maxPoints and i <= (currentStacks - maxPoints) then
        drawColor = color2
      end

      -- Use class color if enabled
      if classColor then
        drawColor = classColor
      end

      if i <= currentStacks then
        point.Fill:SetColorTexture(drawColor.r, drawColor.g, drawColor.b, db.currentOpacity or 1)
        point.Fill:Show()
      else
        point.Fill:Hide()
      end

      point.Background:SetColorTexture(0.1, 0.1, 0.1)
      point.Background:SetAlpha(bgOpacity)
    else
      point:Hide()
    end
  end

  frame:SetSize(totalWidth, height)

  -- Update Counter Text
  if db.showText then
    counterText:Show()
    counterText:SetText(currentStacks)
    counterText:SetFont(BUII_GetFontPath(), db.currentFontSize or 12, "OUTLINE")
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
  UpdatePoints()
end

function BUII_ResourceTracker_Enable()
  BUII_ResourceTracker_Initialize()

  frame:RegisterEvent("UNIT_AURA")
  frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_ResourceTracker_Custom_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_ResourceTracker_Custom_OnExit")

  BUII_EditModeUtils:ApplySavedPosition(frame, "resource_tracker")
  UpdatePoints()
end

function BUII_ResourceTracker_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_ResourceTracker_Custom_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_ResourceTracker_Custom_OnExit")

  frame:Hide()
end
