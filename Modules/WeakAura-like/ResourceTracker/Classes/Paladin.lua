-- Paladin Resource Configuration

local addonName, addon = ...

BUII_ResourceTracker_CONFIG.PALADIN = {
  handler = "GenericPower",
  powerType = Enum.PowerType.HolyPower,
  name = "Holy Power",
  color = { r = 0.95, g = 0.9, b = 0.1 },
  nativeFrame = "PaladinPowerBarFrame",
}
