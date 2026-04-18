-- Demon Hunter Resource Configuration

local addonName, addon = ...

local function DevourerSoulFragmentsHandler(config)
  local inVoidMeta = C_UnitAuras.GetPlayerAuraBySpellID(1217607) ~= nil
  local current, max = 0, 0

  if inVoidMeta then
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(1227702)
    current = aura and aura.applications or 0
    max = (GetCollapsingStarCost and GetCollapsingStarCost()) or 1
  else
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(1225789)
    current = aura and aura.applications or 0
    max = C_Spell.GetSpellMaxCumulativeAuraApplications(1225789) or 1
  end

  local percent = 0
  if max > 0 and not issecretvalue(current) and not issecretvalue(max) then
    percent = current / max
  end

  return current, percent, nil
end

BUII_ResourceHandlers.DevourerSoulFragments = DevourerSoulFragmentsHandler

BUII_ResourceTracker_CONFIG.DEMONHUNTER = {
  {
    spec = 577,
    handler = "SimplePower",
    powerType = Enum.PowerType.Fury,
    name = "Fury",
    color = { r = 0.8, g = 0.2, b = 0.8 },
    isBar = false,
    hidePrimary = true,
  },
  {
    spec = 581,
    handler = "AbilityStacks",
    abilityStacks = 228477,
    name = "Soul Fragments",
    maxPoints = 6,
    color = { r = 0.8, g = 0.2, b = 0.8 },
  },
  {
    spec = 1480,
    handler = "DevourerSoulFragments",
    name = "Soul Fragments",
    isBar = true,
    isDevourerSoulFragments = true,
    color = { r = 0.33, g = 0.08, b = 0.76 },
    nativeFrame = "DemonHunterSoulFragmentsBarFrame",
  },
}
