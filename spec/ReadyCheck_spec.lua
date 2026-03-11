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

  describe("BUII_ReadyCheck_InitDB", function()
    it("initializes missing database values", function()
      BUII_ReadyCheck_InitDB()
      assert.is_false(_G.BUIIDatabase["ready_check"])
    end)
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
end)
