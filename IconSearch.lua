local addonName, addon = ...

-- Global list of icons found during search
local filteredIcons = nil

-- Cache for search results to avoid lag while typing
local searchCache = {}
local lastSearchText = ""

local searchBoxXOffset = 72
local searchBoxYOffset = 34

-- Utility to get all spellbook items (Unused but kept for structure if user edits)
local function GetSpellBookIcons(text)
  return {}
end

local function SearchIcons(text)
  text = string.lower(text)
  if text == lastSearchText and searchCache[text] then
    return searchCache[text].icons, searchCache[text].names
  end

  local icons = {}
  local names = {}
  local seen = {}

  local function Add(texture, name)
    if texture and not seen[texture] then
      table.insert(icons, texture)
      seen[texture] = true
      names[texture] = name
    end
  end

  -- Spell Search
  if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
    local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines()
    for i = 1, numSkillLines do
      local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
      if skillLineInfo and not skillLineInfo.shouldHide then
        local offset = skillLineInfo.itemIndexOffset
        local numItems = skillLineInfo.numSpellBookItems
        for j = 1, numItems do
          local slotIndex = offset + j
          local info = C_SpellBook.GetSpellBookItemInfo(slotIndex, Enum.SpellBookSpellBank.Player)
          if info and info.itemType == Enum.SpellBookItemType.Spell and info.name then
            if
              string.find(string.lower(info.name), text, 1, true)
              or (info.iconID and string.find(tostring(info.iconID), text, 1, true))
            then
              Add(info.iconID, info.name)
            end
          end
        end
      end
    end
  elseif GetSpellBookItemName then
    -- Fallback
    local numSpells = 0
    local GetNumSpellTabs = GetNumSpellTabs
    if GetNumSpellTabs then
      local _, _, offset, num = GetSpellTabInfo(GetNumSpellTabs())
      numSpells = offset + num
    end
    for i = 1, numSpells do
      local name = GetSpellBookItemName(i, "player")
      local texture = GetSpellBookItemTexture(i, "player")
      if
        (name and string.find(string.lower(name), text, 1, true))
        or (texture and string.find(tostring(texture), text, 1, true))
      then
        Add(texture, name)
      end
    end
  end

  -- Inventory Search
  for bag = 0, 4 do
    local numSlots = C_Container.GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemName then
        if
          string.find(string.lower(info.itemName), text, 1, true)
          or (info.iconFileID and string.find(tostring(info.iconFileID), text, 1, true))
        then
          Add(info.iconFileID, info.itemName)
        end
      end
    end
  end

  -- Equipped Search
  for slot = 1, 19 do
    local itemId = GetInventoryItemID("player", slot)
    if itemId then
      local name = C_Item.GetItemNameByID(itemId)
      local texture = GetInventoryItemTexture("player", slot)
      if
        (name and string.find(string.lower(name), text, 1, true))
        or (texture and string.find(tostring(texture), text, 1, true))
      then
        Add(texture, name)
      end
    end
  end

  -- Mount Search
  if C_MountJournal then
    local numMounts = C_MountJournal.GetNumMounts()
    for i = 1, numMounts do
      local name, spellId, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetDisplayedMountInfo(i)
      if
        isCollected
        and (
          (name and string.find(string.lower(name), text, 1, true))
          or (icon and string.find(tostring(icon), text, 1, true))
        )
      then
        Add(icon, name)
      end
    end
  end

  -- Toy Search
  if C_ToyBox then
    local numToys = C_ToyBox.GetNumToys()
    for i = 1, numToys do
      local toyID = C_ToyBox.GetToyFromIndex(i)
      if toyID then
        local _, name, icon = C_ToyBox.GetToyInfo(toyID)
        if
          (name and string.find(string.lower(name), text, 1, true))
          or (icon and string.find(tostring(icon), text, 1, true))
        then
          Add(icon, name)
        end
      end
    end
  end

  -- Pet Search
  if C_PetJournal then
    local _, numOwned = C_PetJournal.GetNumPets()
    for i = 1, numOwned do
      local _, _, _, customName, _, _, _, speciesName, icon = C_PetJournal.GetPetInfoByIndex(i)
      if icon then
        local name = customName or speciesName
        if (name and string.find(string.lower(name), text, 1, true)) or string.find(tostring(icon), text, 1, true) then
          Add(icon, name)
        end
      end
    end
  end

  -- Numeric ID Search (Force with # prefix)
  if string.sub(text, 1, 1) == "#" then
    local idText = string.sub(text, 2)
    local numericID = tonumber(idText)
    if numericID then
      Add(numericID, "Icon ID: " .. numericID)
    end
  end

  searchCache[text] = { icons = icons, names = names }
  lastSearchText = text
  return icons, names
end

local function EnableIconTooltips(frame)
  if frame.iconTooltipsEnabled then
    return
  end

  local iconSelector = frame.IconSelector
  if not iconSelector then
    return
  end

  local origSetup = iconSelector.setupCallback

  local function NewSetupCallback(button, selectionIndex, icon)
    if origSetup then
      origSetup(button, selectionIndex, icon)
    end

    if BUIIDatabase["icon_tooltips"] then
      button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local currentIcon = self:GetIconTexture()

        -- Show name if found in current search
        if frame.filteredNames and frame.filteredNames[currentIcon] then
          GameTooltip:SetText(frame.filteredNames[currentIcon], 1, 1, 1)
          GameTooltip:AddLine("Icon ID: " .. tostring(currentIcon), 0.5, 0.5, 0.5)
        else
          GameTooltip:SetText("Icon ID: " .. tostring(currentIcon), 1, 1, 1)
        end

        GameTooltip:Show()
      end)
      button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)
    else
      button:SetScript("OnEnter", nil)
      button:SetScript("OnLeave", nil)
    end
  end

  iconSelector:SetSetupCallback(NewSetupCallback)
  frame.iconTooltipsEnabled = true
end

local function SetupSearchBox(frame)
  if frame.BUIISearchBox then
    return
  end

  local parent = frame.BorderBox or frame
  local searchBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  searchBox:SetSize(150, 20)
  searchBox:SetFrameStrata("DIALOG")
  searchBox:SetFrameLevel(parent:GetFrameLevel() + 20)

  local label = searchBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  label:SetText("Search")
  label:SetPoint("RIGHT", searchBox, "LEFT", -10, 0)
  searchBox.Label = label

  if frame.BorderBox then
    searchBox:SetPoint("TOPLEFT", frame.BorderBox, "BOTTOMLEFT", searchBoxXOffset, searchBoxYOffset)
  else
    searchBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -30)
  end

  searchBox:SetAutoFocus(false)
  searchBox:SetTextInsets(0, 0, 0, 0)
  searchBox:SetFontObject("ChatFontNormal")

  searchBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    if text == "" then
      frame.filteredIcons = nil
      frame.filteredNames = nil
    else
      frame.filteredIcons, frame.filteredNames = SearchIcons(text)
    end
    frame:Update()

    if frame.IconSelector then
      local getSelection = function(index)
        return frame:GetIconByIndex(index)
      end
      local getNumSelections = function()
        return frame:GetNumIcons()
      end
      frame.IconSelector:SetSelectionsDataProvider(getSelection, getNumSelections)
      frame.IconSelector:ScrollToSelectedIndex()
    end
  end)

  frame.BUIISearchBox = searchBox

  -- Hook Data Provider
  if not frame.origGetNumIcons then
    frame.origGetNumIcons = frame.GetNumIcons
    frame.GetNumIcons = function(self)
      if self.filteredIcons then
        return #self.filteredIcons
      end
      if self.origGetNumIcons then
        return self.origGetNumIcons(self)
      end
      return 0
    end
  end

  if not frame.origGetIconByIndex then
    frame.origGetIconByIndex = frame.GetIconByIndex
    frame.GetIconByIndex = function(self, index)
      if self.filteredIcons then
        return self.filteredIcons[index]
      end
      if self.origGetIconByIndex then
        return self.origGetIconByIndex(self, index)
      end
      return nil
    end
  end

  searchBox:Show()
end

local function InitIconSearch()
  if not BUIIDatabase["icon_search"] then
    return
  end

  local function HookMacro()
    if MacroPopupFrame then
      MacroPopupFrame:HookScript("OnShow", function(self)
        SetupSearchBox(self)
        EnableIconTooltips(self)
        if self.BUIISearchBox then
          self.BUIISearchBox:ClearAllPoints()
          self.BUIISearchBox:SetPoint("TOPLEFT", self.BorderBox, "BOTTOMLEFT", searchBoxXOffset, searchBoxYOffset)
          self.BUIISearchBox:SetSize(150, 20)
        end
      end)
      if MacroPopupFrame:IsShown() then
        SetupSearchBox(MacroPopupFrame)
        EnableIconTooltips(MacroPopupFrame)
        if MacroPopupFrame.BUIISearchBox then
          MacroPopupFrame.BUIISearchBox:ClearAllPoints()
          MacroPopupFrame.BUIISearchBox:SetPoint(
            "TOPLEFT",
            MacroPopupFrame.BorderBox,
            "BOTTOMLEFT",
            searchBoxXOffset,
            searchBoxYOffset
          )
          MacroPopupFrame.BUIISearchBox:SetSize(150, 20)
        end
      end
    end
  end

  if C_AddOns.IsAddOnLoaded("Blizzard_MacroUI") then
    HookMacro()
  else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, arg1)
      if arg1 == "Blizzard_MacroUI" then
        HookMacro()
        self:UnregisterAllEvents()
      end
    end)
  end

  local function HookTransmog()
    if TransmogFrame and TransmogFrame.OutfitPopup then
      TransmogFrame.OutfitPopup:HookScript("OnShow", function(self)
        SetupSearchBox(self)
        EnableIconTooltips(self)
        if self.BUIISearchBox then
          self.BUIISearchBox:ClearAllPoints()
          self.BUIISearchBox:SetPoint("TOPLEFT", self.BorderBox, "BOTTOMLEFT", searchBoxXOffset, searchBoxYOffset)
          self.BUIISearchBox:SetSize(150, 20)
        end
      end)
      if TransmogFrame.OutfitPopup:IsShown() then
        SetupSearchBox(TransmogFrame.OutfitPopup)
        EnableIconTooltips(TransmogFrame.OutfitPopup)
        if TransmogFrame.OutfitPopup.BUIISearchBox then
          TransmogFrame.OutfitPopup.BUIISearchBox:ClearAllPoints()
          TransmogFrame.OutfitPopup.BUIISearchBox:SetPoint(
            "TOPLEFT",
            TransmogFrame.OutfitPopup.BorderBox,
            "BOTTOMLEFT",
            searchBoxXOffset,
            searchBoxYOffset
          )
          TransmogFrame.OutfitPopup.BUIISearchBox:SetSize(150, 20)
        end
      end
    end
  end

  if C_AddOns.IsAddOnLoaded("Blizzard_Transmog") then
    HookTransmog()
  else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, arg1)
      if arg1 == "Blizzard_Transmog" then
        HookTransmog()
        self:UnregisterAllEvents()
      end
    end)
  end

  if GearManagerPopupFrame then
    GearManagerPopupFrame:HookScript("OnShow", function(self)
      SetupSearchBox(self)
      EnableIconTooltips(self)
      if self.BUIISearchBox then
        self.BUIISearchBox:ClearAllPoints()
        self.BUIISearchBox:SetPoint("TOPLEFT", self.BorderBox, "BOTTOMLEFT", searchBoxXOffset, searchBoxYOffset)
        self.BUIISearchBox:SetSize(150, 20)
      end
    end)
    if GearManagerPopupFrame:IsShown() then
      SetupSearchBox(GearManagerPopupFrame)
      EnableIconTooltips(GearManagerPopupFrame)
      if GearManagerPopupFrame.BUIISearchBox then
        GearManagerPopupFrame.BUIISearchBox:ClearAllPoints()
        GearManagerPopupFrame.BUIISearchBox:SetPoint(
          "TOPLEFT",
          GearManagerPopupFrame.BorderBox,
          "BOTTOMLEFT",
          searchBoxXOffset,
          searchBoxYOffset
        )
        GearManagerPopupFrame.BUIISearchBox:SetSize(150, 20)
      end
    end
  end
end

function BUII_IconSearch_InitDB()
  if BUIIDatabase["icon_search"] == nil then
    BUIIDatabase["icon_search"] = true
  end
end

function BUII_IconSearch_Enable()
  InitIconSearch()
end

function BUII_IconSearch_Disable()
  if MacroPopupFrame and MacroPopupFrame.BUIISearchBox then
    MacroPopupFrame.BUIISearchBox:Hide()
  end
  if TransmogFrame and TransmogFrame.OutfitPopup and TransmogFrame.OutfitPopup.BUIISearchBox then
    TransmogFrame.OutfitPopup.BUIISearchBox:Hide()
  end
  if GearManagerPopupFrame and GearManagerPopupFrame.BUIISearchBox then
    GearManagerPopupFrame.BUIISearchBox:Hide()
  end
end

function BUII_IconSearch_UpdateTooltips(enabled)
  local frames = { MacroPopupFrame, TransmogFrame and TransmogFrame.OutfitPopup, GearManagerPopupFrame }
  for _, frame in ipairs(frames) do
    if frame and frame:IsShown() and frame.IconSelector then
      frame.IconSelector:UpdateSelections()
    end
  end
end
