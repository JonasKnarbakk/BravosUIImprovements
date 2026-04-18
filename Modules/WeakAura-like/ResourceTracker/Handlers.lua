-- ResourceTracker Handlers Module
-- Shared resource state handlers used by multiple classes

local addonName, addon = ...

BUII_ResourceHandlers = {}

-- Generic power type handler (Paladin, Monk Windwalker, Mage Arcane, Shaman Elemental, Priest Shadow)
function BUII_ResourceHandlers.GenericPower(config)
  local power = UnitPower("player", config.powerType)
  local partial = 0
  if config.isBar then
    if UnitPowerPercent then
      partial = UnitPowerPercent("player", config.powerType)
    else
      local max = UnitPowerMax("player", config.powerType)
      if max and max > 0 and not issecretvalue(power) then
        partial = power / max
      end
    end
  end
  return power, partial, nil
end

-- Simple power handler (Hunter, Warrior, Priest Disc/Holy)
function BUII_ResourceHandlers.SimplePower(config)
  local power = UnitPower("player", config.powerType)
  return power, 0, nil
end

-- Combo Points handler (Rogue, Druid)
function BUII_ResourceHandlers.ComboPoints(config)
  local power = UnitPower("player", config.powerType)
  local chargedPoints = GetUnitChargedPowerPoints("player")
  return power, 0, chargedPoints
end

-- Buff stacks handler (Shaman Enhancement, Mage Frost)
function BUII_ResourceHandlers.BuffStacks(config)
  local count = 0

  for _, buffId in ipairs(config.buffs) do
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(buffId)
    if aura then
      count = aura.applications
      break
    end
  end

  return count, 0, nil
end

-- Spell charges handler (Shaman Restoration, Monk Mistweaver, Mage Fire)
function BUII_ResourceHandlers.SpellCharges(config)
  local chargeInfo = C_Spell.GetSpellCharges(config.charges)
  if chargeInfo then
    return chargeInfo.currentCharges, 0, nil
  end
  return 0, 0, nil
end

-- Ability stacks handler (Demon Hunter Vengeance)
function BUII_ResourceHandlers.AbilityStacks(config)
  local count = C_Spell.GetSpellCastCount(config.abilityStacks) or 0
  return count, 0, nil
end

-- Class-specific handlers are defined in their respective class files:
-- DeathKnight: DeathKnight.lua, Evoker: Evoker.lua, Warlock: Warlock.lua
-- Monk Stagger: Monk.lua, Demon Hunter Devourer: DemonHunter.lua
