local arenaEnemyFrameOverlay = nil
local arenaEnemyFrameHooksInstalled = false
local moveableArenaEnemyFramesEnabled = false

-- Settings Constants
local enum_ArenaEnemyFramesSetting_Scale = 1

-- Sync the ArenaEnemyFrameContainer to follow our overlay position
local function syncContainerToOverlay()
  if not arenaEnemyFrameOverlay or not ArenaEnemyFramesContainer then
    return
  end

  ArenaEnemyFramesContainer:ClearAllPoints()
  ArenaEnemyFramesContainer:SetPoint("TOPLEFT", arenaEnemyFrameOverlay, "TOPLEFT", 0, 0)
end

-- Update overlay size to match container
local function updateOverlaySize()
  if not arenaEnemyFrameOverlay or not ArenaEnemyFramesContainer then
    return
  end

  local width = ArenaEnemyFramesContainer:GetWidth()
  local height = ArenaEnemyFramesContainer:GetHeight()

  -- Ensure minimum size for Edit Mode selection
  width = math.max(width, 100)
  height = math.max(height, 50)

  arenaEnemyFrameOverlay:SetSize(width, height)
end

local function setupArenaEnemyFrameOverlay()
  if arenaEnemyFrameOverlay then
    return
  end

  -- ArenaEnemyFramesContainer may not exist until arena is entered
  if not ArenaEnemyFramesContainer then
    return
  end

  local systemEnum = Enum.EditModeSystem.BUII_ArenaEnemyFrames or 113
  local systemName = BUII_HUD_EDIT_MODE_ARENA_ENEMY_FRAMES_LABEL or "Arena Enemy Frames"
  local dbKey = "arena_enemy_frames"

  -- Create overlay frame for Edit Mode
  arenaEnemyFrameOverlay = CreateFrame(
    "Frame",
    "BUIIArenaEnemyFramesOverlay",
    UIParent,
    "BUII_ArenaEnemyFramesEditModeTemplate"
  )
  arenaEnemyFrameOverlay:SetSize(200, 150)
  arenaEnemyFrameOverlay:SetMovable(true)
  arenaEnemyFrameOverlay:SetClampedToScreen(true)
  arenaEnemyFrameOverlay:SetDontSavePosition(true)

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
        return ArenaEnemyFramesContainer:GetScale()
      end,
      setter = function(f, val)
        ArenaEnemyFramesContainer:SetScale(val)
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
      -- Show overlay even if arena frames aren't visible
      arenaEnemyFrameOverlay:Show()
      updateOverlaySize()
    end,
    OnEditModeExit = function()
      syncContainerToOverlay()
    end,
  })

  -- Keep overlay synced during Edit Mode
  arenaEnemyFrameOverlay:HookScript("OnUpdate", function()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
      syncContainerToOverlay()
    end
  end)

  -- Hook container to update size when it changes
  if not arenaEnemyFrameHooksInstalled then
    hooksecurefunc(ArenaEnemyFramesContainer, "Layout", function()
      if moveableArenaEnemyFramesEnabled then
        updateOverlaySize()
        syncContainerToOverlay()
      end
    end)
    arenaEnemyFrameHooksInstalled = true
  end
end

function BUII_MoveableArenaEnemyFrames_Enable()
  moveableArenaEnemyFramesEnabled = true

  -- ArenaEnemyFramesContainer might not exist yet, set up when it does
  if ArenaEnemyFramesContainer then
    setupArenaEnemyFrameOverlay()

    if arenaEnemyFrameOverlay then
      C_Timer.After(0, function()
        BUII_EditModeUtils:ApplySavedPosition(arenaEnemyFrameOverlay, "arena_enemy_frames")
        syncContainerToOverlay()
        updateOverlaySize()
      end)
    end
  else
    -- Wait for the frame to be created
    local waitFrame = CreateFrame("Frame")
    waitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    waitFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    waitFrame:SetScript("OnEvent", function(self)
      if ArenaEnemyFramesContainer then
        setupArenaEnemyFrameOverlay()
        if arenaEnemyFrameOverlay then
          BUII_EditModeUtils:ApplySavedPosition(arenaEnemyFrameOverlay, "arena_enemy_frames")
          syncContainerToOverlay()
          updateOverlaySize()
        end
        self:UnregisterAllEvents()
        self:SetScript("OnEvent", nil)
      end
    end)
  end
end

function BUII_MoveableArenaEnemyFrames_Disable()
  moveableArenaEnemyFramesEnabled = false

  if arenaEnemyFrameOverlay then
    arenaEnemyFrameOverlay:Hide()
  end

  -- Reset container to default position
  if ArenaEnemyFramesContainer then
    ArenaEnemyFramesContainer:ClearAllPoints()
    -- Let Blizzard handle default positioning
  end
end

function BUII_MoveableArenaEnemyFrames_InitDB()
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
