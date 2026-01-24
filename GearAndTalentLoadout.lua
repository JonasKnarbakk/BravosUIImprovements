local frame = nil
local contentFrame = nil
local icon = nil
local gearText = nil
local talentText = nil

-- Settings Constants
local enum_GearTalentSetting_Scale = 40
local enum_GearTalentSetting_IconSize = 41
local enum_GearTalentSetting_FontSize = 42
local enum_GearTalentSetting_VerticalSpacing = 43

-- Default values
local DEFAULT_ICON_SIZE = 40
local DEFAULT_TEXT_FONT_SIZE = 22
local DEFAULT_VERTICAL_SPACING = 2

local function UpdateDisplay()
  if not frame or not contentFrame then
    return
  end

  local iconSize = BUIIDatabase["gear_talent_icon_size"] or DEFAULT_ICON_SIZE
  local fontSize = BUIIDatabase["gear_talent_font_size"] or DEFAULT_TEXT_FONT_SIZE
  local verticalSpacing = BUIIDatabase["gear_talent_vertical_spacing"] or DEFAULT_VERTICAL_SPACING

  local loadoutName = "Default"

  -- Get Talent Loadout
  local specId = PlayerUtil.GetCurrentSpecID()
  if specId then
    local configId = C_ClassTalents.GetLastSelectedSavedConfigID(specId)
    if configId then
      local configInfo = C_Traits.GetConfigInfo(configId)
      if configInfo and configInfo.name then
        loadoutName = configInfo.name
      end
    end
  end
  -- Get Equipment Set
  local foundSet = false
  local setName = "Unsaved Set"

  for i = 0, C_EquipmentSet.GetNumEquipmentSets() - 1 do
    local name, texture, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(i)
    if isEquipped then
      icon:SetTexture(texture)
      setName = name
      foundSet = true
      break
    end
  end

  if not foundSet then
    icon:SetTexture(134400) -- Question mark icon
  end

  gearText:SetText(setName)
  talentText:SetText(loadoutName)

  icon:SetSize(iconSize, iconSize)

  gearText:SetFont(BUII_GetFontPath(), fontSize, BUII_GetFontFlags())
  talentText:SetFont(BUII_GetFontPath(), fontSize, BUII_GetFontFlags())

  gearText:SetShadowOffset(BUII_GetFontShadow())
  talentText:SetShadowOffset(BUII_GetFontShadow())

  gearText:ClearAllPoints()
  gearText:SetPoint("BOTTOM", contentFrame, "CENTER", 0, iconSize / 2 + verticalSpacing)

  talentText:ClearAllPoints()
  talentText:SetPoint("TOP", contentFrame, "CENTER", 0, -(iconSize / 2 + verticalSpacing))

  -- Calculate total height based on icon + text heights
  local gearHeight = gearText:GetStringHeight()
  local talentHeight = talentText:GetStringHeight()
  local totalHeight = gearHeight + iconSize + talentHeight + (verticalSpacing * 2) + 4 -- 4px padding

  -- Calculate width based on the widest element
  local maxTextWidth = math.max(gearText:GetStringWidth(), talentText:GetStringWidth())
  local totalWidth = math.max(iconSize, maxTextWidth) + 10 -- 10px horizontal padding

  -- Resize content frame - positioning frame stays fixed
  contentFrame:SetSize(totalWidth, totalHeight)

  frame:SetSize(iconSize, iconSize)
end

local function onEvent(self, event, ...)
  if event == "EQUIPMENT_SETS_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
    UpdateDisplay()
  end

  -- Need a delay otherwise we get the old set info
  if event == "EQUIPMENT_SWAP_FINISHED" then
    C_Timer.NewTimer(1, function()
      UpdateDisplay()
    end)
  end
end

local function BUII_GearAndTalentLoadout_Initialize()
  if frame then
    return
  end

  -- Create positioning frame (small, stable anchor that Edit Mode controls)
  frame = CreateFrame("Frame", "BUII_GearAndTalentLoadoutFrame", UIParent, "BUII_GearAndTalentLoadoutEditModeTemplate")
  frame:SetSize(DEFAULT_ICON_SIZE, DEFAULT_ICON_SIZE) -- Initial size, updated by UpdateDisplay
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  frame.defaultPoint = "CENTER"
  frame.defaultRelativePoint = "CENTER"
  frame.defaultX = 0
  frame.defaultY = -100

  -- Create content frame - holds all visual elements, centered on positioning frame
  -- Parent to positioning frame so it scales together
  contentFrame = CreateFrame("Frame", nil, frame)
  contentFrame:SetSize(100, 100) -- Initial size, updated by UpdateDisplay
  contentFrame:SetPoint("CENTER", frame, "CENTER")
  contentFrame:SetFrameStrata("LOW")

  -- Create icon texture - anchored to content frame center
  icon = contentFrame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(DEFAULT_ICON_SIZE, DEFAULT_ICON_SIZE)
  icon:SetPoint("CENTER", contentFrame, "CENTER")
  icon:SetTexCoord(0, 1, 0, 1) -- No zoom

  -- Create gear text - anchored BOTTOM to CENTER of content frame
  gearText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  gearText:SetFontObject("GameFontHighlight")
  gearText:SetFont(BUII_GetFontPath(), DEFAULT_TEXT_FONT_SIZE, BUII_GetFontFlags())
  gearText:SetPoint("BOTTOM", contentFrame, "CENTER", 0, DEFAULT_ICON_SIZE / 2 + DEFAULT_VERTICAL_SPACING)
  gearText:SetJustifyH("CENTER")

  -- Create talent text - anchored TOP to CENTER of content frame
  talentText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  talentText:SetFontObject("GameFontHighlight")
  talentText:SetFont(BUII_GetFontPath(), DEFAULT_TEXT_FONT_SIZE, BUII_GetFontFlags())
  talentText:SetPoint("TOP", contentFrame, "CENTER", 0, -(DEFAULT_ICON_SIZE / 2 + DEFAULT_VERTICAL_SPACING))
  talentText:SetJustifyH("CENTER")

  -- Register System
  local settingsConfig = {
    {
      setting = enum_GearTalentSetting_IconSize,
      name = "Icon Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 20,
      maxValue = 80,
      stepSize = 2,
      formatter = function(val)
        return math.floor(val + 0.5)
      end,
      getter = function(f)
        return BUIIDatabase["gear_talent_icon_size"] or DEFAULT_ICON_SIZE
      end,
      setter = function(f, val)
        BUIIDatabase["gear_talent_icon_size"] = val
        UpdateDisplay()
      end,
      key = "gear_talent_icon_size",
      defaultValue = DEFAULT_ICON_SIZE,
    },
    {
      setting = enum_GearTalentSetting_FontSize,
      name = "Font Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 10,
      maxValue = 40,
      stepSize = 1,
      formatter = function(val)
        return math.floor(val + 0.5)
      end,
      getter = function(f)
        return BUIIDatabase["gear_talent_font_size"] or DEFAULT_TEXT_FONT_SIZE
      end,
      setter = function(f, val)
        BUIIDatabase["gear_talent_font_size"] = val
        UpdateDisplay()
      end,
      key = "gear_talent_font_size",
      defaultValue = DEFAULT_TEXT_FONT_SIZE,
    },
    {
      setting = enum_GearTalentSetting_VerticalSpacing,
      name = "Vertical Spacing",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = -10,
      maxValue = 20,
      stepSize = 1,
      formatter = function(val)
        return math.floor(val + 0.5)
      end,
      getter = function(f)
        return BUIIDatabase["gear_talent_vertical_spacing"] or DEFAULT_VERTICAL_SPACING
      end,
      setter = function(f, val)
        BUIIDatabase["gear_talent_vertical_spacing"] = val
        UpdateDisplay()
      end,
      key = "gear_talent_vertical_spacing",
      defaultValue = DEFAULT_VERTICAL_SPACING,
    },
  }

  BUII_EditModeUtils:AddScaleSetting(settingsConfig, enum_GearTalentSetting_Scale, "scale")

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_GearAndTalentLoadout,
    "Gear & Talent Loadout",
    settingsConfig,
    "gear_talent_loadout",
    {
      OnReset = function(f)
        UpdateDisplay()
      end,
      OnApplySettings = function(f)
        UpdateDisplay()
      end,
      OnEditModeEnter = function(f)
        UpdateDisplay()
      end,
      OnEditModeExit = function(f)
        UpdateDisplay()
      end,
    }
  )
end

function BUII_GearAndTalentLoadout_Enable()
  BUII_GearAndTalentLoadout_Initialize()

  frame:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
  frame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
  frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)

  BUII_EditModeUtils:ApplySavedPosition(frame, "gear_talent_loadout")
  frame:Show()
  contentFrame:Show()
  UpdateDisplay()
end

function BUII_GearAndTalentLoadout_Disable()
  if not frame then
    return
  end
  frame:UnregisterEvent("EQUIPMENT_SWAP_FINISHED")
  frame:UnregisterEvent("EQUIPMENT_SETS_CHANGED")
  frame:UnregisterEvent("TRAIT_CONFIG_UPDATED")
  frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", nil)

  frame:Hide()
  if contentFrame then
    contentFrame:Hide()
  end
end

function BUII_GearAndTalentLoadout_Refresh()
  UpdateDisplay()
end

function BUII_GearAndTalentLoadout_InitDB()
  if BUIIDatabase["gear_talent_loadout"] == nil then
    BUIIDatabase["gear_talent_loadout"] = false
  end
  if BUIIDatabase["gear_talent_icon_size"] == nil then
    BUIIDatabase["gear_talent_icon_size"] = 40
  end
  if BUIIDatabase["gear_talent_font_size"] == nil then
    BUIIDatabase["gear_talent_font_size"] = 22
  end
  if BUIIDatabase["gear_talent_vertical_spacing"] == nil then
    BUIIDatabase["gear_talent_vertical_spacing"] = 2
  end
end
