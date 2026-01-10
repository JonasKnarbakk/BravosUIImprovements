-- Edit Mode Integration
Enum.EditModeSystem.BUII_GroupTools = 101
BUII_HUD_EDIT_MODE_GROUP_TOOLS_LABEL = "Group Tools"

Enum.EditModeSystem.BUII_CallToArms = 102
BUII_HUD_EDIT_MODE_CALL_TO_ARMS_LABEL = "Call to Arms"

Enum.EditModeSystem.BUII_CombatState = 103
BUII_HUD_EDIT_MODE_COMBAT_STATE_LABEL = "Combat State Notification"

Enum.EditModeSystem.BUII_GearAndTalentLoadout = 104
BUII_HUD_EDIT_MODE_GEAR_AND_TALENT_LOADOUT_LABEL = "Gear & Talent Loadout"

Enum.EditModeSystem.BUII_ReadyCheck = 105
BUII_HUD_EDIT_MODE_READY_CHECK_LABEL = "Ready Check Notification"

Enum.EditModeSystem.BUII_StanceTracker = 106
BUII_HUD_EDIT_MODE_STANCE_TRACKER_LABEL = "Stance Tracker"

Enum.EditModeSystem.BUII_ResourceTracker = 107
BUII_HUD_EDIT_MODE_RESOURCE_TRACKER_LABEL = "Resource Tracker"

Enum.EditModeSystem.BUII_StatPanel = 108
BUII_HUD_EDIT_MODE_STAT_PANEL_LABEL = "Stat Panel"

Enum.EditModeSystem.BUII_LootSpec = 109
BUII_HUD_EDIT_MODE_LOOT_SPEC_LABEL = "Loot Specialization"

function BUII_GetFontPath()
  local fontName = "Expressway"
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local font = LSM:Fetch("font", fontName)
    if font then
      return font
    end
  end
  -- Fallback
  local filename = GameFontHighlight:GetFont()
  return filename
end
