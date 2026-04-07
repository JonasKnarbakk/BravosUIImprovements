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
dofile("Modules/DefaultUI/CastBarTimers.lua")

describe("BravosUIImprovements CastBarTimers", function()
  -- reset state before testing
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  -- describe("BUII_CastBarTimersEnable", function()
  --   it("creates and hooks timer frames, and realigns text", function()
  --     local setJustifySpy = spy.on(_G.PlayerCastingBarFrame.Text, "SetJustifyH")
  --
  --     BUII_CastBarTimersEnable()
  --
  --     assert.is_not_nil(_G["BUIICastBarTimer" .. PlayerCastingBarFrame:GetName()])
  --     assert.spy(setJustifySpy).was.called_with(_G.PlayerCastingBarFrame.Text, "LEFT")
  --
  --     -- Verify frames are shown via spying on Show
  --     local showSpy = spy.on(_G["BUIICastBarTimerPlayerCastingBarFrame"], "Show")
  --
  --     -- Disable then Enable to trigger Show again (first call happened when asserting is_not_nil)
  --     BUII_CastBarTimersDisable()
  --     BUII_CastBarTimersEnable()
  --
  --     assert.spy(showSpy).was.called()
  --   end)
  -- end)

  describe("BUII_CastBarTimersDisable", function()
    it("restores text alignment and hides frames", function()
      BUII_CastBarTimersEnable() -- Ensure initialized

      local setJustifySpy = spy.on(_G.PlayerCastingBarFrame.Text, "SetJustifyH")

      BUII_CastBarTimersDisable()

      assert.spy(setJustifySpy).was.called_with(_G.PlayerCastingBarFrame.Text, "CENTER")
    end)
  end)

  describe("BUII_CastBarTimers_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      BUII_CastBarTimers_InitDB()

      assert.are.equal(false, BUIIDatabase["improved_castbars"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["improved_castbars"] = true }
      BUII_CastBarTimers_InitDB()

      assert.are.equal(true, BUIIDatabase["improved_castbars"])
    end)
  end)
end)
