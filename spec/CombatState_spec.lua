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

pcall(dofile, "Modules/WeakAura-like/CombatState.lua")

describe("BravosUIImprovements CombatState", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  describe("BUII_CombatState_Enable", function()
    it("creates frame, registers events, and shows frame", function()
      BUII_CombatState_Enable()
      local frame = _G.BUII_CombatStateFrame
      assert.is_not_nil(frame)

      -- Verify frame visibility by spying on Show during a subsequent Enable
      local showSpy = spy.on(frame, "Show")
      BUII_CombatState_Enable()
      assert.spy(showSpy).was.called()
    end)
  end)

  describe("Combat Event Handlers", function()
    it("handles combat events without crashing", function()
      BUII_CombatState_Enable()
      local frame = _G.BUII_CombatStateFrame
      local handler = frame:GetScript("OnEvent")

      -- Trigger the events to ensure it updates its font strings and animations without crashing
      handler(frame, "PLAYER_REGEN_DISABLED")
      handler(frame, "PLAYER_REGEN_ENABLED")
    end)
  end)

  describe("BUII_CombatState_Disable", function()
    it("disables without crashing and hides frame", function()
      BUII_CombatState_Enable()
      local frame = _G.BUII_CombatStateFrame
      local hideSpy = spy.on(frame, "Hide")
      local unregisterSpy = spy.on(frame, "UnregisterEvent")

      BUII_CombatState_Disable()

      assert.spy(hideSpy).was.called()
      assert.spy(unregisterSpy).was.called_with(match.is_table(), "PLAYER_REGEN_DISABLED")
    end)
  end)

  describe("BUII_CombatState_Refresh", function()
    it("refreshes fonts", function()
      BUII_CombatState_Enable()
      -- If we reached this function without crash it means Text elements exist and setFont didn't crash
      local status = pcall(BUII_CombatState_Refresh)
      assert.is_true(status)
    end)
  end)
  describe("BUII_CombatState_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      BUII_CombatState_InitDB()

      assert.are.equal(false, BUIIDatabase["combat_state"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["combat_state"] = true }
      BUII_CombatState_InitDB()

      assert.are.equal(true, BUIIDatabase["combat_state"])
    end)
  end)
end)
