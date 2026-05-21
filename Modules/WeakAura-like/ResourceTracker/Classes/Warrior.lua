-- Warrior Resource Module
local addonName, addon = ...

local WarriorModule = {}

function WarriorModule:SetupLayout(frame)
  BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  frame.ResourceBar:Hide()
end

function WarriorModule:Update(frame, db, isEditMode)
  BUII_ResourceTracker_LayoutHelper:UpdateCounterText(frame, 0, nil)
end

BUII_ResourceTracker_RegisterModule("WARRIOR", WarriorModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.WARRIOR = {
  handler = "SimplePower",
  powerType = Enum.PowerType.Rage,
  name = "Rage",
  color = { r = 1.00, g = 0.00, b = 0.00 },
  isBar = false,
  hidePrimary = true,
}
