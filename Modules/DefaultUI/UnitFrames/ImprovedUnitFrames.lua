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

---@type boolean
local isSyncPending = false

---@type table|nil
local playerFrameCache = nil

--- Snapshot atlases / numeric values that we mutate so we can restore them.
---@return nil
local function cachePlayerFrameDefaults()
  if playerFrameCache then
    return
  end

  local container = PlayerFrame.PlayerFrameContainer
  local healthBarsContainer = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer
  local mask = healthBarsContainer.HealthBarMask
  local healthBar = healthBarsContainer.HealthBar

  local function snapshotTextureRegion(region)
    -- Atlas takes precedence over texture path. GetAtlas returns nil if
    -- the region was set via SetTexture instead.
    return {
      atlas = region.GetAtlas and region:GetAtlas() or nil,
      texture = region.GetTextureFilePath and region:GetTextureFilePath() or nil,
    }
  end

  local tempMaxHPLoss = healthBarsContainer.PlayerFrameTempMaxHealthLoss
  local tempMaxHealthLossAnchors = {}
  if tempMaxHPLoss then
    for i = 1, tempMaxHPLoss:GetNumPoints() do
      local point, relativeTo, relativePoint, x, y = tempMaxHPLoss:GetPoint(i)
      tempMaxHealthLossAnchors[#tempMaxHealthLossAnchors + 1] = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        x = x,
        y = y,
      }
    end
  end

  local frameFlash = container.FrameFlash
  local frameFlashAnchors = {}
  for i = 1, frameFlash:GetNumPoints() do
    local point, relativeTo, relativePoint, x, y = frameFlash:GetPoint(i)
    frameFlashAnchors[#frameFlashAnchors + 1] = {
      point = point,
      relativeTo = relativeTo,
      relativePoint = relativePoint,
      x = x,
      y = y,
    }
  end

  playerFrameCache = {
    frameTexture = snapshotTextureRegion(container.FrameTexture),
    alternateFrameTexture = snapshotTextureRegion(container.AlternatePowerFrameTexture),
    frameFlash = snapshotTextureRegion(container.FrameFlash),
    frameFlashAnchors = frameFlashAnchors,
    maskAtlas = mask.GetAtlas and mask:GetAtlas() or nil,
    maskHeight = mask:GetHeight(),
    healthBarHeight = healthBar:GetHeight(),
    healthBarsContainerHeight = healthBarsContainer:GetHeight(),
    tempMaxHealthLossAnchors = tempMaxHealthLossAnchors,
  }
end

--- Re-apply a cached texture region (atlas wins; falls back to texture path).
---@param region table
---@param snapshot table from snapshotTextureRegion
local function restoreTextureRegion(region, snapshot)
  if snapshot.atlas then
    -- useAtlasSize=true preserves the original sizing behavior.
    region:SetAtlas(snapshot.atlas, true)
    region:SetTexCoord(0, 1, 0, 1)
  elseif snapshot.texture then
    region:SetTexture(snapshot.texture)
  end
end

--- Restore the PlayerFrame to its pre-mutation appearance.
---@return nil
local function restorePlayerFrame()
  if not playerFrameCache then
    return
  end

  local container = PlayerFrame.PlayerFrameContainer
  local healthBarsContainer = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer
  local mask = healthBarsContainer.HealthBarMask
  local healthBar = healthBarsContainer.HealthBar

  restoreTextureRegion(container.FrameTexture, playerFrameCache.frameTexture)
  restoreTextureRegion(container.AlternatePowerFrameTexture, playerFrameCache.alternateFrameTexture)
  restoreTextureRegion(container.FrameFlash, playerFrameCache.frameFlash)

  local frameFlash = container.FrameFlash
  if playerFrameCache.frameFlashAnchors and #playerFrameCache.frameFlashAnchors > 0 then
    frameFlash:ClearAllPoints()
    for _, a in ipairs(playerFrameCache.frameFlashAnchors) do
      frameFlash:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
    end
  end

  if playerFrameCache.maskAtlas then
    mask:SetAtlas(playerFrameCache.maskAtlas, true)
  end
  mask:ClearAllPoints()
  mask:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -2, 6)
  if playerFrameCache.maskHeight then
    mask:SetHeight(playerFrameCache.maskHeight)
  end
  mask:Show()

  healthBar:SetHeight(playerFrameCache.healthBarHeight)
  if playerFrameCache.healthBarsContainerHeight then
    healthBarsContainer:SetHeight(playerFrameCache.healthBarsContainerHeight)
  end

  local tempMaxHPLoss = healthBarsContainer.PlayerFrameTempMaxHealthLoss
  if tempMaxHPLoss and playerFrameCache.tempMaxHealthLossAnchors and #playerFrameCache.tempMaxHealthLossAnchors > 0 then
    tempMaxHPLoss:ClearAllPoints()
    for _, a in ipairs(playerFrameCache.tempMaxHealthLossAnchors) do
      tempMaxHPLoss:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
    end
  end

  local divider = healthBarsContainer.TempMaxHealthLossDivider
  if divider then
    divider:SetAlpha(1)
  end

  local leftText = healthBarsContainer.LeftText
  local middleText = healthBarsContainer.HealthBarText
  local rightText = healthBarsContainer.RightText
  leftText:ClearAllPoints()
  leftText:SetPoint("LEFT", healthBarsContainer, "LEFT", 2, 0)
  middleText:ClearAllPoints()
  middleText:SetPoint("CENTER", healthBarsContainer, "CENTER", 0, 0)
  rightText:ClearAllPoints()
  rightText:SetPoint("RIGHT", healthBarsContainer, "RIGHT", -2, 0)

  AlternatePowerBar:RegisterEvent("UNIT_DISPLAYPOWER")

  for i = 1, #resourceBars do
    resourceBars[i]:SetAlpha(1)
  end
end

--- Sync the PlayerFrame with applied settings
---@type frame
---@return nil
local function syncPlayerFrame()
  if not initialized then
    return
  end

  if InCombatLockdown() then
    isSyncPending = true
    return
  end

  if GetImprovedUnitFramesDB()["PlayerFrame"]["hide_power"] then
    cachePlayerFrameDefaults()

    for i = 1, #resourceBars do
      local statusBar = resourceBars[i]
      statusBar:SetAlpha(0)
    end

    local container = PlayerFrame.PlayerFrameContainer
    local healthBarsContainer = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer
    local mask = healthBarsContainer.HealthBarMask
    local healthBar = healthBarsContainer.HealthBar

    local isAlterntePowerFrame = PlayerFrame.activeAlternatePowerBar
    local frameTexture = isAlterntePowerFrame and container.AlternatePowerFrameTexture or container.FrameTexture
    local frameFlash = container.FrameFlash

    frameTexture:SetTexture("Interface\\AddOns\\BravosUIImprovements\\Media\\Textures\\PlayerFrameHealthOnly.tga")
    frameFlash:SetTexture("Interface\\AddOns\\BravosUIImprovements\\Media\\Textures\\PlayerFrameHealthOnly.tga")

    if isAlterntePowerFrame then
      frameTexture:SetTexCoord(unpack(coords.alternateFrameTexture))
      frameFlash:SetTexCoord(unpack(coords.alternateFrameFlash))
    else
      frameTexture:SetTexCoord(unpack(coords.frameTexture))
      frameFlash:SetTexCoord(unpack(coords.frameFlash))
    end

    mask:SetTexture("Interface\\AddOns\\BravosUIImprovements\\Media\\Textures\\PlayerFrameHealthOnlyMask.tga")
    mask:ClearAllPoints()
    mask:SetPoint("TOPLEFT", healthBarsContainer, "TOPLEFT", -2, 6)
    mask:SetPoint("BOTTOMRIGHT", healthBarsContainer, "BOTTOMRIGHT", 2, -10)
    mask:Show()

    healthBar:SetHeight(30.5)
    healthBarsContainer:SetHeight(32)

    local tempMaxHPLoss = healthBarsContainer.PlayerFrameTempMaxHealthLoss
    if tempMaxHPLoss then
      tempMaxHPLoss:ClearAllPoints()
      tempMaxHPLoss:SetPoint("TOPLEFT", healthBarsContainer, "TOPLEFT", 0, 0)
      tempMaxHPLoss:SetPoint("BOTTOMRIGHT", healthBarsContainer, "BOTTOMRIGHT", 0, 0)
    end

    -- Hide the temp max HP loss divider line. The divider's mask atlas has a
    -- fixed ~16px native size with CLAMPTOBLACKADDITIVE wrap mode, which makes
    -- it impossible to stretch cleanly to the taller (32px) container
    local divider = healthBarsContainer.TempMaxHealthLossDivider
    if divider then
      divider:SetAlpha(0)
    end

    local healthTextLeft = healthBarsContainer.LeftText
    local healthTextMiddle = healthBarsContainer.HealthBarText
    local healthTextRight = healthBarsContainer.RightText

    healthTextLeft:SetPoint("LEFT", healthBar, "LEFT")
    healthTextMiddle:SetPoint("CENTER", healthBar, "CENTER")
    healthTextRight:SetPoint("RIGHT", healthBar, "RIGHT")
  else
    restorePlayerFrame()
  end

  isSyncPending = false
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

-- Called when the player leaves combat
local function combat_OnExit()
  if isSyncPending then
    syncPlayerFrame()
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
  if not initialized then
    initialized = true

    if not secureHooksInstalled then
      hooksecurefunc(editModeSettingsDialog, "UpdateSettings", editModeSystemSettingsDialog_OnUpdateSettings)
      hooksecurefunc(
        editModeSettingsDialog,
        "OnSettingValueChanged",
        editModeSystemSettingsDialog_OnSettingValueChanged
      )
      -- Prevent the PlayerFrame from changing back. Both PlayerFrame_Update
      -- and PlayerFrame_UpdateArt can reset our changes — _UpdateArt fires on
      -- alternate-power-bar toggle, vehicle enter/exit, etc., and explicitly
      -- resets HealthBarsContainer:SetHeight(19) and the HealthBarMask atlas
      -- (see PlayerFrame_ToPlayerArt in wow-ui-source PlayerFrame.lua:701-711).
      hooksecurefunc("PlayerFrame_Update", syncPlayerFrame)
      hooksecurefunc("PlayerFrame_UpdateArt", syncPlayerFrame)
      secureHooksInstalled = true
    end

    if GetImprovedUnitFramesDB()["PlayerFrame"]["hide_power"] then
      AlternatePowerBar:UnregisterEvent("UNIT_DISPLAYPOWER")
    end

    -- Combat watcher to sync frame after combat in case we're unable to update it
    EventRegistry:RegisterFrameEventAndCallback(
      "PLAYER_REGEN_ENABLED",
      combat_OnExit,
      "BUII_ImprovedUnitFrames_OnCombatLeave"
    )

    syncPlayerFrame()
  end
end

--- Disables ImprovedUnitFrames and undos any applied setting
---@return nil
function BUII_ImprovedUnitFramesDisable()
  if initialized then
    -- de-init
    initialized = false

    restorePlayerFrame()
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
