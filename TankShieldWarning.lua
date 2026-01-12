local frame = nil
local text = nil
local animGroup = nil
local lastDurability = 100
local lastSoundTime = 0

-- Settings Constants
local enum_TankShieldWarningSetting_Scale = 60
local enum_TankShieldWarningSetting_Threshold = 61
local enum_TankShieldWarningSetting_BounceIntensity = 62
local enum_TankShieldWarningSetting_AudioWarning = 63
local enum_TankShieldWarningSetting_Sound = 64

-- Available warning sounds
local BUII_WARNING_SOUNDS = {
  { name = "Chain Break", id = 235094 },
  { name = "Glass Break", id = 12334 },
  { name = "Warrior Shield Break", id = 13092 },
  { name = "Siegebreaker", id = 114148 },
  { name = "Impact Break", id = 147347 },
}

-- Calculate shield durability percentage
local function getShieldDurability()
  local current, max = GetInventoryItemDurability(17) -- Off-hand slot
  if current and max and max > 0 then
    return (current / max) * 100
  end
  return 100
end

-- Check if player has a shield equipped
local function hasShieldEquipped()
  -- Simple check: if the off-hand slot (17) has durability info, it's likely a shield
  -- Only shields can be equipped in the off-hand slot and have durability
  local current, max = GetInventoryItemDurability(17)
  return (current ~= nil and max ~= nil and max > 0)
end

local function playSoundIfEnabled()
  if not BUIIDatabase["tank_shield_warning_audio"] then
    return
  end

  -- Throttle sound to once per 5 seconds
  local currentTime = GetTime()
  if currentTime - lastSoundTime < 5 then
    return
  end

  local soundID = BUIIDatabase["tank_shield_warning_sound"]
  if soundID and soundID > 0 then
    PlaySound(soundID)
    lastSoundTime = currentTime
  end
end

-- Check if player is a tank spec that uses shields
local function isShieldTankSpec()
  local specID = GetSpecialization()
  if not specID then
    return false
  end

  local specIDActual = GetSpecializationInfo(specID)
  if not specIDActual then
    return false
  end

  -- Protection Warrior (73) or Protection Paladin (66)
  return specIDActual == 73 or specIDActual == 66
end

local function updateDisplay()
  if not frame or not BUIIDatabase["tank_shield_warning"] then
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
    text:SetText("Shield: 42%")
    frame:Show()
    if not animGroup:IsPlaying() then
      animGroup:Play()
    end
    return
  end

  -- Check if player has a shield equipped
  if not hasShieldEquipped() then
    frame:Hide()
    if animGroup then
      animGroup:Stop()
    end
    return
  end

  local threshold = BUIIDatabase["tank_shield_warning_threshold"] or 20
  local durability = getShieldDurability()

  if durability < threshold then
    text:SetText(string.format("Shield: %.0f%%", durability))
    frame:Show()
    if not animGroup:IsPlaying() then
      animGroup:Play()
      playSoundIfEnabled()
    end
  else
    frame:Hide()
    if animGroup then
      animGroup:Stop()
    end
  end

  lastDurability = durability
end

local function updateAnimationIntensity()
  if not animGroup or not text then
    return
  end

  local intensity = BUIIDatabase["tank_shield_warning_intensity"] or 20
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
      -- Update animation offsets to bounce ±intensity around center
      up:SetOffset(0, intensity * 2)
      down:SetOffset(0, -intensity * 2)
      if frame and frame:IsShown() then
        animGroup:Play()
      end
    end
  end
end

local function onEvent(self, event, ...)
  if event == "UPDATE_INVENTORY_DURABILITY" then
    updateDisplay()
  elseif event == "PLAYER_EQUIPMENT_CHANGED" then
    local slot = ...
    if slot == 17 then -- Off-hand slot
      updateDisplay()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    updateDisplay()
  end
end

local function BUII_TankShieldWarning_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_TankShieldWarningFrame", UIParent, "BUII_TankShieldWarningEditModeTemplate")
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
  -- The text will bounce from -intensity to +intensity around the frame center
  animGroup = text:CreateAnimationGroup()
  animGroup:SetLooping("REPEAT")

  local bounceUp = animGroup:CreateAnimation("Translation")
  bounceUp:SetDuration(0.3)
  bounceUp:SetOrder(1)
  bounceUp:SetSmoothing("IN_OUT")

  local bounceDown = animGroup:CreateAnimation("Translation")
  bounceDown:SetDuration(0.3)
  bounceDown:SetOrder(2)
  bounceDown:SetSmoothing("IN_OUT")

  -- Initialize with default intensity
  local defaultIntensity = BUIIDatabase["tank_shield_warning_intensity"] or 20
  text:SetPoint("CENTER", frame, "CENTER", 0, -defaultIntensity)
  bounceUp:SetOffset(0, defaultIntensity * 2)
  bounceDown:SetOffset(0, -defaultIntensity * 2)

  -- Register System
  local settingsConfig = {
    {
      setting = enum_TankShieldWarningSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 3.0,
      stepSize = 0.1,
      formatter = BUII_EditModeUtils.FormatPercentage,
      getter = function(f)
        return f:GetScale()
      end,
      setter = function(f, val)
        f:SetScale(val)
      end,
    },
    {
      setting = enum_TankShieldWarningSetting_Threshold,
      name = "Durability Threshold",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 1,
      maxValue = 99,
      stepSize = 1,
      formatter = function(val)
        return string.format("%.0f%%", val)
      end,
      getter = function(f)
        return BUIIDatabase["tank_shield_warning_threshold"] or 20
      end,
      setter = function(f, val)
        BUIIDatabase["tank_shield_warning_threshold"] = val
        updateDisplay()
      end,
    },
    {
      setting = enum_TankShieldWarningSetting_BounceIntensity,
      name = "Bounce Intensity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 100,
      stepSize = 5,
      formatter = function(val)
        return string.format("%.0f", val)
      end,
      getter = function(f)
        return BUIIDatabase["tank_shield_warning_intensity"] or 20
      end,
      setter = function(f, val)
        BUIIDatabase["tank_shield_warning_intensity"] = val
        updateAnimationIntensity()
      end,
    },
    {
      setting = enum_TankShieldWarningSetting_AudioWarning,
      name = "Audio Warning",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      getter = function(f)
        return BUIIDatabase["tank_shield_warning_audio"] and 1 or 0
      end,
      setter = function(f, val)
        BUIIDatabase["tank_shield_warning_audio"] = (val == 1)
      end,
    },
    {
      setting = enum_TankShieldWarningSetting_Sound,
      name = "Sound",
      type = Enum.EditModeSettingDisplayType.Dropdown,
      options = (function()
        local opts = {}
        for i, sound in ipairs(BUII_WARNING_SOUNDS) do
          opts[i] = { text = sound.name, value = sound.id }
        end
        return opts
      end)(),
      getter = function(f)
        return BUIIDatabase["tank_shield_warning_sound"] or 0
      end,
      setter = function(f, val)
        if BUIIDatabase["tank_shield_warning_sound"] ~= val then
          BUIIDatabase["tank_shield_warning_sound"] = val
          -- Play preview sound if not "None"
          if val and val > 0 then
            PlaySound(val, "Master")
          end
        end
      end,
    },
  }

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_TankShieldWarning,
    "Tank Shield Warning",
    settingsConfig,
    "tank_shield_warning",
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

function BUII_TankShieldWarning_Enable()
  -- Only initialize for Protection Warriors and Protection Paladins
  if not isShieldTankSpec() then
    return
  end

  BUII_TankShieldWarning_Initialize()

  frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
  frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)

  BUII_EditModeUtils:ApplySavedPosition(frame, "tank_shield_warning")

  updateDisplay()
end

function BUII_TankShieldWarning_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)

  frame:Hide()
  if animGroup then
    animGroup:Stop()
  end
end

function BUII_TankShieldWarning_Refresh()
  if frame and text then
    updateDisplay()
  end
end

function BUII_TankShieldWarning_InitDB()
  if BUIIDatabase["tank_shield_warning"] == nil then
    BUIIDatabase["tank_shield_warning"] = false
  end
  if BUIIDatabase["tank_shield_warning_threshold"] == nil then
    BUIIDatabase["tank_shield_warning_threshold"] = 20
  end
  if BUIIDatabase["tank_shield_warning_intensity"] == nil then
    BUIIDatabase["tank_shield_warning_intensity"] = 20
  end
  if BUIIDatabase["tank_shield_warning_audio"] == nil then
    BUIIDatabase["tank_shield_warning_audio"] = true
  end
  if BUIIDatabase["tank_shield_warning_sound"] == nil then
    BUIIDatabase["tank_shield_warning_sound"] = SOUNDKIT.RAID_WARNING
  end
end
