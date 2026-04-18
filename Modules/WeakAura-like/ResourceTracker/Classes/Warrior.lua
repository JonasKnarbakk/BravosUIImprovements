-- Warrior Resource Configuration

local addonName, addon = ...

BUII_ResourceTracker_CONFIG.WARRIOR = {
  handler = "SimplePower",
  powerType = Enum.PowerType.Rage,
  name = "Rage",
  color = { r = 1.00, g = 0.00, b = 0.00 },
  isBar = false,
  hidePrimary = true,
}
