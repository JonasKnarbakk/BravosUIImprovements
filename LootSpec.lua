local addonName, addon = ...
local frame = nil
local icon = nil
local text = nil

-- Settings Constants
local enum_LootSpecSetting_Scale = 90
local enum_LootSpecSetting_ShowIcon = 91
local enum_LootSpecSetting_IconSize = 92
local enum_LootSpecSetting_ShowText = 93
local enum_LootSpecSetting_FontSize = 94

local function updateDisplay()
  if not frame then
    return
  end

  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
  local showIcon = BUIIDatabase["loot_spec_show_icon"]
  local showText = BUIIDatabase["loot_spec_show_text"]
  local iconSize = BUIIDatabase["loot_spec_icon_size"] or 20
  local fontSize = BUIIDatabase["loot_spec_font_size"] or 12

  -- Get loot specialization
  local lootSpecID = GetLootSpecialization()
  local specID, specName, specIcon

  if lootSpecID == 0 then
    -- "Current Spec" is selected, use active spec
    local currentSpec = GetSpecialization()
    if currentSpec then
      specID, specName, _, specIcon = GetSpecializationInfo(currentSpec)
    end
  else
    -- Specific loot spec is selected
    for i = 1, GetNumSpecializations() do
      local id, name, _, iconTexture = GetSpecializationInfo(i)
      if id == lootSpecID then
        specID = id
        specName = name
        specIcon = iconTexture
        break
      end
    end
  end

  -- If we couldn't determine spec, hide and return
  if not specName or not specIcon then
    if not isEditMode then
      frame:Hide()
      return
    else
      specName = "Loot Spec"
      specIcon = 134400 -- Question mark icon
    end
  end

  -- Update icon
  if showIcon then
    icon:SetTexture(specIcon)
    icon:SetSize(iconSize, iconSize)
    icon:Show()
  else
    icon:Hide()
  end

  -- Update text
  if showText then
    text:SetFont(BUII_GetFontPath(), fontSize, "OUTLINE")
    text:SetText(specName)
    text:Show()
  else
    text:Hide()
  end

  -- Calculate frame size and position elements
  local totalWidth = 0
  local totalHeight = 0

  if showIcon and showText then
    -- Side by side layout
    icon:ClearAllPoints()
    icon:SetPoint("LEFT", frame, "LEFT")

    text:ClearAllPoints()
    text:SetPoint("LEFT", icon, "RIGHT", 4, 0)

    totalWidth = iconSize + 4 + text:GetStringWidth()
    totalHeight = math.max(iconSize, text:GetStringHeight())
  elseif showIcon then
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", frame, "CENTER")

    totalWidth = iconSize
    totalHeight = iconSize
  elseif showText then
    text:ClearAllPoints()
    text:SetPoint("CENTER", frame, "CENTER")

    totalWidth = text:GetStringWidth()
    totalHeight = text:GetStringHeight()
  else
    -- Nothing to show, but keep a minimum size for edit mode
    totalWidth = 50
    totalHeight = 20
  end

  frame:SetSize(math.max(totalWidth, 10), math.max(totalHeight, 10))

  if isEditMode or (specName and specIcon) then
    frame:Show()
  else
    frame:Hide()
  end
end

local function onEvent(self, event, ...)
  if event == "EDIT_MODE_LAYOUTS_UPDATED" then
    BUII_EditModeUtils:ApplySavedPosition(frame, "loot_spec")
    return
  end

  if
    event == "PLAYER_LOOT_SPEC_UPDATED"
    or event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "PLAYER_ENTERING_WORLD"
  then
    updateDisplay()
  end
end

local function BUII_LootSpec_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_LootSpecFrame", UIParent, "BUII_LootSpecEditModeTemplate")
  frame:SetSize(100, 20)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  -- Set default position
  frame.defaultPoint = "CENTER"
  frame.defaultRelativePoint = "CENTER"
  frame.defaultX = 0
  frame.defaultY = -150

  -- Create icon
  icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("LEFT", frame, "LEFT")

  -- Create text
  text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetFont(BUII_GetFontPath(), 12, "OUTLINE")
  text:SetTextColor(1, 1, 1, 1) -- White text
  text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
  text:SetJustifyH("LEFT")

  -- Register System
  local settingsConfig = {
    {
      setting = enum_LootSpecSetting_Scale,
      name = "Scale",
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
      setting = enum_LootSpecSetting_ShowIcon,
      name = "Show Icon",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      getter = function(f)
        return BUIIDatabase["loot_spec_show_icon"] and 1 or 0
      end,
      setter = function(f, val)
        BUIIDatabase["loot_spec_show_icon"] = (val == 1)
        updateDisplay()
      end,
    },
    {
      setting = enum_LootSpecSetting_IconSize,
      name = "Icon Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 10,
      maxValue = 50,
      stepSize = 1,
      formatter = function(val)
        return math.floor(val + 0.5)
      end,
      getter = function(f)
        return BUIIDatabase["loot_spec_icon_size"] or 20
      end,
      setter = function(f, val)
        BUIIDatabase["loot_spec_icon_size"] = val
        updateDisplay()
      end,
    },
    {
      setting = enum_LootSpecSetting_ShowText,
      name = "Show Text",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      getter = function(f)
        return BUIIDatabase["loot_spec_show_text"] and 1 or 0
      end,
      setter = function(f, val)
        BUIIDatabase["loot_spec_show_text"] = (val == 1)
        updateDisplay()
      end,
    },
    {
      setting = enum_LootSpecSetting_FontSize,
      name = "Font Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 32,
      stepSize = 1,
      formatter = function(val)
        return math.floor(val + 0.5)
      end,
      getter = function(f)
        return BUIIDatabase["loot_spec_font_size"] or 12
      end,
      setter = function(f, val)
        BUIIDatabase["loot_spec_font_size"] = val
        updateDisplay()
      end,
    },
  }

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_LootSpec,
    "Loot Specialization",
    settingsConfig,
    "loot_spec",
    {
      OnReset = function(f)
        updateDisplay()
      end,
      OnApplySettings = function(f)
        updateDisplay()
      end,
    }
  )
end

-- Edit Mode Integration
local function editMode_OnEnter()
  frame:EnableMouse(true)
  updateDisplay()
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  updateDisplay()
end

function BUII_LootSpec_Enable()
  BUII_LootSpec_Initialize()

  frame:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
  frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_LootSpec_Custom_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_LootSpec_Custom_OnExit")

  BUII_EditModeUtils:ApplySavedPosition(frame, "loot_spec")
  updateDisplay()
end

function BUII_LootSpec_Disable()
  if not frame then
    return
  end
  frame:UnregisterEvent("PLAYER_LOOT_SPEC_UPDATED")
  frame:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_LootSpec_Custom_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_LootSpec_Custom_OnExit")

  frame:Hide()
end

function BUII_LootSpec_InitDB()
  if BUIIDatabase["loot_spec"] == nil then
    BUIIDatabase["loot_spec"] = false
  end
  if BUIIDatabase["loot_spec_show_icon"] == nil then
    BUIIDatabase["loot_spec_show_icon"] = true
  end
  if BUIIDatabase["loot_spec_show_text"] == nil then
    BUIIDatabase["loot_spec_show_text"] = true
  end
  if BUIIDatabase["loot_spec_icon_size"] == nil then
    BUIIDatabase["loot_spec_icon_size"] = 20
  end
  if BUIIDatabase["loot_spec_font_size"] == nil then
    BUIIDatabase["loot_spec_font_size"] = 12
  end
end
