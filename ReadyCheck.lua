local frame = nil
local text = nil
local animGroup = nil
local hideTimer = nil

-- Settings Constants
local enum_ReadyCheckSetting_Scale = 50
local enum_ReadyCheckSetting_FontSize = 51

local function onEvent(self, event)
  if event == "EDIT_MODE_LAYOUTS_UPDATED" then
    BUII_EditModeUtils:ApplySavedPosition(frame, "ready_check")
    return
  end

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

local function BUII_ReadyCheck_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_ReadyCheckFrame", UIParent, "BUII_ReadyCheckEditModeTemplate")
  frame:SetSize(300, 50)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  text:SetFont(BUII_GetFontPath(), 44, "OUTLINE")
  text:SetPoint("CENTER", frame, "CENTER")
  text:SetText("Check Gear & Talents")
  text:SetTextColor(1, 1, 1) -- White text

  -- Animation (Bouncing)
  animGroup = text:CreateAnimationGroup()
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

  -- Register System
  local settingsConfig = {
    {
      setting = enum_ReadyCheckSetting_Scale,
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
    Enum.EditModeSystem.BUII_ReadyCheck,
    "Ready Check Notification",
    settingsConfig,
    "ready_check",
    {
      OnReset = function(f)
        text:SetFont(BUII_GetFontPath(), 44, "OUTLINE")
      end,
      OnApplySettings = function(f)
        -- Scale handled automatically
      end,
    }
  )
end

-- Edit Mode Integration
local function editMode_OnEnter()
  frame:EnableMouse(true)
  animGroup:Play()
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  animGroup:Stop()
  frame:Hide()
end

function BUII_ReadyCheck_Enable()
  BUII_ReadyCheck_Initialize()

  frame:RegisterEvent("READY_CHECK")
  frame:RegisterEvent("READY_CHECK_FINISHED")
  frame:SetScript("OnEvent", onEvent)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_ReadyCheck_Custom_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_ReadyCheck_Custom_OnExit")

  BUII_EditModeUtils:ApplySavedPosition(frame, "ready_check")
  frame:Hide() -- Hide initially
end

function BUII_ReadyCheck_Disable()
  if not frame then
    return
  end
  frame:UnregisterEvent("READY_CHECK")
  frame:UnregisterEvent("READY_CHECK_FINISHED")
  frame:SetScript("OnEvent", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_ReadyCheck_Custom_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_ReadyCheck_Custom_OnExit")

  frame:Hide()
  animGroup:Stop()
  if hideTimer then
    hideTimer:Cancel()
    hideTimer = nil
  end
end
