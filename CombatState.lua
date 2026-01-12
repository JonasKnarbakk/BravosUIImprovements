local frame = nil
local text = nil
local animGroup = nil

-- Settings Constants
local enum_CombatStateSetting_Scale = 30
local enum_CombatStateSetting_FontSize = 31

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

local function BUII_CombatState_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_CombatStateFrame", UIParent, "BUII_CombatStateEditModeTemplate")
  frame:SetSize(200, 50)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  text:SetFont(BUII_GetFontPath(), 32, BUII_GetFontFlags())
  text:SetPoint("CENTER", frame, "CENTER")
  text:SetAlpha(0) -- Start invisible

  -- Animation
  animGroup = text:CreateAnimationGroup()
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

  -- Register System
  local settingsConfig = {
    {
      setting = enum_CombatStateSetting_Scale,
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
    Enum.EditModeSystem.BUII_CombatState,
    "Combat State Notification",
    settingsConfig,
    "combat_state",
    {
      OnReset = function(f)
        text:SetFont(BUII_GetFontPath(), 32, BUII_GetFontFlags())
      end,
      OnApplySettings = function(f)
        -- Scale handled automatically
      end,
      OnEditModeEnter = function(f)
        -- Preview
        text:SetText("+Combat+")
        text:SetTextColor(1, 0.8, 0.8)
        text:SetAlpha(1)
      end,
      OnEditModeExit = function(f)
        text:SetAlpha(0)
      end,
    }
  )
end

function BUII_CombatState_Enable()
  BUII_CombatState_Initialize()

  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", onEvent)

  BUII_EditModeUtils:ApplySavedPosition(frame, "combat_state")
  frame:Show()
end

function BUII_CombatState_Disable()
  if not frame then
    return
  end
  frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
  frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", nil)

  frame:Hide()
end

function BUII_CombatState_Refresh()
  if frame and text then
    text:SetFont(BUII_GetFontPath(), 32, BUII_GetFontFlags())
    text:SetShadowOffset(BUII_GetFontShadow())
  end
end

function BUII_CombatState_InitDB()
  if BUIIDatabase["combat_state"] == nil then
    BUIIDatabase["combat_state"] = false
  end
end
