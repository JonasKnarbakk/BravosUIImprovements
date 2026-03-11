---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}

pcall(dofile, "Modules/WeakAura-like/Ion.lua")

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
    it("registers PLAYER_DEAD event and sets OnEvent script", function()
      local registerSpy = spy.on(_G.BUII_IonFrame, "RegisterEvent")
      local setScriptSpy = spy.on(_G.BUII_IonFrame, "SetScript")

      BUII_Ion_Enable()

      assert.spy(registerSpy).was.called_with(match.is_table(), "PLAYER_DEAD")
      assert.spy(setScriptSpy).was.called_with(match.is_table(), "OnEvent", match.is_function())
    end)
  end)

  describe("BUII_Ion_Disable", function()
    it("unregisters PLAYER_DEAD event and clears OnEvent script", function()
      local unregisterSpy = spy.on(_G.BUII_IonFrame, "UnregisterEvent")
      local setScriptSpy = spy.on(_G.BUII_IonFrame, "SetScript")

      BUII_Ion_Disable()

      assert.spy(unregisterSpy).was.called_with(match.is_table(), "PLAYER_DEAD")
      assert.spy(setScriptSpy).was.called_with(match.is_table(), "OnEvent", nil)
    end)
  end)

  describe("Ion onEvent Handler", function()
    local onEvent
    before_each(function()
      local originalSetScript = _G.BUII_IonFrame.SetScript
      _G.BUII_IonFrame.SetScript = function(self, scriptName, handler)
        if scriptName == "OnEvent" then
          onEvent = handler
        end
      end
      BUII_Ion_Enable()
      _G.BUII_IonFrame.SetScript = originalSetScript
    end)

    it("plays sound file when PLAYER_DEAD and not in pvp/arena", function()
      local playSoundSpy = spy.on(_G, "PlaySoundFile")
      _G["IsInInstance"] = function()
        return false, "none"
      end

      onEvent(_G.BUII_IonFrame, "PLAYER_DEAD")

      assert.spy(playSoundSpy).was.called_with(match.is_string(), "Master")
      playSoundSpy:revert()
    end)

    it("does not play sound file when in pvp instance", function()
      local playSoundSpy = spy.on(_G, "PlaySoundFile")
      _G["IsInInstance"] = function()
        return true, "pvp"
      end

      onEvent(_G.BUII_IonFrame, "PLAYER_DEAD")

      assert.spy(playSoundSpy).was_not_called()
      playSoundSpy:revert()
    end)

    it("does not play sound file when in arena instance", function()
      local playSoundSpy = spy.on(_G, "PlaySoundFile")
      _G["IsInInstance"] = function()
        return true, "arena"
      end

      onEvent(_G.BUII_IonFrame, "PLAYER_DEAD")

      assert.spy(playSoundSpy).was_not_called()
      playSoundSpy:revert()
    end)

    it("ignores events other than PLAYER_DEAD", function()
      local playSoundSpy = spy.on(_G, "PlaySoundFile")
      _G["IsInInstance"] = function()
        return false, "none"
      end

      onEvent(_G.BUII_IonFrame, "PLAYER_ALIVE")

      assert.spy(playSoundSpy).was_not_called()
      playSoundSpy:revert()
    end)
  end)
end)
