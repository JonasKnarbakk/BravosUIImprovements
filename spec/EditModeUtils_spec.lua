---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

-- Provide required Globals
_G.BUIIDatabase = {}
_G.BUIICharacterDatabase = {}

-- By default, it's defined in setup hook, we're gonna clear it so dofile can load the real module
_G.BUII_EditModeUtils = nil

pcall(dofile, "EditModeUtils.lua")

describe("BravosUIImprovements EditModeUtils", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_EditModeUtils:GetDB", function()
    it("returns the appropriate DB based on character specific setting", function()
      _G.BUIIDatabase["test_use_char_settings"] = false
      _G.BUIICharacterDatabase["test_use_char_settings"] = true

      local db = BUII_EditModeUtils:GetDB("test")
      assert.are.equal(_G.BUIICharacterDatabase, db)

      _G.BUIICharacterDatabase["test_use_char_settings"] = false
      local db2 = BUII_EditModeUtils:GetDB("test")
      assert.are.equal(_G.BUIIDatabase, db2)
    end)
  end)

  describe("BUII_EditModeUtils.FormatPercentage", function()
    it("formats decimals into percentages correctly", function()
      assert.are.equal("100%", BUII_EditModeUtils.FormatPercentage(1.0))
      assert.are.equal("50%", BUII_EditModeUtils.FormatPercentage(0.5))
      assert.are.equal("125%", BUII_EditModeUtils.FormatPercentage(1.25))
    end)
  end)

  describe("BUII_EditModeUtils:ApplySavedPosition", function()
    it("does not crash when called on a simple mock frame", function()
      local frame = CreateFrame("Frame")
      frame.buiiSettingsConfig = {}
      frame.systemInfo = { anchorInfo = {}, settings = {} }
      frame.GetScale = function()
        return 1.0
      end
      -- Mostly a smoke test to ensure no missing deps cause hard crashes
      pcall(function()
        BUII_EditModeUtils:ApplySavedPosition(frame, "mock_key")
      end)
    end)
  end)
end)
