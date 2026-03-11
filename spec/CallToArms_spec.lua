---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

-- Provide required Globals
_G.BUIIDatabase = {
  call_to_arms = true,
  call_to_arms_dungeon_normal = true,
  call_to_arms_dungeon_heroic = true,
  call_to_arms_dungeon_timewalking = true,
  call_to_arms_lfr = true,
  call_to_arms_roles = {
    tank = true,
    healer = true,
    damage = true,
  },
  call_to_arms_sound_id = 8959,
}

_G.BUII_GetFontPath = function()
  return "testfont"
end
_G.BUII_GetFontFlags = function()
  return ""
end

-- Load Module (using pcall because we might be missing some edge case WoW globals, but we want to load functions)
pcall(dofile, "CallToArms.lua")

describe("BravosUIImprovements CallToArms", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase.call_to_arms = true
  end)

  describe("BUII_CallToArms_Enable", function()
    it("initializes frame, registers event, and calls updateDisplay", function()
      -- Call Enable once to ensure frame is created in the module
      BUII_CallToArms_Enable()

      local frame = _G.BUII_CallToArmsFrame
      local registerSpy = spy.on(frame, "RegisterEvent")
      local setScriptSpy = spy.on(frame, "SetScript")

      BUII_CallToArms_Enable()

      assert.spy(registerSpy).was.called_with(frame, "LFG_UPDATE_RANDOM_INFO")
      assert.spy(setScriptSpy).was.called_with(frame, "OnEvent", match.is_function())
    end)
  end)

  describe("BUII_CallToArms_Disable", function()
    it("hides frame and clears events", function()
      BUII_CallToArms_Enable()
      local frame = _G.BUII_CallToArmsFrame
      local unregisterSpy = spy.on(frame, "UnregisterEvent")
      local setScriptSpy = spy.on(frame, "SetScript")
      local hideSpy = spy.on(frame, "Hide")

      BUII_CallToArms_Disable()

      assert.spy(unregisterSpy).was.called_with(match.is_table(), "LFG_UPDATE_RANDOM_INFO")
      assert.spy(setScriptSpy).was.called_with(match.is_table(), "OnEvent", nil)
      assert.spy(hideSpy).was.called()
    end)
  end)

  describe("BUII_CallToArms_TestMode", function()
    it("toggles test mode on and off", function()
      local original_print = print
      _G.print = function(t) end

      BUII_CallToArms_Enable()
      local frame = _G.BUII_CallToArmsFrame
      local showSpy = spy.on(frame, "Show")

      -- Turn on test mode
      BUII_CallToArms_TestMode()
      assert.spy(showSpy).was.called()

      -- Turn off test mode
      showSpy:clear()
      BUII_CallToArms_TestMode()
      -- Should not be shown twice if it updates to hide

      _G.print = original_print
    end)
  end)

  describe("CallToArms CheckStatus Logic", function()
    local frame
    local onEvent
    local originalEditModeIsShown
    before_each(function()
      BUII_CallToArms_Enable()
      frame = _G.BUII_CallToArmsFrame

      originalEditModeIsShown = _G.EditModeManagerFrame.IsShown
      _G.EditModeManagerFrame.IsShown = function()
        return false
      end

      _G.BUIIDatabase["call_to_arms"] = true
      _G.BUIIDatabase["call_to_arms_dungeon_normal"] = true
      _G.BUIIDatabase["call_to_arms_dungeon_heroic"] = true
      _G.BUIIDatabase["call_to_arms_dungeon_timewalking"] = true
      _G.BUIIDatabase["call_to_arms_lfr"] = true

      -- Extract the onEvent function
      local oldSetScript = frame.SetScript
      frame.SetScript = function(self, evt, handler)
        if evt == "OnEvent" then
          onEvent = handler
        end
        oldSetScript(self, evt, handler)
      end
      BUII_CallToArms_Enable()

      -- Reset mock to default "rewards available"
      _G.GetLFGRoleShortageRewards = function(dId, shortageIndex)
        return true, true, false, false, 1, 0, 0
      end
    end)

    after_each(function()
      _G.EditModeManagerFrame.IsShown = originalEditModeIsShown
    end)

    it("hides frame when all dungeon types are disabled", function()
      _G.BUIIDatabase["call_to_arms_dungeon_normal"] = false
      _G.BUIIDatabase["call_to_arms_dungeon_heroic"] = false
      _G.BUIIDatabase["call_to_arms_dungeon_timewalking"] = false
      _G.BUIIDatabase["call_to_arms_lfr"] = false
      local hideSpy = spy.on(frame, "Hide")

      onEvent(frame, "LFG_UPDATE_RANDOM_INFO")
      assert.spy(hideSpy).was.called()
    end)

    it("shows frame and plays sound when rewards are found", function()
      _G.BUIIDatabase.call_to_arms = true
      local showSpy = spy.on(frame, "Show")
      local playSoundSpy = spy.on(_G, "PlaySound")

      onEvent(frame, "LFG_UPDATE_RANDOM_INFO")

      assert.spy(showSpy).was.called()
      assert.spy(playSoundSpy).was.called()
    end)

    it("hides frame when no rewards are found", function()
      _G.BUIIDatabase.call_to_arms = true
      _G.GetLFGRoleShortageRewards = function(dId, shortageIndex)
        return false, false, false, false, 0, 0, 0
      end
      local hideSpy = spy.on(frame, "Hide")

      onEvent(frame, "LFG_UPDATE_RANDOM_INFO")

      assert.spy(hideSpy).was.called()
    end)
  end)
end)
