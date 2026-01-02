local frame = nil
local bRezText = nil
local timerFrame = nil

-- Settings Constants
local enum_GroupToolsSetting_Scale = 20

-- Pending changes tracking
local pendingSettings = nil

local function UpdateBattleRez()
  if not frame then return end
  local spellChargeInfo = C_Spell.GetSpellCharges(20484)
  local greyCol = "|cFFAAAAAA"
  local redCol = "|cFFB40000"
  local greenCol = "|cFF00FF00"
  local whiteCol = "|cFFFFFFFF"

  if spellChargeInfo == nil then
    local crs = { 20484, 391054, 20707, 61999 }
    local crItems = { 221954, 221993, 198428 }
    local found = false
    for _, cr in ipairs(crs) do
      if IsSpellKnown(cr) then
        local crInfo = C_Spell.GetSpellCooldown(cr)
        if crInfo then
          local isReady = false
          pcall(function() isReady = (crInfo.startTime == 0) end)
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
          pcall(function() isReady = (start == 0) end)
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

  pcall(function() chargesStr = tostring(charges) end)
  pcall(function() if charges < 1 then color = redCol end end)

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
  if not frame then return end
  local inInstance, instanceType = IsInInstance()
  if inInstance and (instanceType == "party" or instanceType == "raid") then
    frame:Show()
  else
    frame:Hide()
  end
end

local function onEvent(self, event)
  UpdateBattleRez()
  UpdateVisibility()
  if event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_START" then
    if timerFrame then timerFrame:Show() end
  elseif event == "ENCOUNTER_END" then
    if timerFrame then timerFrame:Show() end
  end
end

local function BUII_ApplySavedPosition()
  if not frame then return end
  if BUIIDatabase["group_tools_pos"] then
    local pos = BUIIDatabase["group_tools_pos"]
    if pos.scale then frame:SetScale(pos.scale) end
    frame:ClearAllPoints()
    -- Support both new offsetX/offsetY and legacy x/y
    local x = pos.offsetX or pos.x or 0
    local y = pos.offsetY or pos.y or 0
    frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", x, y)
  end
end

local function updatePending()
  if not frame then return end
  local point, _, relativePoint, offsetX, offsetY = frame:GetPoint()
  pendingSettings = {
    point = point,
    relativePoint = relativePoint,
    offsetX = offsetX,
    offsetY = offsetY,
    scale = frame:GetScale(),
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

-- Hook for Edit Mode Settings Dialog
local function groupTools_OnUpdateSettings(self, systemFrame)
  if systemFrame == self.attachedToSystem and systemFrame.system == Enum.EditModeSystem.BUII_GroupTools then
    local scaleSetting = {
      setting = enum_GroupToolsSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 2.0,
      stepSize = 0.05,
    }

    local scaleSettingData = {
      displayInfo = scaleSetting,
      currentValue = systemFrame:GetScale(),
      settingName = "Scale",
    }

    local settingPool = self:GetSettingPool(Enum.ChrCustomizationOptionType.Slider)
    if settingPool then
      local settingFrame = settingPool:Acquire()
      settingFrame:SetPoint("TOPLEFT")
      settingFrame.layoutIndex = enum_GroupToolsSetting_Scale
      settingFrame:Show()
      self.Settings:Show()
      self.Settings:Layout()
      settingFrame:SetupSetting(scaleSettingData)
      self.Buttons:SetPoint("TOPLEFT", self.Settings, "BOTTOMLEFT", 0, -12)
      self:UpdateButtons(systemFrame)
    end
  end
end

local function groupTools_OnSettingValueChanged(self, setting, value)
  local currentFrame = self.attachedToSystem
  if setting == enum_GroupToolsSetting_Scale and currentFrame and currentFrame.system == Enum.EditModeSystem.BUII_GroupTools then
    currentFrame:SetScale(value)
    updatePending()
    MarkLayoutDirty()
    if EditModeSystemSettingsDialog then
      EditModeSystemSettingsDialog:UpdateButtons(currentFrame)
    end
  end
end

local function BUII_GroupTools_Initialize()
  if frame then return end

  frame = CreateFrame("Frame", "BUII_GroupToolsFrame", UIParent, "BUII_GroupToolsEditModeTemplate")
  frame:SetSize(140, 80)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:Hide()

  frame.systemIndex = 0
  
  -- MANDATORY: Blizzard expects this data structure for interaction events
  frame.systemInfo = {
    system = Enum.EditModeSystem.BUII_GroupTools,
    systemIndex = 0,
    anchorInfo = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", offsetX = 0, offsetY = 0 },
    settings = { { setting = enum_GroupToolsSetting_Scale, value = 1.0 } },
    isInDefaultPosition = true
  }

  -- Override Mixin methods
  frame.ResetToDefaultPosition = function(self)
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    updatePending()
    MarkLayoutDirty()
  end

  frame.UpdateSystem = function(self, systemInfo)
    BUII_ApplySavedPosition()
  end

  frame.HasActiveChanges = function(self)
    return self.hasActiveChanges or false
  end

  frame.RevertChanges = function(self)
    pendingSettings = nil
    self.hasActiveChanges = false
    BUII_ApplySavedPosition()
    if EditModeManagerFrame then
      EditModeManagerFrame:CheckForSystemActiveChanges()
    end
  end

  -- Blizzard expects this map to exist for interaction events
  frame.settingDisplayInfoMap = {
    [enum_GroupToolsSetting_Scale] = {
      setting = enum_GroupToolsSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 2.0,
      stepSize = 0.05,
    }
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
    local timer = UnitInRaid("player") and 10 or 5
    if button == "LeftButton" then
      if C_PartyInfo and C_PartyInfo.DoCountdown then C_PartyInfo.DoCountdown(timer) end
    elseif button == "RightButton" then
      if C_PartyInfo and C_PartyInfo.DoCountdown then C_PartyInfo.DoCountdown(0) end
    end
  end)

  local rcBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  rcBtn:SetSize(140, 20)
  rcBtn:SetPoint("TOP", pullBtn, "BOTTOM", 0, -5)
  rcBtn:SetText("Ready Check")
  rcBtn:GetFontString():SetFont(BUII_GetFontPath(), 10, "OUTLINE")
  rcBtn:SetScript("OnClick", function() DoReadyCheck() end)

  -- Selection Scripts
  frame.Selection.Label:SetText("Group Tools")
  
  frame.Selection:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      EditModeManagerFrame:SelectSystem(frame)
      frame.Selection:ShowSelected()
      frame:StartMoving()
    end
  end)

  local function onDragStop()
    frame:StopMovingOrSizing()
    frame.Selection:ShowHighlighted()
    updatePending()
    MarkLayoutDirty()
  end

  frame.Selection:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      onDragStop()
    end
  end)

  frame.Selection:SetScript("OnDragStop", onDragStop)

  -- Register Settings Hooks
  if EditModeSystemSettingsDialog then
    hooksecurefunc(EditModeSystemSettingsDialog, "UpdateSettings", groupTools_OnUpdateSettings)
    hooksecurefunc(EditModeSystemSettingsDialog, "OnSettingValueChanged", groupTools_OnSettingValueChanged)
  end

  -- Hook Edit Mode Save/Revert/LayoutSwitch
  if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "SaveLayouts", function()
      if pendingSettings then
        BUIIDatabase["group_tools_pos"] = BUIIDatabase["group_tools_pos"] or {}
        for k, v in pairs(pendingSettings) do
          BUIIDatabase["group_tools_pos"][k] = v
        end
        pendingSettings = nil
        frame.hasActiveChanges = false
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "RevertAllChanges", function()
      pendingSettings = nil
      frame.hasActiveChanges = false
      BUII_ApplySavedPosition()
      if EditModeManagerFrame then
        EditModeManagerFrame:CheckForSystemActiveChanges()
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "SelectLayout", function()
      BUII_ApplySavedPosition()
    end)
  end

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
  if not frame then return end
  pendingSettings = nil
  frame.hasActiveChanges = false
  frame:Show()
  frame.Selection:Show()
  frame.Selection:ShowHighlighted()
end

local function editMode_OnExit()
  if not frame then return end
  if frame.hasActiveChanges then
    BUII_ApplySavedPosition()
    frame.hasActiveChanges = false
    pendingSettings = nil
  end
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
  frame:SetScript("OnEvent", onEvent)

  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_GroupTools_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_GroupTools_OnExit")

  BUII_ApplySavedPosition()

  UpdateVisibility()
  timerFrame:Show()
  UpdateBattleRez()
end

function BUII_GroupTools_Disable()
  if not frame then return end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)
  timerFrame:Hide()
  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_GroupTools_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_GroupTools_OnExit")
  frame:Hide()
end