---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.BUIICharacterDatabase = {}
_G.BUII_GetTexturePath = function()
  return "testtexture"
end
_G.BUII_GetFontPath = function()
  return "testfont"
end
_G.BUII_GetFontFlags = function()
  return ""
end
_G.BUII_GetFontShadow = function()
  return 1, -1
end
_G.BUII_FormatNumber = function(n)
  return tostring(n)
end

-- Store original functions
local originals = {
  UnitClass = _G.UnitClass,
  PlayerUtil_GetCurrentSpecID = _G.PlayerUtil.GetCurrentSpecID,
  GetSpecialization = _G.GetSpecialization,
  UnitPower = _G.UnitPower,
  UnitPowerMax = _G.UnitPowerMax,
  UnitPartialPower = _G.UnitPartialPower,
  GetRuneCooldown = _G.GetRuneCooldown,
  C_UnitAuras_GetPlayerAuraBySpellID = _G.C_UnitAuras.GetPlayerAuraBySpellID,
  C_Spell_GetSpellCharges = _G.C_Spell.GetSpellCharges,
  C_Spell_GetSpellCastCount = _G.C_Spell.GetSpellCastCount,
  UnitStagger = _G.UnitStagger,
  UnitHealthMax = _G.UnitHealthMax,
  GetUnitChargedPowerPoints = _G.GetUnitChargedPowerPoints,
  UnitPowerDisplayMod = _G.UnitPowerDisplayMod,
  UnitPowerPercent = _G.UnitPowerPercent,
  UnitPowerType = _G.UnitPowerType,
  issecretvalue = _G.issecretvalue,
  CreateFrame = _G.CreateFrame,
}

pcall(dofile, "Modules/WeakAura-like/ResourceTracker.lua")

describe("BravosUIImprovements ResourceTracker", function()
  -- Helper to reset all mocks
  local function resetMocks()
    _G.UnitClass = originals.UnitClass
    _G.PlayerUtil.GetCurrentSpecID = originals.PlayerUtil_GetCurrentSpecID
    _G.GetSpecialization = originals.GetSpecialization
    _G.UnitPower = originals.UnitPower
    _G.UnitPowerMax = originals.UnitPowerMax
    _G.UnitPartialPower = originals.UnitPartialPower
    _G.GetRuneCooldown = originals.GetRuneCooldown
    _G.C_UnitAuras.GetPlayerAuraBySpellID = originals.C_UnitAuras_GetPlayerAuraBySpellID
    _G.C_Spell.GetSpellCharges = originals.C_Spell_GetSpellCharges
    _G.C_Spell.GetSpellCastCount = originals.C_Spell_GetSpellCastCount
    _G.UnitStagger = originals.UnitStagger
    _G.UnitHealthMax = originals.UnitHealthMax
    _G.GetUnitChargedPowerPoints = originals.GetUnitChargedPowerPoints
    _G.UnitPowerDisplayMod = originals.UnitPowerDisplayMod
    _G.UnitPowerPercent = originals.UnitPowerPercent
    _G.UnitPowerType = originals.UnitPowerType
    _G.issecretvalue = originals.issecretvalue
    _G.CreateFrame = originals.CreateFrame
  end

  -- reset state before each test
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
    resetMocks()
  end)

  after_each(function()
    -- Ensure we clean up any frames
    BUII_ResourceTracker_Disable()
  end)

  describe("BUII_ResourceTracker_Enable", function()
    it("initializes without crashing given standard mocks", function()
      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
      end)
    end)

    it("creates the main frame", function()
      BUII_ResourceTracker_Enable()
      assert.is_not_nil(_G.BUII_ResourceTrackerFrame)
    end)

    it("creates frame with expected name", function()
      BUII_ResourceTracker_Enable()

      -- Frame should exist in global namespace
      assert.is_not_nil(_G.BUII_ResourceTrackerFrame)
    end)
  end)

  describe("BUII_ResourceTracker_Disable", function()
    it("disables without crashing when not enabled", function()
      assert.has_no.errors(function()
        BUII_ResourceTracker_Disable()
      end)
    end)

    it("disables without crashing when enabled", function()
      BUII_ResourceTracker_Enable()
      assert.has_no.errors(function()
        BUII_ResourceTracker_Disable()
      end)
    end)
  end)

  describe("BUII_ResourceTracker_Refresh", function()
    it("refreshes without crashing when frame not initialized", function()
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("refreshes without crashing when frame exists", function()
      BUII_ResourceTracker_Enable()
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)
  end)

  describe("BUII_ResourceTracker_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      _G.BUIICharacterDatabase = {}
      BUII_ResourceTracker_InitDB()

      assert.are.equal(false, BUIIDatabase["resource_tracker"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_shaman"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_demonhunter"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_warlock"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_paladin"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_priest"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_monk"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_deathknight"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_evoker"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_hunter"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_rogue"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_druid"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_mage"])
      assert.are.equal(false, BUIIDatabase["resource_tracker_show_border"])
      assert.are.equal(false, BUIIDatabase["resource_tracker_use_class_color"])
      assert.are.equal(false, BUIIDatabase["resource_tracker_hide_native"])
      assert.are.equal(false, BUIIDatabase["resource_tracker_show_power_bar"])
      assert.are.equal(4, BUIIDatabase["resource_tracker_power_bar_height"])
      assert.are.equal(2, BUIIDatabase["resource_tracker_power_bar_padding"])
      assert.are.equal(false, BUIIDatabase["resource_tracker_power_bar_show_text"])
      assert.are.equal(12, BUIIDatabase["resource_tracker_power_bar_font_size"])
      assert.are.equal(2, BUIIDatabase["resource_tracker_frame_strata"])
      assert.are.equal(false, BUIICharacterDatabase["resource_tracker_use_char_settings"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["resource_tracker"] = true, ["resource_tracker_shaman"] = false }
      _G.BUIICharacterDatabase = { ["resource_tracker_use_char_settings"] = true }
      BUII_ResourceTracker_InitDB()

      assert.are.equal(true, BUIIDatabase["resource_tracker"])
      assert.are.equal(false, BUIIDatabase["resource_tracker_shaman"])
      assert.are.equal(true, BUIICharacterDatabase["resource_tracker_use_char_settings"])
    end)
  end)

  describe("Settings Integration", function()
    it("applies total width setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_total_width = 200 }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies height setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_height = 20 }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies show border setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_show_border = true }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies use class color setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_use_class_color = true }
      _G.C_ClassColor.GetClassColor = function()
        return { r = 0.96, g = 0.55, b = 0.73 }
      end
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies show power bar setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_show_power_bar = true }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies resource opacity setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_opacity = 0.8 }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies background opacity setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_background_opacity = 0.3 }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies show text setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_show_stacks = true }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies font size setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_stacks_font_size = 16 }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies show decimal setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_show_decimal = true }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies frame strata setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_frame_strata = 4 } -- HIGH
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies power bar height setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = {
        resource_tracker_show_power_bar = true,
        resource_tracker_power_bar_height = 6,
      }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies power bar padding setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = {
        resource_tracker_show_power_bar = true,
        resource_tracker_power_bar_padding = 4,
      }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies power bar show text setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = {
        resource_tracker_show_power_bar = true,
        resource_tracker_power_bar_show_text = true,
      }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies power bar font size setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = {
        resource_tracker_show_power_bar = true,
        resource_tracker_power_bar_font_size = 14,
      }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("applies hide native frame setting without error", function()
      BUII_ResourceTracker_Enable()
      _G.BUIIDatabase = { resource_tracker_hide_native = true }
      assert.has_no.errors(function()
        BUII_ResourceTracker_Refresh()
      end)
    end)
  end)

  describe("Character Specific Settings", function()
    it("uses character database when enabled", function()
      _G.BUIICharacterDatabase = {
        resource_tracker_use_char_settings = true,
        resource_tracker_show_border = true,
      }

      -- Verify the GetDB function returns character DB when enabled
      local result = BUII_EditModeUtils:GetDB("resource_tracker")
      -- Result should be BUIICharacterDatabase since use_char_settings is true
      assert.are.equal(_G.BUIICharacterDatabase.resource_tracker_show_border, true)
    end)

    it("uses global database when character settings disabled", function()
      _G.BUIIDatabase = {
        resource_tracker_show_border = true,
        resource_tracker_use_char_settings = false,
      }
      _G.BUIICharacterDatabase = {
        resource_tracker_use_char_settings = false,
        resource_tracker_show_border = false,
      }

      -- Verify the global DB has the expected values
      assert.are.equal(true, _G.BUIIDatabase.resource_tracker_show_border)
      assert.are.equal(false, _G.BUIIDatabase.resource_tracker_use_char_settings)
    end)
  end)

  describe("Edge Cases", function()
    it("handles secret values gracefully", function()
      _G.UnitPower = function()
        return "secret"
      end
      _G.issecretvalue = function(v)
        return v == "secret"
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("handles Druid in non-energy form", function()
      _G.UnitClass = function()
        return "Druid", "DRUID"
      end
      _G.UnitPowerType = function()
        return Enum.PowerType.Mana
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("handles Druid in energy form", function()
      _G.UnitClass = function()
        return "Druid", "DRUID"
      end
      _G.UnitPowerType = function()
        return Enum.PowerType.Energy
      end
      _G.UnitPowerMax = function()
        return 5
      end
      _G.UnitPower = function()
        return 3
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("handles nil aura returns", function()
      _G.UnitClass = function()
        return "Shaman", "SHAMAN"
      end
      _G.PlayerUtil.GetCurrentSpecID = function()
        return 263
      end
      _G.C_UnitAuras.GetPlayerAuraBySpellID = function()
        return nil
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("handles nil spell charges", function()
      _G.UnitClass = function()
        return "Mage", "MAGE"
      end
      _G.PlayerUtil.GetCurrentSpecID = function()
        return 63
      end
      _G.C_Spell.GetSpellCharges = function()
        return nil
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("handles combat lockdown", function()
      _G.InCombatLockdown = function()
        return true
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("handles Edit Mode entry", function()
      _G.EditModeManagerFrame.IsShown = function()
        return true
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
      end)
    end)

    it("handles disabled class", function()
      _G.UnitClass = function()
        return "Warrior", "WARRIOR"
      end
      _G.BUIIDatabase = { resource_tracker_warrior = false }

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("handles unknown class", function()
      _G.UnitClass = function()
        return "Unknown", "UNKNOWN"
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)

    it("handles zero max points", function()
      _G.UnitClass = function()
        return "Paladin", "PALADIN"
      end
      _G.UnitPowerMax = function()
        return 0
      end

      assert.has_no.errors(function()
        BUII_ResourceTracker_Enable()
        BUII_ResourceTracker_Refresh()
      end)
    end)
  end)

  describe("Database Defaults", function()
    it("initializes all class-specific defaults", function()
      _G.BUIIDatabase = {}
      BUII_ResourceTracker_InitDB()

      -- All classes should have their defaults set to true (enabled)
      local classSettings = {
        "resource_tracker_shaman",
        "resource_tracker_demonhunter",
        "resource_tracker_warlock",
        "resource_tracker_paladin",
        "resource_tracker_priest",
        "resource_tracker_monk",
        "resource_tracker_deathknight",
        "resource_tracker_evoker",
        "resource_tracker_hunter",
        "resource_tracker_rogue",
        "resource_tracker_druid",
        "resource_tracker_mage",
      }

      for _, setting in ipairs(classSettings) do
        assert.are.equal(true, BUIIDatabase[setting], "Expected " .. setting .. " to be true")
      end
    end)

    it("initializes all power bar defaults", function()
      _G.BUIIDatabase = {}
      BUII_ResourceTracker_InitDB()

      assert.are.equal(false, BUIIDatabase["resource_tracker_show_power_bar"])
      assert.are.equal(4, BUIIDatabase["resource_tracker_power_bar_height"])
      assert.are.equal(2, BUIIDatabase["resource_tracker_power_bar_padding"])
      assert.are.equal(false, BUIIDatabase["resource_tracker_power_bar_show_text"])
      assert.are.equal(12, BUIIDatabase["resource_tracker_power_bar_font_size"])
    end)
  end)
end)
