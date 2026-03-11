---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}

pcall(dofile, "Ion.lua")

describe("BravosUIImprovements Ion", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  describe("BUII_Ion_InitDB", function()
    it("initializes missing database values", function()
      BUII_Ion_InitDB()
      assert.is_false(_G.BUIIDatabase["ion_mode"])
    end)
  end)

  describe("BUII_Ion_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_Ion_Enable()
    end)
  end)

  describe("BUII_Ion_Disable", function()
    it("disables without crashing", function()
      BUII_Ion_Disable()
    end)
  end)
end)
