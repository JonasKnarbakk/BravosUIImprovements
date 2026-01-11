-- Edit Mode Integration
Enum.EditModeSystem.BUII_GroupTools = 101
BUII_HUD_EDIT_MODE_GROUP_TOOLS_LABEL = "Group Tools"

Enum.EditModeSystem.BUII_CallToArms = 102
BUII_HUD_EDIT_MODE_CALL_TO_ARMS_LABEL = "Call to Arms"

Enum.EditModeSystem.BUII_CombatState = 103
BUII_HUD_EDIT_MODE_COMBAT_STATE_LABEL = "Combat State Notification"

Enum.EditModeSystem.BUII_GearAndTalentLoadout = 104
BUII_HUD_EDIT_MODE_GEAR_AND_TALENT_LOADOUT_LABEL = "Gear & Talent Loadout"

Enum.EditModeSystem.BUII_ReadyCheck = 105
BUII_HUD_EDIT_MODE_READY_CHECK_LABEL = "Ready Check Notification"

Enum.EditModeSystem.BUII_StanceTracker = 106
BUII_HUD_EDIT_MODE_STANCE_TRACKER_LABEL = "Stance Tracker"

Enum.EditModeSystem.BUII_ResourceTracker = 107
BUII_HUD_EDIT_MODE_RESOURCE_TRACKER_LABEL = "Resource Tracker"

Enum.EditModeSystem.BUII_StatPanel = 108
BUII_HUD_EDIT_MODE_STAT_PANEL_LABEL = "Stat Panel"

Enum.EditModeSystem.BUII_LootSpec = 109
BUII_HUD_EDIT_MODE_LOOT_SPEC_LABEL = "Loot Specialization"

Enum.EditModeSystem.BUII_TankShieldWarning = 110
BUII_HUD_EDIT_MODE_TANK_SHIELD_WARNING_LABEL = "Tank Shield Warning"

-- Default WoW fonts
local DEFAULT_FONTS = {
  { name = "Friz Quadrata TT", path = "Fonts\\FRIZQT__.TTF" },
  { name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
  { name = "Skurri", path = "Fonts\\skurri.ttf" },
  { name = "Morpheus", path = "Fonts\\MORPHEUS.ttf" },
}

-- Outline options
BUII_OUTLINE_OPTIONS = {
  { name = "None", value = "" },
  { name = "Outline", value = "OUTLINE" },
  { name = "Thick Outline", value = "THICKOUTLINE" },
  { name = "Monochrome", value = "MONOCHROME" },
  { name = "Monochrome Outline", value = "MONOCHROME, OUTLINE" },
  { name = "Monochrome Thick", value = "MONOCHROME, THICKOUTLINE" },
}

-- Default WoW Textures
local DEFAULT_TEXTURES = {
  { name = "Solid", path = "Interface\\Buttons\\WHITE8X8" },
  { name = "Blizzard", path = "Interface\\TargetingFrame\\UI-StatusBar" },
  { name = "Blizzard Character Skills", path = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar" },
  { name = "Blizzard Raid Bar", path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
}

function BUII_GetAvailableTextures()
  local textures = {}
  local textureNames = {} -- Track added textures to avoid duplicates

  -- Add default WoW textures
  for _, texture in ipairs(DEFAULT_TEXTURES) do
    if not textureNames[texture.name] then
      table.insert(textures, texture)
      textureNames[texture.name] = true
    end
  end

  -- Add LSM textures if available
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local lsmTextures = LSM:List("statusbar")
    for _, textureName in ipairs(lsmTextures) do
      -- Skip if already added
      if not textureNames[textureName] then
        local texturePath = LSM:Fetch("statusbar", textureName)
        if texturePath then
          table.insert(textures, { name = textureName, path = texturePath })
          textureNames[textureName] = true
        end
      end
    end
  end

  -- Sort textures alphabetically by name
  table.sort(textures, function(a, b)
    return a.name < b.name
  end)

  return textures
end

function BUII_GetTexturePath()
  if not BUIIDatabase then
    return "Interface\\Buttons\\WHITE8X8"
  end

  local selectedTexture = BUIIDatabase["texture_name"]
  if not selectedTexture then
    selectedTexture = "Solid"
  end

  -- Try LSM first
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local success, texture = pcall(LSM.Fetch, LSM, "statusbar", selectedTexture)
    if success and texture then
      return texture
    end
  end

  -- Try default textures
  for _, texture in ipairs(DEFAULT_TEXTURES) do
    if texture.name == selectedTexture then
      return texture.path
    end
  end

  -- Fallback to Solid
  return "Interface\\Buttons\\WHITE8X8"
end

function BUII_GetAvailableFonts()
  local fonts = {}
  local fontNames = {} -- Track added fonts to avoid duplicates

  -- Add default WoW fonts
  for _, font in ipairs(DEFAULT_FONTS) do
    if not fontNames[font.name] then
      table.insert(fonts, font)
      fontNames[font.name] = true
    end
  end

  -- Add LSM fonts if available
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local lsmFonts = LSM:List("font")
    for _, fontName in ipairs(lsmFonts) do
      -- Skip if already added
      if not fontNames[fontName] then
        local fontPath = LSM:Fetch("font", fontName)
        if fontPath then
          table.insert(fonts, { name = fontName, path = fontPath })
          fontNames[fontName] = true
        end
      end
    end
  end

  -- Sort fonts alphabetically by name for easier browsing
  table.sort(fonts, function(a, b)
    return a.name < b.name
  end)

  return fonts
end

-- Test if a font path is valid by trying to create a temporary font string
local function BUII_ValidateFontPath(fontPath, fontSize, flags)
  if not fontPath or fontPath == "" then
    return false
  end

  -- Create a temporary font string to test the font
  local testFrame = CreateFrame("Frame")
  local testString = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local success = pcall(testString.SetFont, testString, fontPath, fontSize or 12, flags or "")

  testFrame:Hide()
  testFrame = nil

  return success
end

function BUII_GetFontPath()
  if not BUIIDatabase then
    return GameFontHighlight:GetFont()
  end

  local selectedFont = BUIIDatabase["font_name"]
  if not selectedFont then
    selectedFont = "Expressway"
  end

  local fontPath = nil

  -- Try LSM first
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local success, font = pcall(LSM.Fetch, LSM, "font", selectedFont)
    if success and font then
      fontPath = font
    end
  end

  -- Try default fonts if LSM failed
  if not fontPath then
    for _, font in ipairs(DEFAULT_FONTS) do
      if font.name == selectedFont then
        fontPath = font.path
        break
      end
    end
  end

  -- Validate the font path before returning it
  -- Use a simple outline flag for validation to avoid recursion
  if fontPath and BUII_ValidateFontPath(fontPath, 12, "OUTLINE") then
    return fontPath
  end

  -- If validation failed, fall back to default WoW font
  print("BUII: Font '" .. (selectedFont or "nil") .. "' failed to load, using default")
  return GameFontHighlight:GetFont()
end

function BUII_GetFontFlags()
  if not BUIIDatabase then
    return "OUTLINE"
  end

  local flags = BUIIDatabase["font_outline"]
  if not flags then
    flags = "OUTLINE"
  end

  return flags
end

function BUII_GetFontShadow()
  if not BUIIDatabase then
    return 1, -1
  end

  if BUIIDatabase["font_shadow"] == false then
    return 0, 0
  end

  return 1, -1
end
