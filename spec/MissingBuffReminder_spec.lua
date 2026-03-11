---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.BUIICharacterDatabase = {}
_G.BUII_GetFontPath = function()
  return "testfont"
end
_G.BUII_GetFontFlags = function()
  return ""
end
_G.BUII_GetFontShadow = function()
  return 1, -1
end

pcall(dofile, "Modules/WeakAura-like/MissingBuffReminder.lua")

describe("BravosUIImprovements MissingBuffReminder", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_MissingBuffReminder_InitDB", function()
    it("initializes missing database values", function()
      BUII_MissingBuffReminder_InitDB()
      assert.is_false(_G.BUIIDatabase["missing_buff_reminder"])
    end)
  end)

  describe("BUII_MissingBuffReminder_Enable", function()
    it("creates frame, registers events, and calls updateDisplay", function()
      _G.BUIIDatabase["missing_buff_reminder"] = true

      -- Spy on frame creation / methods before enabling
      local registerEventSpy = spy.new(function() end)
      local setScriptSpy = spy.new(function() end)

      local originalCreateFrame = _G.CreateFrame
      _G.CreateFrame = function(frameType, name, parent, template)
        local f = originalCreateFrame(frameType, name, parent, template)
        if name == "BUII_MissingBuffReminderFrame" then
          f.RegisterEvent = registerEventSpy
          f.SetScript = setScriptSpy
          f.UnregisterAllEvents = spy.new(function() end)
        end
        return f
      end

      BUII_MissingBuffReminder_Enable()

      assert.spy(registerEventSpy).was.called_with(match.is_table(), "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
      assert.spy(registerEventSpy).was.called_with(match.is_table(), "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
      assert.spy(registerEventSpy).was.called_with(match.is_table(), "GROUP_ROSTER_UPDATE")
      assert.spy(setScriptSpy).was.called_with(match.is_table(), "OnEvent", match.is_function())

      _G.CreateFrame = originalCreateFrame
    end)
  end)

  describe("BUII_MissingBuffReminder_Disable", function()
    it("unregisters all events and hides frame", function()
      BUII_MissingBuffReminder_Enable()

      local frame = _G.BUII_MissingBuffReminderFrame
      local unregisterSpy = spy.on(frame, "UnregisterAllEvents")
      local hideSpy = spy.on(frame, "Hide")
      local setScriptSpy = spy.on(frame, "SetScript")

      BUII_MissingBuffReminder_Disable()

      assert.spy(unregisterSpy).was.called()
      assert.spy(hideSpy).was.called()
      assert.spy(setScriptSpy).was.called_with(frame, "OnEvent", nil)
    end)
  end)

  describe("MissingBuffReminder logic", function()
    local frame
    local onEvent
    local originalEditModeIsShown

    before_each(function()
      BUII_MissingBuffReminder_Enable()
      frame = _G.BUII_MissingBuffReminderFrame

      originalEditModeIsShown = _G.EditModeManagerFrame.IsShown
      _G.EditModeManagerFrame.IsShown = function()
        return false
      end

      -- Extract the onEvent function
      local setScriptCalled = false
      local oldSetScript = frame.SetScript
      frame.SetScript = function(self, evt, handler)
        if evt == "OnEvent" then
          onEvent = handler
        end
        oldSetScript(self, evt, handler)
      end
      -- Re-trigger enable to grab handler
      BUII_MissingBuffReminder_Enable()
    end)

    after_each(function()
      _G.EditModeManagerFrame.IsShown = originalEditModeIsShown
    end)

    it("does not show frame if addon feature is disabled", function()
      _G.BUIIDatabase["missing_buff_reminder"] = false
      local hideSpy = spy.on(frame, "Hide")

      BUII_MissingBuffReminder_Refresh()

      assert.spy(hideSpy).was.called()
    end)

    it("shows frame when in group, buff is missing, and feature is enabled", function()
      _G.BUIIDatabase["missing_buff_reminder"] = true
      _G["IsInGroup"] = function()
        return true
      end
      _G["IsInRaid"] = function()
        return false
      end

      -- Mock spell activation for Arcane Intellect (1459)
      _G.C_SpellActivationOverlay.IsSpellOverlayed = function(spellID)
        return spellID == 1459
      end

      local showSpy = spy.on(frame, "Show")

      -- Trigger event
      onEvent(frame, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 1459)

      assert.spy(showSpy).was.called()
    end)

    it("hides frame when only in combat is checked and player is out of combat", function()
      _G.BUIIDatabase["missing_buff_reminder"] = true
      _G.BUIIDatabase["missing_buff_only_in_combat"] = true
      _G["UnitAffectingCombat"] = function()
        return false
      end

      local hideSpy = spy.on(frame, "Hide")

      onEvent(frame, "PLAYER_REGEN_ENABLED")

      assert.spy(hideSpy).was.called()
    end)
  end)
end)
