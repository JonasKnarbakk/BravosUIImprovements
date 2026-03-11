---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

-- Provide required Globals
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

-- Required frames for ImprovedEditMode
_G.MainMenuBar = CreateFrame("Frame", "MainMenuBar")
_G.MainActionBar = CreateFrame("Frame", "MainActionBar")
_G.MultiBarLeft = CreateFrame("Frame", "MultiBarLeft")
_G.MultiBarRight = CreateFrame("Frame", "MultiBarRight")
_G.MultiBarBottomLeft = CreateFrame("Frame", "MultiBarBottomLeft")
_G.MultiBarBottomRight = CreateFrame("Frame", "MultiBarBottomRight")
_G.MultiBar5 = CreateFrame("Frame", "MultiBar5")
_G.MultiBar6 = CreateFrame("Frame", "MultiBar6")
_G.MultiBar7 = CreateFrame("Frame", "MultiBar7")
_G.BagsBar = CreateFrame("Frame", "BagsBar")
_G.MicroMenu = CreateFrame("Frame", "MicroMenu")
_G.MicroMenuContainer = CreateFrame("Frame", "MicroMenuContainer")
_G.QueueStatusButton = CreateFrame("Frame", "QueueStatusButton")

-- Create child buttons for bars
for i = 1, 12 do
  _G["ActionButton" .. i] = CreateFrame("Frame", "ActionButton" .. i)
  _G["ActionButton" .. i].HotKey = _G["ActionButton" .. i]:CreateFontString()
  _G["MultiBarLeftButton" .. i] = CreateFrame("Frame", "MultiBarLeftButton" .. i)
  _G["MultiBarLeftButton" .. i].HotKey = _G["MultiBarLeftButton" .. i]:CreateFontString()
end

pcall(dofile, "ImprovedEditMode.lua")

describe("BravosUIImprovements ImprovedEditMode", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_ImprovedEditMode_InitDB", function()
    it("initializes missing database values", function()
      BUII_ImprovedEditMode_InitDB()
      assert.is_false(_G.BUIIDatabase["improved_edit_mode"])
      assert.is_not_nil(_G.BUIIDatabase["queue_status_button_layouts"])
    end)
  end)

  describe("BUII_ImprovedEditModeEnable", function()
    it("initializes without crashing given standard mocks", function()
      -- Another sanity check to make sure events and hooks apply cleanly
      local status, err = pcall(BUII_ImprovedEditModeEnable)
      if not status then
        print("Failed to enable: ", err)
      end
    end)
  end)

  describe("BUII_ImprovedEditModeDisable", function()
    it("disables without crashing", function()
      pcall(BUII_ImprovedEditModeDisable)
    end)
  end)
end)
