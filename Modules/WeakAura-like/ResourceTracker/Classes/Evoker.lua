-- Evoker Resource Configuration

local addonName, addon = ...

local function EvokerHandler(config)
  local power = UnitPower("player", config.powerType)
  local partial = UnitPartialPower("player", config.powerType) or 0

  if issecretvalue(power) and UnitPowerPercent then
    local percent = UnitPowerPercent("player", config.powerType)
    if percent and not issecretvalue(percent) then
      local max = UnitPowerMax("player", config.powerType)
      if not max or issecretvalue(max) then
        max = config.maxPoints or 5
      end
      local floatPower = percent * max
      power = math.floor(floatPower)
      partial = (floatPower - power) * 1000
    end
  end

  if not issecretvalue(partial) then
    partial = partial / 1000
  else
    partial = 0
  end

  return power, partial, nil
end

BUII_ResourceHandlers.Evoker = EvokerHandler

BUII_ResourceTracker_CONFIG.EVOKER = {
  handler = "Evoker",
  powerType = Enum.PowerType.Essence,
  name = "Essence",
  color = { r = 0.4, g = 0.8, b = 1.0 },
  progressFill = true,
  nativeFrame = "EssencePlayerFrame",
}
