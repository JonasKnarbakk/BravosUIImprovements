---@type boolean
local initialized = false
---@type boolean
local secureHooksInstalled = false
---@type string
local databaseKey = "improved_unitframes"
---@type table
local editModeSettingsDialog = EditModeSystemSettingsDialog
---@type table
local editModeManagerFrame = EditModeManagerFrame
---@type boolean
local unitFrameSettingsHasChanges = false

---@type table
local coords = {
  frameTexture = {
    0.00048828125, --left
    0.19384765625, --right
    0.1669921875, --top
    0.3056640625, -- bottom
  },
  frameFlash = {
    0.57568359375, --left
    0.76318359375, --right
    0.1669921875, --top
    0.3056640625, -- bottom
  },
  alternateFrameTexture = {
    0.78466796875, --left
    0.97802734375, --right
    0.0009765625, --top
    0.1455078125, -- bottom
  },
  alternateFrameFlash = {
    0.38720703125, --left
    0.57470703125, --right
    0.1669921875, --top
    0.3056640625, -- bottom
  },
  healthBarMask = {
    2 / 128, --left
    126 / 128, --right
    15 / 64, --top
    52 / 64, -- bottom
  },
}

---@type table
local resourceBars = {
  AlternatePowerBar,
  DemonHunterSoulFragmentsBar,
  EvokerEbonMightBar,
  InsanityBarFrame,
  MonkStaggerBar,
  PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar,
}

---@type number
local enum_ImprovedUnitFramesSetting_HidePower = 20

--- Gets the ImprovedUnitFrames database settings
---@return table|nil
local function GetImprovedUnitFramesDB()
  return BUII_EditModeUtils:GetDB(databaseKey)
end

--- Add a setting type to the EditModeSystemSettingsDialog for the given Frame
---@param settingIndex number index value of added setting, passed back in editModeSystemSettingsDialog_OnSettingValueChanged
---@param optionType number Enum option of type Enum.ChrCustomizationOptionType
---@param settingData table Setting data that will be passed to SetupSetting
local function addOptionToSettingsDialog(settingIndex, optionType, settingData)
  assert(type(settingIndex) == "number")
  assert(type(optionType) == "number")
  assert(type(settingData) == "table")

  local settingPool = editModeSettingsDialog:GetSettingPool(optionType)

  if settingPool then
    local settingFrame = settingPool:Acquire()
    settingFrame:SetPoint("TOPLEFT")
    settingFrame.layoutIndex = settingIndex
    settingFrame:Show()

    editModeSettingsDialog:Show()
    editModeSettingsDialog:Layout()
    settingFrame:SetupSetting(settingData)
  end
end

--- Add the additional settings to PlayerFrame
local function settingsDialogPlayerFrameAddOptions()
  local hidePowerBar = {
    setting = enum_ImprovedUnitFramesSetting_HidePower,
    name = BUII_HUD_EDIT_MODE_PLAYER_FRAME_HIDE_POWER_LABEL,
    type = Enum.EditModeSettingDisplayType.Checkbox,
  }

  local hidePowerBarData = {
    displayInfo = hidePowerBar,
    currentValue = GetImprovedUnitFramesDB()["PlayerFrame"]["hide_power"] == true and 1 or 0,
    settingName = BUII_HUD_EDIT_MODE_PLAYER_FRAME_HIDE_POWER_LABEL,
  }

  addOptionToSettingsDialog(
    enum_ImprovedUnitFramesSetting_HidePower,
    Enum.ChrCustomizationOptionType.Checkbox,
    hidePowerBarData
  )
end

--- Sync the PlayerFrame with applied settings
---@type frame
---@return nil
local function syncPlayerFrame()
  if not initialized or InCombatLockdown() then
    return
  end

  if GetImprovedUnitFramesDB()["PlayerFrame"]["hide_power"] then
    for i = 1, #resourceBars do
      local statusBar = resourceBars[i]
      statusBar:SetAlpha(0)
    end

    local isAlterntePowerFrame = PlayerFrame.activeAlternatePowerBar
    local frameTexture = isAlterntePowerFrame and PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture
      or PlayerFrame.PlayerFrameContainer.FrameTexture
    local frameFlash = PlayerFrame.PlayerFrameContainer.FrameFlash

    frameTexture:SetTexture("Interface\\AddOns\\BravosUIImprovements\\Media\\Textures\\PlayerFrameHealthOnly.tga")
    frameFlash:SetTexture("Interface\\AddOns\\BravosUIImprovements\\Media\\Textures\\PlayerFrameHealthOnly.tga")

    if isAlterntePowerFrame then
      frameTexture:SetTexCoord(unpack(coords.alternateFrameTexture))
      frameFlash:SetTexCoord(unpack(coords.alternateFrameFlash))
    else
      frameTexture:SetTexCoord(unpack(coords.frameTexture))
      frameFlash:SetTexCoord(unpack(coords.frameFlash))
    end

    local mask = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBarMask
    local healthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar
    mask:SetTexture("Interface\\AddOns\\BravosUIImprovements\\Media\\Textures\\PlayerFrameHealthOnlyMask.tga")
    mask:SetPoint("TOPLEFT", healthBar, -3, 7)
    mask:SetPoint("BOTTOMRIGHT", healthBar, 2, -12)
    mask:Show()
    healthBar:SetHeight(30.5)

    local healthTextLeft = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.LeftText
    local healthTextMiddle = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBarText
    local healthTextRight = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.RightText

    healthTextLeft:SetPoint("LEFT", healthBar, "LEFT")
    healthTextMiddle:SetPoint("CENTER", healthBar, "CENTER")
    healthTextRight:SetPoint("RIGHT", healthBar, "RIGHT")
  end
end

-- Mark UnitFrame settings as having unsaved changes
local function markUnitFrameSettingsDirty()
  if unitFrameSettingsHasChanges then
    return
  end
  unitFrameSettingsHasChanges = true
  if editModeManagerFrame then
    editModeManagerFrame:SetHasActiveChanges(true)
  end
end

--- Hooked to EditModeSystemSettingsDialog:UpdateSettings
---@param self table EditModeSystemSettingsDialog
---@param systemFrame table The frame the settings belong to e.g MainMenuBar
local function editModeSystemSettingsDialog_OnUpdateSettings(self, systemFrame)
  if not initialized then
    return
  end

  if systemFrame == self.attachedToSystem then
    local currentFrameName = systemFrame:GetName()

    if not currentFrameName then
      return
    end

    if currentFrameName == "PlayerFrame" then
      settingsDialogPlayerFrameAddOptions()
    end
  end
end

--- Called when a setting value changes
---@param self table EditModeSystemSettingsDialog frame
---@param setting number Enum of the setting getting changed
---@param value number New value for the setting that is changing
local function editModeSystemSettingsDialog_OnSettingValueChanged(self, setting, value)
  if not initialized then
    return
  end

  local currentFrame = self.attachedToSystem
  local currentFrameName = currentFrame:GetName()

  if not currentFrameName then
    return
  end

  if currentFrameName == "PlayerFrame" then
    if setting == enum_ImprovedUnitFramesSetting_HidePower then
      GetImprovedUnitFramesDB()["PlayerFrame"]["hide_power"] = value == 1 and true or false
      syncPlayerFrame()
    end
    -- Mark as having unsaved changes instead of saving immediately
    markUnitFrameSettingsDirty()
  end
end

--- Enables and initializes ImprovedUnitFrames
---@return nil
function BUII_ImprovedUnitFramesEnable()
  print("enable called, initialized: ", initialized)
  if not initialized then
    initialized = true

    if not secureHooksInstalled then
      hooksecurefunc(editModeSettingsDialog, "UpdateSettings", editModeSystemSettingsDialog_OnUpdateSettings)
      hooksecurefunc(
        editModeSettingsDialog,
        "OnSettingValueChanged",
        editModeSystemSettingsDialog_OnSettingValueChanged
      )
      -- Prevent the PlayerFrame from changing back
      hooksecurefunc("PlayerFrame_Update", syncPlayerFrame)
      secureHooksInstalled = true
    end

    if GetImprovedUnitFramesDB()["PlayerFrame"]["hide_power"] then
      AlternatePowerBar:UnregisterEvent("UNIT_DISPLAYPOWER")
    end

    syncPlayerFrame()
  end
end

--- Disables ImprovedUnitFrames and undos any applied setting
---@return nil
function BUII_ImprovedUnitFramesDisable()
  print("disable called, initialized: ", initialized)
  if initialized then
    -- de-init
    initialized = false

    local isAlterntePowerFrame = PlayerFrame.activeAlternatePowerBar
    local frameTexture = isAlterntePowerFrame and PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture
      or PlayerFrame.PlayerFrameContainer.FrameTexture
    local frameFlash = PlayerFrame.PlayerFrameContainer.FrameFlash
    local mask = addonTable.globalUnitVariables.player.healthBarMask
    local healthBar = addonTable.globalUnitVariables.player.healthBar
    if isAlterntePowerFrame then
      frameTexture:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-ClassResource")
      frameTexture:SetTexCoord(0, 1, 0, 1)
      frameFlash:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-ClassResource-InCombat")
      frameFlash:SetTexCoord(0, 1, 0, 1)
    else
      frameTexture:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn")
      frameTexture:SetTexCoord(0, 1, 0, 1)
      frameFlash:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-InCombat")
      frameFlash:SetTexCoord(0, 1, 0, 1)
    end
    mask:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Mask")

    AlternatePowerBar:RegisterEvent("UNIT_DISPLAYPOWER")

    healthBar:SetHeight(20)
    for i = 1, #resourceBars do
      resourceBars[i]:SetAlpha(1)
    end
  end
end

local DB_DEFAULTS = {
  PlayerFrame = {
    hide_power = false,
  },
  TargetFrame = {
    hide_power = false,
  },
}

function BUII_CastBarTimers_InitDB()
  MergeDefaults(BUIIDatabase, DB_DEFAULTS)
end

BUII_RegisterModule({
  dbKey = databaseKey,
  enable = BUII_ImprovedUnitFramesEnable,
  disable = BUII_ImprovedUnitFramesDisable,
  checkboxPath = "defaultUI.ImprovedUnitFrames",
})
