-- Druid Resource Configuration

local addonName, addon = ...

BUII_ResourceTracker_CONFIG.DRUID = {
  handler = "ComboPoints",
  powerType = Enum.PowerType.ComboPoints,
  name = "Combo Points",
  color = { r = 1.0, g = 0.1, b = 0.1 },
  nativeFrame = "DruidComboPointBarFrame",
}
