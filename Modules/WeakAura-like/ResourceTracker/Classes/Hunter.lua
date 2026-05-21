-- Hunter Resource Module
local addonName, addon = ...

local HunterModule = {}

function HunterModule:SetupLayout(frame)
  BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  frame.ResourceBar:Hide()
end

function HunterModule:Update(frame, db, isEditMode)
  BUII_ResourceTracker_LayoutHelper:UpdateCounterText(frame, 0, nil)
end

BUII_ResourceTracker_RegisterModule("HUNTER", HunterModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.HUNTER = {
  handler = "SimplePower",
  powerType = Enum.PowerType.Focus,
  name = "Focus",
  color = { r = 1.00, g = 0.56, b = 0.26 },
  isBar = false,
  hidePrimary = true,
}
