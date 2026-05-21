-- Monk Resource Module
local addonName, addon = ...

local MonkModule = {}

function MonkModule:SetupLayout(frame)
  local specId = PlayerUtil.GetCurrentSpecID()
  if specId == 268 then -- Brewmaster: Stagger Bar
    frame.ResourceBar:Show()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  elseif specId == 269 then -- Windwalker: Chi Points
    frame.ResourceBar:Hide()
    local maxChi = 5
    if not EditModeManagerFrame or not EditModeManagerFrame:IsShown() then
      maxChi = UnitPowerMax("player", Enum.PowerType.Chi) or 5
    end
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, maxChi)
  elseif specId == 270 then -- Mistweaver: Renewing Mist Charges Points
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 3)
  else
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  end
end

function MonkModule:Update(frame, db, isEditMode)
  local specId = isEditMode and 269 or PlayerUtil.GetCurrentSpecID()

  if specId == 268 then -- Brewmaster: Stagger Bar
    local stagger = 50000
    local maxHealth = 100000
    local percent = 0.5
    local color = { r = 0.2, g = 1.0, b = 0.2 }

    if not isEditMode then
      stagger = UnitStagger("player") or 0
      maxHealth = UnitHealthMax("player") or 1
      if not BUII_IsSecretValue(maxHealth) and maxHealth > 0 and not BUII_IsSecretValue(stagger) then
        percent = stagger / maxHealth
        if percent >= 0.60 then
          color = { r = 1.0, g = 0.2, b = 0.2 }
        elseif percent >= 0.30 then
          color = { r = 1.0, g = 1.0, b = 0.2 }
        else
          color = { r = 0.2, g = 1.0, b = 0.2 }
        end
      end
    end

    BUII_ResourceTracker_LayoutHelper:UpdateBar(frame, percent, color, stagger)

  elseif specId == 269 then -- Windwalker: Chi Points
    local chi = 3
    local maxChi = 5
    if not isEditMode then
      maxChi = UnitPowerMax("player", Enum.PowerType.Chi) or 5
      chi = UnitPower("player", Enum.PowerType.Chi) or 0
    end
    local color = { r = 0.0, g = 0.78, b = 0.86 }

    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, maxChi, function(i, point)
      return (not BUII_IsSecretValue(chi) and i <= chi), 0, color, false
    end, chi)

  elseif specId == 270 then -- Mistweaver: Renewing Mist Charges Points
    local charges = 2
    if not isEditMode then
      local chargeInfo = C_Spell.GetSpellCharges(115151)
      charges = chargeInfo and chargeInfo.currentCharges or 0
    end
    local color = { r = 0.20, g = 0.90, b = 0.50 }

    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, 3, function(i, point)
      return (not BUII_IsSecretValue(charges) and i <= charges), 0, color, false
    end, charges)
  end
end

BUII_ResourceTracker_RegisterModule("MONK", MonkModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.MONK = {
  {
    spec = 268,
    handler = "Stagger",
    name = "Stagger",
    isBar = true,
    isStagger = true,
    color = { r = 0.0, g = 1.0, b = 0.0 },
  },
  {
    spec = 269,
    handler = "GenericPower",
    powerType = Enum.PowerType.Chi,
    name = "Chi",
    color = { r = 0.0, g = 0.78, b = 0.86 },
    nativeFrame = "MonkHarmonyBarFrame",
  },
  {
    spec = 270,
    handler = "SpellCharges",
    name = "Renewing Mist",
    charges = 115151,
    maxPoints = 3,
    color = { r = 0.20, g = 0.90, b = 0.50 },
  },
}
