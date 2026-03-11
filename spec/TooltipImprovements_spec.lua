---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.GameTooltip = { GetItem = function() end, AddLine = function() end }
_G.ItemRefTooltip = { GetItem = function() end, AddLine = function() end }
_G.TooltipDataProcessor = { AddTooltipPostCall = function() end }
_G.C_Item = { GetItemInfo = function() end }

pcall(dofile, "Modules/DefaultUI/TooltipImprovements.lua")

describe("BravosUIImprovements TooltipImprovements", function()
  before_each(function()
    _G.BUIIDatabase = {}
  end)

  describe("BUII_TooltipImprovements_InitDB", function()
    it("initializes missing database values", function()
      BUII_TooltipImprovements_InitDB()
      assert.is_false(_G.BUIIDatabase["tooltip_expansion"])
    end)
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

      -- Mock EJ_GetTierInfo to return expansion Name
      _G.EJ_GetTierInfo = function(tierIndex)
        if tierIndex == 9 then
          return "Shadowlands"
        end
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

      -- Check override worked instead of relying on tier info
      assert.spy(addLineSpy).was.called_with(match.is_table(), "Wrath of the Lich King", 0, 0.8, 1)
    end)

    it("handles Current Season by falling back to Dragonflight/TWW", function()
      BUII_TooltipImprovements_Enabled()
      local addLineSpy = spy.on(_G.GameTooltip, "AddLine")
      _G.GameTooltip.GetItem = function()
        return "name", "link", 999999
      end
      _G.C_Item.GetItemInfo = function(item)
        return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 1
      end

      _G.EJ_GetTierInfo = function()
        return "Current Season"
      end

      _G.GetServerExpansionLevel = function()
        return 9
      end
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was.called_with(match.is_table(), "Dragonflight", 0, 1, 0.6)

      _G.GetServerExpansionLevel = function()
        return 10
      end
      postCallback(_G.GameTooltip, {})
      assert.spy(addLineSpy).was.called_with(match.is_table(), "The War Within", 1, 0.4, 0)
    end)
  end)
end)
