-- Druid Resource Module
local addonName, addon = ...

local DruidModule = {}

function DruidModule:SetupLayout(frame)
  local maxPoints = 5
  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
  if not isEditMode then
    local powerType = UnitPowerType("player")
    if powerType ~= Enum.PowerType.Energy then
      maxPoints = 0
    else
      maxPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 5
    end
  end
  BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, maxPoints)
  frame.ResourceBar:Hide()
end

function DruidModule:Update(frame, db, isEditMode)
  local isEnergyForm = true
  if not isEditMode then
    local powerType = UnitPowerType("player")
    if powerType ~= Enum.PowerType.Energy then
      isEnergyForm = false
    end
  end

  if not isEnergyForm then
    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, 0, function() end, 0)
    return
  end

  local maxPoints = 5
  local power = 3

  if not isEditMode then
    maxPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 5
    power = UnitPower("player", Enum.PowerType.ComboPoints) or 0
  end

  local color = { r = 1.0, g = 0.1, b = 0.1 }

  BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, maxPoints, function(i, point)
    return (not BUII_IsSecretValue(power) and i <= power), 0, color, false
  end, power)
end

BUII_ResourceTracker_RegisterModule("DRUID", DruidModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.DRUID = {
  handler = "ComboPoints",
  powerType = Enum.PowerType.ComboPoints,
  name = "Combo Points",
  color = { r = 1.0, g = 0.1, b = 0.1 },
  nativeFrame = "DruidComboPointBarFrame",
}
