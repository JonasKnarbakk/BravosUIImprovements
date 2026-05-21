-- Paladin Resource Module
local addonName, addon = ...

local PaladinModule = {}

function PaladinModule:SetupLayout(frame)
  local maxHolyPower = 5
  if not EditModeManagerFrame or not EditModeManagerFrame:IsShown() then
    maxHolyPower = UnitPowerMax("player", Enum.PowerType.HolyPower) or 5
  end
  BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, maxHolyPower)
  frame.ResourceBar:Hide()
end

function PaladinModule:Update(frame, db, isEditMode)
  local maxHolyPower = 5
  local power = 3

  if not isEditMode then
    maxHolyPower = UnitPowerMax("player", Enum.PowerType.HolyPower) or 5
    power = UnitPower("player", Enum.PowerType.HolyPower) or 0
  end

  local color = { r = 0.95, g = 0.9, b = 0.1 }

  BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, maxHolyPower, function(i, point)
    return (not BUII_IsSecretValue(power) and i <= power), 0, color, false
  end, power)
end

BUII_ResourceTracker_RegisterModule("PALADIN", PaladinModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.PALADIN = {
  handler = "GenericPower",
  powerType = Enum.PowerType.HolyPower,
  name = "Holy Power",
  color = { r = 0.95, g = 0.9, b = 0.1 },
  nativeFrame = "PaladinPowerBarFrame",
}
