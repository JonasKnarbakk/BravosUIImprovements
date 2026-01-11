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

  local panel = BUIIOptionsPanel
  local defaultUIContent = panel.ScrollFrame.ScrollChild.DefaultUIContent

  if defaultUIContent.HealthClassColor:GetChecked() then
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

local function BUII_RefreshAllModuleFonts()
  -- Update all active modules that use fonts
  if BUIIDatabase["stat_panel"] and BUII_StatPanel_Refresh then
    BUII_StatPanel_Refresh()
  end
  if BUIIDatabase["stance_tracker"] and BUII_StanceTracker_Refresh then
    BUII_StanceTracker_Refresh()
  end
  if BUIIDatabase["resource_tracker"] and BUII_ResourceTracker_Refresh then
    BUII_ResourceTracker_Refresh()
  end
  if BUIIDatabase["gear_talent_loadout"] and BUII_GearAndTalentLoadout_Refresh then
    BUII_GearAndTalentLoadout_Refresh()
  end
  if BUIIDatabase["combat_state"] and BUII_CombatState_Refresh then
    BUII_CombatState_Refresh()
  end
  if BUIIDatabase["ready_check"] and BUII_ReadyCheck_Refresh then
    BUII_ReadyCheck_Refresh()
  end
  if BUIIDatabase["call_to_arms"] and BUII_CallToArms_Refresh then
    BUII_CallToArms_Refresh()
  end
  if BUIIDatabase["group_tools"] and BUII_GroupTools_Refresh then
    BUII_GroupTools_Refresh()
  end
  if BUIIDatabase["loot_spec"] and BUII_LootSpec_Refresh then
    BUII_LootSpec_Refresh()
  end
end

function BUII_OptionsPanel_SelectTab(tabNum)
  local panel = BUIIOptionsPanel
  local scrollChild = panel.ScrollFrame.ScrollChild

  -- Hide all tab contents
  scrollChild.DefaultUIContent:Hide()
  scrollChild.WeakAuraContent:Hide()

  -- Show selected tab content
  if tabNum == 1 then
    scrollChild.DefaultUIContent:Show()
    PanelTemplates_SetTab(panel, 1)
  elseif tabNum == 2 then
    scrollChild.WeakAuraContent:Show()
    PanelTemplates_SetTab(panel, 2)
  end
end

local function BUII_InitializeFontDropdowns()
  local panel = BUIIOptionsPanel
  local weakAura = panel.ScrollFrame.ScrollChild.WeakAuraContent
  local fontDropdown = weakAura.FontLabel
  local outlineDropdown = weakAura.OutlineLabel

  -- Get actual dropdown frames (children of the label frames)
  fontDropdown = weakAura.FontDropdown
  outlineDropdown = weakAura.OutlineDropdown

  -- Set dropdown widths
  UIDropDownMenu_SetWidth(fontDropdown, 150)
  UIDropDownMenu_SetWidth(outlineDropdown, 150)

  -- Initialize Font Dropdown
  UIDropDownMenu_Initialize(fontDropdown, function(self, level)
    local fonts = BUII_GetAvailableFonts()
    for _, font in ipairs(fonts) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = font.name
      info.arg1 = font.name
      info.func = function(self, fontName)
        BUIIDatabase["font_name"] = fontName
        UIDropDownMenu_SetText(fontDropdown, fontName)
        CloseDropDownMenus()
        BUII_RefreshAllModuleFonts()
      end
      info.checked = (BUIIDatabase["font_name"] == font.name)
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  UIDropDownMenu_SetText(fontDropdown, BUIIDatabase["font_name"] or "Expressway")

  -- Initialize Outline Dropdown
  UIDropDownMenu_Initialize(outlineDropdown, function(self, level)
    for _, option in ipairs(BUII_OUTLINE_OPTIONS) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = option.name
      info.arg1 = option.value
      info.arg2 = option.name
      info.func = function(self, outlineValue, outlineName)
        BUIIDatabase["font_outline"] = outlineValue
        UIDropDownMenu_SetText(outlineDropdown, outlineName)
        CloseDropDownMenus()
        BUII_RefreshAllModuleFonts()
      end
      info.checked = (BUIIDatabase["font_outline"] == option.value)
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  -- Find and set the display name for the current outline value
  local currentOutlineName = "Outline"
  for _, option in ipairs(BUII_OUTLINE_OPTIONS) do
    if option.value == (BUIIDatabase["font_outline"] or "OUTLINE") then
      currentOutlineName = option.name
      break
    end
  end
  UIDropDownMenu_SetText(outlineDropdown, currentOutlineName)
end

function BUII_OnLoadHandler(self)
  self:RegisterEvent("ADDON_LOADED")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_Improvements_OnExit")
  hooksecurefunc("UnitFramePortrait_Update", handleUnitFramePortraitUpdate)

  -- Register with modern Settings API
  if Settings and Settings.RegisterVerticalLayoutCategory then
    -- Create main category with vertical layout
    local mainCategory, mainLayout = Settings.RegisterVerticalLayoutCategory("Bravo's UI Improvements")
    mainCategory.ID = "BravosUIImprovements"

    -- Create Default UI subcategory
    local defaultUIPanel = BUIIOptionsPanel.ScrollFrame.ScrollChild.DefaultUIContent
    defaultUIPanel.name = "Default UI"
    local defaultUICategory, defaultUILayout =
      Settings.RegisterCanvasLayoutSubcategory(mainCategory, defaultUIPanel, "Default UI")
    defaultUICategory.ID = "BravosUIImprovements_DefaultUI"

    -- Create WeakAura-like subcategory
    local weakAuraPanel = BUIIOptionsPanel.ScrollFrame.ScrollChild.WeakAuraContent
    weakAuraPanel.name = "WeakAura-like"
    local weakAuraCategory, weakAuraLayout =
      Settings.RegisterCanvasLayoutSubcategory(mainCategory, weakAuraPanel, "WeakAura-like")
    weakAuraCategory.ID = "BravosUIImprovements_WeakAura"

    -- Register the addon category
    Settings.RegisterAddOnCategory(mainCategory)

    -- Hide manual tabs since Settings API provides category navigation
    if BUIIOptionsPanel.Tab1 then
      BUIIOptionsPanel.Tab1:Hide()
    end
    if BUIIOptionsPanel.Tab2 then
      BUIIOptionsPanel.Tab2:Hide()
    end

    addon.settingsCategory = mainCategory
    addon.defaultUICategory = defaultUICategory
    addon.weakAuraCategory = weakAuraCategory
  else
    -- Fallback for older interface
    self.name = "Bravo's UI Improvements"
    InterfaceOptions_AddCategory(self)
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
      if BUIIDatabase["font_name"] == nil then
        BUIIDatabase["font_name"] = "Expressway"
      end
      if BUIIDatabase["font_outline"] == nil then
        BUIIDatabase["font_outline"] = "OUTLINE"
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
      BUII_LootSpec_InitDB()

      -- Initialize font and outline dropdowns
      BUII_InitializeFontDropdowns()

      self:UnregisterEvent("ADDON_LOADED")
    elseif arg1 == "Blizzard_EditMode" then
      BUII_RegisterEditModeSystem()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    local panel = BUIIOptionsPanel
    local defaultUI = panel.ScrollFrame.ScrollChild.DefaultUIContent
    local weakAura = panel.ScrollFrame.ScrollChild.WeakAuraContent

    if BUIIDatabase["class_color"] then
      defaultUI.HealthClassColor:SetChecked(true)
      setPlayerClassColor()
    end

    if BUIIDatabase["castbar_timers"] then
      BUII_CastBarTimersEnable()
      defaultUI.CastBarTimers:SetChecked(true)
    end

    if BUIIDatabase["castbar_icon"] then
      showPlayerCastBarIcon(true)
      defaultUI.CastBarIcon:SetChecked(true)
    end

    if BUIIDatabase["castbar_on_top"] then
      setCastBarOnTop(true)
      defaultUI.CastBarOnTop:SetChecked(true)
    end

    if BUIIDatabase["sane_bag_sort"] then
      setSaneBagSorting(true)
      defaultUI.SaneCombinedBagSorting:SetChecked(true)
    end

    if BUIICharacterDatabase["hide_stance_bar"] then
      setHideStanceBar(true)
      defaultUI.HideStanceBar:SetChecked(true)
    end

    if BUIIDatabase["quick_keybind_shortcut"] then
      BUII_QuickKeybindModeShortcutEnable()
      defaultUI.QuickKeybindShortcut:SetChecked(true)
    end

    if BUIIDatabase["improved_edit_mode"] then
      BUII_ImprovedEditModeEnable()
      defaultUI.ImprovedEditMode:SetChecked(true)
    end

    if BUIIDatabase["tooltip_expansion"] then
      BUII_TooltipImprovements_Enabled()
      defaultUI.TooltipExpansion:SetChecked(true)
    end

    if BUIIDatabase["call_to_arms"] then
      BUII_CallToArms_Enable()
      weakAura.CallToArms:SetChecked(true)
    end

    if BUIIDatabase["ion_mode"] then
      BUII_Ion_Enable()
      weakAura.Ion:SetChecked(true)
    end

    if BUIIDatabase["gear_talent_loadout"] then
      BUII_GearAndTalentLoadout_Enable()
      weakAura.GearAndTalentLoadout:SetChecked(true)
    end

    if BUIIDatabase["combat_state"] then
      BUII_CombatState_Enable()
      weakAura.CombatState:SetChecked(true)
    end

    if BUIIDatabase["ready_check"] then
      BUII_ReadyCheck_Enable()
      weakAura.ReadyCheck:SetChecked(true)
    end

    if BUIIDatabase["group_tools"] then
      BUII_GroupTools_Enable()
      weakAura.GroupTools:SetChecked(true)
    end

    if BUIIDatabase["stance_tracker"] then
      BUII_StanceTracker_Enable()
      weakAura.StanceTracker:SetChecked(true)
    else
      weakAura.StanceTracker:SetChecked(false)
    end

    if BUIIDatabase["stat_panel"] then
      BUII_StatPanel_Enable()
      weakAura.StatPanel:SetChecked(true)
    else
      weakAura.StatPanel:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
      weakAura.ResourceTracker:SetChecked(true)
    else
      weakAura.ResourceTracker:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_shaman"] then
      weakAura.ResourceTrackerShaman:SetChecked(true)
    else
      weakAura.ResourceTrackerShaman:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_demonhunter"] then
      weakAura.ResourceTrackerDemonHunter:SetChecked(true)
    else
      weakAura.ResourceTrackerDemonHunter:SetChecked(false)
    end

    if BUIIDatabase["stance_tracker_druid"] then
      weakAura.StanceTrackerDruid:SetChecked(true)
    else
      weakAura.StanceTrackerDruid:SetChecked(false)
    end

    if BUIIDatabase["stance_tracker_paladin"] then
      weakAura.StanceTrackerPaladin:SetChecked(true)
    else
      weakAura.StanceTrackerPaladin:SetChecked(false)
    end

    if BUIIDatabase["stance_tracker_rogue"] then
      weakAura.StanceTrackerRogue:SetChecked(true)
    else
      weakAura.StanceTrackerRogue:SetChecked(false)
    end

    if BUIIDatabase["stance_tracker_warrior"] then
      weakAura.StanceTrackerWarrior:SetChecked(true)
    else
      weakAura.StanceTrackerWarrior:SetChecked(false)
    end

    if BUIIDatabase["loot_spec"] then
      BUII_LootSpec_Enable()
      weakAura.LootSpec:SetChecked(true)
    else
      weakAura.LootSpec:SetChecked(false)
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

function BUII_LootSpec_OnClick(self)
  if self:GetChecked() then
    BUII_LootSpec_Enable()
    BUIIDatabase["loot_spec"] = true
  else
    BUII_LootSpec_Disable()
    BUIIDatabase["loot_spec"] = false
  end
end
