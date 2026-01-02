local frame = CreateFrame("Frame", "BUII_GearAndTalentLoadoutFrame", UIParent)
local icon = frame:CreateTexture(nil, "ARTWORK")
local gearText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
local talentText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

-- Configuration
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Default position
frame:SetMovable(true)
frame:EnableMouse(false) -- Disable mouse by default, enable in Edit Mode

-- Icon Setup
icon:SetSize(40, 40)
icon:SetPoint("CENTER", frame, "CENTER")
icon:SetTexCoord(0, 1, 0, 1) -- No zoom

local function GetFontPath()
  local fontName = "Expressway"
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local font = LSM:Fetch("font", fontName)
    if font then
      return font
    end
  end
  -- Fallback
  local filename = GameFontHighlight:GetFont()
  return filename
end

-- Text Setup
gearText:SetFontObject("GameFontHighlight")
gearText:SetFont(GetFontPath(), 22, "OUTLINE")
gearText:SetPoint("CENTER", icon, "TOP", 0, 0)
gearText:SetJustifyH("CENTER")

talentText:SetFontObject("GameFontHighlight")
talentText:SetFont(GetFontPath(), 22, "OUTLINE")
talentText:SetPoint("CENTER", icon, "BOTTOM", 0, 0)
talentText:SetJustifyH("CENTER")

-- Edit Mode Selection Frame
local selection = CreateFrame("Frame", nil, frame, "EditModeSystemSelectionTemplate")
selection:SetAllPoints(frame)
selection:Hide()
frame.Selection = selection

frame.Selection.GetLabelText = function()
  return "Gear & Talent Loadout"
end
frame.Selection.CheckShowInstructionalTooltip = function()
  return false
end

-- Edit Mode Interaction Handlers
function frame:OnDragStart()
  if EditModeManagerFrame then
    EditModeManagerFrame:SelectSystem(frame)
  end

  frame.Selection:ShowSelected()
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:StartMoving()
end

function frame:OnDragStop()
  frame.Selection:ShowHighlighted()
  frame:StopMovingOrSizing()
  frame:SetMovable(false)
  frame:SetClampedToScreen(false)

  local point, _, relativePoint, x, y = frame:GetPoint()
  BUIIDatabase["gear_talent_loadout_pos"] = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function UpdateDisplay()
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

  -- Dynamic Resizing for Selection Box
  local textWidth = math.max(gearText:GetStringWidth(), talentText:GetStringWidth())
  local totalWidth = math.max(icon:GetWidth(), textWidth) + 10 -- Padding
  -- Height calculation: Since text is centered on the top/bottom edges,
  -- only half of the text height extends beyond the icon.
  local totalHeight = icon:GetHeight() + (gearText:GetStringHeight() / 2) + (talentText:GetStringHeight() / 2) + 10

  frame:SetSize(totalWidth, totalHeight)
end

local function onEvent(self, event, ...)
  UpdateDisplay()
end

-- Edit Mode Integration
local function editMode_OnEnter()
  frame:EnableMouse(true)
  frame:Show()
  frame.Selection:Show()
  frame.Selection:ShowHighlighted()
  UpdateDisplay()
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  frame.Selection:Hide()
  UpdateDisplay()
end

function BUII_GearAndTalentLoadout_Enable()
  frame:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
  frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_GearAndTalentLoadout_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_GearAndTalentLoadout_OnExit")

  -- Restore position
  if BUIIDatabase["gear_talent_loadout_pos"] then
    local pos = BUIIDatabase["gear_talent_loadout_pos"]
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
  end

  frame:Show()
  UpdateDisplay()
end

function BUII_GearAndTalentLoadout_Disable()
  frame:UnregisterEvent("EQUIPMENT_SWAP_FINISHED")
  frame:UnregisterEvent("TRAIT_CONFIG_UPDATED")
  frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_GearAndTalentLoadout_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_GearAndTalentLoadout_OnExit")

  frame:Hide()
end
