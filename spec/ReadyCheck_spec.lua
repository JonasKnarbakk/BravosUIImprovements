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

pcall(dofile, "Modules/WeakAura-like/ReadyCheck.lua")

describe("BravosUIImprovements ReadyCheck", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  describe("BUII_ReadyCheck_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_ReadyCheck_Enable()
    end)
  end)

  describe("BUII_ReadyCheck_Disable", function()
    it("disables without crashing", function()
      BUII_ReadyCheck_Disable()
    end)
  end)

  describe("BUII_ReadyCheck_Refresh", function()
    it("refreshes fonts without crashing", function()
      BUII_ReadyCheck_Refresh()
    end)
  end)
  describe("BUII_ReadyCheck_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      BUII_ReadyCheck_InitDB()

      assert.are.equal(false, BUIIDatabase["ready_check"])
      assert.are.equal(true, BUIIDatabase["ready_check_show_repair"])
      assert.are.equal(99, BUIIDatabase["ready_check_repair_threshold"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["ready_check"] = true }
      BUII_ReadyCheck_InitDB()

      assert.are.equal(true, BUIIDatabase["ready_check"])
    end)
  end)
end)
