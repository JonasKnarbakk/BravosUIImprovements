---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.GameTooltip = {
  AddLine = function() end,
  GetItem = function()
    return "item", "link", 12345
  end,
}

pcall(dofile, "TooltipImprovements.lua")

describe("BravosUIImprovements TooltipImprovements", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  describe("BUII_TooltipImprovements_InitDB", function()
    it("initializes missing database values", function()
      BUII_TooltipImprovements_InitDB()
      assert.is_false(_G.BUIIDatabase["tooltip_expansion"])
    end)
  end)

  describe("BUII_TooltipImprovements_Enabled", function()
    it("enables without crashing given standard mocks", function()
      BUII_TooltipImprovements_Enabled()
    end)
  end)

  describe("BUII_TooltipImprovements_Disable", function()
    it("disables without crashing", function()
      BUII_TooltipImprovements_Disable()
    end)
  end)
end)
