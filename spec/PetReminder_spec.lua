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

pcall(dofile, "Modules/WeakAura-like/PetReminder.lua")

describe("BravosUIImprovements PetReminder", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_PetReminder_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_PetReminder_Enable()
    end)
  end)

  describe("BUII_PetReminder_Disable", function()
    it("disables without crashing", function()
      BUII_PetReminder_Disable()
    end)
  end)

  describe("BUII_PetReminder_Refresh", function()
    it("refreshes without crashing", function()
      BUII_PetReminder_Refresh()
    end)
  end)
  describe("BUII_PetReminder_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      BUII_PetReminder_InitDB()

      assert.are.equal(false, BUIIDatabase["pet_reminder"])
      assert.are.equal(20, BUIIDatabase["pet_reminder_intensity"])
      assert.are.equal(false, BUIIDatabase["pet_reminder_audio"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["pet_reminder"] = true }
      BUII_PetReminder_InitDB()

      assert.are.equal(true, BUIIDatabase["pet_reminder"])
    end)
  end)
end)
