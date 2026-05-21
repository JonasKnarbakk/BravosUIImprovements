-- Priest Resource Module
local addonName, addon = ...

local PriestModule = {}

function PriestModule:SetupLayout(frame)
  local specId = PlayerUtil.GetCurrentSpecID()
  if specId == 258 then -- Shadow: Insanity Bar
    frame.ResourceBar:Show()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  else
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
  end
end

function PriestModule:Update(frame, db, isEditMode)
  local specId = isEditMode and 258 or PlayerUtil.GetCurrentSpecID()

  if specId == 258 then -- Shadow: Insanity Bar
    local power = 50
    local percent = 0.5
    if not isEditMode then
      power = UnitPower("player", Enum.PowerType.Insanity) or 0
      if UnitPowerPercent then
        percent = UnitPowerPercent("player", Enum.PowerType.Insanity) or 0
      else
        local max = UnitPowerMax("player", Enum.PowerType.Insanity) or 100
        if not BUII_IsSecretValue(max) and max > 0 and not BUII_IsSecretValue(power) then
          percent = power / max
        end
      end
    end
    local color = { r = 0.50, g = 0.00, b = 1.00 }

    BUII_ResourceTracker_LayoutHelper:UpdateBar(frame, percent, color, power)
  else
    -- Holy / Disc: Hidden primary
    BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, 0)
    frame.ResourceBar:Hide()
    BUII_ResourceTracker_LayoutHelper:UpdateCounterText(frame, 0, nil)
  end
end

BUII_ResourceTracker_RegisterModule("PRIEST", PriestModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.PRIEST = {
  {
    spec = 256,
    handler = "SimplePower",
    powerType = Enum.PowerType.Mana,
    name = "Mana",
    color = { r = 0.00, g = 0.00, b = 1.00 },
    isBar = false,
    hidePrimary = true,
  },
  {
    spec = 257,
    handler = "SimplePower",
    powerType = Enum.PowerType.Mana,
    name = "Mana",
    color = { r = 0.00, g = 0.00, b = 1.00 },
    isBar = false,
    hidePrimary = true,
  },
  {
    spec = 258,
    handler = "GenericPower",
    powerType = Enum.PowerType.Insanity,
    name = "Insanity",
    color = { r = 0.50, g = 0.00, b = 1.00 },
    isBar = true,
    powerId = 0,
    powerKey = "MANA",
  },
}
