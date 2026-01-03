local frame = nil
local icon = nil
local gearText = nil
local talentText = nil

-- Settings Constants
local enum_GearTalentSetting_Scale = 40
local enum_GearTalentSetting_FontSize = 41

local function UpdateDisplay()
  if not frame then
    return
  end

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

  -- Apply Font Size (Fixed)
  gearText:SetFont(BUII_GetFontPath(), 22, "OUTLINE")
  talentText:SetFont(BUII_GetFontPath(), 22, "OUTLINE")

  -- Dynamic Resizing for Selection Box
  local textWidth = math.max(gearText:GetStringWidth(), talentText:GetStringWidth())
  local totalWidth = math.max(icon:GetWidth(), textWidth) + 10 -- Padding
  -- Height calculation: Since text is centered on the top/bottom edges,
  -- only half of the text height extends beyond the icon.
  local totalHeight = icon:GetHeight() + (gearText:GetStringHeight() / 2) + (talentText:GetStringHeight() / 2) + 10

  frame:SetSize(totalWidth, totalHeight)
end

local function onEvent(self, event, ...)
  if event == "EDIT_MODE_LAYOUTS_UPDATED" then
    BUII_EditModeUtils:ApplySavedPosition(frame, "gear_talent_loadout")
    return
  end
  UpdateDisplay()
end

local function BUII_GearAndTalentLoadout_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_GearAndTalentLoadoutFrame", UIParent, "BUII_GearAndTalentLoadoutEditModeTemplate")
  frame:SetSize(100, 100) -- Initial size, updated by UpdateDisplay
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(40, 40)
  icon:SetPoint("CENTER", frame, "CENTER")
  icon:SetTexCoord(0, 1, 0, 1) -- No zoom

  gearText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  gearText:SetFontObject("GameFontHighlight")
  gearText:SetFont(BUII_GetFontPath(), 22, "OUTLINE")
  gearText:SetPoint("CENTER", icon, "TOP", 0, 0)
  gearText:SetJustifyH("CENTER")

  talentText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  talentText:SetFontObject("GameFontHighlight")
  talentText:SetFont(BUII_GetFontPath(), 22, "OUTLINE")
  talentText:SetPoint("CENTER", icon, "BOTTOM", 0, 0)
  talentText:SetJustifyH("CENTER")

  -- Register System
  local settingsConfig = {
    {
      setting = enum_GearTalentSetting_Scale,
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
  }

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
    }
  )
end

-- Edit Mode Integration
local function editMode_OnEnter()
  frame:EnableMouse(true)
  UpdateDisplay()
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  UpdateDisplay()
end

function BUII_GearAndTalentLoadout_Enable()
  BUII_GearAndTalentLoadout_Initialize()

  frame:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
  frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_GearAndTalentLoadout_Custom_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_GearAndTalentLoadout_Custom_OnExit")

  BUII_EditModeUtils:ApplySavedPosition(frame, "gear_talent_loadout")
  frame:Show()
  UpdateDisplay()
end

function BUII_GearAndTalentLoadout_Disable()
  if not frame then
    return
  end
  frame:UnregisterEvent("EQUIPMENT_SWAP_FINISHED")
  frame:UnregisterEvent("TRAIT_CONFIG_UPDATED")
  frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_GearAndTalentLoadout_Custom_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_GearAndTalentLoadout_Custom_OnExit")

  frame:Hide()
end
