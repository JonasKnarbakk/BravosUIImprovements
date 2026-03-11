---@diagnostic disable: undefined-global, undefined-field

require("spec.setup")

-- Assuming Utils.lua defines its functions globally in the WoW fashion,
-- we'll just load the file and test the globals.
dofile("Utils.lua")

describe("BravosUIImprovements Utils", function()
  describe("BUII_FormatNumber", function()
    it("returns '0' if no number is provided", function()
      assert.are.equal("0", BUII_FormatNumber(nil))
    end)

    it("returns '???' if the value is a secret value", function()
      -- Mock issecretvalue to return true inside the test
      local original_issecret = _G.issecretvalue
      _G.issecretvalue = function()
        return true
      end

      assert.are.equal("???", BUII_FormatNumber(100))

      -- Restore original mock
      _G.issecretvalue = original_issecret
    end)

    it("formats numbers greater than or equal to 1,000,000 as M", function()
      assert.are.equal("1.0M", BUII_FormatNumber(1000000))
      assert.are.equal("1.5M", BUII_FormatNumber(1500000))
      assert.are.equal("1.2M", BUII_FormatNumber(1234567))
    end)

    it("formats numbers greater than or equal to 1,000 as K", function()
      assert.are.equal("1.0K", BUII_FormatNumber(1000))
      assert.are.equal("1.5K", BUII_FormatNumber(1500))
      assert.are.equal("12.3K", BUII_FormatNumber(12345))
    end)

    it("returns the floored number for values less than 1,000", function()
      assert.are.equal("999", BUII_FormatNumber(999))
      assert.are.equal("500", BUII_FormatNumber(500.5))
      assert.are.equal("1", BUII_FormatNumber(1))
      assert.are.equal("0", BUII_FormatNumber(0))
    end)
  end)

  describe("BUII_GetFontShadow", function()
    it("returns defaults when BUIIDatabase is nil", function()
      _G.BUIIDatabase = nil
      local x, y = BUII_GetFontShadow()
      assert.are.equal(1, x)
      assert.are.equal(-1, y)
    end)

    it("returns 0, 0 when font_shadow is false", function()
      _G.BUIIDatabase = { font_shadow = false }
      local x, y = BUII_GetFontShadow()
      assert.are.equal(0, x)
      assert.are.equal(0, y)
      _G.BUIIDatabase = nil
    end)

    it("returns 1, -1 when font_shadow is true", function()
      _G.BUIIDatabase = { font_shadow = true }
      local x, y = BUII_GetFontShadow()
      assert.are.equal(1, x)
      assert.are.equal(-1, y)
      _G.BUIIDatabase = nil
    end)
  end)
end)
