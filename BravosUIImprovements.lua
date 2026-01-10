local addonName, addon = ...
local spellBarHookSet = false
local stanceBarHookSet = false
local castingBarHookSet = false

local function handleTargetFrameSpellBar_OnUpdate(self, arg1, ...)
  if BUIIDatabase["castbar_on_top"] then
    self:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 45, 20)
  end
end

local function handleFocusFrameSpellBar_OnUpdate(self, arg1, ...)
  if BUIIDatabase["castbar_on_top"] then
    if FocusFrame.smallSize then
      self:SetPoint("TOPLEFT", FocusFrame, "TOPLEFT", 38, 20)
    else
      self:SetPoint("TOPLEFT", FocusFrame, "TOPLEFT", 45, 20)
    end
  end
end

local function setPlayerClassColor()
  local _, const_class = UnitClass("player")
  local r, g, b = GetClassColor(const_class)
  local playerHealthBar

  if PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea ~= nil then
    playerHealthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar
  else
    playerHealthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar
  end

  if _G["BUIIOptionsPanelHealthClassColor"]:GetChecked() then
    playerHealthBar:SetStatusBarDesaturated(true)
    playerHealthBar:SetStatusBarColor(r, g, b)
    BUIIDatabase["class_color"] = true
  else
    playerHealthBar:SetStatusBarDesaturated(false)
    playerHealthBar:SetStatusBarColor(1, 1, 1)
    BUIIDatabase["class_color"] = false
  end
end

local function setCastBarOnTop(setOnTop)
  if setOnTop then
    if not spellBarHookSet then
      TargetFrameSpellBar:HookScript("OnUpdate", handleTargetFrameSpellBar_OnUpdate)
      FocusFrameSpellBar:HookScript("OnUpdate", handleFocusFrameSpellBar_OnUpdate)
      spellBarHookSet = true
    end
    BUIIDatabase["castbar_on_top"] = true
  else
    BUIIDatabase["castbar_on_top"] = false
  end
end

local function setSaneBagSorting(setSane)
  if setSane then
    C_Container.SetSortBagsRightToLeft(true)
    C_Container.SetInsertItemsLeftToRight(false)
    BUIIDatabase["sane_bag_sort"] = true
  else
    C_Container.SetSortBagsRightToLeft(false)
    C_Container.SetInsertItemsLeftToRight(false)
    BUIIDatabase["sane_bag_sort"] = false
  end
end

local function stanceBar_OnUpdate()
  if BUIICharacterDatabase["hide_stance_bar"] then
    local point, _, relativePoint, xOffset, yOffset = StanceBar:GetPoint()
    if
      point ~= "TOPLEFT"
      or relativePoint ~= "TOPLEFT"
      or math.ceil(xOffset) ~= math.ceil(0 - (StanceBar:GetWidth() + 100))
      or yOffset ~= 0
    then
      StanceBar:ClearAllPoints()
      StanceBar:SetClampedToScreen(false)
      StanceBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", math.ceil(0 - (StanceBar:GetWidth() + 100)), 0)
    end
  end
end

local function setHideStanceBar(shouldHide)
  if shouldHide then
    local point, _, relativePoint, xOffset, yOffset = StanceBar:GetPoint()
    BUIICharacterDatabase["stance_bar_position"] = {
      point = point,
      relativeTo = nil,
      relativePoint = relativePoint,
      xOffset = xOffset,
      yOffset = yOffset,
    }

    -- The StanceBar gets tainted if we just hide it (It also can't be hidden in combat)
    -- so we just chuck it outside the screen to hide it
    BUIICharacterDatabase["hide_stance_bar"] = shouldHide
    StanceBar:ClearAllPoints()
    StanceBar:SetClampedToScreen(false)
    StanceBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", math.ceil(0 - (StanceBar:GetWidth() + 100)), 0)
    if not stanceBarHookSet then
      StanceBar:HookScript("OnUpdate", stanceBar_OnUpdate)
      stanceBarHookSet = true
    end
  else
    BUIICharacterDatabase["hide_stance_bar"] = shouldHide
    StanceBar:ClearAllPoints()
    StanceBar:SetClampedToScreen(true)
    StanceBar:SetPoint(
      BUIICharacterDatabase["stance_bar_position"]["point"],
      UIParent,
      BUIICharacterDatabase["stance_bar_position"]["relativePoint"],
      BUIICharacterDatabase["stance_bar_position"]["xOffset"],
      BUIICharacterDatabase["stance_bar_position"]["yOffset"]
    )
  end
end

local function editMode_OnExit()
  if BUIICharacterDatabase["hide_stance_bar"] then
    StanceBar:ClearAllPoints()
    StanceBar:SetClampedToScreen(false)
    StanceBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0 - (StanceBar:GetWidth() + 100), 0)
  end
end

local function showPlayerCastBarIcon(shouldShow)
  if shouldShow then
    local point, relativeTo, relativePoint = PlayerCastingBarFrame.Icon:GetPoint()
    PlayerCastingBarFrame.Icon:SetSize(24, 24)
    PlayerCastingBarFrame.Icon:SetPoint(point, relativeTo, relativePoint, -2, -6)
    PlayerCastingBarFrame.Icon:Show()
    BUIIDatabase["castbar_icon"] = true

    if not castingBarHookSet then
      PlayerCastingBarFrame:HookScript("OnEvent", function()
        if BUIIDatabase["castbar_icon"] then
          PlayerCastingBarFrame.Icon:Show()
        else
          PlayerCastingBarFrame.Icon:Hide()
        end
      end)
      castingBarHookSet = true
    end
  else
    PlayerCastingBarFrame.Icon:Hide()
    BUIIDatabase["castbar_icon"] = false
  end
end

local function handleUnitFramePortraitUpdate(self)
  local healthBar = self.HealthBar

  if self.unit == "player" then
    -- If we're in a vehicle we want to color the pet frame instead
    -- as that's where the player will be
    if UnitInVehicle(self.unit) then
      healthBar = PetFrameHealthBar
    else
      if PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea ~= nil then
        healthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar
      else
        healthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBar
      end
    end
  elseif self.unit == "pet" then
    healthBar = PetFrameHealthBar
  elseif self.unit == "target" then
    if TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar ~= nil then
      healthBar = TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar
    else
      healthBar = TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar
    end
  elseif self.unit == "focus" then
    if FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBar ~= nil then
      healthBar = FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBar
    else
      healthBar = FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar
    end
  elseif self.unit == "vehicle" then
    if PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea ~= nil then
      healthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar
    else
      healthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBar
    end
  end

  -- If we've reached this point and healthBar isn't valid bail out
  if not healthBar then
    return
  end

  if UnitIsPlayer(self.unit) and UnitIsConnected(self.unit) and BUIIDatabase["class_color"] then
    local _, const_class = UnitClass(self.unit)
    local r, g, b = GetClassColor(const_class)
    healthBar:SetStatusBarDesaturated(true)
    healthBar:SetStatusBarColor(r, g, b)
  elseif UnitIsPlayer(self.unit) and not UnitIsConnected(self.unit) then
    healthBar:SetStatusBarDesaturated(true)
    healthBar:SetStatusBarColor(1, 1, 1)
  elseif BUIIDatabase["class_color"] then
    healthBar:SetStatusBarDesaturated(true)
    healthBar:SetStatusBarColor(0, 1, 0)
  else
    healthBar:SetStatusBarDesaturated(false)
    healthBar:SetStatusBarColor(1, 1, 1)
  end
end

function BUII_OnLoadHandler(self)
  self:RegisterEvent("ADDON_LOADED")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_Improvements_OnExit")
  hooksecurefunc("UnitFramePortrait_Update", handleUnitFramePortraitUpdate)

  self.name = "Bravo's UI Improvements"
  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(self)
  else
    local category, layout = Settings.RegisterCanvasLayoutCategory(self, self.name)
    Settings.RegisterAddOnCategory(category)
    addon.settingsCategory = category
  end
end

local function BUII_RegisterEditModeSystem()
  -- Define the minimum necessary for the settings dialog to work without crashing Blizzard's ipairs
  if
    EditModeSettingDisplayInfoManager
    and not EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[Enum.EditModeSystem.BUII_GroupTools]
  then
    EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[Enum.EditModeSystem.BUII_GroupTools] = {}
  end
end

function BUII_OnEventHandler(self, event, arg1, ...)
  if event == "PLAYER_SPECIALIZATION_CHANGED" then
    -- Force restore positions for all our custom frames
    if BUII_EditModeUtils and BUII_EditModeUtils.RegisteredSystems then
      for _, frame in pairs(BUII_EditModeUtils.RegisteredSystems) do
        if frame and frame.buiiDbKey then
          BUII_EditModeUtils:ApplySavedPosition(frame, frame.buiiDbKey, true)
        end
      end
    end
    -- Also update Stance Tracker explicitly as its content changes with spec
    if BUII_StanceTracker_GetDB and BUII_StanceTracker_GetDB()["stance_tracker"] then
      BUII_StanceTracker_Enable()
    end

    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  elseif event == "ADDON_LOADED" then
    if arg1 == "BravosUIImprovements" then
      BUII_RegisterEditModeSystem()

      -- Initialize BUIIDatabase if it doesn't exist
      if BUIIDatabase == nil then
        BUIIDatabase = {}
      end

      -- Initialize BUIICharacterDatabase if it doesn't exist
      if BUIICharacterDatabase == nil then
        BUIICharacterDatabase = {}
      end

      -- Initialize main file settings (class_color, castbar_icon, castbar_on_top, sane_bag_sort, hide_stance_bar)
      if BUIIDatabase["class_color"] == nil then
        BUIIDatabase["class_color"] = false
      end
      if BUIIDatabase["castbar_icon"] == nil then
        BUIIDatabase["castbar_icon"] = false
      end
      if BUIIDatabase["castbar_on_top"] == nil then
        BUIIDatabase["castbar_on_top"] = false
      end
      if BUIIDatabase["sane_bag_sort"] == nil then
        BUIIDatabase["sane_bag_sort"] = false
      end

      -- Initialize character-specific main file settings
      if BUIICharacterDatabase["hide_stance_bar"] == nil then
        BUIICharacterDatabase["hide_stance_bar"] = false
      end
      if BUIICharacterDatabase["stance_bar_position"] == nil then
        local point, _, relativePoint, xOffset, yOffset = StanceBar:GetPoint()
        BUIICharacterDatabase["stance_bar_position"] = {
          point = point,
          relativeTo = nil,
          relativePoint = relativePoint,
          xOffset = xOffset,
          yOffset = yOffset,
        }
      end

      -- Call module initialization functions
      BUII_CastBarTimers_InitDB()
      BUII_QuickKeybindModeShortcut_InitDB()
      BUII_ImprovedEditMode_InitDB()
      BUII_TooltipImprovements_InitDB()
      BUII_CallToArms_InitDB()
      BUII_Ion_InitDB()
      BUII_GearAndTalentLoadout_InitDB()
      BUII_CombatState_InitDB()
      BUII_ReadyCheck_InitDB()
      BUII_GroupTools_InitDB()
      BUII_StanceTracker_InitDB()
      BUII_StatPanel_InitDB()
      BUII_ResourceTracker_InitDB()

      self:UnregisterEvent("ADDON_LOADED")
    elseif arg1 == "Blizzard_EditMode" then
      BUII_RegisterEditModeSystem()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    if BUIIDatabase["class_color"] then
      _G["BUIIOptionsPanelHealthClassColor"]:SetChecked(true)
      setPlayerClassColor()
    end

    if BUIIDatabase["castbar_timers"] then
      BUII_CastBarTimersEnable()
      _G["BUIIOptionsPanelCastBarTimers"]:SetChecked(true)
    end

    if BUIIDatabase["castbar_icon"] then
      showPlayerCastBarIcon(true)
      _G["BUIIOptionsPanelCastBarIcon"]:SetChecked(true)
    end

    if BUIIDatabase["castbar_on_top"] then
      setCastBarOnTop(true)
      _G["BUIIOptionsPanelCastBarOnTop"]:SetChecked(true)
    end

    if BUIIDatabase["sane_bag_sort"] then
      setSaneBagSorting(true)
      _G["BUIIOptionsPanelSaneCombinedBagSorting"]:SetChecked(true)
    end

    if BUIICharacterDatabase["hide_stance_bar"] then
      setHideStanceBar(true)
      _G["BUIIOptionsPanelHideStanceBar"]:SetChecked(true)
    end

    if BUIIDatabase["quick_keybind_shortcut"] then
      BUII_QuickKeybindModeShortcutEnable()
      _G["BUIIOptionsPanelQuickKeybindShortcut"]:SetChecked(true)
    end

    if BUIIDatabase["improved_edit_mode"] then
      BUII_ImprovedEditModeEnable()
      _G["BUIIOptionsPanelImprovedEditMode"]:SetChecked(true)
    end

    if BUIIDatabase["tooltip_expansion"] then
      BUII_TooltipImprovements_Enabled()
      _G["BUIIOptionsPanelTooltipExpansion"]:SetChecked(true)
    end

    if BUIIDatabase["call_to_arms"] then
      BUII_CallToArms_Enable()
      _G["BUIIOptionsPanelCallToArms"]:SetChecked(true)
    end

    if BUIIDatabase["ion_mode"] then
      BUII_Ion_Enable()
      _G["BUIIOptionsPanelIon"]:SetChecked(true)
    end

    if BUIIDatabase["gear_talent_loadout"] then
      BUII_GearAndTalentLoadout_Enable()
      _G["BUIIOptionsPanelGearAndTalentLoadout"]:SetChecked(true)
    end

    if BUIIDatabase["combat_state"] then
      BUII_CombatState_Enable()
      _G["BUIIOptionsPanelCombatState"]:SetChecked(true)
    end

    if BUIIDatabase["ready_check"] then
      BUII_ReadyCheck_Enable()
      _G["BUIIOptionsPanelReadyCheck"]:SetChecked(true)
    end

    if BUIIDatabase["group_tools"] then
      BUII_GroupTools_Enable()
      _G["BUIIOptionsPanelGroupTools"]:SetChecked(true)
    end

    if BUIIDatabase["stance_tracker"] then
      BUII_StanceTracker_Enable()
      _G["BUIIOptionsPanelStanceTracker"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelStanceTracker"]:SetChecked(false)
    end

    if BUIIDatabase["stat_panel"] then
      BUII_StatPanel_Enable()
      _G["BUIIOptionsPanelStatPanel"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelStatPanel"]:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
      _G["BUIIOptionsPanelResourceTracker"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelResourceTracker"]:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_shaman"] then
      _G["BUIIOptionsPanelResourceTrackerShaman"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelResourceTrackerShaman"]:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_demonhunter"] then
      _G["BUIIOptionsPanelResourceTrackerDemonHunter"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelResourceTrackerDemonHunter"]:SetChecked(false)
    end

    if BUIIDatabase["stance_tracker_druid"] then
      _G["BUIIOptionsPanelStanceTrackerDruid"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelStanceTrackerDruid"]:SetChecked(false)
    end

    if BUIIDatabase["stance_tracker_paladin"] then
      _G["BUIIOptionsPanelStanceTrackerPaladin"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelStanceTrackerPaladin"]:SetChecked(false)
    end

    if BUIIDatabase["stance_tracker_rogue"] then
      _G["BUIIOptionsPanelStanceTrackerRogue"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelStanceTrackerRogue"]:SetChecked(false)
    end

    if BUIIDatabase["stance_tracker_warrior"] then
      _G["BUIIOptionsPanelStanceTrackerWarrior"]:SetChecked(true)
    else
      _G["BUIIOptionsPanelStanceTrackerWarrior"]:SetChecked(false)
    end
  end
end

function BUII_HealthClassColorCheckButton_OnClick(self)
  setPlayerClassColor()
end

function BUII_CastBarTimersCheckButton_OnClick(self)
  if self:GetChecked() then
    BUII_CastBarTimersEnable()
    BUIIDatabase["castbar_timers"] = true
  else
    BUII_CastBarTimersDisable()
    BUIIDatabase["castbar_timers"] = false
  end
end

function BUII_CastBarIconCheckButton_OnClick(self)
  if self:GetChecked() then
    showPlayerCastBarIcon(true)
  else
    showPlayerCastBarIcon(false)
  end
end

function BUII_CastBarOnTopCheckButton_OnClick(self)
  if self:GetChecked() then
    setCastBarOnTop(true)
  else
    setCastBarOnTop(false)
  end
end

function BUII_SaneCombinedBagSortingCheckButton_OnClick(self)
  setSaneBagSorting(self:GetChecked())
end

function BUII_HideStanceBar_OnClick(self)
  setHideStanceBar(self:GetChecked())
end

function BUII_QuickKeybindShortcut_OnClick(self)
  if self:GetChecked() then
    BUII_QuickKeybindModeShortcutEnable()
    BUIIDatabase["quick_keybind_shortcut"] = true
  else
    BUII_QuickKeybindModeShortcutDisable()
    BUIIDatabase["quick_keybind_shortcut"] = false
  end
end

function BUII_ImprovedEditMode_OnClick(self)
  if self:GetChecked() then
    BUII_ImprovedEditModeEnable()
    BUIIDatabase["improved_edit_mode"] = true
  else
    BUII_ImprovedEditModeDisable()
    BUIIDatabase["improved_edit_mode"] = false
  end
end

function BUII_TooltipExpansion_OnClick(self)
  if self:GetChecked() then
    BUII_TooltipImprovements_Enabled()
    BUIIDatabase["tooltip_expansion"] = true
  else
    BUII_TooltipImprovements_Disable()
    BUIIDatabase["tooltip_expansion"] = false
  end
end

function BUII_CallToArms_OnClick(self)
  if self:GetChecked() then
    BUII_CallToArms_Enable()
    BUIIDatabase["call_to_arms"] = true
  else
    BUII_CallToArms_Disable()
    BUIIDatabase["call_to_arms"] = false
  end
end

function BUII_Ion_OnClick(self)
  if self:GetChecked() then
    BUII_Ion_Enable()
    BUIIDatabase["ion_mode"] = true
  else
    BUII_Ion_Disable()
    BUIIDatabase["ion_mode"] = false
  end
end

function BUII_GearAndTalentLoadout_OnClick(self)
  if self:GetChecked() then
    BUII_GearAndTalentLoadout_Enable()
    BUIIDatabase["gear_talent_loadout"] = true
  else
    BUII_GearAndTalentLoadout_Disable()
    BUIIDatabase["gear_talent_loadout"] = false
  end
end

function BUII_CombatState_OnClick(self)
  if self:GetChecked() then
    BUII_CombatState_Enable()
    BUIIDatabase["combat_state"] = true
  else
    BUII_CombatState_Disable()
    BUIIDatabase["combat_state"] = false
  end
end

function BUII_ReadyCheck_OnClick(self)
  if self:GetChecked() then
    BUII_ReadyCheck_Enable()
    BUIIDatabase["ready_check"] = true
  else
    BUII_ReadyCheck_Disable()
    BUIIDatabase["ready_check"] = false
  end
end

function BUII_GroupTools_OnClick(self)
  if self:GetChecked() then
    BUII_GroupTools_Enable()
    BUIIDatabase["group_tools"] = true
  else
    BUII_GroupTools_Disable()
    BUIIDatabase["group_tools"] = false
  end
end

function BUII_StanceTracker_OnClick(self)
  if self:GetChecked() then
    BUII_StanceTracker_Enable()
    BUIIDatabase["stance_tracker"] = true
  else
    BUII_StanceTracker_Disable()
    BUIIDatabase["stance_tracker"] = false
  end
end

function BUII_StanceTrackerDruid_OnClick(self)
  BUIIDatabase["stance_tracker_druid"] = self:GetChecked()
  if BUIIDatabase["stance_tracker"] then
    BUII_StanceTracker_Enable()
  end
end

function BUII_StanceTrackerPaladin_OnClick(self)
  BUIIDatabase["stance_tracker_paladin"] = self:GetChecked()
  if BUIIDatabase["stance_tracker"] then
    BUII_StanceTracker_Enable()
  end
end

function BUII_StanceTrackerRogue_OnClick(self)
  BUIIDatabase["stance_tracker_rogue"] = self:GetChecked()
  if BUIIDatabase["stance_tracker"] then
    BUII_StanceTracker_Enable()
  end
end

function BUII_StanceTrackerWarrior_OnClick(self)
  BUIIDatabase["stance_tracker_warrior"] = self:GetChecked()
  if BUIIDatabase["stance_tracker"] then
    BUII_StanceTracker_Enable()
  end
end

function BUII_ResourceTracker_OnClick(self)
  if self:GetChecked() then
    BUII_ResourceTracker_Enable()
    BUIIDatabase["resource_tracker"] = true
  else
    BUII_ResourceTracker_Disable()
    BUIIDatabase["resource_tracker"] = false
  end
end

function BUII_ResourceTrackerShaman_OnClick(self)
  BUIIDatabase["resource_tracker_shaman"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_ResourceTrackerDemonHunter_OnClick(self)
  BUIIDatabase["resource_tracker_demonhunter"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_StatPanel_OnClick(self)
  if self:GetChecked() then
    BUII_StatPanel_Enable()
    BUIIDatabase["stat_panel"] = true
  else
    BUII_StatPanel_Disable()
    BUIIDatabase["stat_panel"] = false
  end
end
