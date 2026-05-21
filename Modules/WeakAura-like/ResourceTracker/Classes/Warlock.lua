-- Warlock Resource Module
local addonName, addon = ...

local WarlockModule = {}

function WarlockModule:SetupLayout(frame)
  local maxShards = 5
  if not EditModeManagerFrame or not EditModeManagerFrame:IsShown() then
    maxShards = UnitPowerMax("player", Enum.PowerType.SoulShards) or 5
  end
  BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, maxShards)
  frame.ResourceBar:Hide()
end

function WarlockModule:Update(frame, db, isEditMode)
  local maxShards = 5
  local power = 3
  local partial = 0.5

  if not isEditMode then
    maxShards = UnitPowerMax("player", Enum.PowerType.SoulShards) or 5
    power = UnitPower("player", Enum.PowerType.SoulShards) or 0
    local precise = UnitPower("player", Enum.PowerType.SoulShards, true) or 0
    local mod = UnitPowerDisplayMod(Enum.PowerType.SoulShards) or 1
    if not BUII_IsSecretValue(mod) and mod > 1 then
      if not BUII_IsSecretValue(precise) then
        partial = (precise % mod) / mod
      else
        partial = 0
      end
    else
      partial = 0
    end
  end

  local color = { r = 0.64, g = 0.00, b = 0.94 }

  BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, maxShards, function(i, point)
    local isFull = (not BUII_IsSecretValue(power) and i <= power)
    local myPartial = 0
    if not isFull and not BUII_IsSecretValue(power) and i == power + 1 then
      myPartial = partial
    end
    return isFull, myPartial, color, false
  end, power)
end

BUII_ResourceTracker_RegisterModule("WARLOCK", WarlockModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.WARLOCK = {
  handler = "SoulShards",
  powerType = Enum.PowerType.SoulShards,
  name = "Soul Shards",
  color = { r = 0.64, g = 0.00, b = 0.94 },
  progressFill = true,
  nativeFrame = "WarlockPowerFrame",
}
