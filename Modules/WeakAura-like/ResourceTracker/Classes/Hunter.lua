-- Hunter Resource Configuration

local addonName, addon = ...

BUII_ResourceTracker_CONFIG.HUNTER = {
  handler = "SimplePower",
  powerType = Enum.PowerType.Focus,
  name = "Focus",
  color = { r = 1.00, g = 0.56, b = 0.26 },
  isBar = false,
  hidePrimary = true,
}
