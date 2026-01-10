BUII_EditModeUtils = {}
BUII_EditModeUtils.RegisteredSystems = {}
BUII_EditModeUtils.HooksInitialized = false

-- Generic Formatters
function BUII_EditModeUtils.FormatPercentage(value)
  return math.floor(value * 100 + 0.5) .. "%"
end

-- Helper to get active layout
function BUII_EditModeUtils:GetActiveLayoutKey()
  local layoutName = "Default"
  pcall(function()
    if C_EditMode and C_EditMode.GetActiveLayoutInfo then
      local layoutInfo = C_EditMode.GetActiveLayoutInfo()
      if layoutInfo and layoutInfo.layoutName then
        layoutName = layoutInfo.layoutName
      end
    elseif EditModeManagerFrame then
      local layoutInfo = EditModeManagerFrame:GetActiveLayoutInfo()
      if layoutInfo and layoutInfo.layoutName then
        layoutName = layoutInfo.layoutName
      end
    end
  end)
  return layoutName
end

-- Helper to apply position
function BUII_EditModeUtils:ApplySavedPosition(frame, dbKey, force)
  if not frame then
    return
  end

  -- Prevent infinite recursion if a setter triggers an update
  if frame.isApplyingSettings then
    return
  end
  frame.isApplyingSettings = true

  -- Don't overwrite if we have unsaved changes or are currently moving the frame
  -- unless we are explicitly forcing it (e.g. during a layout switch or save)
  if not force and (frame.hasActiveChanges or frame.isSelected) then
    frame.isApplyingSettings = false
    return
  end

  local db = BUIIDatabase
  if frame.GetSettingsDB then
    db = frame:GetSettingsDB()
  end

  local layoutKey = self:GetActiveLayoutKey()
  local layouts = db[dbKey .. "_layouts"] or {}
  local pos = layouts[layoutKey]

  -- Fallback logic if current layout has no settings
  if not pos then
    -- 1. Try to find a "Default" layout setting
    if layouts["Default"] then
      pos = layouts["Default"]
    -- 2. Fallback to *any* existing layout to ensure we have a valid position
    elseif next(layouts) then
      for _, p in pairs(layouts) do
        pos = p
        break
      end
    -- 3. Legacy fallback if no layouts exist at all
    elseif db[dbKey .. "_pos"] then
      pos = db[dbKey .. "_pos"]
    end
  end

  local point, relPoint, x, y, scale
  if pos then
    point = pos.point or "CENTER"
    relPoint = pos.relativePoint or "CENTER"
    x = pos.offsetX or pos.x or 0
    y = pos.offsetY or pos.y or 0
    scale = pos.scale or 1.0
  else
    -- No settings found anywhere.
    -- If frame is already positioned, keep current position (inherit from previous spec/layout)
    if frame:GetPoint() then
      point, _, relPoint, x, y = frame:GetPoint()
      scale = frame:GetScale()
    else
      -- Only use defaults if frame has never been positioned
      point = frame.defaultPoint or "CENTER"
      relPoint = frame.defaultRelativePoint or "CENTER"
      x = frame.defaultX or 0
      y = frame.defaultY or 0
      scale = 1.0
    end
  end

  if frame:GetScale() ~= scale then
    frame:SetScale(scale)
  end

  local currentPoint, _, currentRel, currentX, currentY = frame:GetPoint()
  if
    currentPoint ~= point
    or currentRel ~= relPoint
    or math.abs((currentX or 0) - x) > 0.1
    or math.abs((currentY or 0) - y) > 0.1
  then
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relPoint, x, y)
  end

  -- Update System Info for Edit Mode
  frame.systemInfo.anchorInfo = {
    point = point,
    relativeTo = "UIParent",
    relativePoint = relPoint,
    offsetX = x,
    offsetY = y,
  }

  -- Update Settings in System Info
  frame.systemInfo.settings = {}

  -- Apply Custom Settings first so getter returns correct value for systemInfo
  for _, settingConfig in ipairs(frame.buiiSettingsConfig or {}) do
    if settingConfig.key then
      local val = nil
      if pos and pos[settingConfig.key] ~= nil then
        val = pos[settingConfig.key]
      elseif settingConfig.defaultValue ~= nil then
        val = settingConfig.defaultValue
      end

      if val ~= nil then
        settingConfig.setter(frame, val)
      end
    end
  end

  -- Now refresh systemInfo with current state
  for _, settingConfig in ipairs(frame.buiiSettingsConfig or {}) do
    local val = settingConfig.getter(frame)
    table.insert(frame.systemInfo.settings, { setting = settingConfig.setting, value = val })
  end

  frame.savedSystemInfo = CopyTable(frame.systemInfo)
  frame.isApplyingSettings = false

  -- Notify system
  if frame.OnApplySettings then
    frame.OnApplySettings(frame)
  end
end

-- Helper to save pending changes
function BUII_EditModeUtils:CommitPendingChanges(frame, dbKey)
  if frame.pendingSettings then
    local db = BUIIDatabase
    if frame.GetSettingsDB then
      db = frame:GetSettingsDB()
    end

    local layoutKey = self:GetActiveLayoutKey()
    db[dbKey .. "_layouts"] = db[dbKey .. "_layouts"] or {}

    local data = {
      point = frame.pendingSettings.point,
      relativePoint = frame.pendingSettings.relativePoint,
      offsetX = frame.pendingSettings.offsetX,
      offsetY = frame.pendingSettings.offsetY,
      scale = frame.pendingSettings.scale,
    }

    -- Save custom settings
    for key, value in pairs(frame.pendingSettings.custom or {}) do
      data[key] = value
    end

    db[dbKey .. "_layouts"][layoutKey] = data

    frame.pendingSettings = nil
    frame.hasActiveChanges = false

    -- Visual refresh
    self:ApplySavedPosition(frame, dbKey, true)
  end
end

local function UpdatePending(frame)
  local point, _, relativePoint, offsetX, offsetY = frame:GetPoint()

  frame.pendingSettings = {
    point = point,
    relativePoint = relativePoint,
    offsetX = offsetX,
    offsetY = offsetY,
    scale = frame:GetScale(),
    custom = {},
  }

  -- Capture custom settings
  for _, settingConfig in ipairs(frame.buiiSettingsConfig or {}) do
    if settingConfig.key then
      frame.pendingSettings.custom[settingConfig.key] = settingConfig.getter(frame)
    end
  end
end

local function MarkLayoutDirty(frame)
  frame.hasActiveChanges = true
  if EditModeManagerFrame then
    EditModeManagerFrame:SetHasActiveChanges(true)
    EditModeManagerFrame:OnEditModeSystemAnchorChanged()
  end
end

-- Hook Handlers
local function OnUpdateSettings(self, systemFrame)
  if systemFrame and BUII_EditModeUtils.RegisteredSystems[systemFrame.system] then
    local frame = systemFrame -- It is the same frame

    -- If we have registered settings
    if frame.buiiSettingsConfig then
      self.Settings:Show()

      -- Acquire pools using the correct Enums as defined in EditModeDialogs.lua
      local sliderPool = self:GetSettingPool(Enum.EditModeSettingDisplayType.Slider)
      local checkboxPool = self:GetSettingPool(Enum.ChrCustomizationOptionType.Checkbox)
      local dropdownPool = self:GetSettingPool(Enum.EditModeSettingDisplayType.Dropdown)

      for _, config in ipairs(frame.buiiSettingsConfig) do
        local pool
        if config.type == Enum.EditModeSettingDisplayType.Slider then
          pool = sliderPool
        elseif config.type == Enum.ChrCustomizationOptionType.Checkbox then
          pool = checkboxPool
        elseif config.type == Enum.EditModeSettingDisplayType.Dropdown then
          pool = dropdownPool
        end

        if pool then
          local settingData = {
            displayInfo = {
              setting = config.setting,
              name = config.name,
              type = config.type,
              minValue = config.minValue,
              maxValue = config.maxValue,
              stepSize = config.stepSize,
              formatter = config.formatter,
              options = config.options,
            },
            currentValue = config.getter(frame),
            settingName = config.name,
          }

          local settingFrame = pool:Acquire()
          settingFrame:SetPoint("TOPLEFT")
          settingFrame.layoutIndex = config.setting
          settingFrame:Show()
          settingFrame:SetupSetting(settingData)
        end
      end

      self.Settings:Layout()
      self.Buttons:SetPoint("TOPLEFT", self.Settings, "BOTTOMLEFT", 0, -12)
      self:UpdateButtons(systemFrame)
    end
  end
end

local function OnSettingValueChanged(self, setting, value)
  local currentFrame = self.attachedToSystem
  if currentFrame and BUII_EditModeUtils.RegisteredSystems[currentFrame.system] then
    local frame = currentFrame

    if frame.buiiSettingsConfig then
      for _, config in ipairs(frame.buiiSettingsConfig) do
        if config.setting == setting then
          config.setter(frame, value)
          UpdatePending(frame)
          MarkLayoutDirty(frame)

          -- Trigger UI Refresh for non-sliders (e.g. Dropdowns need to update selected text)
          -- Sliders handle their own visual state during drag, and refreshing would interrupt them.
          if config.type ~= Enum.EditModeSettingDisplayType.Slider then
            if self.Settings and self.Settings.GetChildren then
              local children = { self.Settings:GetChildren() }
              for _, child in ipairs(children) do
                if child.layoutIndex == setting and child.SetupSetting then
                  local settingData = {
                    displayInfo = {
                      setting = config.setting,
                      name = config.name,
                      type = config.type,
                      minValue = config.minValue,
                      maxValue = config.maxValue,
                      stepSize = config.stepSize,
                      formatter = config.formatter,
                      options = config.options,
                    },
                    currentValue = value,
                    settingName = config.name,
                  }
                  child:SetupSetting(settingData)
                  break
                end
              end
            end
          end
          break
        end
      end
    end

    if EditModeSystemSettingsDialog then
      EditModeSystemSettingsDialog:UpdateButtons(currentFrame)
    end

    if currentFrame.isSelected then
      currentFrame.Selection:ShowSelected()
    end
  end
end

function BUII_EditModeUtils:RegisterSystem(frame, systemEnum, systemName, settingsConfig, dbKey, callbacks)
  if self.RegisteredSystems[systemEnum] then
    return
  end

  self.RegisteredSystems[systemEnum] = frame

  -- Ensure EditModeSettingDisplayInfoManager has an entry for this system
  -- This prevents a crash in EditModeSystemSettingsDialogMixin:UpdateSettings where it iterates over this table.
  if
    EditModeSettingDisplayInfoManager and not EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[systemEnum]
  then
    EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[systemEnum] = {}
  end

  frame.system = systemEnum
  frame.systemIndex = 0 -- Default
  frame.isSelected = false
  frame.isManagedFrame = false
  frame.buiiSettingsConfig = settingsConfig
  frame.buiiDbKey = dbKey

  -- Assign Callbacks
  frame.OnReset = callbacks and callbacks.OnReset
  frame.OnApplySettings = callbacks and callbacks.OnApplySettings

  -- Initialize System Info
  frame.systemInfo = {
    system = systemEnum,
    systemIndex = 0,
    anchorInfo = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", offsetX = 0, offsetY = 0 },
    settings = {},
    isInDefaultPosition = true,
  }
  -- Populate initial settings in systemInfo
  for _, config in ipairs(settingsConfig or {}) do
    table.insert(frame.systemInfo.settings, { setting = config.setting, value = config.getter(frame) })
  end
  frame.savedSystemInfo = CopyTable(frame.systemInfo)

  -- Mixin Overrides
  frame.ResetToDefaultPosition = function(self)
    self:SetScale(1.0)
    self:ClearAllPoints()
    self:SetPoint(
      self.defaultPoint or "CENTER",
      UIParent,
      self.defaultRelativePoint or "CENTER",
      self.defaultX or 0,
      self.defaultY or 0
    )

    if self.OnReset then
      self.OnReset(self)
    end

    UpdatePending(self)
    MarkLayoutDirty(self)

    if EditModeSystemSettingsDialog then
      EditModeSystemSettingsDialog:UpdateButtons(self)
    end
    if self.isSelected then
      self.Selection:ShowSelected()
    end
  end

  frame.UpdateSystem = function(self, systemInfo)
    self.pendingSettings = nil
    self.hasActiveChanges = false
    BUII_EditModeUtils:ApplySavedPosition(self, self.buiiDbKey, true)
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

  -- Setting Display Info Map (Standard Blizzard requirement)
  frame.settingDisplayInfoMap = {}
  for _, config in ipairs(settingsConfig or {}) do
    if config.setting then
      frame.settingDisplayInfoMap[config.setting] = {
        setting = config.setting,
        name = config.name,
        type = config.type,
        minValue = config.minValue,
        maxValue = config.maxValue,
        stepSize = config.stepSize,
      }
    end
  end

  -- Selection Interaction
  if frame.Selection then
    frame.Selection.Label:SetText(systemName)
  end

  -- Hook Drag Stop to capture position changes
  hooksecurefunc(frame, "OnDragStop", function(self)
    UpdatePending(self)
    MarkLayoutDirty(self)
    if EditModeSystemSettingsDialog then
      EditModeSystemSettingsDialog:UpdateButtons(self)
    end
  end)

  -- Position Enforcement Loop
  frame:HookScript("OnUpdate", function(self)
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
      if not self.isSelected and not self.hasActiveChanges then
        BUII_EditModeUtils:ApplySavedPosition(self, self.buiiDbKey)
      elseif self.isSelected then
        -- Detect position changes from arrow keys
        local point, _, relativePoint, offsetX, offsetY = self:GetPoint()
        local lastPos = self.lastKnownPosition

        if
          not lastPos
          or lastPos.point ~= point
          or lastPos.relativePoint ~= relativePoint
          or math.abs((lastPos.offsetX or 0) - (offsetX or 0)) > 0.01
          or math.abs((lastPos.offsetY or 0) - (offsetY or 0)) > 0.01
        then
          -- Position changed - update pending and mark dirty
          self.lastKnownPosition = {
            point = point,
            relativePoint = relativePoint,
            offsetX = offsetX,
            offsetY = offsetY,
          }

          UpdatePending(self)
          MarkLayoutDirty(self)

          if EditModeSystemSettingsDialog then
            EditModeSystemSettingsDialog:UpdateButtons(self)
          end
        end
      end
    end
  end)

  -- Initialize Global Hooks if not already done
  if not self.HooksInitialized then
    self:InitHooks()
  end

  -- Enter/Exit Events
  local function editMode_OnEnter()
    self.pendingSettings = nil
    self.hasActiveChanges = false
    self.isSelected = false
    frame:Show()
    if frame.Selection then
      frame.Selection:Show()
      frame.Selection:ShowHighlighted()
    end
  end

  local function editMode_OnExit()
    if frame.hasActiveChanges then
      BUII_EditModeUtils:ApplySavedPosition(frame, frame.buiiDbKey)
      frame.hasActiveChanges = false
      self.pendingSettings = nil
    end
    frame.isSelected = false
    frame.lastKnownPosition = nil
    if frame.Selection then
      frame.Selection:Hide()
    end
    if frame.OnApplySettings then
      frame.OnApplySettings(frame) -- Often used to update visibility
    end
  end

  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_EditMode_" .. systemEnum .. "_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_EditMode_" .. systemEnum .. "_OnExit")

  -- Initial Apply
  BUII_EditModeUtils:ApplySavedPosition(frame, dbKey)
end

function BUII_EditModeUtils:InitHooks()
  if self.HooksInitialized then
    return
  end

  if EditModeSystemSettingsDialog then
    hooksecurefunc(EditModeSystemSettingsDialog, "UpdateSettings", OnUpdateSettings)
    hooksecurefunc(EditModeSystemSettingsDialog, "OnSettingValueChanged", OnSettingValueChanged)
  end

  if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "RevertAllChanges", function()
      for _, frame in pairs(self.RegisteredSystems) do
        frame:UpdateSystem()
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "RevertSystemChanges", function(mgr, systemFrame)
      if self.RegisteredSystems[systemFrame.system] then
        systemFrame:RevertChanges()
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "SelectSystem", function(mgr, systemFrame)
      if systemFrame and self.RegisteredSystems[systemFrame.system] then
        local frame = self.RegisteredSystems[systemFrame.system]
        frame.isSelected = true
        
        local point, _, relativePoint, offsetX, offsetY = frame:GetPoint()
        frame.lastKnownPosition = {
          point = point,
          relativePoint = relativePoint,
          offsetX = offsetX,
          offsetY = offsetY,
        }
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "ClearSelectedSystem", function()
      for _, frame in pairs(self.RegisteredSystems) do
        frame.isSelected = false
        frame.lastKnownPosition = nil
      end
    end)

    hooksecurefunc(EditModeManagerFrame, "SelectLayout", function()
      for _, frame in pairs(self.RegisteredSystems) do
        frame.pendingSettings = nil
        frame.hasActiveChanges = false
        frame.isSelected = false
        frame.lastKnownPosition = nil
        self:ApplySavedPosition(frame, frame.buiiDbKey, true)
      end
    end)
  end

  EventRegistry:RegisterCallback("EditMode.SavedLayouts", function()
    for _, frame in pairs(self.RegisteredSystems) do
      self:CommitPendingChanges(frame, frame.buiiDbKey)
    end
  end, "BUII_EditModeUtils_OnSave")

  self.HooksInitialized = true
end
