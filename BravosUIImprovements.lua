local addonName, addon = ...
---@type boolean
local spellBarHookSet = false
---@type boolean
local castingBarHookSet = false

---@class BUIIDatabase
---@field class_color boolean
---@field castbar_icon boolean
---@field castbar_on_top boolean
---@field sane_bag_sort boolean
---@field font_name string
---@field font_outline string
---@field font_shadow boolean
---@field texture_name string
---@field stat_panel boolean
---@field stance_tracker boolean
---@field resource_tracker boolean
---@field gear_talent_loadout boolean
---@field combat_state boolean
---@field ready_check boolean
---@field tank_shield_warning boolean
---@field call_to_arms boolean
---@field group_tools boolean
---@field loot_spec boolean
---@field pet_reminder boolean
---@field missing_buff_reminder boolean
---@field icon_search boolean
---@field icon_tooltips boolean
---@field castbar_timers boolean
---@field quick_keybind_shortcut boolean
---@field improved_edit_mode boolean
---@field tooltip_expansion boolean
---@field ion_mode boolean
---@field resource_tracker_shaman boolean
---@field resource_tracker_demonhunter boolean
---@field resource_tracker_rogue boolean
---@field resource_tracker_druid boolean
---@field resource_tracker_mage boolean
---@field resource_tracker_warlock boolean
---@field resource_tracker_paladin boolean
---@field resource_tracker_priest boolean
---@field resource_tracker_monk boolean
---@field resource_tracker_deathknight boolean
---@field resource_tracker_evoker boolean
---@field resource_tracker_hunter boolean
---@field stance_tracker_druid boolean
---@field stance_tracker_paladin boolean
_G.BUIIDatabase = BUIIDatabase or {}

---@class BUIICharacterDatabase
---@field hide_stance_bar boolean
---@field stance_bar_position table
_G.BUIICharacterDatabase = BUIICharacterDatabase or {}

--- Centralized default values for BUIIDatabase.
--- Core defaults for BravosUIImprovements.lua settings only.
--- Module-specific defaults are defined in each module's InitDB() function.
---@type table<string, any>
local BUII_CORE_DB_DEFAULTS = {
  class_color = false,
  castbar_icon = false,
  castbar_on_top = false,
  sane_bag_sort = false,
  font_name = "Friz Quadrata TT",
  font_outline = "OUTLINE",
  font_shadow = true,
  texture_name = "Solid",
  icon_search = true,
  icon_tooltips = true,
}

--- Core defaults for BUIICharacterDatabase settings managed by BravosUIImprovements.lua.
---@type table<string, any>
local BUII_CORE_CHAR_DB_DEFAULTS = {
  hide_stance_bar = false,
  -- stance_bar_position is set dynamically from StanceBar:GetPoint() at runtime
}

--- Creates a standard toggle handler for a registered module.
--- The returned function toggles a database key and calls enable/disable.
---@param dbKey string
---@param enableFunc function
---@param disableFunc function
---@return function
local function BUII_CreateToggleHandler(dbKey, enableFunc, disableFunc)
  return function(self)
    if self:GetChecked() then
      enableFunc()
      BUIIDatabase[dbKey] = true
    else
      disableFunc()
      BUIIDatabase[dbKey] = false
    end
  end
end

--- Handles Target Frame Spell Bar OnUpdate Event
---@param self Frame|any
---@param arg1 any
---@param ... any
---@return nil
local function handleTargetFrameSpellBar_OnUpdate(self, arg1, ...)
  if BUIIDatabase["castbar_on_top"] then
    self:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 45, 20)
  end
end

--- Handles Focus Frame Spell Bar OnUpdate Event
---@param self Frame|any
---@param arg1 any
---@param ... any
---@return nil
local function handleFocusFrameSpellBar_OnUpdate(self, arg1, ...)
  if BUIIDatabase["castbar_on_top"] then
    if FocusFrame.smallSize then
      self:SetPoint("TOPLEFT", FocusFrame, "TOPLEFT", 38, 20)
    else
      self:SetPoint("TOPLEFT", FocusFrame, "TOPLEFT", 45, 20)
    end
  end
end

--- Resolves the correct health bar child frame from a unit frame's content area.
--- Handles the Blizzard hierarchy variations (HealthBarArea vs HealthBarsContainer vs direct HealthBar).
---@param contentMain table the PlayerFrameContentMain or TargetFrameContentMain frame
---@return StatusBar|any|nil healthBar
local function GetUnitHealthBar(contentMain)
  if contentMain.HealthBarArea then
    return contentMain.HealthBarArea.HealthBar
  elseif contentMain.HealthBarsContainer then
    return contentMain.HealthBarsContainer.HealthBar
  else
    return contentMain.HealthBar
  end
end

--- Sets the player's health bar color based on their class
---@return nil
local function setPlayerClassColor()
  local _, const_class = UnitClass("player")
  local r, g, b = GetClassColor(const_class)
  local playerHealthBar = GetUnitHealthBar(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain)

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

--- Toggles cast bar positioning on top of the target/focus frames
---@param setOnTop boolean
---@return nil
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

--- Toggles sane bag sorting (right-to-left)
---@param setSane boolean
---@return nil
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

--- Helper to show or hide stance buttons
---@param shouldHide boolean
---@return nil
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

--- Toggles visibility of the stance bar
---@param shouldHide boolean
---@return nil
local function setHideStanceBar(shouldHide)
  BUIICharacterDatabase["hide_stance_bar"] = shouldHide
  hideStanceButtons(shouldHide)
end

--- Toggles display of the player cast bar icon
---@param shouldShow boolean
---@return nil
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

--- Handles Unit Frame Portrait updates (used for class coloring)
---@param self Frame|any
---@return nil
local function handleUnitFramePortraitUpdate(self)
  local healthBar = self.HealthBar
  local playerContentMain = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain

  if self.unit == "player" then
    -- If we're in a vehicle we want to color the pet frame instead
    -- as that's where the player will be
    if UnitInVehicle(self.unit) then
      healthBar = PetFrameHealthBar
      local playerBar = GetUnitHealthBar(playerContentMain)
      if playerBar then
        playerBar:SetStatusBarDesaturated(false)
        playerBar:SetStatusBarColor(1, 1, 1)
      end
    else
      healthBar = GetUnitHealthBar(playerContentMain)
    end
  elseif self.unit == "pet" then
    healthBar = PetFrameHealthBar
  elseif self.unit == "target" then
    healthBar = GetUnitHealthBar(TargetFrame.TargetFrameContent.TargetFrameContentMain)
  elseif self.unit == "focus" then
    healthBar = GetUnitHealthBar(FocusFrame.TargetFrameContent.TargetFrameContentMain)
  elseif self.unit == "vehicle" then
    healthBar = GetUnitHealthBar(playerContentMain)
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

local modules = BUII_Modules

--- Refreshes fonts for all registered modules that have a refresh function
---@return nil
local function BUII_RefreshAllModuleFonts()
  for _, mod in ipairs(modules) do
    if BUIIDatabase[mod.dbKey] and mod.refresh then
      mod.refresh()
    end
  end
end

--- Refreshes textures for all registered modules that have a refresh function and refreshTexture flag
---@return nil
local function BUII_RefreshAllModuleTextures()
  for _, mod in ipairs(modules) do
    if BUIIDatabase[mod.dbKey] and mod.refresh and mod.refreshTexture then
      mod.refresh()
    end
  end
end

---@type table<string, Font>
local BUII_FontObjects = {}
--- Gets or creates a Font object for the given name and path
---@param fontName string
---@param fontPath string
---@return Font
local function BUII_GetFontObject(fontName, fontPath)
  if not BUII_FontObjects[fontName] then
    local name = "BUII_FontObject_" .. fontName:gsub("%s", "")
    local fontObj = CreateFont(name)
    fontObj:SetFont(fontPath, 12, "OUTLINE")
    BUII_FontObjects[fontName] = fontObj
  end
  return BUII_FontObjects[fontName]
end

--- Selects a tab in the Options Panel
---@param tabNum number
---@return nil
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

--- Initializes options panel dropdowns
---@return nil
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

--- Main OnLoad handler for the addon
---@param self Frame|any
---@return nil
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
  end
end

--- Registers BUII systems with the native Edit Mode manager
---@return nil
local function BUII_RegisterEditModeSystem()
  -- Define the minimum necessary for the settings dialog to work without crashing Blizzard's ipairs
  if
    EditModeSettingDisplayInfoManager
    and not EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[Enum.EditModeSystem.BUII_GroupTools]
  then
    EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[Enum.EditModeSystem.BUII_GroupTools] = {}
  end
end

--- Main Event handler for the addon
---@param self Frame|any
---@param event string
---@param arg1 any
---@param ... any
---@return nil
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

      -- Initialize saved variables tables if they don't exist
      if BUIIDatabase == nil then
        BUIIDatabase = {}
      end
      if BUIICharacterDatabase == nil then
        BUIICharacterDatabase = {}
      end

      -- Apply core defaults (only sets keys that are currently nil)
      MergeDefaults(BUIIDatabase, BUII_CORE_DB_DEFAULTS)
      MergeDefaults(BUIICharacterDatabase, BUII_CORE_CHAR_DB_DEFAULTS)

      -- Initialize stance bar position from current frame (requires runtime data)
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

      -- Call each module's InitDB() to apply module-specific defaults
      BUII_CastBarTimers_InitDB()
      BUII_QuickKeybindModeShortcut_InitDB()
      BUII_ImprovedEditMode_InitDB()
      BUII_QueueStatusButton_InitDB()
      BUII_TooltipImprovements_InitDB()
      BUII_MoveableArenaEnemyFrames_InitDB()
      BUII_MoveableTotemFrame_InitDB()
      BUII_IconSearch_InitDB()
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
      BUII_MissingBuffReminder_InitDB()

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

    -- Registry-driven module initialization
    for _, mod in ipairs(modules) do
      -- Resolve checkbox from checkboxPath (e.g. "weakAura.Ion" -> weakAura.Ion)
      local container, childKey = mod.checkboxPath:match("^(%w+)%.(.+)$")
      local checkbox
      if container == "defaultUI" then
        checkbox = defaultUI[childKey]
      elseif container == "weakAura" then
        checkbox = weakAura[childKey]
      end

      if BUIIDatabase[mod.dbKey] then
        mod.enable()
        if checkbox then
          checkbox:SetChecked(true)
        end
      elseif mod.alwaysSetChecked and checkbox then
        -- No disable() call needed: this is init, the module was never enabled.
        -- This just ensures the checkbox UI reflects the saved false state.
        checkbox:SetChecked(false)
      end
    end

    -- Sub-toggles: resource tracker per-class checkboxes (no enable/disable, just UI state)
    weakAura.ResourceTrackerShaman:SetChecked(BUIIDatabase["resource_tracker_shaman"] or false)
    weakAura.ResourceTrackerDemonHunter:SetChecked(BUIIDatabase["resource_tracker_demonhunter"] or false)
    weakAura.ResourceTrackerRogue:SetChecked(BUIIDatabase["resource_tracker_rogue"] or false)
    weakAura.ResourceTrackerDruid:SetChecked(BUIIDatabase["resource_tracker_druid"] or false)
    weakAura.ResourceTrackerMage:SetChecked(BUIIDatabase["resource_tracker_mage"] or false)
    weakAura.ResourceTrackerWarlock:SetChecked(BUIIDatabase["resource_tracker_warlock"] or false)
    weakAura.ResourceTrackerPaladin:SetChecked(BUIIDatabase["resource_tracker_paladin"] or false)
    weakAura.ResourceTrackerPriest:SetChecked(BUIIDatabase["resource_tracker_priest"] or false)
    weakAura.ResourceTrackerMonk:SetChecked(BUIIDatabase["resource_tracker_monk"] or false)
    weakAura.ResourceTrackerDeathKnight:SetChecked(BUIIDatabase["resource_tracker_deathknight"] or false)
    weakAura.ResourceTrackerEvoker:SetChecked(BUIIDatabase["resource_tracker_evoker"] or false)
    weakAura.ResourceTrackerHunter:SetChecked(BUIIDatabase["resource_tracker_hunter"] or false)

    -- Sub-toggles: stance tracker per-class checkboxes
    weakAura.StanceTrackerDruid:SetChecked(BUIIDatabase["stance_tracker_druid"] or false)
    weakAura.StanceTrackerPaladin:SetChecked(BUIIDatabase["stance_tracker_paladin"] or false)
    weakAura.StanceTrackerRogue:SetChecked(BUIIDatabase["stance_tracker_rogue"] or false)
    weakAura.StanceTrackerWarrior:SetChecked(BUIIDatabase["stance_tracker_warrior"] or false)

    -- Core-inline toggles: icon_tooltips and font_shadow (no enable/disable module)
    if BUIIDatabase["icon_tooltips"] then
      defaultUI.IconTooltips:SetChecked(true)
    end

    if BUIIDatabase["font_shadow"] then
      weakAura.FontShadow:SetChecked(true)
    else
      weakAura.FontShadow:SetChecked(false)
    end
  end
end

--- Toggle handler for Class Color check button
---@param self CheckButton|any
---@return nil
function BUII_HealthClassColorCheckButton_OnClick(self)
  setPlayerClassColor()
end

function BUII_ImprovedUnitFramesCheckButton_OnClick(self)
  BUII_CreateToggleHandler("improved_unitframes", BUII_ImprovedUnitFramesEnable, BUII_ImprovedUnitFramesDisable)(self)
end

--- Toggle handler for Cast Bar Timers check button (XML global shim)
function BUII_CastBarTimersCheckButton_OnClick(self)
  BUII_CreateToggleHandler("castbar_timers", BUII_CastBarTimersEnable, BUII_CastBarTimersDisable)(self)
end

--- Toggle handler for Cast Bar Icon check button
---@param self CheckButton|any
---@return nil
function BUII_CastBarIconCheckButton_OnClick(self)
  if self:GetChecked() then
    showPlayerCastBarIcon(true)
  else
    showPlayerCastBarIcon(false)
  end
end

--- Toggle handler for Cast Bar on Top check button
---@param self CheckButton|any
---@return nil
function BUII_CastBarOnTopCheckButton_OnClick(self)
  if self:GetChecked() then
    setCastBarOnTop(true)
  else
    setCastBarOnTop(false)
  end
end

--- Toggle handler for Sane Bag Sorting check button
---@param self CheckButton|any
---@return nil
function BUII_SaneCombinedBagSortingCheckButton_OnClick(self)
  setSaneBagSorting(self:GetChecked())
end

--- Toggle handler for Hide Stance Bar check button
---@param self CheckButton|any
---@return nil
function BUII_HideStanceBar_OnClick(self)
  setHideStanceBar(self:GetChecked())
end

--- Toggle handler for Quick Keybind Shortcut check button (XML global shim)
function BUII_QuickKeybindShortcut_OnClick(self)
  BUII_CreateToggleHandler(
    "quick_keybind_shortcut",
    BUII_QuickKeybindModeShortcutEnable,
    BUII_QuickKeybindModeShortcutDisable
  )(self)
end

--- Toggle handler for Improved Edit Mode check button (XML global shim)
function BUII_ImprovedEditMode_OnClick(self)
  BUII_CreateToggleHandler("improved_edit_mode", BUII_ImprovedEditModeEnable, BUII_ImprovedEditModeDisable)(self)
end

--- Toggle handler for Tooltip Expansion check button (XML global shim)
function BUII_TooltipExpansion_OnClick(self)
  BUII_CreateToggleHandler("tooltip_expansion", BUII_TooltipImprovements_Enabled, BUII_TooltipImprovements_Disable)(
    self
  )
end

--- Toggle handler for Moveable Arena Frames check button (XML global shim)
function BUII_MoveableArenaFrames_OnClick(self)
  BUII_CreateToggleHandler(
    "moveable_arena_frames",
    BUII_MoveableArenaEnemyFrames_Enable,
    BUII_MoveableArenaEnemyFrames_Disable
  )(self)
end

--- Toggle handler for Moveable Totem Frame check button (XML global shim)
function BUII_MoveableTotemFrame_OnClick(self)
  BUII_CreateToggleHandler("moveable_totem_frame", BUII_MoveableTotemFrame_Enable, BUII_MoveableTotemFrame_Disable)(
    self
  )
end

--- Toggle handler for Icon Search check button (XML global shim)
function BUII_IconSearch_OnClick(self)
  BUII_CreateToggleHandler("icon_search", BUII_IconSearch_Enable, BUII_IconSearch_Disable)(self)
end

--- Toggle handler for Icon Tooltips check button
---@param self CheckButton|any
---@return nil
function BUII_IconTooltips_OnClick(self)
  if self:GetChecked() then
    BUIIDatabase["icon_tooltips"] = true
    if BUII_IconSearch_UpdateTooltips then
      BUII_IconSearch_UpdateTooltips(true)
    end
  else
    BUIIDatabase["icon_tooltips"] = false
    if BUII_IconSearch_UpdateTooltips then
      BUII_IconSearch_UpdateTooltips(false)
    end
  end
end

--- Toggle handler for Call To Arms check button (XML global shim)
function BUII_CallToArms_OnClick(self)
  BUII_CreateToggleHandler("call_to_arms", BUII_CallToArms_Enable, BUII_CallToArms_Disable)(self)
end

--- Toggle handler for Ion Mode check button (XML global shim)
function BUII_Ion_OnClick(self)
  BUII_CreateToggleHandler("ion_mode", BUII_Ion_Enable, BUII_Ion_Disable)(self)
end

--- Toggle handler for Gear And Talent Loadout check button (XML global shim)
function BUII_GearAndTalentLoadout_OnClick(self)
  BUII_CreateToggleHandler("gear_talent_loadout", BUII_GearAndTalentLoadout_Enable, BUII_GearAndTalentLoadout_Disable)(
    self
  )
end

--- Toggle handler for Combat State check button (XML global shim)
function BUII_CombatState_OnClick(self)
  BUII_CreateToggleHandler("combat_state", BUII_CombatState_Enable, BUII_CombatState_Disable)(self)
end

--- Toggle handler for Ready Check check button (XML global shim)
function BUII_ReadyCheck_OnClick(self)
  BUII_CreateToggleHandler("ready_check", BUII_ReadyCheck_Enable, BUII_ReadyCheck_Disable)(self)
end

--- Toggle handler for Tank Shield Warning check button (XML global shim)
function BUII_TankShieldWarning_OnClick(self)
  BUII_CreateToggleHandler("tank_shield_warning", BUII_TankShieldWarning_Enable, BUII_TankShieldWarning_Disable)(self)
end

--- Toggle handler for Group Tools check button (XML global shim)
function BUII_GroupTools_OnClick(self)
  BUII_CreateToggleHandler("group_tools", BUII_GroupTools_Enable, BUII_GroupTools_Disable)(self)
end

--- Toggle handler for Stance Tracker check button (XML global shim)
function BUII_StanceTracker_OnClick(self)
  BUII_CreateToggleHandler("stance_tracker", BUII_StanceTracker_Enable, BUII_StanceTracker_Disable)(self)
end

--- Toggle handler for Druid Stance Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_StanceTrackerDruid_OnClick(self)
  BUIIDatabase["stance_tracker_druid"] = self:GetChecked()
  if BUIIDatabase["stance_tracker"] then
    BUII_StanceTracker_Enable()
  end
end

--- Toggle handler for Paladin Stance Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_StanceTrackerPaladin_OnClick(self)
  BUIIDatabase["stance_tracker_paladin"] = self:GetChecked()
  if BUIIDatabase["stance_tracker"] then
    BUII_StanceTracker_Enable()
  end
end

--- Toggle handler for Rogue Stance Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_StanceTrackerRogue_OnClick(self)
  BUIIDatabase["stance_tracker_rogue"] = self:GetChecked()
  if BUIIDatabase["stance_tracker"] then
    BUII_StanceTracker_Enable()
  end
end

--- Toggle handler for Warrior Stance Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_StanceTrackerWarrior_OnClick(self)
  BUIIDatabase["stance_tracker_warrior"] = self:GetChecked()
  if BUIIDatabase["stance_tracker"] then
    BUII_StanceTracker_Enable()
  end
end

--- Toggle handler for Resource Tracker check button (XML global shim)
function BUII_ResourceTracker_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker", BUII_ResourceTracker_Enable, BUII_ResourceTracker_Disable)(self)
end

--- Toggle handler for Shaman Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerShaman_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_shaman", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Demon Hunter Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerDemonHunter_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_demonhunter", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Rogue Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerRogue_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_rogue", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Druid Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerDruid_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_druid", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Mage Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerMage_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_mage", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Warlock Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerWarlock_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_warlock", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Paladin Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerPaladin_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_paladin", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Priest Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerPriest_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_priest", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Monk Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerMonk_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_monk", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Death Knight Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerDeathKnight_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_deathknight", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Evoker Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerEvoker_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_evoker", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Hunter Resource Tracker check button
---@param self CheckButton|any
---@return nil
function BUII_ResourceTrackerHunter_OnClick(self)
  BUII_CreateToggleHandler("resource_tracker_hunter", function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Enable()
    end
  end, function()
    if BUIIDatabase["resource_tracker"] then
      BUII_ResourceTracker_Disable()
    end
  end)(self)
end

--- Toggle handler for Stat Panel check button (XML global shim)
function BUII_StatPanel_OnClick(self)
  BUII_CreateToggleHandler("stat_panel", BUII_StatPanel_Enable, BUII_StatPanel_Disable)(self)
end

--- Toggle handler for Loot Spec check button (XML global shim)
function BUII_LootSpec_OnClick(self)
  BUII_CreateToggleHandler("loot_spec", BUII_LootSpec_Enable, BUII_LootSpec_Disable)(self)
end

--- Toggle handler for Pet Reminder check button (XML global shim)
function BUII_PetReminder_OnClick(self)
  BUII_CreateToggleHandler("pet_reminder", BUII_PetReminder_Enable, BUII_PetReminder_Disable)(self)
end

--- Toggle handler for Missing Buff Reminder check button (XML global shim)
function BUII_MissingBuffReminder_OnClick(self)
  BUII_CreateToggleHandler("missing_buff_reminder", BUII_MissingBuffReminder_Enable, BUII_MissingBuffReminder_Disable)(
    self
  )
end

--- Toggle handler for Font Shadow check button
---@param self CheckButton|any
---@return nil
function BUII_FontShadow_OnClick(self)
  BUIIDatabase["font_shadow"] = self:GetChecked()
  BUII_RefreshAllModuleFonts()
end
