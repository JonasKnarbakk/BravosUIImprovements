-- Priest Resource Configuration

local addonName, addon = ...

BUII_ResourceTracker_CONFIG.PRIEST = {
  {
    spec = 256,
    handler = "SimplePower",
    powerType = Enum.PowerType.Mana,
    name = "Mana",
    color = { r = 0.00, g = 0.00, b = 1.00 },
    isBar = false,
    hidePrimary = true,
  },
  {
    spec = 257,
    handler = "SimplePower",
    powerType = Enum.PowerType.Mana,
    name = "Mana",
    color = { r = 0.00, g = 0.00, b = 1.00 },
    isBar = false,
    hidePrimary = true,
  },
  {
    spec = 258,
    handler = "GenericPower",
    powerType = Enum.PowerType.Insanity,
    name = "Insanity",
    color = { r = 0.50, g = 0.00, b = 1.00 },
    isBar = true,
    powerId = 0,
    powerKey = "MANA",
  },
}
