local addonName, addon = ...
local frame = nil
local icon = nil
local text = nil
local isTestMode = false

-- Settings Constants
local enum_StanceTrackerSetting_Scale = 10
local enum_StanceTrackerSetting_ShowIcon = 11
local enum_StanceTrackerSetting_IconSize = 12
local enum_StanceTrackerSetting_ShowText = 13
local enum_StanceTrackerSetting_FontSize = 14
local enum_StanceTrackerSetting_Emphasize = 15
local enum_StanceTrackerSetting_EmphasizeScale = 16
local enum_StanceTrackerSetting_EmphasizeIntensity = 17
local enum_StanceTrackerSetting_EmphasizeYOffset = 18

local function GetStanceTrackerDB()
  return BUII_EditModeUtils:GetDB("stance_tracker")
end

local empAnchor = nil
local empFrame = nil
local empText = nil
local empAnimGroup = nil

local function updateEmphasize()
  local db = GetStanceTrackerDB()
  if not empFrame then
    return
  end

  local _, playerClass = UnitClass("player")
  local classKey = "stance_tracker_" .. string.lower(playerClass)
  if BUIIDatabase[classKey] == false then
    empFrame:Hide()
    if empAnimGroup then
      empAnimGroup:Stop()
    end
    return
  end

  local stance = GetShapeshiftForm()
  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
  local shouldShow = false

  -- Font Update Workaround
  local currentEmpText = empText:GetText()
  empText:SetText("")
  empText:SetFont(BUII_GetFontPath(), 44, BUII_GetFontFlags())
  empText:SetShadowOffset(BUII_GetFontShadow())
  empText:SetText(currentEmpText or "")

  if db["stance_tracker_emphasize"] then
    if isEditMode then
      shouldShow = true
      empText:SetText(playerClass == "PALADIN" and "NO AURA" or "NO STANCE")
    elseif stance == 0 and (playerClass == "PALADIN" or playerClass == "WARRIOR") then
      shouldShow = true
      empText:SetText(playerClass == "PALADIN" and "NO AURA" or "NO STANCE")
    end
  end

  if shouldShow then
    local scale = db["stance_tracker_emp_scale"] or 1.0
    local intensity = db["stance_tracker_emp_intensity"] or 20
    local yOffset = db["stance_tracker_emp_y_offset"] or 60
    empFrame:SetScale(scale)

    empAnchor:ClearAllPoints()
    empAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, yOffset)

    -- Update animation intensity safely
    local animations = { empAnimGroup:GetAnimations() }
    local up = animations[1]
    local down = animations[2]

    if up and down then
      local _, currentUpY = up:GetOffset()
      if currentUpY ~= intensity then
        empAnimGroup:Stop()
        up:SetOffset(0, intensity)
        down:SetOffset(0, -intensity)
      end
    end

    empFrame:Show()
    if not empAnimGroup:IsPlaying() then
      empAnimGroup:Play()
    end
  else
    empFrame:Hide()
    if empAnimGroup then
      empAnimGroup:Stop()
    end
  end
end

local function updateDisplay()
  local db = GetStanceTrackerDB()
  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()

  -- Enabled state is always account wide
  if not BUIIDatabase["stance_tracker"] and not isEditMode then
    if frame then
      frame:Hide()
    end
    updateEmphasize()
    return
  end

  local _, playerClass = UnitClass("player")
  local classKey = "stance_tracker_" .. string.lower(playerClass)
  if BUIIDatabase[classKey] == false and not isEditMode then
    if frame then
      frame:Hide()
    end
    updateEmphasize()
    return
  end

  local displayText = ""
  local displayIcon = 0
  local textColor = { r = 1, g = 1, b = 1 }
  local showFrame = false

  -- Determine Content
  if isEditMode then
    displayText = "Battle Stance"
    displayIcon = 132349 -- Warrior Battle Stance
    if playerClass == "PALADIN" then
      displayText = "Devotion Aura"
      displayIcon = 135893 -- Devotion Aura
    end
    showFrame = true
  else
    local stance = GetShapeshiftForm()
    if stance == 0 then
      if playerClass == "PALADIN" or playerClass == "WARRIOR" then
        displayText = playerClass == "PALADIN" and "NO AURA" or "NO STANCE"
        displayIcon = 134400
        textColor = { r = 1, g = 0, b = 0 }
        showFrame = true
      end
    else
      local texture, active, castable, spellID = GetShapeshiftFormInfo(stance)
      displayText = ""
      displayIcon = texture

      if spellID then
        local spellName = C_Spell.GetSpellName(spellID)
        if spellName then
          displayText = spellName
        end

        local spellTexture = C_Spell.GetSpellTexture(spellID)
        if spellTexture then
          displayIcon = spellTexture
        end
      end
      showFrame = true
    end
  end

  if not showFrame then
    frame:Hide()
    updateEmphasize()
    return
  end

  -- Font Update Workaround
  text:SetText("")
  local db = GetStanceTrackerDB()
  local fontSize = db["stance_tracker_font_size"] or 12
  text:SetFont(BUII_GetFontPath(), fontSize, BUII_GetFontFlags())
  text:SetShadowOffset(BUII_GetFontShadow())

  text:SetText(displayText)
  text:SetTextColor(textColor.r, textColor.g, textColor.b)
  icon:SetTexture(displayIcon)

  -- Visibility
  if db["stance_tracker_show_icon"] then
    icon:Show()
  else
    icon:Hide()
  end

  if db["stance_tracker_show_text"] then
    text:Show()
  else
    text:Hide()
  end

  -- Layout
  local iconSize = tonumber(db["stance_tracker_icon_size"]) or 20

  if db["stance_tracker_show_icon"] then
    icon:SetSize(iconSize, iconSize)
    icon:ClearAllPoints()
    icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
    text:ClearAllPoints()
    text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
  else
    text:ClearAllPoints()
    text:SetPoint("LEFT", frame, "LEFT", 0, 0)
  end

  frame:SetWidth(250) -- Fixed width to prevent alignment jumping
  frame:SetHeight(math.max(iconSize, text:GetStringHeight()))
  frame:Show()

  updateEmphasize()
end

local function onEvent(self, event, ...)
  updateDisplay()
end

local function BUII_StanceTracker_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_StanceTrackerFrame", UIParent, "BUII_StanceTrackerEditModeTemplate")
  frame:SetSize(100, 30) -- Initial size, updated by updateDisplay
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  -- Expose DB selector for EditModeUtils
  frame.GetSettingsDB = GetStanceTrackerDB
  icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
  text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetFont(BUII_GetFontPath(), 12, BUII_GetFontFlags())
  text:SetTextColor(1, 1, 1)
  text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
  text:SetJustifyH("LEFT")

  -- Emphasize Frame Setup
  empAnchor = CreateFrame("Frame", "BUII_StanceTrackerEmphasizeAnchor", UIParent)
  empAnchor:SetSize(1, 1)
  empAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 60)

  empFrame = CreateFrame("Frame", "BUII_StanceTrackerEmphasizeFrame", empAnchor)
  empFrame:SetSize(1, 1)
  empFrame:SetPoint("CENTER", empAnchor, "CENTER", 0, 0)
  empFrame:Hide()

  empText = empFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  empText:SetFont(BUII_GetFontPath(), 44, BUII_GetFontFlags())
  empText:SetTextColor(1, 1, 1)
  empText:SetPoint("CENTER", empFrame, "CENTER")

  empAnimGroup = empText:CreateAnimationGroup()
  empAnimGroup:SetLooping("REPEAT")

  local up = empAnimGroup:CreateAnimation("Translation")
  up:SetOrder(1)
  up:SetDuration(0.3)
  up:SetSmoothing("IN_OUT")

  local down = empAnimGroup:CreateAnimation("Translation")
  down:SetOrder(2)
  down:SetDuration(0.3)
  down:SetSmoothing("IN_OUT")

  -- Register System
  local settingsConfig = {
    {
      setting = enum_StanceTrackerSetting_ShowIcon,
      name = "Show Icon",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "stance_tracker_show_icon",
      getter = function(f)
        local db = GetStanceTrackerDB()
        return db["stance_tracker_show_icon"] and 1 or 0
      end,
      setter = function(f, val)
        local db = GetStanceTrackerDB()
        db["stance_tracker_show_icon"] = (val == 1)
        updateDisplay()
      end,
    },
    {
      setting = enum_StanceTrackerSetting_IconSize,
      name = "Icon Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 10,
      maxValue = 64,
      stepSize = 1,
      key = "stance_tracker_icon_size",
      formatter = function(value)
        return value
      end,
      getter = function(f)
        local db = GetStanceTrackerDB()
        return db["stance_tracker_icon_size"] or 20
      end,
      setter = function(f, val)
        local db = GetStanceTrackerDB()
        db["stance_tracker_icon_size"] = val
        updateDisplay()
      end,
    },
    {
      setting = enum_StanceTrackerSetting_ShowText,
      name = "Show Text",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "stance_tracker_show_text",
      getter = function(f)
        local db = GetStanceTrackerDB()
        return db["stance_tracker_show_text"] and 1 or 0
      end,
      setter = function(f, val)
        local db = GetStanceTrackerDB()
        db["stance_tracker_show_text"] = (val == 1)
        updateDisplay()
      end,
    },
    {
      setting = enum_StanceTrackerSetting_FontSize,
      name = "Font Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 32,
      stepSize = 1,
      key = "stance_tracker_font_size",
      formatter = function(value)
        return value
      end,
      getter = function(f)
        local db = GetStanceTrackerDB()
        return db["stance_tracker_font_size"] or 12
      end,
      setter = function(f, val)
        local db = GetStanceTrackerDB()
        db["stance_tracker_font_size"] = val
        text:SetFont(BUII_GetFontPath(), val, BUII_GetFontFlags())
        updateDisplay()
      end,
    },
    {
      setting = enum_StanceTrackerSetting_Emphasize,
      name = "Emphasize No Stance/Aura",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "stance_tracker_emphasize",
      getter = function(f)
        local db = GetStanceTrackerDB()
        return db["stance_tracker_emphasize"] and 1 or 0
      end,
      setter = function(f, val)
        local db = GetStanceTrackerDB()
        db["stance_tracker_emphasize"] = (val == 1)
        updateDisplay()
      end,
    },
    {
      setting = enum_StanceTrackerSetting_EmphasizeScale,
      name = "Emphasize Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 3.0,
      stepSize = 0.1,
      key = "stance_tracker_emp_scale",
      formatter = BUII_EditModeUtils.FormatPercentage,
      getter = function(f)
        local db = GetStanceTrackerDB()
        return db["stance_tracker_emp_scale"] or 1.0
      end,
      setter = function(f, val)
        local db = GetStanceTrackerDB()
        db["stance_tracker_emp_scale"] = val
        updateDisplay()
      end,
    },
    {
      setting = enum_StanceTrackerSetting_EmphasizeIntensity,
      name = "Emphasize Intensity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 100,
      stepSize = 5,
      key = "stance_tracker_emp_intensity",
      formatter = function(value)
        return value
      end,
      getter = function(f)
        local db = GetStanceTrackerDB()

        return db["stance_tracker_emp_intensity"] or 20
      end,
      setter = function(f, val)
        local db = GetStanceTrackerDB()
        db["stance_tracker_emp_intensity"] = val
        updateDisplay()
      end,
    },
    {
      setting = enum_StanceTrackerSetting_EmphasizeYOffset,
      name = "Emphasize Y Offset",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = -500,
      maxValue = 500,
      stepSize = 10,
      key = "stance_tracker_emp_y_offset",
      formatter = function(value)
        return value
      end,
      getter = function(f)
        local db = GetStanceTrackerDB()
        return db["stance_tracker_emp_y_offset"] or 60
      end,
      setter = function(f, val)
        local db = GetStanceTrackerDB()
        db["stance_tracker_emp_y_offset"] = val
        updateDisplay()
      end,
    },
  }

  BUII_EditModeUtils:AddScaleSetting(settingsConfig, enum_StanceTrackerSetting_Scale, "scale")

  BUII_EditModeUtils:AddCharacterSpecificSetting(settingsConfig, "stance_tracker", updateDisplay)

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_StanceTracker,
    "Stance Tracker",
    settingsConfig,
    "stance_tracker",
    {
      OnReset = function(f)
        updateDisplay()
      end,
      OnApplySettings = function(f)
        updateDisplay()
      end,
      OnEditModeEnter = function(f)
        updateDisplay()
      end,
      OnEditModeExit = function(f)
        updateDisplay()
      end,
    }
  )
end

function BUII_StanceTracker_Enable()
  BUII_StanceTracker_Initialize()

  frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
  frame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR") -- Sometimes relevant for stance bar updates
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)

  BUII_EditModeUtils:ApplySavedPosition(frame, "stance_tracker")

  -- Apply initial font size
  local db = GetStanceTrackerDB()
  if text and db["stance_tracker_font_size"] then
    text:SetFont(BUII_GetFontPath(), db["stance_tracker_font_size"], BUII_GetFontFlags())
  end

  updateDisplay()
end

function BUII_StanceTracker_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)
  frame:Hide()
  if empFrame then
    empFrame:Hide()
    empAnimGroup:Stop()
  end
end

function BUII_StanceTracker_Refresh()
  if frame then
    updateDisplay()
  end
end

function BUII_StanceTracker_GetDB()
  return GetStanceTrackerDB()
end

function BUII_StanceTracker_InitDB()
  -- BUIIDatabase initialization
  if BUIIDatabase["stance_tracker"] == nil then
    BUIIDatabase["stance_tracker"] = false
  end
  if BUIIDatabase["stance_tracker_druid"] == nil then
    BUIIDatabase["stance_tracker_druid"] = true
  end
  if BUIIDatabase["stance_tracker_paladin"] == nil then
    BUIIDatabase["stance_tracker_paladin"] = true
  end
  if BUIIDatabase["stance_tracker_rogue"] == nil then
    BUIIDatabase["stance_tracker_rogue"] = true
  end
  if BUIIDatabase["stance_tracker_warrior"] == nil then
    BUIIDatabase["stance_tracker_warrior"] = true
  end
  if BUIIDatabase["stance_tracker_icon_size"] == nil then
    BUIIDatabase["stance_tracker_icon_size"] = 20
  end
  if BUIIDatabase["stance_tracker_font_size"] == nil then
    BUIIDatabase["stance_tracker_font_size"] = 12
  end
  if BUIIDatabase["stance_tracker_show_icon"] == nil then
    BUIIDatabase["stance_tracker_show_icon"] = true
  end
  if BUIIDatabase["stance_tracker_show_text"] == nil then
    BUIIDatabase["stance_tracker_show_text"] = true
  end
  if BUIIDatabase["stance_tracker_emphasize"] == nil then
    BUIIDatabase["stance_tracker_emphasize"] = false
  end
  if BUIIDatabase["stance_tracker_emp_scale"] == nil then
    BUIIDatabase["stance_tracker_emp_scale"] = 1.0
  end
  if BUIIDatabase["stance_tracker_emp_intensity"] == nil then
    BUIIDatabase["stance_tracker_emp_intensity"] = 20
  end

  -- BUIICharacterDatabase initialization
  if BUIICharacterDatabase["stance_tracker_use_char_settings"] == nil then
    BUIICharacterDatabase["stance_tracker_use_char_settings"] = false
  end
  -- Mirror all global settings in character DB
  if BUIICharacterDatabase["stance_tracker"] == nil then
    BUIICharacterDatabase["stance_tracker"] = false
  end
  if BUIICharacterDatabase["stance_tracker_icon_size"] == nil then
    BUIICharacterDatabase["stance_tracker_icon_size"] = 20
  end
  if BUIICharacterDatabase["stance_tracker_font_size"] == nil then
    BUIICharacterDatabase["stance_tracker_font_size"] = 12
  end
  if BUIICharacterDatabase["stance_tracker_show_icon"] == nil then
    BUIICharacterDatabase["stance_tracker_show_icon"] = true
  end
  if BUIICharacterDatabase["stance_tracker_show_text"] == nil then
    BUIICharacterDatabase["stance_tracker_show_text"] = true
  end
  if BUIICharacterDatabase["stance_tracker_emphasize"] == nil then
    BUIICharacterDatabase["stance_tracker_emphasize"] = false
  end
  if BUIICharacterDatabase["stance_tracker_emp_scale"] == nil then
    BUIICharacterDatabase["stance_tracker_emp_scale"] = 1.0
  end
  if BUIICharacterDatabase["stance_tracker_emp_intensity"] == nil then
    BUIICharacterDatabase["stance_tracker_emp_intensity"] = 20
  end
end
