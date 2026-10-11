-- Moves the Queue Status Button (LFG eye) out of the Micro Menu so it can be placed on its own in Edit Mode.
--
-- Retail still parents QueueStatusButton to MicroMenuContainer, while WoW Forever made it its own
-- Edit Mode system ("Group Finder"). This module does nothing when the button is already an Edit Mode
-- system, so it steps aside automatically once retail gets the same change.
--
-- To remove this module:
--   - Delete Modules/DefaultUI/QueueStatusButton/ and spec/QueueStatusButton_spec.lua
--   - Remove its Include from BravosUIImprovements.xml
--   - Remove the BUII_QueueStatusButton_* calls in ImprovedEditMode.lua and BravosUIImprovements.lua
--   - Remove Enum.EditModeSystem.BUIIQueueStatusButton and its label from EditModeUtils.lua
--   - Remove the remaining QueueStatusButton references in spec/

local queueStatusButtonOverlay = nil
local queueStatusButtonHooksInstalled = false
local queueStatusButtonEnabled = false
local queueStatusButtonSyncInProgress = false
local pendingCombatUpdate = false
local enum_QueueStatusButtonSetting_Scale = 30

--- Checks if Blizzard already lets the button be moved on its own in Edit Mode
---@return boolean
local function hasNativeEditModeSupport()
  return QueueStatusButton ~= nil and QueueStatusButton.system ~= nil
end

--- Checks if a frame can't be changed right now (protected frame during combat)
---@param frame Frame|nil
---@return boolean
local function isLockedForCombat(frame)
  return frame ~= nil and InCombatLockdown() and frame:IsProtected()
end

local function syncButtonToOverlay()
  if
    not queueStatusButtonEnabled
    or queueStatusButtonSyncInProgress
    or not queueStatusButtonOverlay
    or not QueueStatusButton
  then
    return
  end
  queueStatusButtonSyncInProgress = true
  -- Direct atomic anchor to prevent spazzing/jitter during resizing or moving
  QueueStatusButton:ClearAllPoints()
  QueueStatusButton:SetPoint("CENTER", queueStatusButtonOverlay, "CENTER", 0, 0)
  queueStatusButtonSyncInProgress = false
end

--- Sizes MicroMenuContainer to only the Micro Menu.
--- Blizzard's Layout still includes QueueStatusButton after it's moved out of the container.
---@return nil
local function resizeMicroMenuContainer()
  if not queueStatusButtonEnabled or not MicroMenu or not MicroMenuContainer then
    return
  end
  if isLockedForCombat(MicroMenuContainer) then
    pendingCombatUpdate = true
    return
  end
  local mmWidth = MicroMenu:GetWidth() * MicroMenu:GetScale()
  local mmHeight = MicroMenu:GetHeight() * MicroMenu:GetScale()
  MicroMenuContainer:SetSize(math.max(mmWidth, 1), math.max(mmHeight, 1))
end

local function setupQueueStatusButton()
  if not QueueStatusButton or queueStatusButtonOverlay then
    return
  end

  local systemEnum = Enum.EditModeSystem.BUIIQueueStatusButton
  local systemName = BUII_HUD_EDIT_MODE_QUEUE_STATUS_BUTTON_LABEL or "Queue Status Button"
  local dbKey = "queue_status_button"

  -- Create dedicated overlay frame for Edit Mode
  queueStatusButtonOverlay = CreateFrame("Frame", nil, UIParent, "BUIIQueueStatusButtonEditModeSystemTemplate")
  queueStatusButtonOverlay:SetSize(32, 32) -- Force standard size
  queueStatusButtonOverlay:SetMovable(true)
  queueStatusButtonOverlay:SetClampedToScreen(true)
  queueStatusButtonOverlay:SetDontSavePosition(true)
  queueStatusButtonOverlay.defaultPoint = "CENTER"

  local settingsConfig = {}
  BUII_EditModeUtils:AddScaleSetting(
    settingsConfig,
    enum_QueueStatusButtonSetting_Scale,
    "Scale",
    "scale",
    function(f, val)
      if QueueStatusButton then
        QueueStatusButton:SetScale(val)
      end
      syncButtonToOverlay()
    end
  )

  BUII_EditModeUtils:RegisterSystem(queueStatusButtonOverlay, systemEnum, systemName, settingsConfig, dbKey, {
    OnApplySettings = syncButtonToOverlay,
    OnEditModeExit = function()
      queueStatusButtonOverlay:Hide()
      syncButtonToOverlay()
    end,
  })

  -- Ensure the actual button follows the overlay
  queueStatusButtonOverlay:HookScript("OnUpdate", function()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
      syncButtonToOverlay()
    end
  end)

  if not queueStatusButtonHooksInstalled then
    -- UpdatePosition is not available on every client. Hook the frame API
    -- instead; syncButtonToOverlay guards against its own SetPoint call.
    hooksecurefunc(QueueStatusButton, "SetPoint", syncButtonToOverlay)

    if MicroMenuContainer and type(MicroMenuContainer.Layout) == "function" then
      hooksecurefunc(MicroMenuContainer, "Layout", resizeMicroMenuContainer)
    end
    queueStatusButtonHooksInstalled = true
  end
end

--- Moves the button out of the Micro Menu and onto the Edit Mode overlay
---@return nil
local function detachQueueStatusButton()
  if not queueStatusButtonEnabled then
    return
  end
  if isLockedForCombat(QueueStatusButton) or isLockedForCombat(MicroMenuContainer) then
    pendingCombatUpdate = true
    return
  end

  if QueueStatusButton:GetParent() ~= UIParent then
    QueueStatusButton:SetParent(UIParent)
  end

  BUII_EditModeUtils:ApplySavedPosition(queueStatusButtonOverlay, "queue_status_button")
  syncButtonToOverlay()

  -- Force MicroMenuContainer to layout without us
  if MicroMenuContainer and MicroMenuContainer.Layout then
    MicroMenuContainer:Layout()
  end
end

--- Applies changes that were skipped during combat
---@return nil
local function onCombatLeave()
  if not pendingCombatUpdate then
    return
  end
  pendingCombatUpdate = false
  detachQueueStatusButton()
end

function BUII_QueueStatusButton_Enable()
  if hasNativeEditModeSupport() then
    return
  end

  queueStatusButtonEnabled = true
  setupQueueStatusButton()
  if queueStatusButtonOverlay then
    EventRegistry:RegisterFrameEventAndCallback(
      "PLAYER_REGEN_ENABLED",
      onCombatLeave,
      "BUII_QueueStatusButton_OnCombatLeave"
    )
    -- Delay unparenting to ensure it happens after Blizzard's initial layout
    RunNextFrame(detachQueueStatusButton)
  end
end

function BUII_QueueStatusButton_Disable()
  -- Nothing to undo if the button was never moved (e.g. Blizzard supports moving it natively)
  if not queueStatusButtonEnabled then
    return
  end

  queueStatusButtonEnabled = false
  pendingCombatUpdate = false
  EventRegistry:UnregisterFrameEventAndCallback("PLAYER_REGEN_ENABLED", "BUII_QueueStatusButton_OnCombatLeave")
  if queueStatusButtonOverlay then
    queueStatusButtonOverlay:Hide()
  end
  if QueueStatusButton and MicroMenuContainer then
    QueueStatusButton:SetParent(MicroMenuContainer)
    if type(MicroMenuContainer.Layout) == "function" then
      MicroMenuContainer:Layout()
    end
  end
end

local QSB_DB_DEFAULTS = {
  queue_status_button_layouts = {
    Default = {
      point = "CENTER",
      relativePoint = "CENTER",
      offsetX = 0,
      offsetY = 0,
      scale = 1.0,
    },
  },
}

function BUII_QueueStatusButton_InitDB()
  -- Migrate old settings to new layout-based system
  if BUIIDatabase["queue_status_button_position"] then
    if not BUIIDatabase["queue_status_button_layouts"] then
      local oldPos = BUIIDatabase["queue_status_button_position"]
      BUIIDatabase["queue_status_button_layouts"] = {
        Default = {
          point = oldPos.point or "BOTTOMRIGHT",
          relativePoint = oldPos.relativePoint or "BOTTOMRIGHT",
          offsetX = oldPos.xOffset or 0,
          offsetY = oldPos.yOffset or 0,
          scale = 1.0,
        },
      }
    end
    BUIIDatabase["queue_status_button_position"] = nil
  end

  MergeDefaults(BUIIDatabase, QSB_DB_DEFAULTS)
end
