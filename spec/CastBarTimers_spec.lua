require("spec.setup")

-- Mock frames that CastBarTimers depends on
_G.PlayerCastingBarFrame = _G.CreateFrame("Frame", "PlayerCastingBarFrame")
_G.PlayerCastingBarFrame.Text = {
  SetJustifyH = function() end,
  SetPoint = function() end,
  ClearAllPoints = function() end,
}
_G.TargetFrameSpellBar = _G.CreateFrame("Frame", "TargetFrameSpellBar")
_G.TargetFrameSpellBar.Text = {
  SetJustifyH = function() end,
  SetPoint = function() end,
  ClearAllPoints = function() end,
}
_G.FocusFrameSpellBar = _G.CreateFrame("Frame", "FocusFrameSpellBar")
_G.FocusFrameSpellBar.Text = {
  SetJustifyH = function() end,
  SetPoint = function() end,
  ClearAllPoints = function() end,
}

_G.BUIIDatabase = {
  castbar_timers = true,
}

-- Load module
dofile("CastBarTimers.lua")

describe("BravosUIImprovements CastBarTimers", function()
  -- reset state before testing
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  describe("BUII_CastBarTimers_InitDB", function()
    it("initializes castbar_timers to false if nil", function()
      BUII_CastBarTimers_InitDB()
      assert.is_false(BUIIDatabase["castbar_timers"])
    end)

    it("keeps existing castbar_timers value", function()
      BUIIDatabase["castbar_timers"] = true
      BUII_CastBarTimers_InitDB()
      assert.is_true(BUIIDatabase["castbar_timers"])
    end)
  end)

  describe("BUII_CastBarTimersEnable", function()
    it("creates and hooks timer frames if not initialized", function()
      BUII_CastBarTimersEnable()
      assert.is_not_nil(_G["BUIICastBarTimer" .. PlayerCastingBarFrame:GetName()])
      -- At minimum test it doesn't crash doing the setup
    end)
  end)
end)
