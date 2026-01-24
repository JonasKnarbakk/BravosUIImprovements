local frame = nil
local contentFrame = nil -- Container for icon and text that bounces together
local icon = nil
local text = nil
local animGroup = nil
local currentMissingBuff = nil

-- Ensure Enum exists
if not Enum.EditModeSystem.BUII_MissingBuffReminder then
  Enum.EditModeSystem.BUII_MissingBuffReminder = 114
end

-- Define the global string for Edit Mode tooltip
BUII_HUD_EDIT_MODE_MISSING_BUFF_REMINDER_LABEL = "Missing Buff Reminder"

-- Settings Constants
local enum_MissingBuffSetting_Scale = 70
local enum_MissingBuffSetting_BounceIntensity = 71
local enum_MissingBuffSetting_OnlyInCombat = 72

-- Raid buff definitions: { spellID, buffName, iconPath, className }
local RAID_BUFFS = {
  {
    spellID = 1459, -- Arcane Intellect
    name = "Arcane Intellect",
    icon = 135932, -- Interface\Icons\Spell_Holy_MagicalSentry
    class = "MAGE",
  },
  {
    spellID = 21562, -- Power Word: Fortitude
    name = "Power Word: Fortitude",
    icon = 135987, -- Interface\Icons\Spell_Holy_WordFortitude
    class = "PRIEST",
  },
  {
    spellID = 1126, -- Mark of the Wild
    name = "Mark of the Wild",
    icon = 136078, -- Interface\Icons\Spell_Nature_Regeneration
    class = "DRUID",
  },
  {
    spellID = 6673, -- Battle Shout
    name = "Battle Shout",
    icon = 132333, -- Interface\Icons\Ability_Warrior_BattleShout
    class = "WARRIOR",
  },
  {
    spellID = 364342, -- Blessing of the Bronze (Evoker)
    name = "Blessing of the Bronze",
    icon = 4622455, -- Interface\Icons\Ability_Evoker_BlessingOfTheBronze
    class = "EVOKER",
  },
}

-- Check if any defined raid buff is currently requested by the game client (Glowing)
local function getMissingBuffInfo()
  -- Only check if in a group
  local inGroup = IsInGroup() or IsInRaid()
  if not inGroup then
    return nil
  end

  for _, buffInfo in ipairs(RAID_BUFFS) do
    if C_SpellActivationOverlay.IsSpellOverlayed(buffInfo.spellID) then
      return buffInfo
    end
  end

  return nil
end

local function updateDisplay()
  if not frame or not BUIIDatabase or not BUIIDatabase["missing_buff_reminder"] then
    if frame then
      frame:Hide()
      if animGroup then
        animGroup:Stop()
      end
    end
    return
  end

  if not text or not icon then
    return
  end

  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()

  -- Update font
  text:SetFont(BUII_GetFontPath(), 24, BUII_GetFontFlags())
  text:SetShadowOffset(BUII_GetFontShadow())

  if isEditMode then
    -- Show preview in edit mode
    local previewBuff = RAID_BUFFS[1] -- Show Arcane Intellect as preview
    icon:SetTexture(previewBuff.icon)
    text:SetText("Buff Missing!")
    text:SetTextColor(1, 1, 1) -- White text
    frame:Show()
    if not animGroup:IsPlaying() then
      animGroup:Play()
    end
    return
  end

  -- Check combat requirement
  local onlyInCombat = BUIIDatabase["missing_buff_only_in_combat"]
  if onlyInCombat and not UnitAffectingCombat("player") then
    frame:Hide()
    if animGroup then
      animGroup:Stop()
    end
    currentMissingBuff = nil
    return
  end

  -- Check for missing buffs using the Overlay API
  local missingBuff = getMissingBuffInfo()

  if missingBuff then
    currentMissingBuff = missingBuff
    icon:SetTexture(missingBuff.icon)
    text:SetText(missingBuff.name .. " Missing")
    text:SetTextColor(1, 1, 1) -- White text
    frame:Show()
    if not animGroup:IsPlaying() then
      animGroup:Play()
    end
  else
    currentMissingBuff = nil
    frame:Hide()
    if animGroup then
      animGroup:Stop()
    end
  end
end

local function updateAnimationIntensity()
  if not animGroup or not contentFrame then
    return
  end

  local intensity = BUIIDatabase["missing_buff_intensity"] or 10
  local animations = { animGroup:GetAnimations() }
  local up = animations[1]
  local down = animations[2]

  if up and down then
    local _, currentUpY = up:GetOffset()
    if currentUpY ~= intensity * 2 then
      animGroup:Stop()
      -- Update content frame anchor point to be centered
      contentFrame:ClearAllPoints()
      contentFrame:SetPoint("CENTER", frame, "CENTER", 0, -intensity)
      -- Update animation offsets to bounce +/- intensity around center
      up:SetOffset(0, intensity * 2)
      down:SetOffset(0, -intensity * 2)
      if frame and frame:IsShown() then
        animGroup:Play()
      end
    end
  end
end

local function onEvent(self, event, arg1)
  if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
    -- Check if the spell event is relevant to our buffs
    if arg1 then
      for _, buff in ipairs(RAID_BUFFS) do
        if buff.spellID == arg1 then
          updateDisplay()
          return
        end
      end
    else
      updateDisplay()
    end
  elseif
    event == "PLAYER_REGEN_DISABLED"
    or event == "PLAYER_REGEN_ENABLED"
    or event == "PLAYER_ENTERING_WORLD"
    or event == "GROUP_ROSTER_UPDATE"
  then
    updateDisplay()
  end
end

local function BUII_MissingBuffReminder_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_MissingBuffReminderFrame", UIParent, "BUII_MissingBuffReminderEditModeTemplate")
  frame:SetSize(300, 60)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  -- Set default position properties for EditModeUtils fallback
  frame.defaultPoint = "CENTER"
  frame.defaultRelativePoint = "CENTER"
  frame.defaultX = 0
  frame.defaultY = 200

  -- Set initial position
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

  -- Create content frame that will hold icon and text and bounce together
  contentFrame = CreateFrame("Frame", nil, frame)
  contentFrame:SetSize(300, 48)
  contentFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)

  -- Create icon (attached to content frame)
  icon = contentFrame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(48, 48)
  icon:SetPoint("LEFT", contentFrame, "LEFT", 10, 0)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim icon borders

  -- Create text (attached to content frame)
  text = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  text:SetFont(BUII_GetFontPath(), 24, BUII_GetFontFlags())
  text:SetPoint("LEFT", icon, "RIGHT", 10, 0)
  text:SetTextColor(1, 1, 1) -- White text

  -- Animation (Bouncing) - applied to content frame so both icon and text bounce together
  animGroup = contentFrame:CreateAnimationGroup()
  animGroup:SetLooping("REPEAT")

  local bounceUp = animGroup:CreateAnimation("Translation")
  bounceUp:SetDuration(0.4)
  bounceUp:SetOrder(1)
  bounceUp:SetSmoothing("IN_OUT")

  local bounceDown = animGroup:CreateAnimation("Translation")
  bounceDown:SetDuration(0.4)
  bounceDown:SetOrder(2)
  bounceDown:SetSmoothing("IN_OUT")

  -- Register System
  local settingsConfig = {
    {
      setting = enum_MissingBuffSetting_BounceIntensity,
      name = "Bounce Intensity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 50,
      stepSize = 5,
      formatter = function(val)
        return string.format("%.0f", val)
      end,
      getter = function(f)
        return BUIIDatabase["missing_buff_intensity"] or 10
      end,
      setter = function(f, val)
        BUIIDatabase["missing_buff_intensity"] = val
        updateAnimationIntensity()
      end,
    },
    {
      setting = enum_MissingBuffSetting_OnlyInCombat,
      name = "Only Warn In Combat",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      getter = function(f)
        return BUIIDatabase["missing_buff_only_in_combat"] and 1 or 0
      end,
      setter = function(f, val)
        BUIIDatabase["missing_buff_only_in_combat"] = (val == 1)
        updateDisplay()
      end,
    },
  }

  BUII_EditModeUtils:AddScaleSetting(settingsConfig, enum_MissingBuffSetting_Scale, "scale")

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_MissingBuffReminder,
    "Missing Buff Reminder",
    settingsConfig,
    "missing_buff_reminder",
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
        -- Explicitly restore position after edit mode exits
        C_Timer.After(0.1, function()
          if frame then
            BUII_EditModeUtils:ApplySavedPosition(frame, "missing_buff_reminder", true)
          end
        end)
        updateDisplay()
      end,
    }
  )
end

function BUII_MissingBuffReminder_Enable()
  BUII_MissingBuffReminder_Initialize()

  frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
  frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
  frame:RegisterEvent("GROUP_ROSTER_UPDATE")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)

  BUII_EditModeUtils:ApplySavedPosition(frame, "missing_buff_reminder")

  updateDisplay()
end

function BUII_MissingBuffReminder_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)

  frame:Hide()
  if animGroup then
    animGroup:Stop()
  end
  currentMissingBuff = nil
end

function BUII_MissingBuffReminder_Refresh()
  if frame and text then
    updateDisplay()
  end
end

function BUII_MissingBuffReminder_InitDB()
  if BUIIDatabase["missing_buff_reminder"] == nil then
    BUIIDatabase["missing_buff_reminder"] = false
  end
  if BUIIDatabase["missing_buff_intensity"] == nil then
    BUIIDatabase["missing_buff_intensity"] = 10
  end
  if BUIIDatabase["missing_buff_only_in_combat"] == nil then
    BUIIDatabase["missing_buff_only_in_combat"] = false
  end
  if
    BUIIDatabase["missing_buff_reminder_layouts"] == nil
    or BUIIDatabase["missing_buff_reminder_layouts"]["Default"] == nil
  then
    BUIIDatabase["missing_buff_reminder_layouts"] = BUIIDatabase["missing_buff_reminder_layouts"] or {}
    BUIIDatabase["missing_buff_reminder_layouts"]["Default"] = {
      point = "CENTER",
      relativePoint = "CENTER",
      offsetX = 0,
      offsetY = 200,
      scale = 1.0,
    }
  end
end
