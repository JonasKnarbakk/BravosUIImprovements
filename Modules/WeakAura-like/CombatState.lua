local addonName, addon = ...
---@class BUII_CombatStateEditModeTemplate : BUII_ManagedFrame
---@type Frame|BUII_CombatStateEditModeTemplate|any|nil
local frame = nil
---@type FontString|nil
local text = nil
---@type AnimationGroup|nil
local animGroup = nil

-- Settings Constants
local enum_CombatStateSetting_Scale = 30
local enum_CombatStateSetting_FontSize = 31

--- Handles combat state changes (enter/leave combat)
---@param self Frame|any
---@param event string
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

--- Initializes the Combat State Notification frame, text, and edit mode settings
---@return nil
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

  -- Set default position properties for EditModeUtils fallback
  frame.defaultPoint = "CENTER"
  frame.defaultRelativePoint = "CENTER"
  frame.defaultX = 0
  frame.defaultY = 150

  -- Set initial position
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)

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
  local settingsConfig = {}
  BUII_EditModeUtils:AddScaleSetting(settingsConfig, enum_CombatStateSetting_Scale, "scale")

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
        -- Explicitly restore position after edit mode exits
        C_Timer.After(0.1, function()
          if frame then
            BUII_EditModeUtils:ApplySavedPosition(frame, "combat_state", true)
          end
        end)
        text:SetAlpha(0)
      end,
    }
  )
end

--- Enables the Combat State Notification feature and registers events
---@return nil
function BUII_CombatState_Enable()
  BUII_CombatState_Initialize()

  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", onEvent)

  BUII_EditModeUtils:ApplySavedPosition(frame, "combat_state")
  frame:Show()
end

--- Disables the Combat State Notification feature and unwires events
---@return nil
function BUII_CombatState_Disable()
  if not frame then
    return
  end
  frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
  frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", nil)

  frame:Hide()
end

--- Refreshes the display configuration (font, shadow)
---@return nil
function BUII_CombatState_Refresh()
  if frame and text then
    text:SetFont(BUII_GetFontPath(), 32, BUII_GetFontFlags())
    text:SetShadowOffset(BUII_GetFontShadow())
  end
end

local DB_DEFAULTS = {
  combat_state = false,
  combat_state_layouts = {
    Default = {
      point = "CENTER",
      relativePoint = "CENTER",
      offsetX = 0,
      offsetY = 150,
      scale = 1.0,
    },
  },
}

function BUII_CombatState_InitDB()
  MergeDefaults(BUIIDatabase, DB_DEFAULTS)
end

BUII_RegisterModule({
  dbKey = "combat_state",
  enable = BUII_CombatState_Enable,
  disable = BUII_CombatState_Disable,
  refresh = BUII_CombatState_Refresh,
  checkboxPath = "weakAura.CombatState",
})
