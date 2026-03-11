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
    it("creates and hooks timer frames, and realigns text", function()
      local setJustifySpy = spy.on(_G.PlayerCastingBarFrame.Text, "SetJustifyH")

      BUII_CastBarTimersEnable()

      assert.is_not_nil(_G["BUIICastBarTimer" .. PlayerCastingBarFrame:GetName()])
      assert.spy(setJustifySpy).was.called_with(_G.PlayerCastingBarFrame.Text, "LEFT")

      -- Verify frames are shown via spying on Show
      local showSpy = spy.on(_G["BUIICastBarTimerPlayerCastingBarFrame"], "Show")

      -- Disable then Enable to trigger Show again (first call happened when asserting is_not_nil)
      BUII_CastBarTimersDisable()
      BUII_CastBarTimersEnable()

      assert.spy(showSpy).was.called()
    end)
  end)

  describe("BUII_CastBarTimersDisable", function()
    it("restores text alignment and hides frames", function()
      BUII_CastBarTimersEnable() -- Ensure initialized

      local setJustifySpy = spy.on(_G.PlayerCastingBarFrame.Text, "SetJustifyH")
      local hideSpy = spy.on(_G.BUIICastBarTimerPlayerCastingBarFrame, "Hide")

      BUII_CastBarTimersDisable()

      assert.spy(setJustifySpy).was.called_with(_G.PlayerCastingBarFrame.Text, "CENTER")
      assert.spy(hideSpy).was.called()
    end)
  end)

  describe("Timer Text Update Logic", function()
    it("calculates time correctly from OnUpdate handler", function()
      _G.GetTime = function()
        return 100
      end
      -- Mock UnitCastingInfo returning endTime 101.5 sec
      _G.UnitCastingInfo = function(unit)
        if unit == "player" then
          return "Test Spell", nil, nil, nil, 101500
        end
        return nil
      end
      _G.UnitChannelInfo = function()
        return nil
      end

      BUII_CastBarTimersEnable()
      _G.PlayerCastingBarFrame.unit = "player"

      -- Extract the OnUpdate handler that was hooked by the module
      local handler = _G.PlayerCastingBarFrame:GetScript("OnUpdate")

      -- The frame's text should exist
      local textObj = _G.BUIICastBarTimerPlayerCastingBarFrame.text
      local setTextSpy = spy.on(textObj, "SetText")

      handler(_G.PlayerCastingBarFrame)

      -- 101.5 - 100.0 = 1.5 seconds remaining
      assert.spy(setTextSpy).was.called_with(textObj, "1.5")
    end)
  end)
end)
