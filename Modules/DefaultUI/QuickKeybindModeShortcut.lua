---@type boolean
local enabled = false
---@type boolean
local gameMenuFrameHook_OnShow = false
---@type boolean
local wasKeybindModeTrigger = false
---@type Button|any|nil
local quickKeybindModeShortcutFrame = nil

--- Check if an object is a function
---@param object any
---@return boolean
local function isFunction(object)
  if type(object) == "function" then
    return true
  end

  return false
end

--- Handles the click event for the Quick Keybind Mode shortcut
---@return nil
local function quickKeybindModeShortcutFrame_OnClick()
  QuickKeybindFrame:Show()
  GameMenuFrame:Hide()
  wasKeybindModeTrigger = true
end

--- Adds the Quick Keybind Mode button to the Game Menu
---@return nil
local function quickKeybinddModeAddButton()
  if enabled and not InCombatLockdown() then
    if isFunction(GameMenuFrame.AddSection) and isFunction(GameMenuFrame.AddButton) then
      GameMenuFrame:AddSection()
      GameMenuFrame:AddButton("Quick Keybind Mode", quickKeybindModeShortcutFrame_OnClick, false, "testdisabled")
    else
      -- Legacy way, will not be needed after The War Within releases (likely pre-patch)
      if not quickKeybindModeShortcutFrame then
        quickKeybindModeShortcutFrame =
          CreateFrame("Button", "BUII_QuickKeybindModeShortcutButton", GameMenuFrame, "GameMenuButtonTemplate") --[[@as Button]]
        quickKeybindModeShortcutFrame:SetText("Quick Keybind Mode")
        quickKeybindModeShortcutFrame:SetScript("OnClick", quickKeybindModeShortcutFrame_OnClick)
        quickKeybindModeShortcutFrame:SetPoint(
          "TOP",
          GameMenuButtonContinue,
          "BOTTOM",
          0,
          -(quickKeybindModeShortcutFrame:GetHeight() / 1.5)
        )
      end

      -- Try and match the look we will have when using AddSection and AddButton
      GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + quickKeybindModeShortcutFrame:GetHeight() * 1.5)
      if not quickKeybindModeShortcutFrame:IsVisible() then
        quickKeybindModeShortcutFrame:Show()
      end
    end
  end
end

--- Handles the disable event for Quick Keybind Mode
---@return nil
local function quickKeybindMode_OnDisable()
  if wasKeybindModeTrigger then
    -- Have to show the GameMenuFrame again otherwise SettingsPanel is shown
    GameMenuFrame:Show()
    wasKeybindModeTrigger = false
  end
end

--- Enables the Quick Keybind Mode Shortcut feature
---@return nil
function BUII_QuickKeybindModeShortcutEnable()
  enabled = true

  if not gameMenuFrameHook_OnShow then
    gameMenuFrameHook_OnShow = true
    GameMenuFrame:HookScript("OnShow", quickKeybinddModeAddButton)
    EventRegistry:RegisterCallback(
      "QuickKeybindFrame.QuickKeybindModeDisabled",
      quickKeybindMode_OnDisable,
      "BUII_QuickKeybindMode_OnDisable"
    )
  end
end

--- Disables the Quick Keybind Mode Shortcut feature
---@return nil
function BUII_QuickKeybindModeShortcutDisable()
  enabled = false
end

local DB_DEFAULTS = {
  quick_keybind_shortcut = false,
}

function BUII_QuickKeybindModeShortcut_InitDB()
  MergeDefaults(BUIIDatabase, DB_DEFAULTS)
end
