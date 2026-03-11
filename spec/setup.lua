-- local lua = require("lua")

-- Mock basic WoW Global APIs
_G.GetTime = function()
  return 1000
end
_G.CreateFrame = function(frameType, name, parent, template)
  local frame = {
    GetName = function()
      return name or "MockedFrame"
    end,
    SetScript = function() end,
    HookScript = function() end,
    RegisterEvent = function() end,
    RegisterForClicks = function() end,
    RegisterUnitEvent = function() end,
    UnregisterEvent = function() end,
    UnregisterAllEvents = function() end,
    Show = function() end,
    Hide = function() end,
    SetWidth = function() end,
    SetHeight = function() end,
    SetSize = function() end,
    GetWidth = function()
      return 100
    end,
    GetHeight = function()
      return 20
    end,
    SetPoint = function() end,
    GetParent = function()
      return _G.UIParent
    end,
    SetParent = function() end,
    SetAlpha = function() end,
    ClearAllPoints = function() end,
    SetText = function() end,
    GetText = function()
      return "MockText"
    end,
    SetFrameStrata = function() end,
    SetFrameLevel = function() end,
    GetFrameLevel = function()
      return 10
    end,
    SetAllPoints = function() end,
    SetBackdropBorderColor = function() end,
    SetStatusBarTexture = function() end,
    SetStatusBarColor = function() end,
    SetMinMaxValues = function() end,
    SetValue = function() end,
    IsShown = function()
      return false
    end,
    GetFontString = function()
      return { SetFont = function() end, SetText = function() end }
    end,
    CreateFontString = function()
      return {
        ClearAllPoints = function() end,
        SetFont = function() end,
        SetPoint = function() end,
        SetText = function() end,
        GetText = function()
          return "MockText"
        end,
        SetTextColor = function() end,
        SetJustifyH = function() end,
        SetShadowOffset = function() end,
        GetStringWidth = function()
          return 100
        end,
        GetStringHeight = function()
          return 20
        end,
        Show = function() end,
        Hide = function() end,
        SetDrawLayer = function() end,
        SetAlpha = function() end,
        GetFontString = function()
          return { SetFont = function() end }
        end,
        CreateAnimationGroup = function()
          return {
            CreateAnimation = function()
              return {
                SetFromAlpha = function() end,
                SetToAlpha = function() end,
                SetDuration = function() end,
                SetSmoothing = function() end,
                SetOrder = function() end,
                SetOffset = function() end,
              }
            end,
            Play = function() end,
            Stop = function() end,
            SetLooping = function() end,
          }
        end,
      }
    end,
    CreateTexture = function()
      return {
        ClearAllPoints = function() end,
        SetTexture = function() end,
        SetSize = function() end,
        SetPoint = function() end,
        GetWidth = function()
          return 100
        end,
        GetHeight = function()
          return 20
        end,
        SetAlpha = function() end,
        SetTexCoord = function() end,
        SetAllPoints = function() end,
        SetColorTexture = function() end,
        SetVertexColor = function() end,
        Hide = function() end,
        Show = function() end,
        IsShown = function()
          return false
        end,
        CreateAnimationGroup = function()
          return {
            CreateAnimation = function()
              return {
                SetFromAlpha = function() end,
                SetToAlpha = function() end,
                SetDuration = function() end,
                SetSmoothing = function() end,
                SetOrder = function() end,
                SetOffset = function() end,
                SetScaleFrom = function() end,
                SetScaleTo = function() end,
                SetOrigin = function() end,
              }
            end,
            Play = function() end,
            Stop = function() end,
            SetLooping = function() end,
            IsPlaying = function()
              return false
            end,
            Restart = function() end,
          }
        end,
      }
    end,
    CreateAnimationGroup = function()
      return {
        CreateAnimation = function()
          return {
            SetFromAlpha = function() end,
            SetToAlpha = function() end,
            SetDuration = function() end,
            SetSmoothing = function() end,
            SetOrder = function() end,
            SetOffset = function() end,
          }
        end,
        Play = function() end,
        Stop = function() end,
        SetLooping = function() end,
      }
    end,
    GetCenter = function()
      return 500, 500
    end,
    GetScale = function()
      return 1.0
    end,
    SetScale = function() end,
    EnableMouse = function() end,
    SetMovable = function() end,
    SetClampedToScreen = function() end,
    SetDontSavePosition = function() end,
    GetPoint = function()
      return "CENTER", "UIParent", "CENTER", 0, 0
    end,
    IsProtected = function()
      return false
    end,
  }
  -- Add global reference if named
  if name then
    _G[name] = frame
  end

  -- Add template-specific children
  if template == "BUII_PowerBarTemplate" then
    frame.ProgressBar = _G.CreateFrame("Frame")
    frame.Background = { SetTexture = function() end, SetVertexColor = function() end }
  elseif template == "BUII_ResourcePointTemplate" then
    frame.ProgressBar = _G.CreateFrame("Frame")
    frame.Background = { SetTexture = function() end, SetVertexColor = function() end }
  end

  return frame
end
_G.hooksecurefunc = function(table, funcName, hookFunc)
  if type(table) == "string" then
    -- hooking a global function
  end
end
_G.Enum = {
  EditModeSettingDisplayType = { Checkbox = 1, Dropdown = 2, Slider = 3 },
  ChrCustomizationOptionType = { Checkbox = 1, Dropdown = 2 },
  EditModeSystem = {
    ActionBar = 1,
    BUII_CombatState = 2,
    BUII_ReadyCheck = 3,
    BUII_GroupTools = 4,
    BUII_StanceTracker = 5,
    BUII_StatPanel = 6,
    BUII_ResourceTracker = 7,
    BUII_PetReminder = 8,
    BUII_MissingBuffReminder = 114,
    BUII_ArenaEnemyFrames = 12,
  },
  EditModeActionBarSetting = { VisibleSetting = 1 },
  ActionBarVisibleSetting = { Always = 0, InCombat = 1, OutOfCombat = 2, Hidden = 3 },
  EditModeMicroMenuSetting = { EyeSize = 1 },
  TooltipDataType = { Item = 1 },
  PowerType = {
    SoulShards = 7,
    HolyPower = 9,
    Chi = 12,
    Runes = 5,
    Essence = 19,
    ComboPoints = 4,
    ArcaneCharges = 16,
    Energy = 3,
  },
}
_G.C_SpellBook = {
  GetNumSpellBookSkillLines = function()
    return 0
  end,
  GetSpellBookSkillLineInfo = function()
    return nil
  end,
}
_G.C_AddOns = {
  IsAddOnLoaded = function(name)
    return false
  end,
}
_G.print = print
_G.issecretvalue = function(val)
  return false
end
_G.GetServerExpansionLevel = function()
  return 11
end
_G.EJ_GetTierInfo = function(id)
  return "The War Within"
end
_G.PlaySoundFile = function() end
_G.GetInventoryItemDurability = function(slot)
  return 100, 100
end
_G.IsSpellKnown = function()
  return false
end
_G.GetItemCooldown = function()
  return 0, 0, 1
end
_G.IsInGroup = function()
  return false
end
_G.IsInRaid = function()
  return false
end
_G.DoReadyCheck = function() end
_G.UnitClass = function(unit)
  return "Warrior", "WARRIOR"
end
_G.GetShapeshiftForm = function()
  return 0
end
_G.GetShapeshiftFormInfo = function(stance)
  return 132349, true, true, 12345
end

-- Mock PetReminder APIs
_G.UnitExists = function()
  return false
end
_G.UnitIsDead = function()
  return false
end
_G.UnitAffectingCombat = function()
  return false
end
_G.C_SpellActivationOverlay = {
  IsSpellOverlayed = function()
    return false
  end,
}

-- Mock ArenaEnemyFramesContainer
_G.ArenaEnemyFramesContainer = _G.CreateFrame("Frame", "ArenaEnemyFramesContainer")
_G.ArenaEnemyFramesContainer.GetParent = function()
  return _G.UIParent
end

-- Mock TotemFrame
_G.PlayerFrameBottomManagedFramesContainer = { Layout = function() end }
_G.TotemFrame = _G.CreateFrame("Frame", "TotemFrame")
_G.TotemFrame.layoutParent = {
  AddManagedFrame = function() end,
  RemoveManagedFrame = function() end,
  Layout = function() end,
}

-- Mock StatPanel APIs
_G.GetCritChance = function()
  return 10
end
_G.GetHaste = function()
  return 10
end
_G.GetMasteryEffect = function()
  return 10
end
_G.GetCombatRatingBonus = function()
  return 10
end
_G.GetVersatilityBonus = function()
  return 10
end
_G.GetLifesteal = function()
  return 10
end
_G.GetSpeed = function()
  return 10
end
_G.GetAvoidance = function()
  return 10
end
_G.GetDodgeChance = function()
  return 10
end
_G.GetParryChance = function()
  return 10
end
_G.GetBlockChance = function()
  return 10
end
_G.CR_VERSATILITY_DAMAGE_DONE = 1
_G.GameFontNormal = {
  GetFont = function()
    return "font", 12, ""
  end,
}

-- Mock ResourceTracker APIs
_G.GetSpecialization = function()
  return 1
end
_G.UnitPowerMax = function()
  return 5
end
_G.UnitPower = function()
  return 3
end
_G.UnitPartialPower = function()
  return 0
end
_G.GetPowerRegenForPowerType = function()
  return 0.2
end
_G.UnitPowerDisplayMod = function()
  return 1
end
_G.GetUnitChargedPowerPoints = function()
  return {}
end
_G.UnitPowerPercent = function()
  return 0
end
_G.UnitStagger = function()
  return 0
end
_G.UnitHealthMax = function()
  return 100
end
_G.C_UnitAuras = {
  GetPlayerAuraBySpellID = function()
    return nil
  end,
}
_G.GetCollapsingStarCost = function()
  return 1
end
_G.GetRuneCooldown = function()
  return 0, 0, true
end
_G.UnitPowerType = function()
  return Enum.PowerType.Energy
end
_G.C_ClassColor = {
  GetClassColor = function()
    return { r = 1, g = 1, b = 1 }
  end,
}

_G.TooltipDataProcessor = {
  AddTooltipPostCall = function() end,
}
_G.C_Item = {
  GetItemInfo = function()
    return nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1
  end,
  GetItemCount = function()
    return 0
  end,
}

-- Utility functions

_G.UIParent = _G.CreateFrame("Frame", "UIParent")
_G.InCombatLockdown = function()
  return false
end
_G.CopyTable = function(t)
  if type(t) ~= "table" then
    return t
  end
  local res = {}
  for k, v in pairs(t) do
    res[k] = CopyTable(v)
  end
  return res
end
_G.EditModeManagerFrame = {
  GetActiveLayoutInfo = function()
    return { layoutName = "Default" }
  end,
  RegisterSystemFrame = function() end,
  SetHasActiveChanges = function() end,
  OnEditModeSystemAnchorChanged = function() end,
  CheckForSystemActiveChanges = function() end,
  IsShown = function()
    return true
  end,
}
_G.EditModeSettingDisplayInfoManager = {
  systemSettingDisplayInfo = {
    [1] = { -- ActionBar
      [2] = { options = {} }, -- VisibleSetting + 1
    },
  },
}
_G.EditModeSystemSettingsDialog = {
  UpdateSettings = function() end,
  OnSettingValueChanged = function() end,
  UpdateButtons = function() end,
  Settings = _G.CreateFrame("Frame", "EditModeSettings"),
  Buttons = _G.CreateFrame("Frame", "EditModeButtons"),
  GetSettingPool = function()
    return {
      Acquire = function()
        return _G.CreateFrame("Frame")
      end,
    }
  end,
}
_G.EditModeSystemMixin = {}
_G.C_EditMode = {
  GetActiveLayoutInfo = function()
    return { layoutName = "Default" }
  end,
}

_G.EventRegistry = {
  RegisterCallback = function() end,
  RegisterFrameEventAndCallback = function() end,
  UnregisterCallback = function() end,
  UnregisterFrameEventAndCallback = function() end,
}

_G.BUII_EditModeUtils = {
  AddScaleSetting = function() end,
  RegisterSystem = function() end,
  ApplySavedPosition = function() end,
  AddCharacterSpecificSetting = function() end,
  GetDB = function()
    return {}
  end,
}
-- Mock C_Timer
_G.C_Timer = {
  NewTimer = function(duration, callback)
    return {
      Cancel = function() end,
      IsCancelled = function()
        return false
      end,
    }
  end,
  NewTicker = function(duration, callback)
    return {
      Cancel = function() end,
      IsCancelled = function()
        return false
      end,
    }
  end,
  After = function(duration, callback)
    callback()
  end,
}

-- Mock C_LFGList
_G.C_LFGList = {
  GetAvailableRoles = function()
    return true, true, true -- tank, healer, dps
  end,
}

-- Mock LFG APIs
_G.IsInInstance = function()
  return false, "none"
end
_G.GetNumGroupMembers = function()
  return 0
end
_G.GetAverageItemLevel = function()
  return 400, 400
end
_G.GetNumRandomDungeons = function()
  return 1
end
_G.GetLFGRandomDungeonInfo = function(index)
  return 2746, "Random Dungeon", 0, 0, 10, 80, 80, 10, 80, 10, 0, "", 1, 5, "", false, 0, 1, false, "", 0
end
_G.GetNumRFDungeons = function()
  return 0
end
_G.GetLFGRoleShortageRewards = function(dId, shortageIndex)
  return true, true, false, false, 1, 0, 0 -- eligible, tank array
end
_G.GetLFDRoleRestrictions = function(dId)
  return false, false, false -- none locked
end
_G.GetLFGDungeonShortageRewardInfo = function(dId, shortageIndex, rewardIndex)
  return "Reward", "Interface\\Icons\\Inv_misc_bag_07", 1, 0, 0, 0, 1
end
_G.RequestLFDPlayerLockInfo = function() end

_G.LFG_ROLE_NUM_SHORTAGE_TYPES = 1

-- Mock GroupTools/Party/Spells APIs
_G.C_Spell = {
  GetSpellCharges = function()
    return nil
  end,
  GetSpellCooldown = function()
    return nil
  end,
  GetSpellName = function()
    return "MockSpell"
  end,
  GetSpellTexture = function()
    return 12345
  end,
  GetSpellMaxCumulativeAuraApplications = function()
    return 1
  end,
  GetSpellCastCount = function()
    return 0
  end,
}
_G.C_PartyInfo = {
  DoCountdown = function() end,
}

-- Mock Loadout APIs
_G.PlayerUtil = {
  GetCurrentSpecID = function()
    return 1
  end,
}

_G.C_ClassTalents = {
  GetLastSelectedSavedConfigID = function(specId)
    return 1
  end,
}

_G.C_Traits = {
  GetConfigInfo = function(configId)
    return { name = "Test Loadout" }
  end,
}

_G.C_EquipmentSet = {
  GetNumEquipmentSets = function()
    return 1
  end,
  GetEquipmentSetInfo = function(index)
    return "Test Set", "Interface\\Icons\\INV_Sword_04", 0, true
  end,
}
