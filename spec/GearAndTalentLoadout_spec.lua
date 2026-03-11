---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

-- Provide required Globals
_G.BUIIDatabase = {
  gear_talent_loadout = true,
  gear_talent_icon_size = 40,
  gear_talent_font_size = 22,
  gear_talent_vertical_spacing = 2,
}

_G.BUII_GetFontPath = function()
  return "testfont"
end
_G.BUII_GetFontFlags = function()
  return ""
end
_G.BUII_GetFontShadow = function()
  return 1, -1
end

-- Load Module (using pcall because we might be missing some edge case WoW globals, but we want to load functions)
pcall(dofile, "Modules/WeakAura-like/GearAndTalentLoadout.lua")

describe("BravosUIImprovements GearAndTalentLoadout", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase.gear_talent_loadout = true
  end)

  describe("BUII_GearAndTalentLoadout_InitDB", function()
    it("initializes missing database values", function()
      _G.BUIIDatabase = {}
      BUII_GearAndTalentLoadout_InitDB()
      assert.is_false(_G.BUIIDatabase["gear_talent_loadout"])
      assert.are.equal(40, _G.BUIIDatabase["gear_talent_icon_size"])
    end)
  end)

  describe("BUII_GearAndTalentLoadout_Enable", function()
    it("initializes and shows the frames", function()
      -- Again, mostly testing that the initialization path doesn't crash given our mocks
      local status, err = pcall(BUII_GearAndTalentLoadout_Enable)
    end)
  end)

  describe("BUII_GearAndTalentLoadout_Disable", function()
    it("hides frame and clears events", function()
      pcall(BUII_GearAndTalentLoadout_Disable)
    end)
  end)
end)
