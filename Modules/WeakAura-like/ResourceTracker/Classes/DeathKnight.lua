-- Death Knight Resource Module
local addonName, addon = ...

local DEATHKNIGHT_COLOR = { r = 0.77, g = 0.12, b = 0.23 }
local DEATHKNIGHT_SPECS = {
  [250] = { r = 0.77, g = 0.12, b = 0.23 }, -- Blood
  [251] = { r = 0.0, g = 0.8, b = 1.0 },   -- Frost
  [252] = { r = 0.2, g = 0.8, b = 0.2 },   -- Unholy
}

local function GetRuneState(maxRunes)
  local ready = 0
  local progressList = {}
  local time = GetTime()

  for i = 1, maxRunes do
    local start, duration, runeReady = GetRuneCooldown(i)
    if not start then
      break
    end

    if runeReady then
      ready = ready + 1
    else
      if not BUII_IsSecretValue(duration) and duration > 0 then
        local prog = 0
        if not BUII_IsSecretValue(time) and not BUII_IsSecretValue(start) and not BUII_IsSecretValue(duration) then
          prog = (time - start) / duration
        end
        local endTime = math.huge
        if not BUII_IsSecretValue(start) and not BUII_IsSecretValue(duration) then
          endTime = start + duration
        end
        table.insert(progressList, {
          progress = math.max(0, math.min(1, prog)),
          start = start,
          duration = duration,
          endTime = endTime,
        })
      else
        table.insert(progressList, { progress = 0, start = 0, duration = 0, endTime = math.huge })
      end
    end
  end

  table.sort(progressList, function(a, b)
    local aEndTime = a.endTime
    local bEndTime = b.endTime
    if BUII_IsSecretValue(aEndTime) or BUII_IsSecretValue(bEndTime) then
      return false
    end
    return aEndTime < bEndTime
  end)

  -- Mark runes beyond first 3 on cooldown as queued
  for i = 4, #progressList do
    progressList[i].isQueued = true
  end

  return ready, progressList
end

local DeathKnightModule = {}

function DeathKnightModule:SetupLayout(frame)
  local maxRunes = 6
  if not EditModeManagerFrame or not EditModeManagerFrame:IsShown() then
    maxRunes = UnitPowerMax("player", Enum.PowerType.Runes) or 6
  end
  BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, maxRunes)
  frame.ResourceBar:Hide()
end

function DeathKnightModule:Update(frame, db, isEditMode)
  local maxRunes = 6
  local ready = 3
  local progressList = {}

  if not isEditMode then
    maxRunes = UnitPowerMax("player", Enum.PowerType.Runes) or 6
    ready, progressList = GetRuneState(maxRunes)
  end

  local color = DEATHKNIGHT_COLOR
  if not isEditMode then
    local specId = PlayerUtil.GetCurrentSpecID()
    color = DEATHKNIGHT_SPECS[specId] or color
  end

  BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, maxRunes, function(i, point)
    local isFull = (not BUII_IsSecretValue(ready) and i <= ready)
    local myPartial = 0

    if not isFull then
      local partialData = progressList[i - ready]
      if partialData then
        myPartial = partialData
      end
    end

    return isFull, myPartial, color, false
  end, ready)
end

BUII_ResourceTracker_RegisterModule("DEATHKNIGHT", DeathKnightModule)

-- Keep config table for compatibility with other modules/DB checks
BUII_ResourceTracker_CONFIG.DEATHKNIGHT = {
  handler = "DeathKnight",
  powerType = Enum.PowerType.Runes,
  name = "Runes",
  color = DEATHKNIGHT_COLOR,
  progressFill = true,
  nativeFrame = "RuneFrame",
  specs = DEATHKNIGHT_SPECS,
}
