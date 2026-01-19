local addonName, addon = ...
local spellBarHookSet = false
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

local function hideStanceButtons(shouldHide)
  -- Use SetAlpha and EnableMouse instead of Hide/Show to avoid tainting secure frames
  -- This works during combat and doesn't cause taint issues
  if StanceBar and StanceBar.actionButtons then
    for _, button in pairs(StanceBar.actionButtons) do
      if button then
        if shouldHide then
          button:SetAlpha(0)
          button:EnableMouse(false)
        else
          button:SetAlpha(1)
          button:EnableMouse(true)
        end
      end
    end
  end
end

local function setHideStanceBar(shouldHide)
  BUIICharacterDatabase["hide_stance_bar"] = shouldHide
  hideStanceButtons(shouldHide)
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
      if PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar ~= nil then
        PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarDesaturated(
          false
        )
        PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(1, 1, 1)
      else
        PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBar:SetStatusBarDesaturated(false)
        PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBar:SetStatusBarColor(1, 1, 1)
      end
    else
      if PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar ~= nil then
        healthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar
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
  if BUIIDatabase["tank_shield_warning"] and BUII_TankShieldWarning_Refresh then
    BUII_TankShieldWarning_Refresh()
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
  if BUIIDatabase["pet_reminder"] and BUII_PetReminder_Refresh then
    BUII_PetReminder_Refresh()
  end
end

local function BUII_RefreshAllModuleTextures()
  if BUIIDatabase["resource_tracker"] and BUII_ResourceTracker_Refresh then
    BUII_ResourceTracker_Refresh()
  end
end

local BUII_FontObjects = {}
local function BUII_GetFontObject(fontName, fontPath)
  if not BUII_FontObjects[fontName] then
    local name = "BUII_FontObject_" .. fontName:gsub("%s", "")
    local fontObj = CreateFont(name)
    fontObj:SetFont(fontPath, 12, "OUTLINE")
    BUII_FontObjects[fontName] = fontObj
  end
  return BUII_FontObjects[fontName]
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

local function BUII_InitializeDropdowns()
  local panel = BUIIOptionsPanel
  local weakAura = panel.ScrollFrame.ScrollChild.WeakAuraContent
  local fontDropdown = weakAura.FontDropdown
  local outlineDropdown = weakAura.OutlineDropdown
  local textureDropdown = weakAura.TextureDropdown

  -- Set dropdown sizes (using SetSize to avoid potential legacy SetWidth hooks)
  fontDropdown:SetSize(150, 25)
  outlineDropdown:SetSize(150, 25)
  textureDropdown:SetSize(150, 25)

  -- Initialize Font Dropdown
  fontDropdown:SetupMenu(function(dropdown, rootDescription)
    rootDescription:SetTag("MENU_FONT_DROPDOWN")
    rootDescription:SetScrollMode(250)

    local fonts = BUII_GetAvailableFonts()
    for _, font in ipairs(fonts) do
      local fontObj = BUII_GetFontObject(font.name, font.path)

      local isSelected = function()
        return BUIIDatabase["font_name"] == font.name
      end

      local setSelected = function()
        BUIIDatabase["font_name"] = font.name
        dropdown:SetText(font.name)
        if dropdown.Text then
          dropdown.Text:SetFont(font.path, 12, BUIIDatabase["font_outline"] or "OUTLINE")
        end
        BUII_RefreshAllModuleFonts()
      end

      local button = rootDescription:CreateRadio(font.name, isSelected, setSelected)

      button:AddInitializer(function(btn, description, menu)
        if btn.fontString then
          btn.fontString:SetFontObject(fontObj)
        end
      end)
    end
  end)

  local selectedFontName = BUIIDatabase["font_name"] or "Friz Quadrata TT"
  fontDropdown:SetText(selectedFontName)
  if fontDropdown.Text then
    fontDropdown.Text:SetFont(BUII_GetFontPath(), 12, BUIIDatabase["font_outline"] or "OUTLINE")
  end

  -- Initialize Outline Dropdown
  outlineDropdown:SetupMenu(function(dropdown, rootDescription)
    rootDescription:SetTag("MENU_OUTLINE_DROPDOWN")
    rootDescription:SetScrollMode(250)

    for _, option in ipairs(BUII_OUTLINE_OPTIONS) do
      local isSelected = function()
        return BUIIDatabase["font_outline"] == option.value
      end

      local setSelected = function()
        BUIIDatabase["font_outline"] = option.value
        dropdown:SetText(option.name)
        if fontDropdown.Text then
          fontDropdown.Text:SetFont(BUII_GetFontPath(), 12, option.value)
        end
        BUII_RefreshAllModuleFonts()
      end

      rootDescription:CreateRadio(option.name, isSelected, setSelected)
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
  outlineDropdown:SetText(currentOutlineName)

  -- Initialize Texture Dropdown
  textureDropdown:SetupMenu(function(dropdown, rootDescription)
    rootDescription:SetTag("MENU_TEXTURE_DROPDOWN")
    rootDescription:SetScrollMode(250)

    local textures = BUII_GetAvailableTextures()

    local orderedClasses = {
      "WARRIOR",
      "PALADIN",
      "HUNTER",
      "ROGUE",
      "PRIEST",
      "DEATHKNIGHT",
      "SHAMAN",
      "MAGE",
      "WARLOCK",
      "MONK",
      "DRUID",
      "DEMONHUNTER",
      "EVOKER",
    }

    for i, texture in ipairs(textures) do
      local classIndex = ((i - 1) % #orderedClasses) + 1
      local className = orderedClasses[classIndex]
      local color = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }

      local isSelected = function()
        return BUIIDatabase["texture_name"] == texture.name
      end

      local setSelected = function()
        BUIIDatabase["texture_name"] = texture.name
        dropdown:SetText(texture.name)
        if dropdown.PreviewTexture then
          dropdown.PreviewTexture:SetTexture(texture.path)
          dropdown.PreviewTexture:SetVertexColor(color.r, color.g, color.b)
        end
        BUII_RefreshAllModuleTextures()
      end

      local button = rootDescription:CreateRadio(texture.name, isSelected, setSelected)

      button:AddInitializer(function(btn, description, menu)
        local r, g, b = color.r, color.g, color.b
        -- Create background texture if not exists
        if not btn.TexturePreview then
          btn.TexturePreview = btn:AttachTexture()
          btn.TexturePreview:SetAllPoints()
          btn.TexturePreview:SetAlpha(1.0)

          -- Ensure text is on top
          if btn.fontString then
            btn.fontString:SetDrawLayer("OVERLAY")
          end
        end
        btn.TexturePreview:SetTexture(texture.path)
        btn.TexturePreview:SetVertexColor(r, g, b)
        btn.TexturePreview:SetDesaturated(false)
        btn.TexturePreview:Show()
      end)
    end
  end)

  textureDropdown:SetText(BUIIDatabase["texture_name"] or "Solid")
  if not textureDropdown.PreviewTexture then
    textureDropdown.PreviewTexture = textureDropdown:CreateTexture(nil, "ARTWORK")
    textureDropdown.PreviewTexture:SetSize(140, 16)
    textureDropdown.PreviewTexture:SetPoint("CENTER", textureDropdown, "CENTER", 0, 2)
    textureDropdown.PreviewTexture:SetAlpha(1.0)

    if textureDropdown.Text then
      textureDropdown.Text:SetDrawLayer("OVERLAY")
    end
  end
  textureDropdown.PreviewTexture:SetTexture(BUII_GetTexturePath())

  -- Calculate initial color based on selection index
  local textures = BUII_GetAvailableTextures()
  local selectedTextureName = BUIIDatabase["texture_name"] or "Solid"
  local selectedIndex = 1
  for i, texture in ipairs(textures) do
    if texture.name == selectedTextureName then
      selectedIndex = i
      break
    end
  end

  local orderedClasses = {
    "WARRIOR",
    "PALADIN",
    "HUNTER",
    "ROGUE",
    "PRIEST",
    "DEATHKNIGHT",
    "SHAMAN",
    "MAGE",
    "WARLOCK",
    "MONK",
    "DRUID",
    "DEMONHUNTER",
    "EVOKER",
  }
  local classIndex = ((selectedIndex - 1) % #orderedClasses) + 1
  local className = orderedClasses[classIndex]
  local color = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }

  textureDropdown.PreviewTexture:SetVertexColor(color.r, color.g, color.b)
  textureDropdown.PreviewTexture:SetDesaturated(false)
end

function BUII_OnLoadHandler(self)
  self:RegisterEvent("ADDON_LOADED")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
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

    if BUIIDatabase["tank_shield_warning"] then
      --  Enable will only work for Protection Warrior/Paladin
      BUII_TankShieldWarning_Enable()
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
        BUIIDatabase["font_name"] = "Friz Quadrata TT"
      end
      if BUIIDatabase["font_outline"] == nil then
        BUIIDatabase["font_outline"] = "OUTLINE"
      end
      if BUIIDatabase["texture_name"] == nil then
        BUIIDatabase["texture_name"] = "Solid"
      end
      if BUIIDatabase["font_shadow"] == nil then
        BUIIDatabase["font_shadow"] = true
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
      BUII_TankShieldWarning_InitDB()
      BUII_GroupTools_InitDB()
      BUII_StanceTracker_InitDB()
      BUII_StatPanel_InitDB()
      BUII_ResourceTracker_InitDB()
      BUII_LootSpec_InitDB()
      BUII_PetReminder_InitDB()

      -- Initialize font, outline, and texture dropdowns
      BUII_InitializeDropdowns()

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

    if BUIIDatabase["tank_shield_warning"] then
      BUII_TankShieldWarning_Enable()
      weakAura.TankShieldWarning:SetChecked(true)
    else
      weakAura.TankShieldWarning:SetChecked(false)
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

    if BUIIDatabase["resource_tracker_rogue"] then
      weakAura.ResourceTrackerRogue:SetChecked(true)
    else
      weakAura.ResourceTrackerRogue:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_druid"] then
      weakAura.ResourceTrackerDruid:SetChecked(true)
    else
      weakAura.ResourceTrackerDruid:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_mage"] then
      weakAura.ResourceTrackerMage:SetChecked(true)
    else
      weakAura.ResourceTrackerMage:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_warlock"] then
      weakAura.ResourceTrackerWarlock:SetChecked(true)
    else
      weakAura.ResourceTrackerWarlock:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_paladin"] then
      weakAura.ResourceTrackerPaladin:SetChecked(true)
    else
      weakAura.ResourceTrackerPaladin:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_monk"] then
      weakAura.ResourceTrackerMonk:SetChecked(true)
    else
      weakAura.ResourceTrackerMonk:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_deathknight"] then
      weakAura.ResourceTrackerDeathKnight:SetChecked(true)
    else
      weakAura.ResourceTrackerDeathKnight:SetChecked(false)
    end

    if BUIIDatabase["resource_tracker_evoker"] then
      weakAura.ResourceTrackerEvoker:SetChecked(true)
    else
      weakAura.ResourceTrackerEvoker:SetChecked(false)
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

    if BUIIDatabase["pet_reminder"] then
      BUII_PetReminder_Enable()
      weakAura.PetReminder:SetChecked(true)
    else
      weakAura.PetReminder:SetChecked(false)
    end

    if BUIIDatabase["font_shadow"] then
      weakAura.FontShadow:SetChecked(true)
    else
      weakAura.FontShadow:SetChecked(false)
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

function BUII_TankShieldWarning_OnClick(self)
  if self:GetChecked() then
    BUIIDatabase["tank_shield_warning"] = true
    BUII_TankShieldWarning_Enable()
  else
    BUIIDatabase["tank_shield_warning"] = false
    BUII_TankShieldWarning_Disable()
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

function BUII_ResourceTrackerRogue_OnClick(self)
  BUIIDatabase["resource_tracker_rogue"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_ResourceTrackerDruid_OnClick(self)
  BUIIDatabase["resource_tracker_druid"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_ResourceTrackerMage_OnClick(self)
  BUIIDatabase["resource_tracker_mage"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_ResourceTrackerWarlock_OnClick(self)
  BUIIDatabase["resource_tracker_warlock"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_ResourceTrackerPaladin_OnClick(self)
  BUIIDatabase["resource_tracker_paladin"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_ResourceTrackerMonk_OnClick(self)
  BUIIDatabase["resource_tracker_monk"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_ResourceTrackerDeathKnight_OnClick(self)
  BUIIDatabase["resource_tracker_deathknight"] = self:GetChecked()
  if BUIIDatabase["resource_tracker"] then
    BUII_ResourceTracker_Enable()
  end
end

function BUII_ResourceTrackerEvoker_OnClick(self)
  BUIIDatabase["resource_tracker_evoker"] = self:GetChecked()
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

function BUII_PetReminder_OnClick(self)
  if self:GetChecked() then
    BUII_PetReminder_Enable()
    BUIIDatabase["pet_reminder"] = true
  else
    BUII_PetReminder_Disable()
    BUIIDatabase["pet_reminder"] = false
  end
end

function BUII_FontShadow_OnClick(self)
  BUIIDatabase["font_shadow"] = self:GetChecked()
  BUII_RefreshAllModuleFonts()
end
