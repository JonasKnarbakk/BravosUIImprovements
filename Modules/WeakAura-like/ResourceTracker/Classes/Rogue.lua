-- Rogue Resource Configuration

local addonName, addon = ...

BUII_ResourceTracker_CONFIG.ROGUE = {
  handler = "ComboPoints",
  powerType = Enum.PowerType.ComboPoints,
  name = "Combo Points",
  color = { r = 1.0, g = 0.1, b = 0.1 },
  colorCharged = { r = 0.0, g = 0.8, b = 1.0 },
  nativeFrame = "RogueComboPointBarFrame",
}
