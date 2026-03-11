---@type boolean
local castBarTimersInitialized = false

--- Creates a child frame specifically to hold the timer text fontstring
---@param parent Frame
---@param xOffset number
---@param yOffset number
---@return nil
local function createChildTimerFrame(parent, xOffset, yOffset)
  local timerFrame = CreateFrame("Frame", "BUIICastBarTimer" .. parent:GetName(), parent)
  timerFrame:SetWidth(1)
  timerFrame:SetHeight(1)
  timerFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", xOffset, yOffset)
  timerFrame.text = timerFrame:CreateFontString(nil, "ARTWORK")
  timerFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
  timerFrame.text:SetPoint("CENTER", 0, 0)
end

--- Realigns the spell name text on castbars to make room for timers
---@return nil
local function realignSpellNameText()
  TargetFrameSpellBar.Text:SetJustifyH("LEFT")
  FocusFrameSpellBar.Text:SetJustifyH("LEFT")
  PlayerCastingBarFrame.Text:SetJustifyH("LEFT")

  PlayerCastingBarFrame.Text:SetPoint("TOPLEFT", PlayerCastingBarFrame, "TOPLEFT", 5, -10)
  PlayerCastingBarFrame.Text:SetPoint("TOPRIGHT", PlayerCastingBarFrame, "TOPRIGHT", -30, -10)
  TargetFrameSpellBar.Text:SetPoint("TOPLEFT", TargetFrameSpellBar, "TOPLEFT", 5, -8)
  TargetFrameSpellBar.Text:SetPoint("TOPRIGHT", TargetFrameSpellBar, "TOPRIGHT", -25, -8)
  FocusFrameSpellBar.Text:SetPoint("TOPLEFT", FocusFrameSpellBar, "TOPLEFT", 5, -8)
  FocusFrameSpellBar.Text:SetPoint("TOPRIGHT", FocusFrameSpellBar, "TOPRIGHT", -25, -8)
end

--- Restores the original alignment of the spell name text on castbars
---@return nil
local function restoreSpellNameText()
  TargetFrameSpellBar.Text:SetJustifyH("CENTER")
  FocusFrameSpellBar.Text:SetJustifyH("CENTER")
  PlayerCastingBarFrame.Text:SetJustifyH("CENTER")

  PlayerCastingBarFrame.Text:ClearAllPoints()
  PlayerCastingBarFrame.Text:SetPoint("TOP", PlayerCastingBarFrame, "TOP", 0, -10)
  TargetFrameSpellBar.Text:ClearAllPoints()
  TargetFrameSpellBar.Text:SetPoint("TOPLEFT", TargetFrameSpellBar, "TOPLEFT", 0, -8)
  TargetFrameSpellBar.Text:SetPoint("TOPRIGHT", TargetFrameSpellBar, "TOPRIGHT", 0, -8)
  FocusFrameSpellBar.Text:ClearAllPoints()
  FocusFrameSpellBar.Text:SetPoint("TOPLEFT", FocusFrameSpellBar, "TOPLEFT", 0, -8)
  FocusFrameSpellBar.Text:SetPoint("TOPRIGHT", FocusFrameSpellBar, "TOPRIGHT", 0, -8)
end

--- Calculates the remaining cast time
---@param endTime number
---@param currentTime number
---@return number
local function calculateTimeLeft(endTime, currentTime)
  return (endTime / 1000) - currentTime
end

--- Updates the timer text based on the castbar's current casting status
---@param castBarFrame Frame|any
---@param timerTextFrame Frame|any
---@return nil
local function setTimerText(castBarFrame, timerTextFrame)
  local timeLeft = nil
  local unit = castBarFrame.unit
  if unit then
    local currentTime = GetTime()
    local _, _, _, _, endTime = UnitCastingInfo(unit)
    if not endTime then
      _, _, _, _, endTime = UnitChannelInfo(unit)
    end
    if endTime then
      local success, result = pcall(calculateTimeLeft, endTime, currentTime)
      if success then
        timeLeft = result
      end
    end
  end

  if timeLeft then
    timeLeft = (timeLeft < 0.1) and 0.01 or timeLeft
    timerTextFrame.text:SetText(string.format("%.1f", timeLeft))
  else
    timerTextFrame.text:SetText("")
  end
end

--- OnUpdate handler for the Player casting bar
---@param self Frame|any
---@param ... any
---@return nil
local function handlePlayerCastBar_OnUpdate(self, ...)
  setTimerText(self, _G["BUIICastBarTimerPlayerCastingBarFrame"])
end

--- OnUpdate handler for the Target casting bar
---@param self Frame|any
---@param ... any
---@return nil
local function handleTargetSpellBar_OnUpdate(self, ...)
  setTimerText(self, _G["BUIICastBarTimerTargetFrameSpellBar"])
end

--- OnUpdate handler for the Focus casting bar
---@param self Frame|any
---@param ... any
---@return nil
local function handleFocusSpellBar_OnUpdate(self, ...)
  setTimerText(self, _G["BUIICastBarTimerFocusFrameSpellBar"])
end

--- Enables castbar timers and hooks their OnUpdate scripts
---@return nil
function BUII_CastBarTimersEnable()
  if not castBarTimersInitialized then
    createChildTimerFrame(PlayerCastingBarFrame, -14, -17)
    PlayerCastingBarFrame:HookScript("OnUpdate", handlePlayerCastBar_OnUpdate)
    createChildTimerFrame(TargetFrameSpellBar, -12, -16)
    TargetFrameSpellBar:HookScript("OnUpdate", handleTargetSpellBar_OnUpdate)
    createChildTimerFrame(FocusFrameSpellBar, -12, -16)
    FocusFrameSpellBar:HookScript("OnUpdate", handleFocusSpellBar_OnUpdate)
    castBarTimersInitialized = true
  end

  -- Prevent the text from flowing into the castbar timer
  realignSpellNameText()

  _G["BUIICastBarTimerPlayerCastingBarFrame"]:Show()
  _G["BUIICastBarTimerTargetFrameSpellBar"]:Show()
  _G["BUIICastBarTimerFocusFrameSpellBar"]:Show()
end

--- Disables castbar timers and hides them
---@return nil
function BUII_CastBarTimersDisable()
  if castBarTimersInitialized then
    restoreSpellNameText()
    _G["BUIICastBarTimerPlayerCastingBarFrame"]:Hide()
    _G["BUIICastBarTimerTargetFrameSpellBar"]:Hide()
    _G["BUIICastBarTimerFocusFrameSpellBar"]:Hide()
  end
end

--- Initializes CastBar timer defaults into the global DB
---@return nil
function BUII_CastBarTimers_InitDB()
  if BUIIDatabase["castbar_timers"] == nil then
    BUIIDatabase["castbar_timers"] = false
  end
end
