local frame = nil
local text = nil
local animGroup = nil
local hideTimer = nil

-- Durability frame variables
local durabilityFrame = nil
local durabilityIcon = nil
local durabilityText = nil

-- Settings Constants
local enum_ReadyCheckSetting_Scale = 50
local enum_ReadyCheckSetting_FontSize = 51
local enum_ReadyCheckSetting_ShowRepairWarning = 52
local enum_ReadyCheckSetting_RepairThreshold = 53
local enum_ReadyCheckSetting_RepairYOffset = 54

-- Equipment slots that have durability
local EQUIPMENT_SLOTS_WITH_DURABILITY = {
  1, -- Head
  3, -- Shoulder
  5, -- Chest
  6, -- Waist
  7, -- Legs
  8, -- Feet
  9, -- Wrist
  10, -- Hands
  16, -- Main Hand
  17, -- Off Hand
}

-- Update durability frame Y position
local function updateDurabilityYPosition()
  if durabilityFrame then
    local yOffset = BUIIDatabase["ready_check_repair_y_offset"] or 52
    durabilityFrame:ClearAllPoints()
    durabilityFrame:SetPoint("CENTER", frame, "CENTER", 0, yOffset)
  end
end

-- Calculate average durability percentage across all equipped items
local function getAverageDurability()
  local totalDurability = 0
  local totalMaxDurability = 0

  for _, slot in ipairs(EQUIPMENT_SLOTS_WITH_DURABILITY) do
    local current, max = GetInventoryItemDurability(slot)
    if current and max then
      totalDurability = totalDurability + current
      totalMaxDurability = totalMaxDurability + max
    end
  end

  if totalMaxDurability == 0 then
    return 100
  end

  return (totalDurability / totalMaxDurability) * 100
end

local function onEvent(self, event)
  if event == "EDIT_MODE_LAYOUTS_UPDATED" then
    BUII_EditModeUtils:ApplySavedPosition(frame, "ready_check")
    return
  end

  if event == "READY_CHECK" then
    local _, instanceType = IsInInstance()
    if instanceType ~= "party" and instanceType ~= "raid" then
      return
    end

    if hideTimer then
      hideTimer:Cancel()
      hideTimer = nil
    end
    frame:Show()
    animGroup:Play()

    -- Check durability and show warning if needed
    local showRepairWarning = BUIIDatabase["ready_check_show_repair"] or false
    local repairThreshold = BUIIDatabase["ready_check_repair_threshold"] or 99

    if showRepairWarning then
      local avgDurability = getAverageDurability()
      if avgDurability < repairThreshold then
        durabilityText:SetText(string.format("Repair: %.0f%%", avgDurability))
        durabilityFrame:Show()
      else
        durabilityFrame:Hide()
      end
    else
      durabilityFrame:Hide()
    end
  elseif event == "READY_CHECK_FINISHED" then
    hideTimer = C_Timer.NewTimer(10, function()
      animGroup:Stop()
      frame:Hide()
      durabilityFrame:Hide()
      hideTimer = nil
    end)
  end
end

local function BUII_ReadyCheck_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_ReadyCheckFrame", UIParent, "BUII_ReadyCheckEditModeTemplate")
  frame:SetSize(300, 50)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  text:SetFont(BUII_GetFontPath(), 44, BUII_GetFontFlags())
  text:SetPoint("CENTER", frame, "CENTER")
  text:SetText("Check Gear & Talents")
  text:SetTextColor(1, 1, 1) -- White text

  -- Animation (Bouncing)
  animGroup = text:CreateAnimationGroup()
  local bounceUp = animGroup:CreateAnimation("Translation")
  bounceUp:SetOffset(0, 10)
  bounceUp:SetDuration(0.3)
  bounceUp:SetOrder(1)
  bounceUp:SetSmoothing("OUT")

  local bounceDown = animGroup:CreateAnimation("Translation")
  bounceDown:SetOffset(0, -10)
  bounceDown:SetDuration(0.3)
  bounceDown:SetOrder(2)
  bounceDown:SetSmoothing("IN")

  animGroup:SetLooping("REPEAT")

  -- Create durability warning frame
  durabilityFrame = CreateFrame("Frame", "BUII_ReadyCheckDurabilityFrame", frame)
  durabilityFrame:SetSize(200, 40)
  updateDurabilityYPosition()
  durabilityFrame:Hide()

  -- Anvil icon
  durabilityIcon = durabilityFrame:CreateTexture(nil, "ARTWORK")
  durabilityIcon:SetTexture(136241) -- Anvil icon
  durabilityIcon:SetSize(32, 32)
  durabilityIcon:SetPoint("LEFT", durabilityFrame, "LEFT", 0, 0)

  -- Durability text
  durabilityText = durabilityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  durabilityText:SetFont(BUII_GetFontPath(), 28, BUII_GetFontFlags())
  durabilityText:SetPoint("LEFT", durabilityIcon, "RIGHT", 8, 0)
  durabilityText:SetTextColor(1, 0.2, 0.2) -- Red text for warning

  -- Register System
  local settingsConfig = {
    {
      setting = enum_ReadyCheckSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 2.0,
      stepSize = 0.05,
      formatter = BUII_EditModeUtils.FormatPercentage,
      getter = function(f)
        return f:GetScale()
      end,
      setter = function(f, val)
        f:SetScale(val)
      end,
    },
    {
      setting = enum_ReadyCheckSetting_ShowRepairWarning,
      name = "Show Repair Warning",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      getter = function(f)
        return BUIIDatabase["ready_check_show_repair"] or false
      end,
      setter = function(f, val)
        BUIIDatabase["ready_check_show_repair"] = val
      end,
    },
    {
      setting = enum_ReadyCheckSetting_RepairThreshold,
      name = "Repair Threshold",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 10,
      maxValue = 99,
      stepSize = 1,
      formatter = function(val)
        return string.format("%.0f%%", val)
      end,
      getter = function(f)
        return BUIIDatabase["ready_check_repair_threshold"] or 99
      end,
      setter = function(f, val)
        BUIIDatabase["ready_check_repair_threshold"] = val
      end,
    },
    {
      setting = enum_ReadyCheckSetting_RepairYOffset,
      name = "Repair Y Offset",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = -100,
      maxValue = 100,
      stepSize = 1,
      formatter = function(val)
        return string.format("%.0f", val)
      end,
      getter = function(f)
        return BUIIDatabase["ready_check_repair_y_offset"] or 52
      end,
      setter = function(f, val)
        BUIIDatabase["ready_check_repair_y_offset"] = val
        updateDurabilityYPosition()
      end,
    },
  }

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_ReadyCheck,
    "Ready Check Notification",
    settingsConfig,
    "ready_check",
    {
      OnReset = function(f)
        text:SetFont(BUII_GetFontPath(), 44, BUII_GetFontFlags())
      end,
      OnApplySettings = function(f)
        -- Scale handled automatically
      end,
    }
  )
end

-- Edit Mode Integration
local function editMode_OnEnter()
  frame:EnableMouse(true)
  animGroup:Play()
  -- Show durability frame in edit mode for preview if enabled
  local showRepairWarning = BUIIDatabase["ready_check_show_repair"] or false
  if showRepairWarning then
    durabilityText:SetText("Repair: 87%")
    durabilityFrame:Show()
  end
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  animGroup:Stop()
  frame:Hide()
  durabilityFrame:Hide()
end

function BUII_ReadyCheck_Enable()
  BUII_ReadyCheck_Initialize()

  frame:RegisterEvent("READY_CHECK")
  frame:RegisterEvent("READY_CHECK_FINISHED")
  frame:SetScript("OnEvent", onEvent)

  -- Register Edit Mode Callbacks
  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_ReadyCheck_Custom_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_ReadyCheck_Custom_OnExit")

  BUII_EditModeUtils:ApplySavedPosition(frame, "ready_check")
  frame:Hide() -- Hide initially
end

function BUII_ReadyCheck_Disable()
  if not frame then
    return
  end
  frame:UnregisterEvent("READY_CHECK")
  frame:UnregisterEvent("READY_CHECK_FINISHED")
  frame:SetScript("OnEvent", nil)

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_ReadyCheck_Custom_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_ReadyCheck_Custom_OnExit")

  frame:Hide()
  animGroup:Stop()
  if hideTimer then
    hideTimer:Cancel()
    hideTimer = nil
  end
end

function BUII_ReadyCheck_Refresh()
  if frame and text then
    text:SetFont(BUII_GetFontPath(), 44, BUII_GetFontFlags())
    text:SetShadowOffset(BUII_GetFontShadow())
  end
  if durabilityText then
    durabilityText:SetFont(BUII_GetFontPath(), 28, BUII_GetFontFlags())
    durabilityText:SetShadowOffset(BUII_GetFontShadow())
  end
end

function BUII_ReadyCheck_InitDB()
  if BUIIDatabase["ready_check"] == nil then
    BUIIDatabase["ready_check"] = false
  end
  if BUIIDatabase["ready_check_show_repair"] == nil then
    BUIIDatabase["ready_check_show_repair"] = true
  end
  if BUIIDatabase["ready_check_repair_threshold"] == nil then
    BUIIDatabase["ready_check_repair_threshold"] = 99
  end
  if BUIIDatabase["ready_check_repair_y_offset"] == nil then
    BUIIDatabase["ready_check_repair_y_offset"] = 52
  end
end
