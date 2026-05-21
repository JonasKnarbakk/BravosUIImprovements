-- Shaman Resource Module
local addonName, addon = ...

local ShamanModule = {}

function ShamanModule:SetupLayout(frame)
  local specId = PlayerUtil.GetCurrentSpecID()
  if specId == 262 then -- Elemental: Maelstrom Bar
    frame.ResourceBar:Show()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  elseif specId == 263 then -- Enhancement: Maelstrom Weapon Points
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 5)
  elseif specId == 264 then -- Restoration: Riptide Charges Points
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 3)
  else
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  end
end

function ShamanModule:Update(frame, db, isEditMode)
  local specId = isEditMode and 263 or PlayerUtil.GetCurrentSpecID()

  if specId == 262 then -- Elemental
    local power = 50
    local percent = 0.5
    if not isEditMode then
      power = UnitPower("player", Enum.PowerType.Maelstrom) or 0
      if UnitPowerPercent then
        percent = UnitPowerPercent("player", Enum.PowerType.Maelstrom)
      else
        local max = UnitPowerMax("player", Enum.PowerType.Maelstrom) or 100
        if not BUII_IsSecretValue(max) and max > 0 and not BUII_IsSecretValue(power) then
          percent = power / max
        end
      end
    end
    local color = { r = 0.447, g = 0.780, b = 1.0 }

    BUII_ResourceTracker_LayoutHelper:UpdateBar(frame, percent, color, power)

  elseif specId == 263 then -- Enhancement
    local count = 7
    if not isEditMode then
      count = 0
      local aura = C_UnitAuras.GetPlayerAuraBySpellID(344179) or C_UnitAuras.GetPlayerAuraBySpellID(384088)
      if aura then
        count = aura.applications or 0
      end
    end

    local color1 = { r = 0.447, g = 0.780, b = 1.0 }
    local color2 = { r = 1.0, g = 0.4, b = 0.4 }
    local maxPoints = 5

    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, maxPoints, function(i, point)
      local isFull = (not BUII_IsSecretValue(count) and i <= count)
      local drawColor = color1
      local isOvercharge = false
      if not BUII_IsSecretValue(count) and count > maxPoints and i <= (count - maxPoints) then
        drawColor = color2
        isOvercharge = true
      end
      
      -- Let the helper know if this is an overcharge color
      local colorData = { r = drawColor.r, g = drawColor.g, b = drawColor.b, isOvercharge = isOvercharge }
      return isFull, 0, colorData, false
    end, count)

  elseif specId == 264 then -- Restoration
    local charges = 2
    if not isEditMode then
      local chargeInfo = C_Spell.GetSpellCharges(61295)
      charges = chargeInfo and chargeInfo.currentCharges or 0
    end
    local color = { r = 0.10, g = 0.75, b = 0.65 }

    BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, 3, function(i, point)
      return (not BUII_IsSecretValue(charges) and i <= charges), 0, color, false
    end, charges)
  end
end

BUII_ResourceTracker_RegisterModule("SHAMAN", ShamanModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.SHAMAN = {
  {
    spec = 262,
    handler = "GenericPower",
    powerType = Enum.PowerType.Maelstrom,
    name = "Maelstrom",
    color = { r = 0.447, g = 0.780, b = 1.0 },
    isBar = true,
    powerId = 0,
    powerKey = "MANA",
  },
  {
    spec = 263,
    handler = "BuffStacks",
    buffs = { 344179, 384088 },
    name = "Maelstrom Weapon",
    maxPoints = 5,
    color = { r = 0.447, g = 0.780, b = 1.0 },
    color2 = { r = 1.0, g = 0.4, b = 0.4 },
    layered = true,
  },
  {
    spec = 264,
    handler = "SpellCharges",
    name = "Riptide",
    charges = 61295,
    maxPoints = 3,
    color = { r = 0.10, g = 0.75, b = 0.65 },
  },
}
