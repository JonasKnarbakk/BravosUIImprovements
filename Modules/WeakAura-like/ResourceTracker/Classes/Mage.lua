-- Mage Resource Configuration

local addonName, addon = ...

BUII_ResourceTracker_CONFIG.MAGE = {
  {
    spec = 62,
    handler = "GenericPower",
    powerType = Enum.PowerType.ArcaneCharges,
    name = "Arcane Charges",
    color = { r = 0.56, g = 0.24, b = 0.85 },
    nativeFrame = "MageArcaneChargesFrame",
  },
  {
    spec = 63,
    handler = "SpellCharges",
    charges = 108853,
    name = "Fire Blast",
    maxPoints = 3,
    color = { r = 0.91, g = 0.49, b = 0.25 },
  },
  {
    spec = 64,
    handler = "BuffStacks",
    buffs = { 205473 },
    name = "Flurry",
    maxPoints = 5,
    color = { r = 0.447, g = 0.780, b = 1.0 },
  },
}
