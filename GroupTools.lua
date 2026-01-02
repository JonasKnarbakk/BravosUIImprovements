local frame = nil
local bRezText = nil
local timerFrame = nil

-- Settings Constants
local enum_GroupToolsSetting_Scale = 20
local enum_GroupToolsSetting_FontSize = 21

-- Pending changes tracking
local pendingSettings = nil

local function UpdateBattleRez()
  if not frame then
    return
  end
  local spellChargeInfo = C_Spell.GetSpellCharges(20484)
  local greyCol = "|cFFAAAAAA"
  local redCol = "|cFFB40000"
  local greenCol = "|cFF00FF00"
  local whiteCol = "|cFFFFFFFF"

  -- Apply font size from the single source of truth
  local fontSize = frame.currentFontSize or 12
  if bRezText then
    bRezText:SetFont(BUII_GetFontPath(), fontSize, "OUTLINE")
  end

  if spellChargeInfo == nil then
    local crs = { 20484, 391054, 20707, 61999 }
    local crItems = { 221954, 221993, 198428 }
    local found = false
    for _, cr in ipairs(crs) do
      if IsSpellKnown(cr) then
        local crInfo = C_Spell.GetSpellCooldown(cr)
        if crInfo then
          local isReady = false
          pcall(function()
            isReady = (crInfo.startTime == 0)
          end)
          if isReady then
            bRezText:SetText(greyCol .. "BR: " .. greenCol .. "Ready")
          else
            local timeStr = "??:??"
            pcall(function()
              local duration = crInfo.duration
              local startTime = crInfo.startTime
              local remaining = duration - (GetTime() - startTime)
              timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
            end)
            bRezText:SetText(greyCol .. "BR: " .. redCol .. timeStr)
          end
          found = true
          break
        end
      end
    end

    if not found then
      for _, itemID in ipairs(crItems) do
        if C_Item.GetItemCount(itemID) > 0 then
          local start, duration, enable = GetItemCooldown(itemID)
          local isReady = false
          pcall(function()
            isReady = (start == 0)
          end)
          if isReady then
            bRezText:SetText(greyCol .. "BR: " .. greenCol .. "Ready")
          else
            local timeStr = "??:??"
            pcall(function()
              local remaining = duration - (GetTime() - start)
              timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
            end)
            bRezText:SetText(greyCol .. "BR: " .. redCol .. timeStr)
          end
          found = true
          break
        end
      end
    end

    if not found then
      bRezText:SetText(greyCol .. "BR: " .. whiteCol .. "N/A")
    end
    return
  end

  local charges = spellChargeInfo.currentCharges or 0
  local started = spellChargeInfo.cooldownStartTime
  local duration = spellChargeInfo.cooldownDuration
  local maxCharges = spellChargeInfo.maxCharges

  local color = greenCol
  local chargesStr = "?"
  local nextText = ""

  pcall(function()
    chargesStr = tostring(charges)
  end)
  pcall(function()
    if charges < 1 then
      color = redCol
    end
  end)

  pcall(function()
    if started and duration and duration > 0 and maxCharges and charges < maxCharges then
      local remaining = duration - (GetTime() - started)
      if remaining > 0 then
        local timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
        nextText = " " .. greyCol .. "(" .. whiteCol .. timeStr .. greyCol .. ")"
      end
    end
  end)

  bRezText:SetText(greyCol .. "BR: " .. color .. chargesStr .. "|r" .. nextText)
end

local function UpdateVisibility()
  if not frame then
    return
  end
  local inInstance, instanceType = IsInInstance()
  if inInstance and (instanceType == "party" or instanceType == "raid") then
    frame:Show()
  else
    frame:Hide()
  end
end

local function onEvent(self, event)
  if event == "EDIT_MODE_LAYOUTS_UPDATED" then
    if frame and not frame.isSelected and not frame.hasActiveChanges then
      BUII_ApplySavedPosition()
    end
    return
  end

  UpdateBattleRez()
  UpdateVisibility()
  if event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_START" then
    if timerFrame then
      timerFrame:Show()
    end
  elseif event == "ENCOUNTER_END" then
    if timerFrame then
      timerFrame:Show()
    end
  end
end

function BUII_GetActiveLayoutKey()
  local layoutName = "Default"
  pcall(function()
    if EditModeManagerFrame then
      local layoutInfo = EditModeManagerFrame:GetActiveLayoutInfo()
      if layoutInfo and layoutInfo.layoutName then
        layoutName = layoutInfo.layoutName
      end
    end
  end)
  return layoutName
end

local function BUII_CommitPendingChanges()
  if pendingSettings then
    local layoutKey = BUII_GetActiveLayoutKey()
    BUIIDatabase["group_tools_layouts"] = BUIIDatabase["group_tools_layouts"] or {}
    BUIIDatabase["group_tools_layouts"][layoutKey] = {
      point = pendingSettings.point,
      relativePoint = pendingSettings.relativePoint,
      offsetX = pendingSettings.offsetX,
      offsetY = pendingSettings.offsetY,
      scale = pendingSettings.scale,
      fontSize = pendingSettings.fontSize,
    }
    pendingSettings = nil
    if frame then
      frame.hasActiveChanges = false
    end
    -- Visual refresh to ensure it's locked in
    BUII_ApplySavedPosition()
  end
end

function BUII_ApplySavedPosition()
  if not frame then
    return
  end

  local layoutKey = BUII_GetActiveLayoutKey()
  local layouts = BUIIDatabase["group_tools_layouts"] or {}
  local pos = layouts[layoutKey]

  -- Fallback to old global setting ONLY if we have NEVER saved any layout-specific settings
  if not pos and not next(layouts) and BUIIDatabase["group_tools_pos"] then
    pos = BUIIDatabase["group_tools_pos"]
  end

  local point, relPoint, x, y, scale, fontSize
  if pos then
    point = pos.point or "CENTER"
    relPoint = pos.relativePoint or "CENTER"
    x = pos.offsetX or pos.x or 0
    y = pos.offsetY or pos.y or 0
    scale = pos.scale or 1.0
    fontSize = pos.fontSize or 12
  else
    point = "CENTER"
    relPoint = "CENTER"
    x = 0
    y = 0
    scale = 1.0
    fontSize = 12
  end

  frame.currentFontSize = fontSize
  if frame:GetScale() ~= scale then
    frame:SetScale(scale)
  end

  local currentPoint, _, currentRel, currentX, currentY = frame:GetPoint()
  if
    currentPoint ~= point
    or currentRel ~= relPoint
    or math.abs(currentX - x) > 0.1
    or math.abs(currentY - y) > 0.1
  then
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relPoint, x, y)
  end

  -- Sync Blizzard systemInfo structure
  frame.systemInfo.anchorInfo = {
    point = point,
    relativeTo = "UIParent",
    relativePoint = relPoint,
    offsetX = x,
    offsetY = y,
  }
  frame.systemInfo.settings = {
    { setting = enum_GroupToolsSetting_Scale, value = scale },
    { setting = enum_GroupToolsSetting_FontSize, value = fontSize },
  }
  frame.savedSystemInfo = CopyTable(frame.systemInfo)

  UpdateBattleRez()
end

local function updatePending()
  if not frame then
    return
  end
  local point, _, relativePoint, offsetX, offsetY = frame:GetPoint()

  pendingSettings = {
    point = point,
    relativePoint = relativePoint,
    offsetX = offsetX,
    offsetY = offsetY,
    scale = frame:GetScale(),
    fontSize = frame.currentFontSize or 12,
  }
end

local function MarkLayoutDirty()
  if frame then
    frame.hasActiveChanges = true
  end
  if EditModeManagerFrame then
    EditModeManagerFrame:SetHasActiveChanges(true)
    EditModeManagerFrame:OnEditModeSystemAnchorChanged()
  end
end

local function BUII_FormatScale(value)
  return string.format("%.2f", value)
end

-- Hook for Edit Mode Settings Dialog
local function groupTools_OnUpdateSettings(self, systemFrame)
  if systemFrame == self.attachedToSystem and systemFrame.system == Enum.EditModeSystem.BUII_GroupTools then
    -- 1. Scale Slider
    local scaleSetting = {
      setting = enum_GroupToolsSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 2.0,
      stepSize = 0.05,
      formatter = BUII_FormatScale,
    }

    local scaleSettingData = {
      displayInfo = scaleSetting,
      currentValue = systemFrame:GetScale(),
      settingName = "Scale",
    }

    -- 2. Font Size Slider
    local fontSetting = {
      setting = enum_GroupToolsSetting_FontSize,
      name = "BR Font Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 24,
      stepSize = 1,
    }

    local fontSettingData = {
      displayInfo = fontSetting,
      currentValue = frame.currentFontSize or 12,
      settingName = "BR Font Size",
    }

    local sliderPool = self:GetSettingPool(Enum.ChrCustomizationOptionType.Slider)
    if sliderPool then
      self.Settings:Show()
      local scaleFrame = sliderPool:Acquire()
      scaleFrame:SetPoint("TOPLEFT")
      scaleFrame.layoutIndex = enum_GroupToolsSetting_Scale
      scaleFrame:Show()
      scaleFrame:SetupSetting(scaleSettingData)

      local fontFrame = sliderPool:Acquire()
      fontFrame:SetPoint("TOPLEFT")
      fontFrame.layoutIndex = enum_GroupToolsSetting_FontSize
      fontFrame:Show()
      fontFrame:SetupSetting(fontSettingData)

      self.Settings:Layout()
      self.Buttons:SetPoint("TOPLEFT", self.Settings, "BOTTOMLEFT", 0, -12)
      self:UpdateButtons(systemFrame)
    end
  end
end

local function groupTools_OnSettingValueChanged(self, setting, value)
  local currentFrame = self.attachedToSystem
  if currentFrame and currentFrame.system == Enum.EditModeSystem.BUII_GroupTools then
    if setting == enum_GroupToolsSetting_Scale then
      value = math.floor(value * 100 + 0.5) / 100
      currentFrame:SetScale(value)
      updatePending()
      MarkLayoutDirty()
    elseif setting == enum_GroupToolsSetting_FontSize then
      currentFrame.currentFontSize = value
      updatePending()
      UpdateBattleRez()
      MarkLayoutDirty()
    end

    if EditModeSystemSettingsDialog then
      EditModeSystemSettingsDialog:UpdateButtons(currentFrame)
    end

    if currentFrame.isSelected then
      currentFrame.Selection:ShowSelected()
    end
  end
end

local function BUII_GroupTools_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_GroupToolsFrame", UIParent, "BUII_GroupToolsEditModeTemplate")
  frame:SetSize(140, 80)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:Hide()

  frame.system = Enum.EditModeSystem.BUII_GroupTools
  frame.systemIndex = 0
  frame.isSelected = false
  frame.isManagedFrame = false
  frame.currentFontSize = 12

  -- Mandatory fields
  frame.systemInfo = {
    system = Enum.EditModeSystem.BUII_GroupTools,
    systemIndex = 0,
    anchorInfo = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", offsetX = 0, offsetY = 0 },
    settings = {
      { setting = enum_GroupToolsSetting_Scale, value = 1.0 },
      { setting = enum_GroupToolsSetting_FontSize, value = 12 },
    },
    isInDefaultPosition = true,
  }
  frame.savedSystemInfo = CopyTable(frame.systemInfo)

  -- Override Mixin methods
  frame.ResetToDefaultPosition = function(self)
    self:SetScale(1.0)
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.currentFontSize = 12
    updatePending()
    UpdateBattleRez()
    MarkLayoutDirty()
    if EditModeSystemSettingsDialog then
      EditModeSystemSettingsDialog:UpdateButtons(self)
    end
    if self.isSelected then
      self.Selection:ShowSelected()
    end
  end

  frame.UpdateSystem = function(self, systemInfo)
    pendingSettings = nil
    self.hasActiveChanges = false
    BUII_ApplySavedPosition()
    if EditModeSystemSettingsDialog and EditModeSystemSettingsDialog.attachedToSystem == self then
      EditModeSystemSettingsDialog:UpdateSettings(self)
    end
    if self.isSelected then
      self.Selection:ShowSelected()
    end
  end

  frame.HasActiveChanges = function(self)
    return self.hasActiveChanges or false
  end

  frame.IsSelected = function(self)
    return self.isSelected or false
  end

  frame.RevertChanges = function(self)
    self:UpdateSystem()
    if EditModeManagerFrame then
      EditModeManagerFrame:CheckForSystemActiveChanges()
    end
  end

  frame.settingDisplayInfoMap = {
    [enum_GroupToolsSetting_Scale] = {
      setting = enum_GroupToolsSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 2.0,
      stepSize = 0.05,
    },
    [enum_GroupToolsSetting_FontSize] = {
      setting = enum_GroupToolsSetting_FontSize,
      name = "BR Font Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 24,
      stepSize = 1,
    },
  }

  local bRezFrame = CreateFrame("Frame", nil, frame)
  bRezFrame:SetSize(140, 30)
  bRezFrame:SetPoint("TOP", frame, "TOP", 0, 0)

  local bRezIcon = bRezFrame:CreateTexture(nil, "ARTWORK")
  bRezIcon:SetSize(30, 30)
  bRezIcon:SetPoint("LEFT", bRezFrame, "LEFT", 5, 0)
  bRezIcon:SetTexture(136080)
  bRezIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  bRezText = bRezFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  bRezText:SetFont(BUII_GetFontPath(), 12, "OUTLINE")
  bRezText:SetPoint("LEFT", bRezIcon, "RIGHT", 5, 0)
  bRezText:SetJustifyH("LEFT")

  local pullBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  pullBtn:SetSize(140, 20)
  pullBtn:SetPoint("TOP", bRezFrame, "BOTTOM", 0, -5)
  pullBtn:SetText("Pull Timer")
  pullBtn:GetFontString():SetFont(BUII_GetFontPath(), 10, "OUTLINE")
  pullBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  pullBtn:SetScript("OnClick", function(self, button)
    local timer = IsInRaid() and 10 or 5
    if button == "LeftButton" then
      if C_PartyInfo and C_PartyInfo.DoCountdown then
        C_PartyInfo.DoCountdown(timer)
      end
    elseif button == "RightButton" then
      if C_PartyInfo and C_PartyInfo.DoCountdown then
        C_PartyInfo.DoCountdown(0)
      end
    end
  end)

  local rcBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  rcBtn:SetSize(140, 20)
  rcBtn:SetPoint("TOP", pullBtn, "BOTTOM", 0, -5)
  rcBtn:SetText("Ready Check")
  rcBtn:GetFontString():SetFont(BUII_GetFontPath(), 10, "OUTLINE")
  rcBtn:SetScript("OnClick", function()
    DoReadyCheck()
  end)

  -- Selection Scripts
  frame.Selection.Label:SetText("Group Tools")

  frame.Selection:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      EditModeManagerFrame:SelectSystem(frame)
      frame.isSelected = true
      self:ShowSelected()
      frame:StartMoving()
    end
  end)

  local function onDragStop()
    frame:StopMovingOrSizing()
    if frame.isSelected then
      frame.Selection:ShowSelected()
    else
      frame.Selection:ShowHighlighted()
    end
    updatePending()
    MarkLayoutDirty()
    if EditModeSystemSettingsDialog then
      EditModeSystemSettingsDialog:UpdateButtons(frame)
    end
  end

  frame.Selection:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      onDragStop()
    end
  end)

  frame.Selection:SetScript("OnDragStop", onDragStop)

  -- Position Enforcement
  frame:SetScript("OnUpdate", function(self)
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
      if not self.isSelected and not self.hasActiveChanges then
        BUII_ApplySavedPosition()
      end
    end
  end)

  -- Register Settings Hooks
  if EditModeSystemSettingsDialog then
    hooksecurefunc(EditModeSystemSettingsDialog, "UpdateSettings", groupTools_OnUpdateSettings)
    hooksecurefunc(EditModeSystemSettingsDialog, "OnSettingValueChanged", groupTools_OnSettingValueChanged)
  end

  -- Hook Edit Mode Save/Revert/LayoutSwitch
  if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "RevertAllChanges", function()
      if frame then
        frame:UpdateSystem()
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "RevertSystemChanges", function(self, systemFrame)
      if systemFrame == frame then
        frame:RevertChanges()
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "ClearSelectedSystem", function()
      if frame then
        frame.isSelected = false
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "SelectLayout", function()
      if frame then
        pendingSettings = nil
        frame.hasActiveChanges = false
        frame.isSelected = false
        BUII_ApplySavedPosition()
      end
    end)
  end

  -- Standard Blizzard Save Event - covers Save button and Save & Exit path
  EventRegistry:RegisterCallback("EditMode.SavedLayouts", BUII_CommitPendingChanges, "BUII_GroupTools_OnSave")

  timerFrame = CreateFrame("Frame")
  timerFrame:Hide()
  local elapsed = 0
  timerFrame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed > 1.0 then
      UpdateBattleRez()
      elapsed = 0
    end
  end)
end

local function editMode_OnEnter()
  if not frame then
    return
  end
  pendingSettings = nil
  frame.hasActiveChanges = false
  frame.isSelected = false
  frame:Show()
  frame.Selection:Show()
  frame.Selection:ShowHighlighted()
end

local function editMode_OnExit()
  if not frame then
    return
  end
  if frame.hasActiveChanges then
    -- Discard visual changes if we exited without saving
    BUII_ApplySavedPosition()
    frame.hasActiveChanges = false
    pendingSettings = nil
  end
  frame.isSelected = false
  frame.Selection:Hide()
  UpdateVisibility()
end

function BUII_GroupTools_Enable()
  BUII_GroupTools_Initialize()

  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("ENCOUNTER_START")
  frame:RegisterEvent("ENCOUNTER_END")
  frame:RegisterEvent("SPELL_UPDATE_CHARGES")
  frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  frame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
  frame:SetScript("OnEvent", onEvent)

  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_GroupTools_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_GroupTools_OnExit")

  BUII_ApplySavedPosition()

  UpdateVisibility()
  timerFrame:Show()
  UpdateBattleRez()
end

function BUII_GroupTools_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)
  timerFrame:Hide()
  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_GroupTools_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_GroupTools_OnExit")
  frame:Hide()
end
