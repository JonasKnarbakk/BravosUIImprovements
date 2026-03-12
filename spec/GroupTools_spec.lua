---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.BUII_GetFontPath = function()
  return "testfont"
end
_G.BUII_GetFontFlags = function()
  return ""
end
_G.BUII_GetFontShadow = function()
  return 1, -1
end

pcall(dofile, "Modules/WeakAura-like/GroupTools.lua")

describe("BravosUIImprovements GroupTools", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  describe("BUII_GroupTools_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_GroupTools_Enable()
    end)
  end)

  describe("BUII_GroupTools_Disable", function()
    it("disables without crashing", function()
      BUII_GroupTools_Disable()
    end)
  end)

  describe("BUII_GroupTools_Refresh", function()
    it("refreshes without crashing", function()
      BUII_GroupTools_Refresh()
    end)
  end)
  describe("BUII_GroupTools_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      BUII_GroupTools_InitDB()

      assert.are.equal(false, BUIIDatabase["group_tools"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["group_tools"] = true }
      BUII_GroupTools_InitDB()

      assert.are.equal(true, BUIIDatabase["group_tools"])
    end)
  end)
end)
