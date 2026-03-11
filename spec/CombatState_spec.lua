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

pcall(dofile, "CombatState.lua")

describe("BravosUIImprovements CombatState", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  describe("BUII_CombatState_InitDB", function()
    it("initializes missing database values", function()
      BUII_CombatState_InitDB()
      assert.is_false(_G.BUIIDatabase["combat_state"])
    end)
  end)

  describe("BUII_CombatState_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_CombatState_Enable()
    end)
  end)

  describe("BUII_CombatState_Disable", function()
    it("disables without crashing", function()
      BUII_CombatState_Disable()
    end)
  end)

  describe("BUII_CombatState_Refresh", function()
    it("refreshes fonts without crashing", function()
      BUII_CombatState_Refresh()
    end)
  end)
end)
