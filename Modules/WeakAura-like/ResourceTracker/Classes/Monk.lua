-- Monk Resource Configuration

local addonName, addon = ...

local function StaggerHandler(config)
  local stagger = UnitStagger("player") or 0
  local maxHealth = UnitHealthMax("player")
  local percent = 0
  local colorOverride = nil

  if maxHealth and maxHealth > 0 and not issecretvalue(stagger) and not issecretvalue(maxHealth) then
    percent = stagger / maxHealth

    if percent >= 0.60 then
      colorOverride = { r = 1.0, g = 0.2, b = 0.2 }
    elseif percent >= 0.30 then
      colorOverride = { r = 1.0, g = 1.0, b = 0.2 }
    else
      colorOverride = { r = 0.2, g = 1.0, b = 0.2 }
    end
  end

  return stagger, percent, colorOverride
end

BUII_ResourceHandlers.Stagger = StaggerHandler

BUII_ResourceTracker_CONFIG.MONK = {
  {
    spec = 268,
    handler = "Stagger",
    name = "Stagger",
    isBar = true,
    isStagger = true,
    color = { r = 0.0, g = 1.0, b = 0.0 },
  },
  {
    spec = 269,
    handler = "GenericPower",
    powerType = Enum.PowerType.Chi,
    name = "Chi",
    color = { r = 0.0, g = 0.78, b = 0.86 },
    nativeFrame = "MonkHarmonyBarFrame",
  },
  {
    spec = 270,
    handler = "SpellCharges",
    name = "Renewing Mist",
    charges = 115151,
    maxPoints = 3,
    color = { r = 0.20, g = 0.90, b = 0.50 },
  },
}
