-- Mage Resource Module
local addonName, addon = ...

local MageModule = {}

function MageModule:SetupLayout(frame)
  local specId = PlayerUtil.GetCurrentSpecID()
  if specId == 62 then -- Arcane: Arcane Charges Points
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 4)
  elseif specId == 63 then -- Fire: Fire Blast Charges Points
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 3)
  elseif specId == 64 then -- Frost: Flurry Buff Stack Points
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 5)
  else
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  end
end

function MageModule:Update(frame, db, isEditMode)
  local specId = isEditMode and 62 or PlayerUtil.GetCurrentSpecID()

  if specId == 62 then -- Arcane
    local count = 3
    if not isEditMode then
      count = UnitPower("player", Enum.PowerType.ArcaneCharges) or 0
    end
    local color = { r = 0.56, g = 0.24, b = 0.85 }

    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, 4, function(i, point)
      return (not BUII_IsSecretValue(count) and i <= count), 0, color, false
    end, count)

  elseif specId == 63 then -- Fire
    local charges = 2
    if not isEditMode then
      local chargeInfo = C_Spell.GetSpellCharges(108853)
      charges = chargeInfo and chargeInfo.currentCharges or 0
    end
    local color = { r = 0.91, g = 0.49, b = 0.25 }

    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, 3, function(i, point)
      return (not BUII_IsSecretValue(charges) and i <= charges), 0, color, false
    end, charges)

  elseif specId == 64 then -- Frost
    local stacks = 3
    if not isEditMode then
      stacks = 0
      local aura = C_UnitAuras.GetPlayerAuraBySpellID(205473)
      if aura then
        stacks = aura.applications or 0
      end
    end
    local color = { r = 0.447, g = 0.780, b = 1.0 }

    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, 5, function(i, point)
      return (not BUII_IsSecretValue(stacks) and i <= stacks), 0, color, false
    end, stacks)
  end
end

BUII_ResourceTracker_RegisterModule("MAGE", MageModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.MAGE = {
  {
    spec = 62,
    handler = "GenericPower",
    powerType = Enum.PowerType.ArcaneCharges,
    name = "Arcane Charges",
    color = { r = 0.56, g = 0.24, b = 0.85 },
    nativeFrame = "MageArcaneChargesFrame",
  },
  {
    spec = 63,
    handler = "SpellCharges",
    charges = 108853,
    name = "Fire Blast",
    maxPoints = 3,
    color = { r = 0.91, g = 0.49, b = 0.25 },
  },
  {
    spec = 64,
    handler = "BuffStacks",
    buffs = { 205473 },
    name = "Flurry",
    maxPoints = 5,
    color = { r = 0.447, g = 0.780, b = 1.0 },
  },
}
