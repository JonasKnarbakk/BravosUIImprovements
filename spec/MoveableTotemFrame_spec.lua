---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.BUIICharacterDatabase = {}

pcall(dofile, "MoveableTotemFrame.lua")

describe("BravosUIImprovements MoveableTotemFrame", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_MoveableTotemFrame_InitDB", function()
    it("initializes missing database values", function()
      BUII_MoveableTotemFrame_InitDB()
      assert.is_false(_G.BUIIDatabase["moveable_totem_frame"])
    end)
  end)

  describe("BUII_MoveableTotemFrame_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_MoveableTotemFrame_Enable()
    end)
  end)

  describe("BUII_MoveableTotemFrame_Disable", function()
    it("disables without crashing", function()
      BUII_MoveableTotemFrame_Disable()
    end)
  end)
end)
