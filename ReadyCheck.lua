local frame = CreateFrame("Frame", "BUII_ReadyCheckFrame", UIParent)
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
text:SetFont(BUII_GetFontPath(), 44, "OUTLINE")

-- Configuration
frame:SetSize(300, 50)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200) -- Default position higher up
frame:SetMovable(true)
frame:EnableMouse(false)

text:SetPoint("CENTER", frame, "CENTER")
text:SetText("Check Gear & Talents")
text:SetTextColor(1, 1, 1) -- White text
frame:Hide()

local hideTimer = nil

-- Animation (Bouncing)
local animGroup = text:CreateAnimationGroup()
local bounceUp = animGroup:CreateAnimation("Translation")
bounceUp:SetOffset(0, 10)
bounceUp:SetDuration(0.3)
bounceUp:SetOrder(1)
bounceUp:SetSmoothing("OUT")

local bounceDown = animGroup:CreateAnimation("Translation")
bounceDown:SetOffset(0, -10)
bounceDown:SetDuration(0.3)
bounceDown:SetOrder(2)
bounceDown:SetSmoothing("IN")

animGroup:SetLooping("REPEAT")

-- Edit Mode Selection Frame
local selection = CreateFrame("Frame", nil, frame, "EditModeSystemSelectionTemplate")
selection:SetAllPoints(frame)
selection:Hide()
frame.Selection = selection

frame.Selection.GetLabelText = function()
  return "Ready Check Notification"
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
  BUIIDatabase["ready_check_pos"] = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function onEvent(self, event)
  if event == "READY_CHECK" then
    local _, instanceType = IsInInstance()
    if instanceType ~= "party" and instanceType ~= "raid" then
      return
    end

    if hideTimer then
      hideTimer:Cancel()
      hideTimer = nil
    end
    frame:Show()
    animGroup:Play()
  elseif event == "READY_CHECK_FINISHED" then
    hideTimer = C_Timer.NewTimer(10, function()
      animGroup:Stop()
      frame:Hide()
      hideTimer = nil
    end)
  end
end

-- Edit Mode Integration
local function editMode_OnEnter()
  frame:EnableMouse(true)
  frame:Show()
  frame.Selection:Show()
  frame.Selection:ShowHighlighted()
  animGroup:Play()
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  frame.Selection:Hide()
  animGroup:Stop()
  frame:Hide()
end

function BUII_ReadyCheck_Enable()
  frame:RegisterEvent("READY_CHECK")
  frame:RegisterEvent("READY_CHECK_FINISHED")
  frame:SetScript("OnEvent", onEvent)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_ReadyCheck_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_ReadyCheck_OnExit")

  -- Restore position
  if BUIIDatabase["ready_check_pos"] then
    local pos = BUIIDatabase["ready_check_pos"]
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
  end

  frame:Hide() -- Hide initially
end

function BUII_ReadyCheck_Disable()
  frame:UnregisterEvent("READY_CHECK")
  frame:UnregisterEvent("READY_CHECK_FINISHED")
  frame:SetScript("OnEvent", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_ReadyCheck_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_ReadyCheck_OnExit")

  frame:Hide()
  animGroup:Stop()
  if hideTimer then
    hideTimer:Cancel()
    hideTimer = nil
  end
end
