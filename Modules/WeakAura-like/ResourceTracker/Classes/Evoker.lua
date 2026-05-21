-- Evoker Resource Module
local addonName, addon = ...

local EvokerModule = {}

function EvokerModule:SetupLayout(frame)
  local maxEssence = 5
  if not EditModeManagerFrame or not EditModeManagerFrame:IsShown() then
    maxEssence = UnitPowerMax("player", Enum.PowerType.Essence) or 5
  end
  BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, maxEssence)
  frame.ResourceBar:Hide()

  -- Evoker Essence requires a frequent update script to animate partial cooldown filling
  frame:SetScript("OnUpdate", function(self, elapsed)
    if not self or self.isApplyingSettings then
      return
    end

    local maxPoints = 5
    if not EditModeManagerFrame or not EditModeManagerFrame:IsShown() then
      maxPoints = UnitPowerMax("player", Enum.PowerType.Essence) or 5
    end

    local power = UnitPower("player", Enum.PowerType.Essence)
    local partial = 0

    if BUII_IsSecretValue(power) and UnitPowerPercent then
      local percent = UnitPowerPercent("player", Enum.PowerType.Essence)
      if percent and not BUII_IsSecretValue(percent) then
        local floatPower = percent * maxPoints
        power = math.floor(floatPower)
        partial = floatPower - power
      else
        return
      end
    else
      partial = UnitPartialPower("player", Enum.PowerType.Essence) or 0
      if BUII_IsSecretValue(partial) then
        return
      end
      partial = partial / 1000
    end

    local fillIndex = power + 1
    if fillIndex <= maxPoints and self.Points then
      local point = self.Points[fillIndex]
      if point and point.ProgressBar and point.ProgressBar:IsShown() then
        point.ProgressBar:SetValue(partial)
      end
    end
  end)
end

function EvokerModule:Update(frame, db, isEditMode)
  local maxEssence = 5
  local power = 3
  local partial = 0.5

  if not isEditMode then
    maxEssence = UnitPowerMax("player", Enum.PowerType.Essence) or 5
    power = UnitPower("player", Enum.PowerType.Essence) or 0

    if BUII_IsSecretValue(power) and UnitPowerPercent then
      local percent = UnitPowerPercent("player", Enum.PowerType.Essence)
      if percent and not BUII_IsSecretValue(percent) then
        local floatPower = percent * maxEssence
        power = math.floor(floatPower)
        partial = floatPower - power
      end
    else
      local p = UnitPartialPower("player", Enum.PowerType.Essence) or 0
      if not BUII_IsSecretValue(p) then
        partial = p / 1000
      else
        partial = 0
      end
    end
  end

  local color = { r = 0.4, g = 0.8, b = 1.0 }

  BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, maxEssence, function(i, point)
    local isFull = (not BUII_IsSecretValue(power) and i <= power)
    local myPartial = 0
    if not isFull and i == power + 1 then
      myPartial = partial
    end
    return isFull, myPartial, color, false
  end, power)
end

BUII_ResourceTracker_RegisterModule("EVOKER", EvokerModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.EVOKER = {
  handler = "Evoker",
  powerType = Enum.PowerType.Essence,
  name = "Essence",
  color = { r = 0.4, g = 0.8, b = 1.0 },
  progressFill = true,
  nativeFrame = "EssencePlayerFrame",
}
