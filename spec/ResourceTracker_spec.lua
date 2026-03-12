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

pcall(dofile, "Modules/WeakAura-like/ResourceTracker.lua")

describe("BravosUIImprovements ResourceTracker", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_ResourceTracker_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_ResourceTracker_Enable()
    end)
  end)

  describe("BUII_ResourceTracker_Disable", function()
    it("disables without crashing", function()
      BUII_ResourceTracker_Disable()
    end)
  end)

  describe("BUII_ResourceTracker_Refresh", function()
    it("refreshes without crashing", function()
      BUII_ResourceTracker_Refresh()
    end)
  end)
  describe("BUII_ResourceTracker_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      _G.BUIICharacterDatabase = {}
      BUII_ResourceTracker_InitDB()

      assert.are.equal(false, BUIIDatabase["resource_tracker"])
      assert.are.equal(true, BUIIDatabase["resource_tracker_shaman"])
      assert.are.equal(false, BUIICharacterDatabase["resource_tracker_use_char_settings"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["resource_tracker"] = true }
      _G.BUIICharacterDatabase = { ["resource_tracker_use_char_settings"] = true }
      BUII_ResourceTracker_InitDB()

      assert.are.equal(true, BUIIDatabase["resource_tracker"])
      assert.are.equal(true, BUIICharacterDatabase["resource_tracker_use_char_settings"])
    end)
  end)
end)
