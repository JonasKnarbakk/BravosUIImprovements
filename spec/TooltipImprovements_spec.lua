---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.GameTooltip = { GetItem = function() end, AddLine = function() end }
_G.ItemRefTooltip = { GetItem = function() end, AddLine = function() end }
_G.TooltipDataProcessor = { AddTooltipPostCall = function() end }
_G.C_Item = { GetItemInfo = function() end }

dofile("Modules/DefaultUI/TooltipImprovements.lua")

describe("BravosUIImprovements TooltipImprovements", function()
  before_each(function()
    _G.BUIIDatabase = {}
    _G.GameTooltip.AddLine = function() end
    _G.ItemRefTooltip.AddLine = function() end
    _G.EXPANSION_NAME0 = "Classic"
    _G.EXPANSION_NAME1 = "The Burning Crusade"
    _G.EXPANSION_NAME8 = "Shadowlands"
    _G.EXPANSION_NAME9 = "Dragonflight"
    _G.EXPANSION_NAME10 = "The War Within"
    _G.EXPANSION_NAME11 = "Midnight"
    _G.EXPANSION_NAME12 = nil
    _G.EJ_GetTierInfo = function()
      error("Encounter Journal tier data is unavailable")
    end
  end)

  local postCallback

  describe("BUII_TooltipImprovements_Enabled", function()
    it("adds a tooltip post call just once", function()
      local addSpy = spy.on(_G.TooltipDataProcessor, "AddTooltipPostCall")
      BUII_TooltipImprovements_Enabled()
      assert.spy(addSpy).was.called_with(Enum.TooltipDataType.Item, match.is_function())

      -- Extract for later tests
      postCallback = addSpy.calls[1].refs[2]

      -- Call again, should not add again
      BUII_TooltipImprovements_Enabled()
      assert.spy(addSpy).was.called(1)
    end)
  end)

  describe("Tooltip callback logic", function()
    it("does nothing if disabled", function()
      BUII_TooltipImprovements_Disable()
      local addLineSpy = spy.on(_G.GameTooltip, "AddLine")
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was_not_called()
    end)

    it("adds colored text for standard expansions", function()
      -- Must be re-enabled
      BUII_TooltipImprovements_Enabled()

      local addLineSpy = spy.on(_G.GameTooltip, "AddLine")

      -- Mock GameTooltip:GetItem to return dummy item data
      _G.GameTooltip.GetItem = function()
        return "name", "link", 123456
      end

      -- Mock C_Item.GetItemInfo to return expansionID 8 (Shadowlands internally)
      _G.C_Item.GetItemInfo = function(item)
        return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 8
      end

      postCallback(_G.GameTooltip, {})

      assert.spy(addLineSpy).was.called_with(match.is_table(), "Shadowlands", 0.6, 0.8, 1)
    end)

    it("uses overrides for specific items", function()
      BUII_TooltipImprovements_Enabled()
      local addLineSpy = spy.on(_G.GameTooltip, "AddLine")

      -- Item 38682 is Enchanting Vellum (Wrath)
      _G.GameTooltip.GetItem = function()
        return "name", "link", 38682
      end
      _G.C_Item.GetItemInfo = function(item)
        return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 1
      end

      postCallback(_G.GameTooltip, {})

      -- Check override worked instead of using the reported expansion
      assert.spy(addLineSpy).was.called_with(match.is_table(), "Wrath of the Lich King", 0, 0.8, 1)
    end)

    it("shows Classic for Bruiseweed without Encounter Journal tier data", function()
      BUII_TooltipImprovements_Enabled()
      local addLineSpy = spy.on(_G.GameTooltip, "AddLine")
      _G.GameTooltip.GetItem = function()
        return "Bruiseweed", "link", 2453
      end
      _G.C_Item.GetItemInfo = function()
        return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0
      end
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was.called_with(_G.GameTooltip, "Classic", 1, 1, 1)
    end)

    it("uses the item's expansion through Midnight regardless of the current season", function()
      BUII_TooltipImprovements_Enabled()
      local addLineSpy = spy.on(_G.GameTooltip, "AddLine")
      _G.GameTooltip.GetItem = function()
        return "name", "link", 999999
      end
      _G.GetServerExpansionLevel = function()
        return 11
      end
      local expansionID = 9
      _G.C_Item.GetItemInfo = function()
        return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, expansionID
      end
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was.called_with(match.is_table(), "Dragonflight", 0, 1, 0.6)

      expansionID = 10
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was.called_with(match.is_table(), "The War Within", 1, 0.4, 0)

      expansionID = 11
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was.called_with(match.is_table(), "Midnight", 0.45, 0.2, 0.9)
    end)

    it("uses localized expansion names and colors on linked item tooltips", function()
      BUII_TooltipImprovements_Enabled()
      local addLineSpy = spy.on(_G.ItemRefTooltip, "AddLine")
      _G.ItemRefTooltip.GetItem = function()
        return "name", "link", 999999
      end
      _G.C_Item.GetItemInfo = function()
        return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 1
      end
      postCallback(_G.ItemRefTooltip, {})
      assert.spy(addLineSpy).was.called_with(_G.ItemRefTooltip, "The Burning Crusade", 0, 1, 0)

      _G.EXPANSION_NAME1 = "La Croisade ardente"
      postCallback(_G.ItemRefTooltip, {})
      assert.spy(addLineSpy).was.called_with(_G.ItemRefTooltip, "La Croisade ardente", 0, 1, 0)
    end)

    it("skips unavailable item data and missing expansion names", function()
      BUII_TooltipImprovements_Enabled()
      local addLineSpy = spy.on(_G.GameTooltip, "AddLine")
      _G.GameTooltip.GetItem = function()
        return "name", "link", 999999
      end
      _G.C_Item.GetItemInfo = function() end
      postCallback(_G.GameTooltip, {})

      _G.C_Item.GetItemInfo = function()
        return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 12
      end
      postCallback(_G.GameTooltip, {})
      _G.EXPANSION_NAME12 = ""
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was_not_called()
    end)

    it("shows a future expansion with a neutral color", function()
      BUII_TooltipImprovements_Enabled()
      local addLineSpy = spy.on(_G.GameTooltip, "AddLine")
      _G.GameTooltip.GetItem = function()
        return "name", "link", 999999
      end
      _G.C_Item.GetItemInfo = function()
        return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 12
      end
      _G.EXPANSION_NAME12 = "Expansion 12"
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was.called_with(_G.GameTooltip, "Expansion 12", 1, 1, 1)
    end)
  end)
  describe("BUII_TooltipImprovements_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      BUII_TooltipImprovements_InitDB()

      assert.are.equal(false, BUIIDatabase["tooltip_expansion"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["tooltip_expansion"] = true }
      BUII_TooltipImprovements_InitDB()

      assert.are.equal(true, BUIIDatabase["tooltip_expansion"])
    end)
  end)
end)
