local arenaEnemyFrameOverlay = nil
local arenaEnemyFrameHooksInstalled = false
local moveableArenaEnemyFramesEnabled = false
local previewFrames = {}
local isSyncing = false -- Prevent recursion when syncing position

-- Settings Constants
local enum_ArenaEnemyFramesSetting_Scale = 1

-- Preview frame dimensions (match Blizzard arena frame)
local PREVIEW_FRAME_WIDTH = 112
local PREVIEW_FRAME_HEIGHT = 32
local PREVIEW_FRAME_SPACING = 10
local PREVIEW_FRAME_COUNT = 3

-- Class texture coordinates for UI-Classes-Circles (row, column format)
local CLASS_ICON_COORDS = {
  { 0, 0.25, 0, 0.25 }, -- Warrior
  { 0.25, 0.5, 0, 0.25 }, -- Mage
  { 0.5, 0.75, 0, 0.25 }, -- Rogue
}

-- Create a single preview frame that mimics an arena enemy frame
local function createPreviewFrame(parent, index)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetSize(PREVIEW_FRAME_WIDTH, PREVIEW_FRAME_HEIGHT)

  -- Background for health/mana bars
  local background = frame:CreateTexture(nil, "BACKGROUND")
  background:SetSize(72, 17)
  background:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -10)
  background:SetColorTexture(0, 0, 0, 0.5)

  -- Class portrait (circular)
  local classPortrait = frame:CreateTexture(nil, "BACKGROUND")
  classPortrait:SetSize(30, 30)
  classPortrait:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -11, -4)
  classPortrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
  -- Use different class icons for variety
  local coords = CLASS_ICON_COORDS[index] or CLASS_ICON_COORDS[1]
  classPortrait:SetTexCoord(coords[1], coords[2], coords[3], coords[4])

  -- Frame border texture
  local borderTexture = frame:CreateTexture(nil, "ARTWORK")
  borderTexture:SetSize(102, 32)
  borderTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
  borderTexture:SetTexture("Interface\\ArenaEnemyFrame\\UI-ArenaTargetingFrame")
  borderTexture:SetTexCoord(0.0, 0.796, 0.0, 0.5)

  -- Health bar
  local healthBar = frame:CreateTexture(nil, "BORDER")
  healthBar:SetSize(70, 8)
  healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -12)
  healthBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  healthBar:SetVertexColor(0.0, 1.0, 0.0, 1.0)

  -- Mana bar
  local manaBar = frame:CreateTexture(nil, "BORDER")
  manaBar:SetSize(70, 8)
  manaBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -20)
  manaBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  manaBar:SetVertexColor(0.0, 0.0, 1.0, 1.0)

  -- Spec portrait
  local specPortrait = frame:CreateTexture(nil, "BORDER")
  specPortrait:SetSize(22, 22)
  specPortrait:SetPoint("TOPLEFT", classPortrait, "CENTER", 4, 0)
  specPortrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

  -- Spec portrait border
  local specBorder = frame:CreateTexture(nil, "ARTWORK")
  specBorder:SetSize(50, 50)
  specBorder:SetPoint("TOPLEFT", classPortrait, "CENTER", 0, 4)
  specBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  -- Name text
  local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  nameText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 24)
  nameText:SetText("Arena Enemy " .. index)
  nameText:SetTextColor(1, 1, 1, 1)
  nameText:SetJustifyH("LEFT")

  return frame
end

-- Create all preview frames
local function createPreviewFrames(parent)
  for i = 1, PREVIEW_FRAME_COUNT do
    local preview = createPreviewFrame(parent, i)
    preview:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((i - 1) * (PREVIEW_FRAME_HEIGHT + PREVIEW_FRAME_SPACING)))
    preview:Hide()
    previewFrames[i] = preview
  end
end

-- Show/hide preview frames
local function setPreviewVisible(visible)
  -- Don't modify protected frames during combat lockdown
  if InCombatLockdown() then
    return
  end

  for _, frame in ipairs(previewFrames) do
    if visible then
      frame:Show()
    else
      frame:Hide()
    end
  end
end

-- Check if there are actual visible arena frames (not just the container)
local function hasVisibleArenaFrames()
  if not ArenaEnemyFramesContainer or not ArenaEnemyFramesContainer:IsShown() then
    return false
  end

  -- Check if any of the prep or match frames are visible
  for i = 1, 5 do
    local prepFrame = _G["ArenaEnemyPrepFrame" .. i]
    local matchFrame = _G["ArenaEnemyMatchFrame" .. i]
    if (prepFrame and prepFrame:IsShown()) or (matchFrame and matchFrame:IsShown()) then
      return true
    end
  end

  return false
end

-- Reparent the container out of the managed frame system to prevent Blizzard from repositioning it
local function reparentContainerIfNeeded()
  if not ArenaEnemyFramesContainer then
    return false
  end

  -- Don't modify protected frames during combat lockdown
  if InCombatLockdown() then
    return false
  end

  local currentParent = ArenaEnemyFramesContainer:GetParent()
  if currentParent and currentParent ~= UIParent then
    -- Reparent to UIParent to escape the managed frame system
    ArenaEnemyFramesContainer:SetParent(UIParent)
    -- Ensure it stays at a reasonable frame strata
    ArenaEnemyFramesContainer:SetFrameStrata("MEDIUM")
  end
  return true
end

-- Sync the ArenaEnemyFrameContainer to follow our overlay position
local function syncContainerToOverlay()
  if not arenaEnemyFrameOverlay or not ArenaEnemyFramesContainer then
    return
  end

  if isSyncing then
    return
  end

  -- Don't modify protected frames during combat lockdown
  if InCombatLockdown() then
    return
  end

  isSyncing = true
  reparentContainerIfNeeded()
  ArenaEnemyFramesContainer:ClearAllPoints()
  ArenaEnemyFramesContainer:SetPoint("TOPLEFT", arenaEnemyFrameOverlay, "TOPLEFT", 0, 0)
  isSyncing = false
end

-- Update overlay size based on preview or actual container
local function updateOverlaySize()
  if not arenaEnemyFrameOverlay then
    return
  end

  -- Don't modify protected frames during combat lockdown
  if InCombatLockdown() then
    return
  end

  local width, height

  if hasVisibleArenaFrames() then
    width = ArenaEnemyFramesContainer:GetWidth()
    height = ArenaEnemyFramesContainer:GetHeight()
  else
    -- Use preview frame dimensions
    width = PREVIEW_FRAME_WIDTH
    height = (PREVIEW_FRAME_HEIGHT * PREVIEW_FRAME_COUNT) + (PREVIEW_FRAME_SPACING * (PREVIEW_FRAME_COUNT - 1))
  end

  -- Ensure minimum size for Edit Mode selection
  width = math.max(width, 100)
  height = math.max(height, 50)

  arenaEnemyFrameOverlay:SetSize(width, height)
end

local function setupArenaEnemyFrameOverlay()
  if arenaEnemyFrameOverlay then
    return
  end

  local systemEnum = Enum.EditModeSystem.BUII_ArenaEnemyFrames or 113
  local systemName = BUII_HUD_EDIT_MODE_ARENA_ENEMY_FRAMES_LABEL or "Arena Enemy Frames"
  local dbKey = "arena_enemy_frames"

  -- Create overlay frame for Edit Mode
  arenaEnemyFrameOverlay =
    CreateFrame("Frame", "BUIIArenaEnemyFramesOverlay", UIParent, "BUII_ArenaEnemyFramesEditModeTemplate")
  arenaEnemyFrameOverlay:SetSize(
    PREVIEW_FRAME_WIDTH,
    (PREVIEW_FRAME_HEIGHT * PREVIEW_FRAME_COUNT) + (PREVIEW_FRAME_SPACING * (PREVIEW_FRAME_COUNT - 1))
  )
  arenaEnemyFrameOverlay:SetMovable(true)
  arenaEnemyFrameOverlay:SetClampedToScreen(true)
  arenaEnemyFrameOverlay:SetDontSavePosition(true)

  -- Create preview frames
  createPreviewFrames(arenaEnemyFrameOverlay)

  local settingsConfig = {
    {
      setting = enum_ArenaEnemyFramesSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 2.0,
      stepSize = 0.05,
      formatter = BUII_EditModeUtils.FormatPercentage,
      getter = function(f)
        if ArenaEnemyFramesContainer then
          return ArenaEnemyFramesContainer:GetScale()
        end
        return f:GetScale()
      end,
      setter = function(f, val)
        if ArenaEnemyFramesContainer then
          ArenaEnemyFramesContainer:SetScale(val)
        end
        arenaEnemyFrameOverlay:SetScale(val)
        syncContainerToOverlay()
      end,
      key = "scale",
      defaultValue = 1.0,
    },
  }

  BUII_EditModeUtils:RegisterSystem(arenaEnemyFrameOverlay, systemEnum, systemName, settingsConfig, dbKey, {
    OnApplySettings = function()
      syncContainerToOverlay()
      updateOverlaySize()
    end,
    OnEditModeEnter = function()
      arenaEnemyFrameOverlay:Show()
      updateOverlaySize()
      syncContainerToOverlay()
      -- Show preview if no actual arena frames are visible
      setPreviewVisible(not hasVisibleArenaFrames())
    end,
    OnEditModeExit = function()
      setPreviewVisible(false)
      syncContainerToOverlay()
    end,
  })
end

-- Hook the container when it becomes available
local function hookContainerIfExists()
  if arenaEnemyFrameHooksInstalled or not ArenaEnemyFramesContainer then
    return
  end

  -- Immediately reparent to escape the managed frame system
  reparentContainerIfNeeded()

  -- Hook Layout to sync after layout changes
  hooksecurefunc(ArenaEnemyFramesContainer, "Layout", function()
    if moveableArenaEnemyFramesEnabled and arenaEnemyFrameOverlay then
      updateOverlaySize()
      syncContainerToOverlay()
    end
  end)

  -- Hook SetParent in case Blizzard tries to reparent it back
  hooksecurefunc(ArenaEnemyFramesContainer, "SetParent", function()
    if moveableArenaEnemyFramesEnabled and arenaEnemyFrameOverlay and not isSyncing then
      C_Timer.After(0, function()
        if
          moveableArenaEnemyFramesEnabled
          and arenaEnemyFrameOverlay
          and ArenaEnemyFramesContainer
          and not isSyncing
        then
          reparentContainerIfNeeded()
          syncContainerToOverlay()
        end
      end)
    end
  end)

  -- Hook Show/Hide to toggle preview visibility during Edit Mode
  hooksecurefunc(ArenaEnemyFramesContainer, "Show", function()
    if moveableArenaEnemyFramesEnabled and arenaEnemyFrameOverlay then
      if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
        -- Only hide preview if there are actual visible arena frames
        setPreviewVisible(not hasVisibleArenaFrames())
      end
      updateOverlaySize()
      syncContainerToOverlay()
    end
  end)

  hooksecurefunc(ArenaEnemyFramesContainer, "Hide", function()
    if moveableArenaEnemyFramesEnabled and arenaEnemyFrameOverlay then
      if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
        setPreviewVisible(true)
      end
    end
  end)

  -- Apply saved position to container
  if arenaEnemyFrameOverlay then
    syncContainerToOverlay()
  end

  arenaEnemyFrameHooksInstalled = true
end

function BUII_MoveableArenaEnemyFrames_Enable()
  moveableArenaEnemyFramesEnabled = true

  -- Always create the overlay (for Edit Mode preview)
  setupArenaEnemyFrameOverlay()

  if arenaEnemyFrameOverlay then
    C_Timer.After(0, function()
      BUII_EditModeUtils:ApplySavedPosition(arenaEnemyFrameOverlay, "arena_enemy_frames")
      hookContainerIfExists()
      syncContainerToOverlay()
      updateOverlaySize()
    end)
  end

  -- Set up listener for when arena frames become available and after combat ends
  local waitFrame = CreateFrame("Frame")
  waitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  waitFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
  waitFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
  waitFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Re-sync after combat ends
  waitFrame:SetScript("OnEvent", function()
    if ArenaEnemyFramesContainer then
      hookContainerIfExists()
      if arenaEnemyFrameOverlay then
        syncContainerToOverlay()
        updateOverlaySize()
      end
    end
  end)
end

function BUII_MoveableArenaEnemyFrames_Disable()
  moveableArenaEnemyFramesEnabled = false

  if arenaEnemyFrameOverlay then
    arenaEnemyFrameOverlay:Hide()
    setPreviewVisible(false)
  end

  -- Reset container to default position
  if ArenaEnemyFramesContainer then
    ArenaEnemyFramesContainer:ClearAllPoints()
    -- Let Blizzard handle default positioning
  end
end

function BUII_MoveableArenaEnemyFrames_InitDB()
  if BUIIDatabase["moveable_arena_frames"] == nil then
    BUIIDatabase["moveable_arena_frames"] = false
  end
  if BUIIDatabase["arena_enemy_frames_layouts"] == nil then
    BUIIDatabase["arena_enemy_frames_layouts"] = {
      Default = {
        point = "TOPRIGHT",
        relativePoint = "TOPRIGHT",
        offsetX = -100,
        offsetY = -200,
        scale = 1.0,
      },
    }
  end
end
