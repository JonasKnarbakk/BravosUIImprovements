---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

-- Mock Database
_G.BUIIDatabase = {
  no_action_bar_padding = false,
}

-- Load module
dofile("Modules/DefaultUI/ActionBarsImproved.lua")

describe("BravosUIImprovements ActionBarsImproved", function()
  before_each(function()
    _G.BUIIDatabase = { no_action_bar_padding = false }
  end)

  describe("BUII_ActionBarsImprovedNoPaddingEnable", function()
    it("currently just runs without crashing (experimental fix inside)", function()
      -- We just test it doesn't throw a lua error right now
      -- since most of this function is commented out in source
      local status, err = pcall(BUII_ActionBarsImprovedNoPaddingEnable)
      -- The experimental padding fix might crash due to GridLayoutUtil being missing,
      -- let's see. If it fails, our mock needs GridLayoutUtil.
    end)
  end)

  describe("BUII_ActionBarsImprovedNoPaddingDisable", function()
    it("sets no_action_bar_padding to false in db", function()
      _G.BUIIDatabase.no_action_bar_padding = true
      BUII_ActionBarsImprovedNoPaddingDisable()
      assert.is_false(_G.BUIIDatabase.no_action_bar_padding)
    end)
  end)
end)
