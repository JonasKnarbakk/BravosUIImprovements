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

pcall(dofile, "Modules/WeakAura-like/StanceTracker.lua")

describe("BravosUIImprovements StanceTracker", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_StanceTracker_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_StanceTracker_Enable()
    end)
  end)

  describe("BUII_StanceTracker_Disable", function()
    it("disables without crashing", function()
      BUII_StanceTracker_Disable()
    end)
  end)

  describe("BUII_StanceTracker_Refresh", function()
    it("refreshes without crashing", function()
      BUII_StanceTracker_Refresh()
    end)
  end)
  describe("BUII_StanceTracker_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      _G.BUIICharacterDatabase = {}
      BUII_StanceTracker_InitDB()

      assert.are.equal(false, BUIIDatabase["stance_tracker"])
      assert.are.equal(20, BUIIDatabase["stance_tracker_icon_size"])
      assert.are.equal(false, BUIICharacterDatabase["stance_tracker_use_char_settings"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["stance_tracker"] = true }
      _G.BUIICharacterDatabase = { ["stance_tracker_use_char_settings"] = true }
      BUII_StanceTracker_InitDB()

      assert.are.equal(true, BUIIDatabase["stance_tracker"])
      assert.are.equal(true, BUIICharacterDatabase["stance_tracker_use_char_settings"])
    end)
  end)
end)
