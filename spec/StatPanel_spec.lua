---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.BUIICharacterDatabase = {}
_G.BUII_GetFontPath = function()
  return "testfont"
end
_G.BUII_GetFontFlags = function()
  return ""
end
_G.BUII_GetFontShadow = function()
  return 1, -1
end

pcall(dofile, "Modules/WeakAura-like/StatPanel.lua")

describe("BravosUIImprovements StatPanel", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_StatPanel_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_StatPanel_Enable()
    end)
  end)

  describe("BUII_StatPanel_Disable", function()
    it("disables without crashing", function()
      BUII_StatPanel_Disable()
    end)
  end)

  describe("BUII_StatPanel_Refresh", function()
    it("refreshes without crashing", function()
      BUII_StatPanel_Refresh()
    end)
  end)
  describe("BUII_StatPanel_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      _G.BUIICharacterDatabase = {}
      BUII_StatPanel_InitDB()

      assert.are.equal(false, BUIIDatabase["stat_panel"])
      assert.are.equal(120, BUIIDatabase["stat_panel_width"])
      assert.are.equal(false, BUIICharacterDatabase["stat_panel_use_char_settings"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["stat_panel"] = true }
      _G.BUIICharacterDatabase = { ["stat_panel_use_char_settings"] = true }
      BUII_StatPanel_InitDB()

      assert.are.equal(true, BUIIDatabase["stat_panel"])
      assert.are.equal(true, BUIICharacterDatabase["stat_panel_use_char_settings"])
    end)
  end)
end)
