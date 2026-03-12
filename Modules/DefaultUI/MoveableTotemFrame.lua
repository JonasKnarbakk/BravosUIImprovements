local addonName, addon = ...
---@type boolean
local moveableTotemFrameEnabled = false
---@type Frame|any
local originalParent = nil
---@type Frame|any
local enum_TotemFrameSetting_GrowthDirection = 8

---@class BUII_TotemFrameEditModeTemplate : BUII_ManagedFrame
---@type BUII_TotemFrameEditModeTemplate|nil
local buiiTotemFrame = nil
---@type Frame|BUII_TotemFrameEditModeTemplate|nil
local totemFrameOverlay = nil

local enum_MoveableTotemFrameSetting_Scale = 1

--- Synchronizes the actual TotemFrame position to follow our custom overlay
---@return nil
local function syncTotemFrameToOverlay()
  if not totemFrameOverlay or not TotemFrame then
    return
  end
  -- Direct atomic anchor to prevent spazzing/jitter during resizing or moving
  TotemFrame:ClearAllPoints()
  TotemFrame:SetPoint("CENTER", totemFrameOverlay, "CENTER", 0, 0)
end

--- Sets up the overlay used for Edit Mode positioning of the Totem Frame
---@return nil
local function setupTotemFrameOverlay()
  if totemFrameOverlay then
    return
  end

  totemFrameOverlay = CreateFrame("Frame", nil, UIParent, "BUII_TotemFrameEditModeTemplate")
  totemFrameOverlay:SetSize(120, 40)
  totemFrameOverlay:SetMovable(true)
  totemFrameOverlay:SetClampedToScreen(true)
  totemFrameOverlay:SetDontSavePosition(true)

  local settingsConfig = {}
  BUII_EditModeUtils:AddScaleSetting(settingsConfig, enum_MoveableTotemFrameSetting_Scale, "scale", function(f, val)
    if TotemFrame then
      TotemFrame:SetScale(val)
    end
  end)

  BUII_EditModeUtils:RegisterSystem(
    totemFrameOverlay,
    Enum.EditModeSystem.BUII_TotemFrame,
    "Totem Frame",
    settingsConfig,
    "moveable_totem_frame",
    {
      OnApplySettings = function()
        syncTotemFrameToOverlay()
      end,
      OnEditModeEnter = function()
        totemFrameOverlay:Show()
        syncTotemFrameToOverlay()
      end,
      OnEditModeExit = function()
        totemFrameOverlay:Hide()
        syncTotemFrameToOverlay()
      end,
    }
  )

  -- Ensure the actual button follows the overlay
  totemFrameOverlay:HookScript("OnUpdate", function()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
      syncTotemFrameToOverlay()
    end
  end)
end

--- Enables the Moveable Totem Frame feature, unhooking it from the default UI managed frame system
---@return nil
function BUII_MoveableTotemFrame_Enable()
  if not TotemFrame then
    return
  end
  moveableTotemFrameEnabled = true

  if not originalParent then
    originalParent = TotemFrame:GetParent()
  end

  -- Detach from managed container logic
  -- We replace the layoutParent with a dummy object so OnShow/OnHide calls don't crash
  if TotemFrame.layoutParent then
    TotemFrame.originalLayoutParent = TotemFrame.layoutParent

    -- Try to remove from the real manager first
    if TotemFrame.layoutParent.RemoveManagedFrame then
      TotemFrame.layoutParent:RemoveManagedFrame(TotemFrame)
    end

    -- Dummy manager
    TotemFrame.layoutParent = {
      AddManagedFrame = function() end,
      RemoveManagedFrame = function() end,
      Layout = function() end,
    }
  end

  TotemFrame:SetParent(UIParent)

  setupTotemFrameOverlay()
  C_Timer.After(0, function()
    -- Apply saved position
    if totemFrameOverlay then
      BUII_EditModeUtils:ApplySavedPosition(totemFrameOverlay, "moveable_totem_frame")
      syncTotemFrameToOverlay()
    end

    -- Force layout update of the container we left, so other frames adjust
    if PlayerFrameBottomManagedFramesContainer and PlayerFrameBottomManagedFramesContainer.Layout then
      PlayerFrameBottomManagedFramesContainer:Layout()
    end
  end)
end

--- Disables the Moveable Totem Frame feature, restoring it to its default parent and layout
---@return nil
function BUII_MoveableTotemFrame_Disable()
  moveableTotemFrameEnabled = false

  if TotemFrame then
    if originalParent then
      TotemFrame:SetParent(originalParent)
    end
    if TotemFrame.originalLayoutParent then
      TotemFrame.layoutParent = TotemFrame.originalLayoutParent
    end

    TotemFrame:ClearAllPoints()

    -- Restore layout
    if PlayerFrameBottomManagedFramesContainer then
      PlayerFrameBottomManagedFramesContainer:Layout()
    end
  end

  if totemFrameOverlay then
    totemFrameOverlay:Hide()
  end
end

local DB_DEFAULTS = {
  moveable_totem_frame = false,
}

function BUII_MoveableTotemFrame_InitDB()
  MergeDefaults(BUIIDatabase, DB_DEFAULTS)
end
