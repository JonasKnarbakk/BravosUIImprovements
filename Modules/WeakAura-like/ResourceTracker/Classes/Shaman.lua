-- Shaman Resource Configuration

local addonName, addon = ...

BUII_ResourceTracker_CONFIG.SHAMAN = {
  {
    spec = 262,
    handler = "GenericPower",
    powerType = Enum.PowerType.Maelstrom,
    name = "Maelstrom",
    color = { r = 0.447, g = 0.780, b = 1.0 },
    isBar = true,
    powerId = 0,
    powerKey = "MANA",
  },
  {
    spec = 263,
    handler = "BuffStacks",
    buffs = { 344179, 384088 },
    name = "Maelstrom Weapon",
    maxPoints = 5,
    color = { r = 0.447, g = 0.780, b = 1.0 },
    color2 = { r = 1.0, g = 0.4, b = 0.4 },
    layered = true,
  },
  {
    spec = 264,
    handler = "SpellCharges",
    name = "Riptide",
    charges = 61295,
    maxPoints = 3,
    color = { r = 0.10, g = 0.75, b = 0.65 },
  },
}
