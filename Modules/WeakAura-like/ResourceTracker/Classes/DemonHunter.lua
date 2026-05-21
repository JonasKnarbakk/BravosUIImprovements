-- Demon Hunter Resource Module
local addonName, addon = ...

local DemonHunterModule = {}

function DemonHunterModule:SetupLayout(frame)
  local specId = PlayerUtil.GetCurrentSpecID()
  if specId == 581 then -- Vengeance
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 6)
  else
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  end
end

function DemonHunterModule:Update(frame, db, isEditMode)
  local specId = isEditMode and 581 or PlayerUtil.GetCurrentSpecID()

  if specId == 581 then -- Vengeance: Soul Fragments points
    local count = 3
    if not isEditMode then
      count = C_Spell.GetSpellCastCount(228477) or 0
    end
    local color = { r = 0.8, g = 0.2, b = 0.8 }

    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, 6, function(i, point)
      return (not BUII_IsSecretValue(count) and i <= count), 0, color, false
    end, count)
    
  elseif specId == 1480 then -- Aldrachi Reaver spec
    -- Devourer Soul Fragments Bar
    local inVoidMeta = false
    local current, max = 3, 6
    local percent = 0.5
    
    if not isEditMode then
      inVoidMeta = C_UnitAuras.GetPlayerAuraBySpellID(1217607) ~= nil
      if inVoidMeta then
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(1227702)
        current = aura and aura.applications or 0
        max = (GetCollapsingStarCost and GetCollapsingStarCost()) or 1
      else
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(1225789)
        current = aura and aura.applications or 0
        max = C_Spell.GetSpellMaxCumulativeAuraApplications(1225789) or 1
      end
      
      if not BUII_IsSecretValue(max) and max > 0 and not BUII_IsSecretValue(current) then
        percent = current / max
      else
        percent = 0
      end
    end

    local color = { r = 0.33, g = 0.08, b = 0.76 }
    BUII_ResourceTracker_LayoutHelper:UpdateBar(frame, percent, color, current)
    
  else -- Havoc: 0 points (hide primary)
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:UpdateCounterText(frame, 0, nil)
  end
end

BUII_ResourceTracker_RegisterModule("DEMONHUNTER", DemonHunterModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.DEMONHUNTER = {
  {
    spec = 577,
    handler = "SimplePower",
    powerType = Enum.PowerType.Fury,
    name = "Fury",
    color = { r = 0.8, g = 0.2, b = 0.8 },
    isBar = false,
    hidePrimary = true,
  },
  {
    spec = 581,
    handler = "BuffStacks",
    buffs = { 203981 },
    name = "Soul Fragments",
    maxPoints = 6,
    color = { r = 0.8, g = 0.2, b = 0.8 },
  },
  {
    spec = 1480,
    handler = "DevourerSoulFragments",
    name = "Soul Fragments",
    isBar = true,
    isDevourerSoulFragments = true,
    color = { r = 0.33, g = 0.08, b = 0.76 },
    nativeFrame = "DemonHunterSoulFragmentsBarFrame",
  },
}
