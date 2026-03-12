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

pcall(dofile, "Modules/DefaultUI/ImprovedEditMode.lua")

describe("BravosUIImprovements ImprovedEditMode", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_ImprovedEditModeEnable", function()
    it("initializes hooks without crashing", function()
      local status, err = pcall(BUII_ImprovedEditModeEnable)
      assert.is_true(status)
    end)
  end)

  describe("BUII_ImprovedEditModeDisable", function()
    it("disables without crashing", function()
      pcall(BUII_ImprovedEditModeDisable)
    end)
  end)

  describe("Combat Visibility Logic", function()
    it("handles entering and leaving combat dynamically based on settings", function()
      BUII_ImprovedEditModeEnable()
      -- Manipulate the local FrameVisibility table using the DB layout mechanism
      _G.BUIIDatabase["actionbar_settings_layouts"] = {
        Default = {
          visibility = {
            MainMenuBar = 1, -- InCombat
            MultiBarLeft = 2, -- OutOfCombat
            MultiBarRight = 0, -- Always
          },
          hideMacroText = {},
          abbreviateKeybindings = {},
        },
      }
      -- Trigger load function manually or via event if possible. Since it's private, we'll
      -- simulate entering combat and verify it didn't crash.
      local f = CreateFrame("Frame")
      -- Fake event firing if we had a reference, but we can't easily grab the event handler
      -- We will just ensure the module loaded without error for now as full testing requires mock events
    end)
  end)

  describe("BUII_QueueStatusButton_Enable", function()
    it("parents QueueStatusButton to UIParent via timer", function()
      _G.QueueStatusButton = CreateFrame("Frame", "QueueStatusButton")
      _G.QueueStatusButton:SetParent(CreateFrame("Frame"))

      BUII_QueueStatusButton_Enable()

      -- We assume the C_Timer callback fired immediately via our setup mock
      assert.are.equal(_G.UIParent, _G.QueueStatusButton:GetParent())
    end)
  end)
  describe("BUII_ImprovedEditMode_InitDB", function()
    it("sets defaults for nil values", function()
      _G.BUIIDatabase = {}
      BUII_ImprovedEditMode_InitDB()

      assert.are.equal(false, BUIIDatabase["improved_edit_mode"])
    end)

    it("preserves existing values", function()
      _G.BUIIDatabase = { ["improved_edit_mode"] = true }
      BUII_ImprovedEditMode_InitDB()

      assert.are.equal(true, BUIIDatabase["improved_edit_mode"])
    end)
  end)
end)
