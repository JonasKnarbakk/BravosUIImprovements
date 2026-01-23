local addonName, addon = ...
local moveableTotemFrameEnabled = false
local originalParent = nil
local totemFrameOverlay = nil

if not Enum.EditModeSystem.BUII_TotemFrame then
  Enum.EditModeSystem.BUII_TotemFrame = 115
end

local enum_MoveableTotemFrameSetting_Scale = 1

local function syncTotemFrameToOverlay()
  if not totemFrameOverlay or not TotemFrame then
    return
  end
  -- Direct atomic anchor to prevent spazzing/jitter during resizing or moving
  TotemFrame:ClearAllPoints()
  TotemFrame:SetPoint("TOPLEFT", totemFrameOverlay, "TOPLEFT", 0, 0)
end

local function setupTotemFrameOverlay()
  if totemFrameOverlay then
    return
  end

  totemFrameOverlay = CreateFrame("Frame", "BUIITotemFrameOverlay", UIParent, "BUII_TotemFrameEditModeTemplate")
  totemFrameOverlay:SetSize(120, 40)
  totemFrameOverlay:SetMovable(true)
  totemFrameOverlay:SetClampedToScreen(true)
  totemFrameOverlay:SetDontSavePosition(true)

  local settingsConfig = {
    {
      setting = enum_MoveableTotemFrameSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 3.0,
      stepSize = 0.1,
      formatter = BUII_EditModeUtils.FormatPercentage,
      getter = function(f)
        return f:GetScale()
      end,
      setter = function(f, val)
        f:SetScale(val)
        if TotemFrame then
          TotemFrame:SetScale(val)
        end
      end,
    },
  }

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

function BUII_MoveableTotemFrame_InitDB()
  if BUIIDatabase["moveable_totem_frame"] == nil then
    BUIIDatabase["moveable_totem_frame"] = false
  end
end
