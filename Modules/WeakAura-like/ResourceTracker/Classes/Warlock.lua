-- Warlock Resource Configuration

local addonName, addon = ...

local function SoulShardsHandler(config)
  local power = UnitPower("player", config.powerType)
  local precise = UnitPower("player", config.powerType, true)
  local mod = UnitPowerDisplayMod(config.powerType)
  local partial = 0
  if mod > 1 then
    partial = (precise % mod) / mod
  end
  return power, partial, nil
end

BUII_ResourceHandlers.SoulShards = SoulShardsHandler

BUII_ResourceTracker_CONFIG.WARLOCK = {
  handler = "SoulShards",
  powerType = Enum.PowerType.SoulShards,
  name = "Soul Shards",
  color = { r = 0.64, g = 0.00, b = 0.94 },
  progressFill = true,
  nativeFrame = "WarlockPowerFrame",
}
