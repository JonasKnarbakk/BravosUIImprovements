-- Death Knight Resource Configuration

local addonName, addon = ...

local function DeathKnightHandler(config)
  local ready = 0
  local progressList = {}
  local time = GetTime()
  local maxRunes = UnitPowerMax("player", config.powerType) or 6

  for i = 1, maxRunes do
    local start, duration, runeReady = GetRuneCooldown(i)
    if not start then
      break
    end

    if runeReady then
      ready = ready + 1
    else
      if duration > 0 then
        local prog = (time - start) / duration
        table.insert(progressList, {
          progress = math.max(0, math.min(1, prog)),
          start = start,
          duration = duration,
          endTime = start + duration,
        })
      else
        table.insert(progressList, { progress = 0, start = 0, duration = 0, endTime = math.huge })
      end
    end
  end

  table.sort(progressList, function(a, b)
    return a.endTime < b.endTime
  end)

  for i = 4, #progressList do
    progressList[i].isQueued = true
  end

  return ready, progressList, nil
end

BUII_ResourceHandlers.DeathKnight = DeathKnightHandler

BUII_ResourceTracker_CONFIG.DEATHKNIGHT = {
  handler = "DeathKnight",
  powerType = Enum.PowerType.Runes,
  name = "Runes",
  color = { r = 0.77, g = 0.12, b = 0.23 },
  progressFill = true,
  nativeFrame = "RuneFrame",
  specs = {
    [250] = { r = 0.77, g = 0.12, b = 0.23 },
    [251] = { r = 0.0, g = 0.8, b = 1.0 },
    [252] = { r = 0.2, g = 0.8, b = 0.2 },
  },
}
