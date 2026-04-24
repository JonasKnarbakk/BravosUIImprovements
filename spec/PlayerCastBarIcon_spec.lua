require("spec.setup")

-- Mock PlayerCastingBarFrame with an Icon child the apply function manipulates.
local function makeIcon()
  return {
    shown = false,
    width = 0,
    height = 0,
    point = { "TOPRIGHT", _G.UIParent, "TOPLEFT", 0, 0 },
    cleared = false,
    Show = function(self)
      self.shown = true
    end,
    Hide = function(self)
      self.shown = false
    end,
    SetSize = function(self, w, h)
      self.width = w
      self.height = h
    end,
    SetPoint = function(self, p, rt, rp, x, y)
      self.point = { p, rt, rp, x, y }
    end,
    GetPoint = function(self)
      local p = self.point
      return p[1], p[2], p[3], p[4], p[5]
    end,
    ClearAllPoints = function(self)
      self.cleared = true
    end,
    IsShown = function(self)
      return self.shown
    end,
  }
end

-- Set up frames the module references at parse / enable time.
_G.PlayerCastingBarFrame = _G.CreateFrame("Frame", "PlayerCastingBarFrame")
_G.PlayerCastingBarFrame.Icon = makeIcon()
-- Mock UpdateIconShown so applyPlayerCastBarIcon can hook + invoke it.
_G.PlayerCastingBarFrame.UpdateIconShown = function() end
-- Per-system dirty tracking spy.
local castBarSetHasActiveChangesCalls = {}
_G.PlayerCastingBarFrame.SetHasActiveChanges = function(_, value)
  table.insert(castBarSetHasActiveChangesCalls, value)
end
_G.PlayerCastingBarFrame.HasActiveChanges = function(self)
  local last = castBarSetHasActiveChangesCalls[#castBarSetHasActiveChangesCalls]
  return last == true
end
_G.QueueStatusButton = _G.CreateFrame("Frame", "QueueStatusButton")
_G.MainMenuBar = _G.CreateFrame("Frame", "MainMenuBar")
_G.BagsBar = _G.CreateFrame("Frame", "BagsBar")
_G.MicroMenu = _G.CreateFrame("Frame", "MicroMenu")
_G.MicroMenuContainer = _G.CreateFrame("Frame", "MicroMenuContainer")

-- Capture EditMode.Enter callback so the spec can fire it.
local editModeEnterCallback = nil
_G.EventRegistry.RegisterCallback = function(_, event, callback, _tag)
  if event == "EditMode.Enter" then
    editModeEnterCallback = callback
  end
end
_G.EventRegistry.UnregisterCallback = function() end
_G.EventRegistry.RegisterFrameEventAndCallback = function() end

-- Capture hooked SaveLayouts / RevertAllChanges / RevertSystemChanges on the
-- manager frame, plus UpdateIconShown installed on PlayerCastingBarFrame.
local saveHooks = {}
local revertHooks = {}
local revertSystemHooks = {}
local castBarUpdateIconShownHooks = {}
_G.hooksecurefunc = function(target, funcName, hookFunc)
  if target == _G.EditModeManagerFrame then
    if funcName == "SaveLayouts" then
      table.insert(saveHooks, hookFunc)
    elseif funcName == "RevertAllChanges" then
      table.insert(revertHooks, hookFunc)
    elseif funcName == "RevertSystemChanges" then
      table.insert(revertSystemHooks, hookFunc)
    end
  elseif target == _G.PlayerCastingBarFrame and funcName == "UpdateIconShown" then
    table.insert(castBarUpdateIconShownHooks, hookFunc)
  end
end

-- Spy state for SetHasActiveChanges.
local setHasActiveChangesCalls = {}
_G.EditModeManagerFrame.SetHasActiveChanges = function(_, value)
  table.insert(setHasActiveChangesCalls, value)
end
_G.EditModeManagerFrame.SaveLayouts = function() end
_G.EditModeManagerFrame.RevertAllChanges = function() end
_G.EditModeManagerFrame.RevertSystemChanges = function() end
_G.EditModeManagerFrame.SelectLayout = function() end
_G.EditModeManagerFrame.editModeActive = false

-- Spies for dialog UpdateButtons / UpdateSettings calls (drives the
-- per-system Revert button enabled state and widget refresh on revert).
local updateButtonsCalls = {}
local updateSettingsCalls = {}
_G.EditModeSystemSettingsDialog.UpdateButtons = function(_, systemFrame)
  table.insert(updateButtonsCalls, systemFrame)
end
_G.EditModeSystemSettingsDialog.UpdateSettings = function(_, systemFrame)
  table.insert(updateSettingsCalls, systemFrame)
end
_G.EditModeSystemSettingsDialog.IsShown = function(self)
  return self._shown == true
end
_G.EditModeSystemSettingsDialog.attachedToSystem = nil

-- Capture the dialog's UpdateSettings / OnSettingValueChanged hooks. The
-- module installs them via hooksecurefunc on editModeSettingsDialog inside
-- setupEditModeSystemSettingsDialog. We need them to drive the value-change
-- handler. Reroute hooksecurefunc to also catch dialog hooks.
local dialogUpdateSettingsHooks = {}
local dialogOnSettingValueChangedHooks = {}
local origHook = _G.hooksecurefunc
_G.hooksecurefunc = function(target, funcName, hookFunc)
  if target == _G.EditModeSystemSettingsDialog then
    if funcName == "UpdateSettings" then
      table.insert(dialogUpdateSettingsHooks, hookFunc)
    elseif funcName == "OnSettingValueChanged" then
      table.insert(dialogOnSettingValueChangedHooks, hookFunc)
    end
    return
  end
  origHook(target, funcName, hookFunc)
end

dofile("Modules/DefaultUI/ImprovedEditMode.lua")

-- Helper to drive a setting change as if the user clicked the checkbox.
local function fireSettingChanged(systemFrame, setting, value)
  local fakeDialog = {
    attachedToSystem = systemFrame,
  }
  for _, h in ipairs(dialogOnSettingValueChangedHooks) do
    h(fakeDialog, setting, value)
  end
end

-- Setting index hardcoded in module (kept in sync intentionally).
local SHOW_ICON_SETTING = 50

describe("ImprovedEditMode Player CastBar Icon", function()
  before_each(function()
    _G.BUIIDatabase = { castbar_icon = false, improved_edit_mode = true }
    _G.PlayerCastingBarFrame.Icon = makeIcon()
    setHasActiveChangesCalls = {}
    castBarSetHasActiveChangesCalls = {}
    updateButtonsCalls = {}
    updateSettingsCalls = {}
    _G.EditModeSystemSettingsDialog._shown = false
    _G.EditModeSystemSettingsDialog.attachedToSystem = nil
    -- Enable the module so hooks fire.
    BUII_ImprovedEditModeEnable()
  end)

  it("registers an EditMode.Enter callback", function()
    assert.is_function(editModeEnterCallback)
  end)

  it("hooks SaveLayouts and RevertAllChanges on the manager frame", function()
    assert.is_true(#saveHooks >= 1)
    assert.is_true(#revertHooks >= 1)
  end)

  describe("on toggle (preview)", function()
    it("shows icon, sets fixed anchor on first apply, dirties Edit Mode, doesn't commit DB", function()
      _G.BUIIDatabase["castbar_icon"] = false
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)

      assert.is_true(_G.PlayerCastingBarFrame.Icon.shown)
      assert.are.equal(24, _G.PlayerCastingBarFrame.Icon.width)
      -- Anchor pinned RIGHT-of-bar / LEFT-of-icon with the documented offsets.
      local p = _G.PlayerCastingBarFrame.Icon.point
      assert.are.equal("RIGHT", p[1])
      assert.are.equal(_G.PlayerCastingBarFrame, p[2])
      assert.are.equal("LEFT", p[3])
      assert.are.equal(-2, p[4])
      assert.are.equal(-6, p[5])
      assert.is_true(_G.PlayerCastingBarFrame.Icon.cleared)

      -- DB unchanged until save
      assert.is_false(_G.BUIIDatabase["castbar_icon"])
      -- SetHasActiveChanges(true) called at least once.
      local sawTrue = false
      for _, v in ipairs(setHasActiveChangesCalls) do
        if v == true then
          sawTrue = true
          break
        end
      end
      assert.is_true(sawTrue)
    end)

    it("installs a UpdateIconShown hook that re-asserts visibility", function()
      assert.is_true(#castBarUpdateIconShownHooks >= 1)

      -- Simulate Blizzard hiding the icon via UpdateIconShown after we toggled on.
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)
      _G.PlayerCastingBarFrame.Icon:Hide()
      for _, h in ipairs(castBarUpdateIconShownHooks) do
        h(_G.PlayerCastingBarFrame)
      end
      assert.is_true(_G.PlayerCastingBarFrame.Icon.shown)

      -- And the inverse: when toggled off, the hook must keep it hidden.
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 0)
      _G.PlayerCastingBarFrame.Icon:Show()
      for _, h in ipairs(castBarUpdateIconShownHooks) do
        h(_G.PlayerCastingBarFrame)
      end
      assert.is_false(_G.PlayerCastingBarFrame.Icon.shown)
    end)

    it("marks the systemFrame dirty and refreshes the per-system Revert button", function()
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)

      -- systemFrame:SetHasActiveChanges(true) called -- this is what
      -- enables the per-system Revert button (Blizzard reads
      -- self.attachedToSystem:HasActiveChanges()).
      local sawTrue = false
      for _, v in ipairs(castBarSetHasActiveChangesCalls) do
        if v == true then
          sawTrue = true
          break
        end
      end
      assert.is_true(sawTrue)

      -- Dialog:UpdateButtons(systemFrame) called so the gray Revert button
      -- re-evaluates its enabled state immediately.
      local sawSystem = false
      for _, sf in ipairs(updateButtonsCalls) do
        if sf == _G.PlayerCastingBarFrame then
          sawSystem = true
          break
        end
      end
      assert.is_true(sawSystem)
    end)
  end)

  describe("on save", function()
    it("commits the pending value to BUIIDatabase", function()
      _G.BUIIDatabase["castbar_icon"] = false
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)
      assert.is_false(_G.BUIIDatabase["castbar_icon"])

      for _, h in ipairs(saveHooks) do
        h()
      end

      assert.is_true(_G.BUIIDatabase["castbar_icon"])
    end)
  end)

  describe("on revert", function()
    it("discards pending value and restores icon from saved DB value", function()
      _G.BUIIDatabase["castbar_icon"] = false
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)
      assert.is_true(_G.PlayerCastingBarFrame.Icon.shown)

      for _, h in ipairs(revertHooks) do
        h()
      end

      -- DB never changed; icon should reflect the saved (false) value now.
      assert.is_false(_G.BUIIDatabase["castbar_icon"])
      assert.is_false(_G.PlayerCastingBarFrame.Icon.shown)
    end)

    it("refreshes injected dialog widgets when dialog is still attached", function()
      _G.BUIIDatabase["castbar_icon"] = false
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)

      -- Pretend the dialog is still showing the cast bar (some flows leave
      -- it visible after RevertAllChanges instead of going through ClearSelectedSystem).
      _G.EditModeSystemSettingsDialog._shown = true
      _G.EditModeSystemSettingsDialog.attachedToSystem = _G.PlayerCastingBarFrame
      updateSettingsCalls = {}

      for _, h in ipairs(revertHooks) do
        h()
      end

      local sawRefresh = false
      for _, sf in ipairs(updateSettingsCalls) do
        if sf == _G.PlayerCastingBarFrame then
          sawRefresh = true
          break
        end
      end
      assert.is_true(sawRefresh)
    end)

    it("does not refresh dialog when it is hidden", function()
      _G.BUIIDatabase["castbar_icon"] = false
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)

      _G.EditModeSystemSettingsDialog._shown = false
      _G.EditModeSystemSettingsDialog.attachedToSystem = _G.PlayerCastingBarFrame
      updateSettingsCalls = {}

      for _, h in ipairs(revertHooks) do
        h()
      end

      assert.are.equal(0, #updateSettingsCalls)
    end)
  end)

  describe("on EditMode.Enter", function()
    it("re-applies the saved state to the icon", function()
      _G.BUIIDatabase["castbar_icon"] = true
      _G.PlayerCastingBarFrame.Icon.shown = false
      assert.is_function(editModeEnterCallback)
      editModeEnterCallback()
      assert.is_true(_G.PlayerCastingBarFrame.Icon.shown)
    end)
  end)

  describe("on per-system revert (RevertSystemChanges)", function()
    it("hooks RevertSystemChanges on the manager frame", function()
      assert.is_true(#revertSystemHooks >= 1)
    end)

    it("discards pending castbar icon value when its system is reverted", function()
      _G.BUIIDatabase["castbar_icon"] = false
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)
      assert.is_true(_G.PlayerCastingBarFrame.Icon.shown)

      for _, h in ipairs(revertSystemHooks) do
        h(_G.EditModeManagerFrame, _G.PlayerCastingBarFrame)
      end

      -- Pending was discarded; icon reflects the saved (false) DB value.
      assert.is_false(_G.PlayerCastingBarFrame.Icon.shown)
      assert.is_false(_G.BUIIDatabase["castbar_icon"])
    end)

    it("ignores reverts for unrelated systems", function()
      _G.BUIIDatabase["castbar_icon"] = false
      fireSettingChanged(_G.PlayerCastingBarFrame, SHOW_ICON_SETTING, 1)

      local otherFrame = _G.CreateFrame("Frame", "MainMenuBar")
      for _, h in ipairs(revertSystemHooks) do
        h(_G.EditModeManagerFrame, otherFrame)
      end

      -- Castbar pending value untouched, icon still shown.
      assert.is_true(_G.PlayerCastingBarFrame.Icon.shown)
    end)
  end)

  describe("BUII_ImprovedEditMode_InitDB", function()
    it("sets castbar_icon default to false", function()
      _G.BUIIDatabase = {}
      BUII_ImprovedEditMode_InitDB()
      assert.are.equal(false, _G.BUIIDatabase["castbar_icon"])
    end)

    it("preserves existing castbar_icon value", function()
      _G.BUIIDatabase = { castbar_icon = true }
      BUII_ImprovedEditMode_InitDB()
      assert.is_true(_G.BUIIDatabase["castbar_icon"])
    end)
  end)
end)
