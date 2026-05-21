local addonName, addon = ...
---@class BUII_ResourceTrackerEditModeTemplate : BUII_ManagedFrame
---@type Frame|BUII_ResourceTrackerEditModeTemplate|any|nil
local frame = nil
---@type FontString|nil
local counterText = nil
---@type BUII_ResourcePointTemplate[]
local points = {}

local enum_ResourceTrackerSetting_Scale = 60
local enum_ResourceTrackerSetting_TotalWidth = 61
local enum_ResourceTrackerSetting_Spacing = 62
local enum_ResourceTrackerSetting_Height = 63
local enum_ResourceTrackerSetting_ShowText = 64
local enum_ResourceTrackerSetting_ShowDecimal = 65
local enum_ResourceTrackerSetting_FontSize = 66
local enum_ResourceTrackerSetting_ShowBorder = 67
local enum_ResourceTrackerSetting_UseClassColor = 68
local enum_ResourceTrackerSetting_ResourceOpacity = 69
local enum_ResourceTrackerSetting_BackgroundOpacity = 70
local enum_ResourceTrackerSetting_FrameStrata = 71
local enum_ResourceTrackerSetting_HideNativeFrame = 72
local enum_ResourceTrackerSetting_ShowPowerBar = 73
local enum_ResourceTrackerSetting_PowerBarHeight = 74
local enum_ResourceTrackerSetting_PowerBarPadding = 75
local enum_ResourceTrackerSetting_PowerBarShowText = 76
local enum_ResourceTrackerSetting_PowerBarFontSize = 77

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

local GetResourceTrackerDB = BUII_ResourceTracker_GetDB
local GetActiveConfig = BUII_ResourceTracker_GetActiveConfig

---@type boolean|nil
local nativeFrameHideHook = nil

local function UpdateNativeFrameVisibility()
  local db = GetResourceTrackerDB()
  local config = GetActiveConfig()

  if not config then
    local _, classFilename = UnitClass("player")
    local rawConfig = BUII_ResourceTracker_CONFIG[classFilename]
    if rawConfig then
      -- If rawConfig is a list (like Mage, Shaman, Priest etc.) check the first one or iterate
      if not rawConfig.nativeFrame and rawConfig[1] then
        rawConfig = rawConfig[1]
      end
      if rawConfig and rawConfig.nativeFrame then
        local nativeFrame = _G[rawConfig.nativeFrame]
        if nativeFrame then
          nativeFrame:Show()
        end
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
      nativeFrame:Show()
    end
  end
end

local function UpdatePoints()
  if not frame or frame.isApplyingSettings then
    return
  end

  local db = GetResourceTrackerDB()
  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()

  local strataIndex = db.resource_tracker_frame_strata or 2
  local strataValue = FRAME_STRATA_VALUES[strataIndex] or "LOW"
  frame:SetFrameStrata(strataValue)

  local _, classFilename = UnitClass("player")

  -- Check if there's any active config or if we are in Edit Mode
  local activeConfig = GetActiveConfig()
  if not activeConfig and not isEditMode then
    frame:Hide()
    return
  end

  -- Retrieve class module
  local module = BUII_ResourceTracker_GetModule(classFilename)
  if module then
    -- Clean/reset OnUpdate script in case the spec setup changes
    frame:SetScript("OnUpdate", nil)

    frame.shouldShow = true
    module:SetupLayout(frame)
    module:Update(frame, db, isEditMode)
    
    if not frame.shouldShow then
      frame:Hide()
      return
    end
    
    frame:Show()
    UpdateNativeFrameVisibility()
  else
    frame:Hide()
    return
  end

  -- Update secondary power bar (mana, energy, focus, etc.) underneath
  BUII_ResourceTracker_LayoutHelper:UpdatePowerBar(frame)
end

local function RequestUpdatePoints()
  RunNextFrame(UpdatePoints)
end

local function onEvent(self, event, ...)
  UpdatePoints()
end

local function BUII_ResourceTracker_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_ResourceTrackerFrame", UIParent, "BUII_ResourceTrackerEditModeTemplate")
  frame:SetSize(174, 20)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  -- Expose DB selector for EditModeUtils
  frame.GetSettingsDB = GetResourceTrackerDB

  frame.PowerBar = CreateFrame("Frame", nil, frame, "BUII_PowerBarTemplate")
  frame.PowerBar:SetHeight(4)
  frame.PowerBar.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())
  frame.PowerBar:Hide()

  frame.ResourceBar = CreateFrame("Frame", nil, frame, "BUII_PowerBarTemplate")
  frame.ResourceBar:SetAllPoints(frame)
  frame.ResourceBar.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())
  frame.ResourceBar:Hide()

  local textFrame = CreateFrame("Frame", nil, frame)
  textFrame:SetAllPoints(frame)
  textFrame:SetFrameLevel(frame:GetFrameLevel() + 10)

  counterText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  counterText:SetPoint("CENTER", textFrame, "TOPLEFT", 85, -10)
  counterText:SetText("0")

  -- Expose for LayoutHelper
  frame.CounterText = counterText
  frame.Points = points

  local settingsConfig = {
    {
      setting = enum_ResourceTrackerSetting_TotalWidth,
      name = "Total Width",
      key = "resource_tracker_total_width",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 50,
      maxValue = 500,
      stepSize = 1,
      defaultValue = 174,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentTotalWidth or 174
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
      setting = enum_ResourceTrackerSetting_ShowDecimal,
      name = "Show Decimal",
      key = "resource_tracker_show_decimal",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_show_decimal and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_show_decimal = (val == 1)
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
      setting = enum_ResourceTrackerSetting_ShowPowerBar,
      name = "Show Power Bar",
      key = "resource_tracker_show_power_bar",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_show_power_bar and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_show_power_bar = (val == 1)
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_PowerBarHeight,
      name = "Power Bar Height",
      key = "resource_tracker_power_bar_height",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 2,
      maxValue = 20,
      stepSize = 1,
      defaultValue = 4,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_power_bar_height or 4
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_power_bar_height = val
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_PowerBarPadding,
      name = "Power Bar Padding",
      key = "resource_tracker_power_bar_padding",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 20,
      stepSize = 1,
      defaultValue = 2,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_power_bar_padding or 2
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_power_bar_padding = val
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_PowerBarShowText,
      name = "Power Bar Show Text",
      key = "resource_tracker_power_bar_show_text",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_power_bar_show_text and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_power_bar_show_text = (val == 1)
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_PowerBarFontSize,
      name = "Power Bar Font Size",
      key = "resource_tracker_power_bar_font_size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 32,
      stepSize = 1,
      defaultValue = 12,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_power_bar_font_size or 12
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_power_bar_font_size = val
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_FrameStrata,
      name = "Frame Strata",
      key = "resource_tracker_frame_strata",
      type = Enum.EditModeSettingDisplayType.Dropdown,
      defaultValue = 2,
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

  BUII_EditModeUtils:AddScaleSetting(
    settingsConfig,
    enum_ResourceTrackerSetting_Scale,
    "Scale",
    "resource_tracker_scale"
  )

  BUII_EditModeUtils:AddCharacterSpecificSetting(settingsConfig, "resource_tracker", UpdatePoints)

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
        db.currentTotalWidth = 174
        db.currentHeight = 12
        db.showText = false
        db.currentFontSize = 12
        db.resource_tracker_show_border = false
        db.resource_tracker_use_class_color = false
        db.resource_tracker_frame_strata = 2
        db.resource_tracker_background_opacity = 0.5
        db.resource_tracker_show_power_bar = false
        db.resource_tracker_power_bar_height = 4
        db.resource_tracker_power_bar_padding = 2
        db.resource_tracker_power_bar_show_text = false
        db.resource_tracker_power_bar_font_size = 12
        UpdatePoints()
      end,

      OnApplySettings = function(f)
        UpdatePoints()
      end,
      OnEditModeEnter = function(f)
        UpdatePoints()
      end,
      OnEditModeExit = function(f)
        if not InCombatLockdown() then
          UpdatePoints()
        end
      end,
    }
  )
end

function BUII_ResourceTracker_Enable()
  BUII_ResourceTracker_Initialize()

  frame:RegisterUnitEvent("UNIT_AURA", "player")
  frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
  frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
  frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
  frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
  frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player")
  frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
  frame:RegisterEvent("SPELL_UPDATE_CHARGES")
  frame:RegisterEvent("RUNE_POWER_UPDATE")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)
  frame:Show()

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
  frame:Hide()

  local _, classFilename = UnitClass("player")
  local rawConfig = BUII_ResourceTracker_CONFIG[classFilename]
  if rawConfig then
    if not rawConfig.nativeFrame and rawConfig[1] then
      rawConfig = rawConfig[1]
    end
    if rawConfig and rawConfig.nativeFrame then
      local nativeFrame = _G[rawConfig.nativeFrame]
      if nativeFrame then
        nativeFrame:Show()
      end
    end
  end
end

function BUII_ResourceTracker_Refresh()
  if frame then
    UpdatePoints()
  end
end

function BUII_ResourceTracker_InitDB()
  MergeDefaults(BUIIDatabase, BUII_ResourceTracker_DB_DEFAULTS)
  MergeDefaults(BUIICharacterDatabase, BUII_ResourceTracker_CHAR_DB_DEFAULTS)
end

BUII_RegisterModule({
  dbKey = "resource_tracker",
  enable = BUII_ResourceTracker_Enable,
  disable = BUII_ResourceTracker_Disable,
  refresh = BUII_ResourceTracker_Refresh,
  refreshTexture = true,
  checkboxPath = "weakAura.ResourceTracker",
  alwaysSetChecked = true,
})
