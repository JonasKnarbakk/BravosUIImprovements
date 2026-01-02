local frame = CreateFrame("Frame", "BUII_CombatStateFrame", UIParent)
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
text:SetFont(BUII_GetFontPath(), 32, "OUTLINE")

-- Configuration
frame:SetSize(200, 50)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100) -- Default position slightly above center
frame:SetMovable(true)
frame:EnableMouse(false)
frame:Hide()

text:SetPoint("CENTER", frame, "CENTER")
text:SetAlpha(0) -- Start invisible

-- Animation
local animGroup = text:CreateAnimationGroup()
local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.2)
fadeIn:SetOrder(1)

local hold = animGroup:CreateAnimation("Alpha")
hold:SetFromAlpha(1)
hold:SetToAlpha(1)
hold:SetDuration(1.5)
hold:SetOrder(2)

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetDuration(0.5)
fadeOut:SetOrder(3)

-- Edit Mode Selection Frame
local selection = CreateFrame("Frame", nil, frame, "EditModeSystemSelectionTemplate")
selection:SetAllPoints(frame)
selection:Hide()
frame.Selection = selection

frame.Selection.GetLabelText = function()
  return "Combat State Notification"
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
  BUIIDatabase["combat_state_pos"] = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function onEvent(self, event)
  if event == "PLAYER_REGEN_DISABLED" then
    -- Enter Combat
    text:SetText("+Combat+")
    text:SetTextColor(1, 0.8, 0.8) -- Red-ish White
    animGroup:Stop()
    animGroup:Play()
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Leave Combat
    text:SetText("-Combat-")
    text:SetTextColor(0.8, 1, 0.8) -- Green-ish White
    animGroup:Stop()
    animGroup:Play()
  end
end

-- Edit Mode Integration
local function editMode_OnEnter()
  frame:EnableMouse(true)
  frame:Show()
  frame.Selection:Show()
  frame.Selection:ShowHighlighted()
  
  -- Preview
  text:SetText("+Combat+")
  text:SetTextColor(1, 0.8, 0.8)
  text:SetAlpha(1)
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  frame.Selection:Hide()
  text:SetAlpha(0)
end

function BUII_CombatState_Enable()
  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", onEvent)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_CombatState_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_CombatState_OnExit")

  -- Restore position
  if BUIIDatabase["combat_state_pos"] then
    local pos = BUIIDatabase["combat_state_pos"]
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
  end

  frame:Show()
end

function BUII_CombatState_Disable()
  frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
  frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", nil)
  
  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_CombatState_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_CombatState_OnExit")
  
  frame:Hide()
end
