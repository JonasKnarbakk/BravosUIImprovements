local addonName, addon = ...
local frame = nil
local text = nil
local timer = nil
local locked = false
local last_status = nil
local isTestMode = false
local animGroup = nil

-- Settings Constants
local enum_CallToArmsSetting_Scale = 10
local enum_CallToArmsSetting_Tank = 11
local enum_CallToArmsSetting_Healer = 12
local enum_CallToArmsSetting_Damage = 13
local enum_CallToArmsSetting_DungeonNormal = 14
local enum_CallToArmsSetting_DungeonHeroic = 15
local enum_CallToArmsSetting_DungeonTimewalking = 16
local enum_CallToArmsSetting_LFR = 17
local enum_CallToArmsSetting_Sound = 18

-- Sound Options
local soundOptions = {
  { text = "LFG Reward", value = 17316 },
  { text = "Raid Warning", value = 8959 },
  { text = "Ready Check", value = 8960 },
  { text = "Quest", value = 618 },
  { text = "Coins", value = 120 },
  { text = "Kaching", value = "Interface\\AddOns\\BravosUIImprovements\\Media\\Sound\\kaching.ogg" },
}

-- Configuration for Dungeon/Raid IDs (Keeping existing config)
local types_config = {
  ["dg_types"] = {
    -- Midnight
    ["2746"] = true, -- Random Dungeon (Midnight)
    ["2748"] = true, -- Random Heroic (Midnight: Season 1)
    ["2747"] = true, -- Random Heroic (Midnight)

    -- The War Within
    ["2516"] = true, -- Random Dungeon (The War Within)
    ["2517"] = true, -- Random Heroic (The War Within)
    ["2723"] = true, -- Random Heroic (The War Within: Season 1)
    ["2807"] = true, -- Random Heroic (The War Within: Season 2)
    ["2993"] = true, -- Random Heroic (The War Within: Season 3)

    -- Dragonflight
    ["2350"] = true, -- Random Dungeon (Dragonflight)
    ["2351"] = true, -- Random Heroic (Dragonflight)

    -- Shadowlands
    ["2086"] = true, -- Random Dungeon (Shadowlands)
    ["2087"] = true, -- Random Heroic (Shadowlands)

    -- Battle for Azeroth
    ["1670"] = true, -- Random Dungeon (Battle for Azeroth)
    ["1671"] = true, -- Random Heroic (Battle for Azeroth)

    -- Legion
    ["1045"] = true, -- Random Legion Dungeon
    ["1046"] = true, -- Random Legion Heroic

    -- Warlords of Draenor
    ["789"] = true, -- Random Warlords of Draenor Heroic
    ["788"] = true, -- Random Warlords of Draenor Dungeon

    -- Mists of Pandaria
    ["462"] = true, -- Random Mists of Pandaria Heroic
    ["2537"] = true, -- Random Mists of Pandaria Heroic
    ["463"] = true, -- Random Mists of Pandaria Dungeon

    -- Cataclysm / Hour of Twilight
    ["434"] = true, -- Random Hour of Twilight Heroic
    ["301"] = true, -- Random Cataclysm Heroic
    ["300"] = true, -- Random Cataclysm Dungeon

    -- Wrath of the Lich King
    ["262"] = true, -- Random Lich King Heroic
    ["261"] = true, -- Random Lich King Dungeon

    -- Burning Crusade
    ["260"] = true, -- Random Burning Crusade Heroic
    ["259"] = true, -- Random Burning Crusade Dungeon

    -- Classic
    ["258"] = true, -- Random Classic Dungeon

    -- Timewalking
    ["3076"] = true, -- Random Timewalking Dungeon (Shadowlands)
    ["744"] = true, -- Random Timewalking Dungeon (Burning Crusade)
    ["2634"] = true, -- Random Timewalking Dungeon (Classic)
    ["1146"] = true, -- Random Timewalking Dungeon (Cataclysm)
    ["995"] = true, -- Random Timewalking Dungeon (Wrath of the Lich King)
    ["1453"] = true, -- Random Timewalking Dungeon (Mists of Pandaria)
    ["1971"] = true, -- Random Timewalking Dungeon (Warlords of Draenor)
    ["2274"] = true, -- Random Timewalking Dungeon (Legion)
    ["2874"] = true, -- Random Timewalking Dungeon (Battle for Azeroth)

    -- Timerunning (Remix)
    ["2538"] = true, -- Random Timerunning Dungeon (Mists of Pandaria)
    ["2817"] = true, -- Random Timerunning Dungeon (Legion)
    ["2539"] = true, -- Random Heroic Timerunning Dungeon (Mists of Pandaria)
    ["2820"] = true, -- Random Heroic Timerunning Dungeon (Legion)
    ["3084"] = true, -- Random Timerunning Raid (Legion)

    -- Seasonal/Holiday
    ["holiday"] = true,
  },
  ["raid_types"] = {
    ["raid_container"] = {
      -- Dragonflight
      ["3160"] = true, -- Crown of the Cosmos
      ["3159"] = true, -- Fanatics of the Light
      ["3156"] = true, -- Weapons of the Void
      ["1287"] = true, -- Darkbough
      ["2844"] = true, -- Darkbough
      ["2598"] = true, -- Guardians of Mogu'shan
      ["527"] = true, -- Guardians of Mogu'shan
      ["2780"] = true, -- Shock and Awesome
      ["3126"] = true, -- The Dreamrift
      ["2750"] = true, -- The Elemental Overlords
      ["2370"] = true, -- The Primal Bulwark
      ["2703"] = true, -- The Primal Bulwark
      ["2649"] = true, -- The Skittering Battlements
      ["849"] = true, -- Walled City
      ["850"] = true, -- Arcane Sanctum
      ["2705"] = true, -- Caverns of Infusion
      ["2371"] = true, -- Caverns of Infusion
      ["2781"] = true, -- Maniacal Machinist
      ["3155"] = true, -- March on Quel'Danas
      ["2650"] = true, -- Secrets of Nerub-ar Palace
      ["2751"] = true, -- Shadowforge City
      ["528"] = true, -- The Vault of Mysteries
      ["2597"] = true, -- The Vault of Mysteries
      ["1288"] = true, -- Tormented Guardians
      ["2845"] = true, -- Tormented Guardians
      ["2651"] = true, -- A Queen's Fall
      ["2706"] = true, -- Fury of the Storm
      ["2372"] = true, -- Fury of the Storm
      ["851"] = true, -- Imperator's Rise
      ["2846"] = true, -- Rift of Aln
      ["1289"] = true, -- Rift of Aln
      ["2596"] = true, -- The Dread Approach
      ["529"] = true, -- The Dread Approach
      ["2752"] = true, -- The Imperial Seat
      ["2782"] = true, -- Two Heads Are Better
      ["2704"] = true, -- Discarded Works
      ["2399"] = true, -- Discarded Works
      ["2595"] = true, -- Nightmare of Shek'zeer
      ["530"] = true, -- Nightmare of Shek'zeer
      ["847"] = true, -- Slagworks
      ["2783"] = true, -- The Chrome King
      ["2851"] = true, -- Trial of Valor
      ["1411"] = true, -- Trial of Valor
      ["2847"] = true, -- Arcing Aqueducts
      ["1290"] = true, -- Arcing Aqueducts
      ["2400"] = true, -- Fury of Giants
      ["2707"] = true, -- Fury of Giants
      ["2599"] = true, -- Terrace of Endless Spring
      ["526"] = true, -- Terrace of Endless Spring
      ["846"] = true, -- The Black Forge
      ["848"] = true, -- Iron Assembly
      ["2594"] = true, -- Last Stand of the Zandalari
      ["610"] = true, -- Last Stand of the Zandalari
      ["2708"] = true, -- Neltharion's Shadow
      ["2401"] = true, -- Neltharion's Shadow
      ["2848"] = true, -- Royal Athenaeum
      ["1291"] = true, -- Royal Athenaeum
      ["823"] = true, -- Blackhand's Crucible
      ["2709"] = true, -- Edge of the Void
      ["2402"] = true, -- Edge of the Void
      ["611"] = true, -- Forgotten Depths
      ["2593"] = true, -- Forgotten Depths
      ["2849"] = true, -- Nightspire
      ["1292"] = true, -- Nightspire
      ["2850"] = true, -- Betrayer's Rise
      ["1293"] = true, -- Betrayer's Rise
      ["612"] = true, -- Halls of Flesh-Shaping
      ["2592"] = true, -- Halls of Flesh-Shaping
      ["982"] = true, -- Hellbreach
      ["2466"] = true, -- Incarnate's Wake
      ["2710"] = true, -- Incarnate's Wake
      ["2799"] = true, -- Might of the Shadowguard
      ["983"] = true, -- Halls of Blood
      ["2711"] = true, -- Molten Incursion
      ["2468"] = true, -- Molten Incursion
      ["2800"] = true, -- Monsters of the Sands
      ["613"] = true, -- Pinnacle of Storms
      ["2591"] = true, -- Pinnacle of Storms
      ["1494"] = true, -- The Gates of Hell
      ["2835"] = true, -- The Gates of Hell
      ["984"] = true, -- Bastion of Shadows
      ["2801"] = true, -- Heart of Darkness
      ["2467"] = true, -- The Viridian Weave
      ["2712"] = true, -- The Viridian Weave
      ["2590"] = true, -- Vale of Eternal Sorrows
      ["716"] = true, -- Vale of Eternal Sorrows
      ["1495"] = true, -- Wailing Halls
      ["2836"] = true, -- Wailing Halls
      ["1496"] = true, -- Chamber of the Avatar
      ["2837"] = true, -- Chamber of the Avatar
      ["985"] = true, -- Destructor's Rise
      ["2469"] = true, -- Fate of Amirdrassil
      ["2713"] = true, -- Fate of Amirdrassil
      ["2589"] = true, -- Gates of Retribution
      ["717"] = true, -- Gates of Retribution
      ["2838"] = true, -- Deceiver's Fall
      ["1497"] = true, -- Deceiver's Fall
      ["986"] = true, -- The Black Gate
      ["2588"] = true, -- The Underhold
      ["724"] = true, -- The Underhold
      ["2587"] = true, -- Downfall
      ["725"] = true, -- Downfall
      ["2821"] = true, -- Light's Breach
      ["1610"] = true, -- Light's Breach
      ["1611"] = true, -- Forbidden Descent
      ["2822"] = true, -- Forbidden Descent
      ["2337"] = true, -- The Leeching Vaults
      ["2090"] = true, -- The Leeching Vaults
      ["1612"] = true, -- Hope's End
      ["2823"] = true, -- Hope's End
      ["2338"] = true, -- Reliquary of Opulence
      ["2091"] = true, -- Reliquary of Opulence
      ["2092"] = true, -- Blood from Stone
      ["2339"] = true, -- Blood from Stone
      ["1613"] = true, -- Seat of the Pantheon
      ["2824"] = true, -- Seat of the Pantheon
      ["2096"] = true, -- An Audience with Arrogance
      ["2340"] = true, -- An Audience with Arrogance
      ["2221"] = true, -- The Jailer's Vanguard
      ["2341"] = true, -- The Jailer's Vanguard
      ["2222"] = true, -- The Dark Bastille
      ["2342"] = true, -- The Dark Bastille
      ["2343"] = true, -- Shackles of Fate
      ["2223"] = true, -- Shackles of Fate
      ["2344"] = true, -- The Reckoning
      ["2224"] = true, -- The Reckoning
      ["2346"] = true, -- Ephemeral Plains
      ["2292"] = true, -- Ephemeral Plains
      ["2345"] = true, -- Cornerstone of Creation
      ["2291"] = true, -- Cornerstone of Creation
      ["2293"] = true, -- Domination's Grasp
      ["2347"] = true, -- Domination's Grasp
      ["2294"] = true, -- The Grand Design
      ["2348"] = true, -- The Grand Design

      -- Cata/Legacy LFRs
      ["417"] = true, -- Fall of Deathwing
      ["416"] = true, -- The Siege of Wyrmrest Temple
    },
  },
}

-- Icons
local tankIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t"
local healerIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t"
local damageIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t"

local function checkTypes(instanceTypes, optionsKey, ilReq, isRaidCheck)
  if instanceTypes[optionsKey] then
    return true
  end
  if not isRaidCheck then
    return false
  end
  for raid_container_key, raid_container_value in pairs(instanceTypes) do
    for k, v in pairs(raid_container_value) do
      if k:find(optionsKey) and v then
        return true
      end
    end
  end
  return false
end

local function getDungeonType(dName, isTimeWalker)
  if dName and dName:find("Timewalking") then
    return "timewalking"
  elseif dName and dName:find("Heroic") then
    return "heroic"
  else
    return "normal"
  end
end

local function checkInstanceType(dID, isHoliday, dName, ilReq, dungeonType)
  local options_key = tostring(dID)
  local dungeon_check = checkTypes(types_config["dg_types"], options_key, ilReq, false)
  local raid_check = checkTypes(types_config["raid_types"], options_key, ilReq, true)
  local holiday_check = types_config["dg_types"]["holiday"] and isHoliday

  -- If it's a dungeon, check if the type matches what the user wants
  if dungeon_check then
    if dungeonType == "normal" and not BUIIDatabase["call_to_arms_dungeon_normal"] then
      return false
    elseif dungeonType == "heroic" and not BUIIDatabase["call_to_arms_dungeon_heroic"] then
      return false
    elseif dungeonType == "timewalking" and not BUIIDatabase["call_to_arms_dungeon_timewalking"] then
      return false
    end
  end

  return dungeon_check or raid_check or holiday_check
end

local function GenerateTestOutput()
  local testOutput = ""
  local rewardIcon = "|T413587:0|t"

  local showTank = BUIIDatabase["call_to_arms_roles"]["tank"]
  local showHealer = BUIIDatabase["call_to_arms_roles"]["healer"]
  local showDamage = BUIIDatabase["call_to_arms_roles"]["damage"]

  local function getRoleString(t, h, d)
    local s = ""
    if t and showTank then
      s = s .. tankIcon
    end
    if h and showHealer then
      s = s .. healerIcon
    end
    if d and showDamage then
      s = s .. damageIcon
    end
    return s
  end

  if BUIIDatabase["call_to_arms_dungeon_normal"] then
    local roles = getRoleString(true, true, true)
    if roles ~= "" then
      testOutput = testOutput .. string.format("%s %s %s|n", rewardIcon, roles, "Random Dungeon (Expansion)")
    end
  end

  if BUIIDatabase["call_to_arms_dungeon_heroic"] then
    local roles = getRoleString(true, false, false)
    if roles ~= "" then
      testOutput = testOutput .. string.format("%s %s %s|n", rewardIcon, roles, "Random Heroic (Expansion: Season 1)")
    end

    roles = getRoleString(false, true, false)
    if roles ~= "" then
      testOutput = testOutput .. string.format("%s %s %s|n", rewardIcon, roles, "Random Heroic (Expansion: Season 2)")
    end
  end

  if BUIIDatabase["call_to_arms_dungeon_timewalking"] then
    local roles = getRoleString(true, true, true)
    if roles ~= "" then
      testOutput = testOutput .. string.format("%s %s %s|n", rewardIcon, roles, "Random Timewalking (Past Expansion)")
    end
  end

  if BUIIDatabase["call_to_arms_lfr"] then
    local roles = getRoleString(false, false, true)
    if roles ~= "" then
      testOutput = testOutput .. string.format("%s %s %s|n", rewardIcon, roles, "LFR Wing 1: The Beginning")
    end

    roles = getRoleString(true, false, true)
    if roles ~= "" then
      testOutput = testOutput .. string.format("%s %s %s|n", rewardIcon, roles, "LFR Wing 2: The Middle")
    end
  end

  -- Fallback if everything is disabled, so the user can still see *something* to move
  if testOutput == "" then
    testOutput = string.format("%s %s %s", rewardIcon, tankIcon, "No Active Filters")
  end

  return testOutput
end

local function IsCallToArmsRelevant()
  if isTestMode or (EditModeManagerFrame and EditModeManagerFrame:IsShown()) then
    return true
  end

  local inInstance, instanceType = IsInInstance()
  local numGroupMembers = GetNumGroupMembers()

  if inInstance then
    if instanceType == "pvp" or instanceType == "arena" then
      return false
    elseif (instanceType == "party" or instanceType == "raid") and numGroupMembers > 3 then
      return false
    end
  end
  return true
end

local function checkStatus()
  if not IsCallToArmsRelevant() then
    return ""
  end

  if isTestMode or (EditModeManagerFrame and EditModeManagerFrame:IsShown()) then
    return GenerateTestOutput()
  end

  local textOutput = ""
  local canTank, canHealer, canDamage = C_LFGList.GetAvailableRoles()
  local ilvl, _ = GetAverageItemLevel()

  local function updateShortageInfo(dID, dName, isHoliday, ilReq, isTimeWalker)
    for j = 1, LFG_ROLE_NUM_SHORTAGE_TYPES do
      local eligible, tank, healer, damage, itemCount, money, xp = GetLFGRoleShortageRewards(dID, j)

      if itemCount > 0 then
        local tankLocked, healerLocked, damageLocked = GetLFDRoleRestrictions(dID)
        local dungeonType = getDungeonType(dName, isTimeWalker)
        local isDesiredType = checkInstanceType(dID, isHoliday, dName, ilReq, dungeonType)
        local isEligible = ilvl > ilReq

        -- Determine which roles are actually being alerted for
        local tank_alert = tank and canTank and not tankLocked and BUIIDatabase["call_to_arms_roles"]["tank"]
        local healer_alert = healer and canHealer and not healerLocked and BUIIDatabase["call_to_arms_roles"]["healer"]
        local damage_alert = damage and canDamage and not damageLocked and BUIIDatabase["call_to_arms_roles"]["damage"]

        if eligible and (tank_alert or healer_alert or damage_alert) and isDesiredType and isEligible then
          local role_icon_text = ""
          if tank_alert then
            role_icon_text = role_icon_text .. tankIcon
          end
          if healer_alert then
            role_icon_text = role_icon_text .. healerIcon
          end
          if damage_alert then
            role_icon_text = role_icon_text .. damageIcon
          end

          local _, rewardIconTexture = GetLFGDungeonShortageRewardInfo(dID, j, 1)
          local rewardIcon = ""
          if rewardIconTexture then
            rewardIcon = "|T" .. rewardIconTexture .. ":0|t"
          else
            -- Fallback to generic bag icon (FileID 413587)
            rewardIcon = "|T413587:0|t"
          end

          textOutput = textOutput .. string.format("%s %s %s|n", rewardIcon, role_icon_text, dName)
        end
      end
    end
  end
  -- Loop through Random Dungeons
  local anyDungeonTypeEnabled = BUIIDatabase["call_to_arms_dungeon_normal"]
    or BUIIDatabase["call_to_arms_dungeon_heroic"]
    or BUIIDatabase["call_to_arms_dungeon_timewalking"]

  if anyDungeonTypeEnabled then
    for i = 1, GetNumRandomDungeons() do
      local dID, dName, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, bonusRepAmount, minPlayers, isTimeWalker, name2, minGear =
        GetLFGRandomDungeonInfo(i)
      if dID then
        updateShortageInfo(dID, dName, isHoliday, minGear, isTimeWalker)
      end
    end
  end

  -- Loop through RFs
  if BUIIDatabase["call_to_arms_lfr"] then
    for i = 1, GetNumRFDungeons() do
      local dID, dName, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, bonusRepAmount, minPlayers, isTimeWalker, name2, minGear =
        GetRFDungeonInfo(i)
      if dID then
        updateShortageInfo(dID, dName, isHoliday, minGear, isTimeWalker)
      end
    end
  end

  return textOutput
end

local lastText = ""

local function updateDisplay()
  if not BUIIDatabase["call_to_arms"] then
    frame:Hide()
    lastText = ""
    return
  end

  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
  local displayText = checkStatus()
  if displayText and string.len(displayText) > 0 then
    text:SetText(displayText)
    frame:SetWidth(text:GetStringWidth() + 10)
    frame:SetHeight(text:GetStringHeight() + 10)

    -- Trigger Sound and Animation if text changed or frame was hidden (but not during edit mode)
    if not isEditMode and (displayText ~= lastText or not frame:IsShown()) then
      local soundId = BUIIDatabase["call_to_arms_sound_id"] or 17316
      if type(soundId) == "number" then
        PlaySound(soundId, "Master")
      else
        PlaySoundFile(soundId, "Master")
      end
      animGroup:Stop()
      animGroup:Play()
    end
    lastText = displayText
    frame:Show()
  else
    lastText = ""

    -- Show only if in edit mode
    if isEditMode then
      frame:Show()
    else
      frame:Hide()
    end
  end
end

local function onEvent(self, event, ...)
  if not BUIIDatabase["call_to_arms"] then
    return
  end

  if not locked then
    locked = true
    updateDisplay()
    timer = C_Timer.NewTimer(10, function()
      locked = false
      if IsCallToArmsRelevant() then
        RequestLFDPlayerLockInfo()
      end
    end, 1)
  elseif timer and timer:IsCancelled() then -- Restart timer if it was somehow cancelled
    timer = C_Timer.NewTimer(10, function()
      locked = false
      if IsCallToArmsRelevant() then
        RequestLFDPlayerLockInfo()
      end
    end, 1)
  end
end

local function BUII_CallToArms_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_CallToArmsFrame", UIParent, "BUII_CallToArmsEditModeTemplate")
  frame:SetSize(200, 20)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetFont(BUII_GetFontPath(), 12, BUII_GetFontFlags())
  text:SetTextColor(1, 1, 1)
  text:SetPoint("CENTER", frame, "CENTER")
  text:SetJustifyH("LEFT")

  -- Animation Setup
  animGroup = frame:CreateAnimationGroup()
  local fade = animGroup:CreateAnimation("Alpha")
  fade:SetFromAlpha(0)
  fade:SetToAlpha(1)
  fade:SetDuration(0.5)
  fade:SetSmoothing("IN_OUT")

  -- Register System
  local settingsConfig = {
    {
      setting = enum_CallToArmsSetting_Scale,
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
    {
      setting = enum_CallToArmsSetting_DungeonNormal,
      name = "Dungeon: Normal",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "dungeon_normal",
      getter = function(f)
        return BUIIDatabase["call_to_arms_dungeon_normal"] and 1 or 0
      end,
      setter = function(f, val)
        local bVal = (val == 1)
        if BUIIDatabase["call_to_arms_dungeon_normal"] ~= bVal then
          BUIIDatabase["call_to_arms_dungeon_normal"] = bVal
          BUII_CallToArms_Update()
        end
      end,
    },
    {
      setting = enum_CallToArmsSetting_DungeonHeroic,
      name = "Dungeon: Heroic",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "dungeon_heroic",
      getter = function(f)
        return BUIIDatabase["call_to_arms_dungeon_heroic"] and 1 or 0
      end,
      setter = function(f, val)
        local bVal = (val == 1)
        if BUIIDatabase["call_to_arms_dungeon_heroic"] ~= bVal then
          BUIIDatabase["call_to_arms_dungeon_heroic"] = bVal
          BUII_CallToArms_Update()
        end
      end,
    },
    {
      setting = enum_CallToArmsSetting_DungeonTimewalking,
      name = "Dungeon: Timewalking",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "dungeon_timewalking",
      getter = function(f)
        return BUIIDatabase["call_to_arms_dungeon_timewalking"] and 1 or 0
      end,
      setter = function(f, val)
        local bVal = (val == 1)
        if BUIIDatabase["call_to_arms_dungeon_timewalking"] ~= bVal then
          BUIIDatabase["call_to_arms_dungeon_timewalking"] = bVal
          BUII_CallToArms_Update()
        end
      end,
    },
    {
      setting = enum_CallToArmsSetting_LFR,
      name = "LFR",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "lfr",
      getter = function(f)
        return BUIIDatabase["call_to_arms_lfr"] and 1 or 0
      end,
      setter = function(f, val)
        local bVal = (val == 1)
        if BUIIDatabase["call_to_arms_lfr"] ~= bVal then
          BUIIDatabase["call_to_arms_lfr"] = bVal
          BUII_CallToArms_Update()
        end
      end,
    },
    {
      setting = enum_CallToArmsSetting_Tank,
      name = "Tank",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "tank",
      getter = function(f)
        return BUIIDatabase["call_to_arms_roles"]["tank"] and 1 or 0
      end,
      setter = function(f, val)
        local bVal = (val == 1)
        if BUIIDatabase["call_to_arms_roles"]["tank"] ~= bVal then
          BUIIDatabase["call_to_arms_roles"]["tank"] = bVal
          BUII_CallToArms_Update()
        end
      end,
    },
    {
      setting = enum_CallToArmsSetting_Healer,
      name = "Healer",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "healer",
      getter = function(f)
        return BUIIDatabase["call_to_arms_roles"]["healer"] and 1 or 0
      end,
      setter = function(f, val)
        local bVal = (val == 1)
        if BUIIDatabase["call_to_arms_roles"]["healer"] ~= bVal then
          BUIIDatabase["call_to_arms_roles"]["healer"] = bVal
          BUII_CallToArms_Update()
        end
      end,
    },
    {
      setting = enum_CallToArmsSetting_Damage,
      name = "Damage",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "damage",
      getter = function(f)
        return BUIIDatabase["call_to_arms_roles"]["damage"] and 1 or 0
      end,
      setter = function(f, val)
        local bVal = (val == 1)
        if BUIIDatabase["call_to_arms_roles"]["damage"] ~= bVal then
          BUIIDatabase["call_to_arms_roles"]["damage"] = bVal
          BUII_CallToArms_Update()
        end
      end,
    },
    {
      setting = enum_CallToArmsSetting_Sound,
      name = "Alert Sound",
      type = Enum.EditModeSettingDisplayType.Dropdown,
      options = soundOptions,
      key = "sound",
      getter = function(f)
        return BUIIDatabase["call_to_arms_sound_id"]
      end,
      setter = function(f, val)
        if BUIIDatabase["call_to_arms_sound_id"] ~= val then
          BUIIDatabase["call_to_arms_sound_id"] = val
          if type(val) == "number" then
            PlaySound(val, "Master")
          else
            PlaySoundFile(val, "Master")
          end
          BUII_CallToArms_Update()
        end
      end,
    },
  }

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_CallToArms,
    "Call to Arms",
    settingsConfig,
    "call_to_arms",
    {
      OnReset = function(f)
        updateDisplay()
      end,
      OnApplySettings = function(f)
        updateDisplay()
      end,
      OnEditModeEnter = function(f)
        -- Show test text for positioning context
        local testOutput = GenerateTestOutput()

        text:SetText(testOutput)
        frame:SetWidth(text:GetStringWidth() + 10)
        frame:SetHeight(text:GetStringHeight() + 10)
        text:Show()
      end,
      OnEditModeExit = function(f)
        text:Show()
        updateDisplay()
      end,
    }
  )
end

function BUII_CallToArms_Enable()
  BUII_CallToArms_Initialize()

  frame:RegisterEvent("LFG_UPDATE_RANDOM_INFO")
  frame:SetScript("OnEvent", onEvent)

  BUII_EditModeUtils:ApplySavedPosition(frame, "call_to_arms")
  RequestLFDPlayerLockInfo()
  updateDisplay()
end

function BUII_CallToArms_Disable()
  if not frame then
    return
  end
  frame:UnregisterEvent("LFG_UPDATE_RANDOM_INFO")
  frame:SetScript("OnEvent", nil)
  frame:Hide()
  if timer then
    timer:Cancel()
  end
end

function BUII_CallToArms_Refresh()
  if frame and text then
    text:SetFont(BUII_GetFontPath(), 12, BUII_GetFontFlags())
    text:SetShadowOffset(BUII_GetFontShadow())
    updateDisplay()
  end
end

function BUII_CallToArms_Update()
  if BUIIDatabase["call_to_arms"] then
    updateDisplay()
  end
end

function BUII_CallToArms_TestMode()
  if not BUIIDatabase["call_to_arms"] then
    return
  end

  isTestMode = not isTestMode

  if isTestMode then
    print("Bravo's UI: Call to Arms Test Mode Enabled")
  else
    print("Bravo's UI: Call to Arms Test Mode Disabled")
  end

  updateDisplay()
end

function BUII_CallToArms_DumpIDs()
  print("--- Random Dungeons ---")
  for i = 1, GetNumRandomDungeons() do
    local dID, dName = GetLFGRandomDungeonInfo(i)
    if dID then
      print(dID .. " - " .. dName)
    end
  end

  print("--- Raid Finder ---")
  for i = 1, GetNumRFDungeons() do
    local dID, dName = GetRFDungeonInfo(i)
    if dID then
      print(dID .. " - " .. dName)
    end
  end
end

function BUII_CallToArms_InitDB()
  if BUIIDatabase["call_to_arms"] == nil then
    BUIIDatabase["call_to_arms"] = false
  end

  -- Backwards compatibility: migrate old dungeon setting to new settings
  if BUIIDatabase["call_to_arms_dungeon"] ~= nil then
    local oldValue = BUIIDatabase["call_to_arms_dungeon"]
    BUIIDatabase["call_to_arms_dungeon_normal"] = oldValue
    BUIIDatabase["call_to_arms_dungeon_heroic"] = oldValue
    BUIIDatabase["call_to_arms_dungeon_timewalking"] = oldValue
    BUIIDatabase["call_to_arms_dungeon"] = nil -- Remove old key
  end

  if BUIIDatabase["call_to_arms_dungeon_normal"] == nil then
    BUIIDatabase["call_to_arms_dungeon_normal"] = true
  end
  if BUIIDatabase["call_to_arms_dungeon_heroic"] == nil then
    BUIIDatabase["call_to_arms_dungeon_heroic"] = true
  end
  if BUIIDatabase["call_to_arms_dungeon_timewalking"] == nil then
    BUIIDatabase["call_to_arms_dungeon_timewalking"] = true
  end
  if BUIIDatabase["call_to_arms_lfr"] == nil then
    BUIIDatabase["call_to_arms_lfr"] = true
  end
  if BUIIDatabase["call_to_arms_roles"] == nil then
    BUIIDatabase["call_to_arms_roles"] = { tank = true, healer = true, damage = true }
  end
  if BUIIDatabase["call_to_arms_sound_id"] == nil then
    BUIIDatabase["call_to_arms_sound_id"] = 17316
  end
end
