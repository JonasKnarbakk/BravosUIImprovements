-- Rogue Resource Module
local addonName, addon = ...

local RogueModule = {}

function RogueModule:SetupLayout(frame)
  local maxPoints = 5
  if not EditModeManagerFrame or not EditModeManagerFrame:IsShown() then
    maxPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 5
  end
  BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, maxPoints)
  frame.ResourceBar:Hide()
end

function RogueModule:Update(frame, db, isEditMode)
  local maxPoints = 5
  local power = 3
  local chargedPoints = nil

  if isEditMode then
    chargedPoints = { 2, 4 }
  else
    maxPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 5
    power = UnitPower("player", Enum.PowerType.ComboPoints) or 0
    chargedPoints = GetUnitChargedPowerPoints("player")
  end

  local color = { r = 1.0, g = 0.1, b = 0.1 }
  local colorCharged = { r = 0.0, g = 0.8, b = 1.0 }

  BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, maxPoints, function(i, point)
    local isFull = (not BUII_IsSecretValue(power) and i <= power)
    
    local isCharged = false
    if chargedPoints then
      for _, cpIndex in ipairs(chargedPoints) do
        if cpIndex == i then
          isCharged = true
          break
        end
      end
    end

    local drawColor = isCharged and colorCharged or color
    return isFull, 0, drawColor, isCharged
  end, power)
end

BUII_ResourceTracker_RegisterModule("ROGUE", RogueModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.ROGUE = {
  handler = "ComboPoints",
  powerType = Enum.PowerType.ComboPoints,
  name = "Combo Points",
  color = { r = 1.0, g = 0.1, b = 0.1 },
  colorCharged = { r = 0.0, g = 0.8, b = 1.0 },
  nativeFrame = "RogueComboPointBarFrame",
}
