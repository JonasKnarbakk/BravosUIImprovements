local frame = nil
local text = nil
local animGroup = nil
local petIdleStartTime = 0
local wasPetAttacking = false
local combatTicker = nil

-- Define the global string for Edit Mode tooltip
BUII_HUD_EDIT_MODE_PET_REMINDER_LABEL = "Pet Reminder"

-- Settings Constants
local enum_PetReminderSetting_Scale = 60
local enum_PetReminderSetting_BounceIntensity = 61
local enum_PetReminderSetting_IdleDelay = 64
local enum_PetReminderSetting_OnlyInCombat = 65

-- Check if player's class can have a permanent pet
local function isPetClass()
  local _, classFilename = UnitClass("player")
  if classFilename == "HUNTER" or classFilename == "WARLOCK" then
    return true
  end
  if classFilename == "DEATHKNIGHT" then
    local specId = PlayerUtil.GetCurrentSpecID()
    if specId == 252 then -- Unholy
      return true
    end
  end
  return false
end

-- Check if player has a pet summoned
local function hasPetSummoned()
  return UnitExists("pet") and not UnitIsDead("pet")
end

-- Check if pet is attacking (has a target and is in combat)
local function isPetAttacking()
  if not hasPetSummoned() then
    return false
  end

  -- Check if pet has a target
  local petTarget = UnitExists("pettarget")

  -- Check if pet is in combat
  local petInCombat = UnitAffectingCombat("pet")

  return petTarget and petInCombat
end

-- Get the current warning state
-- Returns: nil (no warning), "no_pet", or "not_attacking"
local function getWarningState()
  -- Only check for pet classes
  if not isPetClass() then
    return nil
  end

  local playerInCombat = UnitAffectingCombat("player")

  -- Check if player has no pet
  if not hasPetSummoned() then
    wasPetAttacking = false
    -- Only warn about no pet in combat if option is enabled
    local onlyInCombat = BUIIDatabase["pet_reminder_only_in_combat"]
    if onlyInCombat and not playerInCombat then
      return nil
    end
    return "no_pet"
  end

  local petAttacking = isPetAttacking()

  -- Track when pet transitions from attacking to idle
  if wasPetAttacking and not petAttacking then
    -- Pet just stopped attacking, record the time
    petIdleStartTime = GetTime()
  end
  wasPetAttacking = petAttacking

  -- Check if in combat but pet is not attacking
  if playerInCombat and not petAttacking then
    -- Check if pet has been idle long enough (delay check)
    local idleDelay = BUIIDatabase["pet_reminder_idle_delay"] or 2
    local timeSinceIdle = GetTime() - petIdleStartTime
    if timeSinceIdle >= idleDelay then
      return "not_attacking"
    end
  end

  return nil
end

local function updateDisplay()
  if not frame or not BUIIDatabase["pet_reminder"] then
    if frame then
      frame:Hide()
      if animGroup then
        animGroup:Stop()
      end
    end
    return
  end

  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()

  -- Update font
  text:SetText("")
  text:SetFont(BUII_GetFontPath(), 44, BUII_GetFontFlags())
  text:SetShadowOffset(BUII_GetFontShadow())

  if isEditMode then
    text:SetText("No Pet!")
    text:SetTextColor(1, 1, 1)
    frame:Show()
    if not animGroup:IsPlaying() then
      animGroup:Play()
    end
    return
  end

  local warningState = getWarningState()

  if warningState == "no_pet" then
    text:SetText("No Pet!")
    text:SetTextColor(1, 1, 1)
    frame:Show()
    if not animGroup:IsPlaying() then
      animGroup:Play()
    end
  elseif warningState == "not_attacking" then
    text:SetText("Pet Idle!")
    text:SetTextColor(1, 1, 1)
    frame:Show()
    if not animGroup:IsPlaying() then
      animGroup:Play()
    end
  else
    frame:Hide()
    if animGroup then
      animGroup:Stop()
    end
  end
end

local function updateAnimationIntensity()
  if not animGroup or not text then
    return
  end

  local intensity = BUIIDatabase["pet_reminder_intensity"] or 20
  local animations = { animGroup:GetAnimations() }
  local up = animations[1]
  local down = animations[2]

  if up and down then
    local _, currentUpY = up:GetOffset()
    if currentUpY ~= intensity * 2 then
      animGroup:Stop()
      -- Update text anchor point to be centered
      text:ClearAllPoints()
      text:SetPoint("CENTER", frame, "CENTER", 0, -intensity)
      -- Update animation offsets to bounce +/- intensity around center
      up:SetOffset(0, intensity * 2)
      down:SetOffset(0, -intensity * 2)
      if frame and frame:IsShown() then
        animGroup:Play()
      end
    end
  end
end

local function stopCombatTicker()
  if combatTicker then
    combatTicker:Cancel()
    combatTicker = nil
  end
end

local function startCombatTicker()
  stopCombatTicker()
  -- Check every 0.5 seconds during combat
  combatTicker = C_Timer.NewTicker(0.5, function()
    if not UnitAffectingCombat("player") then
      stopCombatTicker()
      return
    end
    updateDisplay()
  end)
end

local function onEvent(self, event, ...)
  if event == "UNIT_PET" then
    local unit = ...
    if unit == "player" then
      updateDisplay()
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Entering combat - record the time and start ticker
    -- If pet is not currently attacking, set idle start time to now
    if not isPetAttacking() then
      petIdleStartTime = GetTime()
    end
    wasPetAttacking = isPetAttacking()
    startCombatTicker()
    updateDisplay()
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Leaving combat - stop ticker
    stopCombatTicker()
    updateDisplay()
  elseif event == "PET_ATTACK_START" or event == "PET_ATTACK_STOP" then
    updateDisplay()
  elseif event == "UNIT_TARGET" then
    local unit = ...
    if unit == "pet" then
      updateDisplay()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Check if already in combat on login/reload
    if UnitAffectingCombat("player") then
      if not isPetAttacking() then
        petIdleStartTime = GetTime()
      end
      wasPetAttacking = isPetAttacking()
      startCombatTicker()
    end
    updateDisplay()
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    local unit = ...
    if unit == "player" then
      updateDisplay()
    end
  end
end

local function BUII_PetReminder_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_PetReminderFrame", UIParent, "BUII_PetReminderEditModeTemplate")
  frame:SetSize(300, 100)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  text:SetFont(BUII_GetFontPath(), 44, BUII_GetFontFlags())
  text:SetTextColor(1, 1, 1) -- White text

  -- Animation (Bouncing) - centered vertically
  animGroup = text:CreateAnimationGroup()
  animGroup:SetLooping("REPEAT")

  local bounceUp = animGroup:CreateAnimation("Translation")
  bounceUp:SetDuration(0.3)
  bounceUp:SetOrder(1)
  bounceUp:SetSmoothing("IN_OUT")

  local bounceDown = animGroup:CreateAnimation("Translation")
  bounceDown:SetDuration(0.3)
  bounceDown:SetSmoothing("IN_OUT")

  -- Register System
  local settingsConfig = {
    {
      setting = enum_PetReminderSetting_BounceIntensity,
      name = "Bounce Intensity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 100,
      stepSize = 5,
      formatter = function(val)
        return string.format("%.0f", val)
      end,
      getter = function(f)
        return BUIIDatabase["pet_reminder_intensity"] or 20
      end,
      setter = function(f, val)
        BUIIDatabase["pet_reminder_intensity"] = val
        updateAnimationIntensity()
      end,
    },
    {
      setting = enum_PetReminderSetting_IdleDelay,
      name = "Idle Warning Delay",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 10,
      stepSize = 0.5,
      formatter = function(val)
        return string.format("%.1fs", val)
      end,
      getter = function(f)
        return BUIIDatabase["pet_reminder_idle_delay"] or 2
      end,
      setter = function(f, val)
        BUIIDatabase["pet_reminder_idle_delay"] = val
      end,
    },
    {
      setting = enum_PetReminderSetting_OnlyInCombat,
      name = "Only Warn In Combat",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      getter = function(f)
        return BUIIDatabase["pet_reminder_only_in_combat"] and 1 or 0
      end,
      setter = function(f, val)
        BUIIDatabase["pet_reminder_only_in_combat"] = (val == 1)
        updateDisplay()
      end,
    },
  }

  BUII_EditModeUtils:AddScaleSetting(settingsConfig, enum_PetReminderSetting_Scale, "scale")

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_PetReminder,
    "Pet Reminder",
    settingsConfig,
    "pet_reminder",
    {
      OnReset = function(f)
        updateDisplay()
      end,
      OnApplySettings = function(f)
        updateDisplay()
      end,
      OnEditModeEnter = function(f)
        updateDisplay()
      end,
      OnEditModeExit = function(f)
        updateDisplay()
      end,
    }
  )
end

function BUII_PetReminder_Enable()
  BUII_PetReminder_Initialize()

  frame:RegisterEvent("UNIT_PET")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PET_ATTACK_START")
  frame:RegisterEvent("PET_ATTACK_STOP")
  frame:RegisterUnitEvent("UNIT_TARGET", "pet")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  frame:SetScript("OnEvent", onEvent)

  BUII_EditModeUtils:ApplySavedPosition(frame, "pet_reminder")

  updateDisplay()
end

function BUII_PetReminder_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)
  stopCombatTicker()

  frame:Hide()
  if animGroup then
    animGroup:Stop()
  end
end

function BUII_PetReminder_Refresh()
  if frame and text then
    updateDisplay()
  end
end

function BUII_PetReminder_InitDB()
  if BUIIDatabase["pet_reminder"] == nil then
    BUIIDatabase["pet_reminder"] = false
  end
  if BUIIDatabase["pet_reminder_intensity"] == nil then
    BUIIDatabase["pet_reminder_intensity"] = 20
  end
  if BUIIDatabase["pet_reminder_audio"] == nil then
    BUIIDatabase["pet_reminder_audio"] = false
  end
  if BUIIDatabase["pet_reminder_sound"] == nil then
    BUIIDatabase["pet_reminder_sound"] = 0
  end
  if BUIIDatabase["pet_reminder_idle_delay"] == nil then
    BUIIDatabase["pet_reminder_idle_delay"] = 2
  end
  if BUIIDatabase["pet_reminder_only_in_combat"] == nil then
    BUIIDatabase["pet_reminder_only_in_combat"] = false
  end
end
