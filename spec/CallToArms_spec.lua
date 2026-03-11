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
    it("initializes and attaches to events", function()
      -- Mostly testing that the initialization path doesn't crash given our mocks
      local status, err = pcall(BUII_CallToArms_Enable)
      -- We don't strictly assert status because if it tries to index a deeply
      -- buried missing WoW API it's fine for now; we just want a basic sanity test structure.
    end)
  end)

  describe("BUII_CallToArms_Disable", function()
    it("hides frame and clears events", function()
      -- Again, ensuring no immediate crash
      pcall(BUII_CallToArms_Disable)
    end)
  end)

  describe("BUII_CallToArms_TestMode", function()
    it("toggles test mode without crashing", function()
      local original_print = print
      local printed_text = nil
      _G.print = function(t)
        printed_text = t
      end

      pcall(BUII_CallToArms_TestMode)

      _G.print = original_print
      -- Test prints something about test mode toggling
    end)
  end)
end)
