local addonName, addon = ...
local frame = nil
local rows = {}
local title = nil

-- Stats Definitions
local STATS = {
  { key = "crit", label = "Crit", name = "Critical Strike", func = GetCritChance, percent = true },
  { key = "haste", label = "Haste", name = "Haste", func = GetHaste, percent = true },
  { key = "mastery", label = "Mastery", name = "Mastery", func = GetMasteryEffect, percent = true },
  {
    key = "vers",
    label = "Vers",
    name = "Versatility",
    func = function()
      return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
    end,
    percent = true,
  },
  { key = "leech", label = "Leech", name = "Leech", func = GetLifesteal, percent = true },
  { key = "speed", label = "Speed", name = "Speed", func = GetSpeed, percent = true },
  { key = "avoidance", label = "Avoidance", name = "Avoidance", func = GetAvoidance, percent = true },
  { key = "dodge", label = "Dodge", name = "Dodge", func = GetDodgeChance, percent = true },
  { key = "parry", label = "Parry", name = "Parry", func = GetParryChance, percent = true },
  { key = "block", label = "Block", name = "Block", func = GetShieldBlock, percent = true },
}

-- Settings Constants
local enum_StatPanelSetting_UseCharSettings = 80
local enum_StatPanelSetting_Scale = 81
local enum_StatPanelSetting_FontSize = 82
local enum_StatPanelSetting_RowSpacing = 83
local enum_StatPanelSetting_BackgroundOpacity = 84
local enum_StatPanelSetting_Width = 85
local enum_StatPanelSetting_ShowTitle = 86

-- Start dynamic enums for stats from 100
local STAT_ENUM_START = 100

local function GetStatPanelDB()
  if BUIICharacterDatabase and BUIICharacterDatabase["stat_panel_use_char_settings"] then
    return BUIICharacterDatabase
  end
  return BUIIDatabase
end

local function FormatValue(value, isPercent)
  if isPercent then
    return string.format("%.1f%%", value)
  else
    return string.format("%.1f", value)
  end
end

local function UpdateStats()
  if not frame then
    return
  end

  local db = GetStatPanelDB()

  -- Style
  local fontSize = db.stat_panel_font_size or 12
  local spacing = db.stat_panel_row_spacing or 2
  local width = db.stat_panel_width or 120
  local bgOpacity = db.stat_panel_background_opacity or 0.5

  frame:SetWidth(width)
  frame.Background:SetAlpha(bgOpacity)

  -- Title
  local currentY = -5
  if db.stat_panel_show_title then
    title:Show()
    title:SetFont(BUII_GetFontPath(), fontSize + 2, "OUTLINE")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    currentY = currentY - (fontSize + 2) - 5
  else
    title:Hide()
  end

  -- Stats
  local visibleRows = 0
  for i, statDef in ipairs(STATS) do
    local isEnabled = db["stat_panel_show_" .. statDef.key]
    if isEnabled == nil then
      isEnabled = true
    end -- Default to true

    if isEnabled then
      visibleRows = visibleRows + 1
      if not rows[i] then
        local row = CreateFrame("Frame", nil, frame)
        row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.Label:SetJustifyH("LEFT")
        row.Value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.Value:SetJustifyH("RIGHT")
        rows[i] = row
      end

      local row = rows[i]
      row:Show()
      row:SetHeight(fontSize)
      row:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, currentY)
      row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, currentY)

      row.Label:SetFont(BUII_GetFontPath(), fontSize, "OUTLINE")
      row.Label:SetText(statDef.label)
      row.Label:SetPoint("LEFT", row, "LEFT", 0, 0)

      row.Value:SetFont(BUII_GetFontPath(), fontSize, "OUTLINE")
      local val = statDef.func()
      row.Value:SetText(FormatValue(val, statDef.percent))
      row.Value:SetPoint("RIGHT", row, "RIGHT", 0, 0)

      currentY = currentY - fontSize - spacing
    else
      if rows[i] then
        rows[i]:Hide()
      end
    end
  end

  local totalHeight = math.abs(currentY) - spacing + 5
  if visibleRows == 0 and db.stat_panel_show_title then
    totalHeight = math.abs(currentY) + 5
  elseif visibleRows == 0 then
    totalHeight = 20 -- Minimum height to grab
  end

  frame:SetHeight(totalHeight)
end

local function onEvent(self, event, ...)
  if event == "EDIT_MODE_LAYOUTS_UPDATED" then
    BUII_EditModeUtils:ApplySavedPosition(frame, "stat_panel")
    return
  end

  UpdateStats()
end

local function BUII_StatPanel_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_StatPanelFrame", UIParent, "EditModeSystemTemplate")
  frame:SetSize(120, 100)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)

  -- Selection Frame for Edit Mode
  frame.Selection = CreateFrame("Frame", nil, frame, "EditModeSystemSelectionTemplate")
  frame.Selection:SetAllPoints(frame)
  frame.Selection:Hide()

  -- Backdrop
  frame.Background = frame:CreateTexture(nil, "BACKGROUND")
  frame.Background:SetAllPoints(frame)
  frame.Background:SetColorTexture(0, 0, 0)
  frame.Background:SetAlpha(0.5)

  -- Title
  title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetText("Stats")
  title:SetJustifyH("CENTER")

  -- Ensure system is set and OnSystemLoad is fully processed
  frame.system = Enum.EditModeSystem.BUII_StatPanel
  frame.systemNameString = _G["BUII_HUD_EDIT_MODE_STAT_PANEL_LABEL"]
  if frame.OnSystemLoad then
    frame:OnSystemLoad()
  end

  -- Edit Mode Configuration
  local settingsConfig = {
    {
      setting = enum_StatPanelSetting_UseCharSettings,
      name = "Character Specific",
      key = "stat_panel_use_char_settings",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      getter = function(f)
        return BUIICharacterDatabase["stat_panel_use_char_settings"] and 1 or 0
      end,
      setter = function(f, val)
        BUIICharacterDatabase["stat_panel_use_char_settings"] = (val == 1)
        if f.UpdateSystem then
          f:UpdateSystem()
        end
        UpdateStats()
      end,
    },
    {
      setting = enum_StatPanelSetting_Scale,
      name = "Scale",
      key = "stat_panel_scale",
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
      setting = enum_StatPanelSetting_Width,
      name = "Width",
      key = "stat_panel_width",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 80,
      maxValue = 300,
      stepSize = 5,
      defaultValue = 120,
      getter = function(f)
        return GetStatPanelDB().stat_panel_width or 120
      end,
      setter = function(f, val)
        GetStatPanelDB().stat_panel_width = val
        UpdateStats()
      end,
    },
    {
      setting = enum_StatPanelSetting_FontSize,
      name = "Font Size",
      key = "stat_panel_font_size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 32,
      stepSize = 1,
      defaultValue = 12,
      getter = function(f)
        return GetStatPanelDB().stat_panel_font_size or 12
      end,
      setter = function(f, val)
        GetStatPanelDB().stat_panel_font_size = val
        UpdateStats()
      end,
    },
    {
      setting = enum_StatPanelSetting_RowSpacing,
      name = "Row Spacing",
      key = "stat_panel_row_spacing",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 10,
      stepSize = 1,
      defaultValue = 2,
      getter = function(f)
        return GetStatPanelDB().stat_panel_row_spacing or 2
      end,
      setter = function(f, val)
        GetStatPanelDB().stat_panel_row_spacing = val
        UpdateStats()
      end,
    },
    {
      setting = enum_StatPanelSetting_BackgroundOpacity,
      name = "Background Opacity",
      key = "stat_panel_background_opacity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 1,
      stepSize = 0.1,
      formatter = BUII_EditModeUtils.FormatPercentage,
      defaultValue = 0.5,
      getter = function(f)
        return GetStatPanelDB().stat_panel_background_opacity or 0.5
      end,
      setter = function(f, val)
        GetStatPanelDB().stat_panel_background_opacity = val
        UpdateStats()
      end,
    },
    {
      setting = enum_StatPanelSetting_ShowTitle,
      name = "Show Title",
      key = "stat_panel_show_title",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = true,
      getter = function(f)
        return GetStatPanelDB().stat_panel_show_title and 1 or 0
      end,
      setter = function(f, val)
        GetStatPanelDB().stat_panel_show_title = (val == 1)
        UpdateStats()
      end,
    },
  }

  -- Add stats checkboxes
  for i, statDef in ipairs(STATS) do
    table.insert(settingsConfig, {
      setting = STAT_ENUM_START + i,
      name = "Show " .. statDef.name,
      key = "stat_panel_show_" .. statDef.key,
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = true,
      getter = function(f)
        local val = GetStatPanelDB()["stat_panel_show_" .. statDef.key]
        if val == nil then
          return 1
        end
        return val and 1 or 0
      end,
      setter = function(f, val)
        GetStatPanelDB()["stat_panel_show_" .. statDef.key] = (val == 1)
        UpdateStats()
      end,
    })
  end

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_StatPanel,
    "Stat Panel",
    settingsConfig,
    "stat_panel",
    {
      OnReset = function(f)
        local db = GetStatPanelDB()
        db.stat_panel_width = 120
        db.stat_panel_font_size = 12
        db.stat_panel_row_spacing = 2
        db.stat_panel_background_opacity = 0.5
        db.stat_panel_show_title = true
        for _, stat in ipairs(STATS) do
          db["stat_panel_show_" .. stat.key] = true
        end
        UpdateStats()
      end,
      OnApplySettings = function(f)
        UpdateStats()
      end,
    }
  )
end

-- Edit Mode Callbacks
local function editMode_OnEnter()
  frame:EnableMouse(true)
  UpdateStats()
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  UpdateStats()
end

function BUII_StatPanel_Enable()
  BUII_StatPanel_Initialize()

  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("UNIT_STATS")
  frame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
  frame:RegisterEvent("SPELL_POWER_CHANGED")
  frame:RegisterEvent("COMBAT_RATING_UPDATE")
  frame:RegisterEvent("MASTERY_UPDATE")
  frame:RegisterEvent("SPEED_UPDATE")
  frame:RegisterEvent("LIFESTEAL_UPDATE")
  frame:RegisterEvent("AVOIDANCE_UPDATE")

  frame:SetScript("OnEvent", onEvent)

  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_StatPanel_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_StatPanel_OnExit")

  BUII_EditModeUtils:ApplySavedPosition(frame, "stat_panel")
  UpdateStats()
  frame:Show()
end

function BUII_StatPanel_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_StatPanel_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_StatPanel_OnExit")

  frame:Hide()
end

function BUII_StatPanel_InitDB()
  -- BUIIDatabase initialization
  if BUIIDatabase["stat_panel"] == nil then
    BUIIDatabase["stat_panel"] = false
  end
  if BUIIDatabase["stat_panel_width"] == nil then
    BUIIDatabase["stat_panel_width"] = 120
  end
  if BUIIDatabase["stat_panel_font_size"] == nil then
    BUIIDatabase["stat_panel_font_size"] = 12
  end
  if BUIIDatabase["stat_panel_row_spacing"] == nil then
    BUIIDatabase["stat_panel_row_spacing"] = 2
  end
  if BUIIDatabase["stat_panel_background_opacity"] == nil then
    BUIIDatabase["stat_panel_background_opacity"] = 0.5
  end
  if BUIIDatabase["stat_panel_show_title"] == nil then
    BUIIDatabase["stat_panel_show_title"] = true
  end
  if BUIIDatabase["stat_panel_show_crit"] == nil then
    BUIIDatabase["stat_panel_show_crit"] = true
  end
  if BUIIDatabase["stat_panel_show_haste"] == nil then
    BUIIDatabase["stat_panel_show_haste"] = true
  end
  if BUIIDatabase["stat_panel_show_mastery"] == nil then
    BUIIDatabase["stat_panel_show_mastery"] = true
  end
  if BUIIDatabase["stat_panel_show_vers"] == nil then
    BUIIDatabase["stat_panel_show_vers"] = true
  end
  if BUIIDatabase["stat_panel_show_leech"] == nil then
    BUIIDatabase["stat_panel_show_leech"] = true
  end
  if BUIIDatabase["stat_panel_show_speed"] == nil then
    BUIIDatabase["stat_panel_show_speed"] = true
  end
  if BUIIDatabase["stat_panel_show_avoidance"] == nil then
    BUIIDatabase["stat_panel_show_avoidance"] = true
  end
  if BUIIDatabase["stat_panel_show_dodge"] == nil then
    BUIIDatabase["stat_panel_show_dodge"] = true
  end
  if BUIIDatabase["stat_panel_show_parry"] == nil then
    BUIIDatabase["stat_panel_show_parry"] = true
  end
  if BUIIDatabase["stat_panel_show_block"] == nil then
    BUIIDatabase["stat_panel_show_block"] = true
  end

  -- BUIICharacterDatabase initialization
  if BUIICharacterDatabase["stat_panel_use_char_settings"] == nil then
    BUIICharacterDatabase["stat_panel_use_char_settings"] = false
  end
end
