---@type boolean
local castBarTimersInitialized = false

--- Gets the Castbar Timers database settings
---@return table|nil
local function GetCastBarTimersDB()
  return BUII_EditModeUtils:GetDB("castbar_timers")
end

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
  timerFrame.text:SetFont(BUII_GetFontPath(), 10, "")
  timerFrame.text:SetPoint("CENTER", 0, 0)
end

--- Takes the existing blizzard CastTimeText and moves it inside the PlayerCastingBar
---@return nil
local function repositionPlayerCastBarText()
  if PlayerCastingBarFrame.CastTimeText ~= nil then
    PlayerCastingBarFrame.CastTimeText:ClearAllPoints()
    PlayerCastingBarFrame.CastTimeText:SetPoint("TOPRIGHT", PlayerCastingBarFrame, "TOPRIGHT", -4, -13)
    PlayerCastingBarFrame.CastTimeText:SetFont(BUII_GetFontPath(), 10, "")
    PlayerCastingBarFrame.CastTimeText:SetPoint("CENTER", 0, 0)
  end
end

local frames = {
  target = TargetFrameSpellBar,
  focus = FocusFrameSpellBar,
}
local overlays = {
  target = nil,
  focus = nil,
}
local hooks = {
  target = false,
  focus = false,
}
local enum_FrameSpellBarSetting_Icon = 10
local enum_FrameSpellBarSetting_Scale = 11

local function syncFrameSpellBarToOverlay(self, parent)
  if not self or not parent or self.buiiTransformUpdateInProgress then
    return
  end

  self.buiiTransformUpdateInProgress = true

  -- if self then
  --   print("Sync on: ", self:GetName(), " parent is: ", parent)
  --   for key, value in pairs(parent) do
  --     print("key: ", key, " value: ", value)
  --   end
  -- end

  if self:GetParent() == parent then
    return
  end
  -- self.IsUserPlaced = true

  local scale = GetCastBarTimersDB()["improved_castbars_scale_" .. self:GetName()]
  if scale then
    self:SetScale(scale)
  end

  self:ClearAllPoints()
  self:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  self.buiiTransformUpdateInProgress = nil
end

--- Takes the existing blizzard CastTimeText and moves it inside the PlayerCastingBar
---@return nil
local function detachAndSetupCastBar(frameKey, frameOverlayTemplate, systemEnum, systemName)
  if not frames[frameKey] or overlays[frameKey] then
    return
  end

  local unitFrame = (frameKey == "target") and TargetFrame or FocusFrame

  if unitFrame then
    -- Tell the unit frame it doesn't have a spellbar anymore.
    -- This stops TargetFrame:UpdateAuras from calling self.spellbar:AdjustPosition()
    unitFrame.spellbar = nil

    -- IMPORTANT: We still keep our 'frame' reference so our addon can move it.
    -- We just hid it from Blizzard's sight.
  end

  -- Create dedicated overlay frame for Edit Mode
  overlays[frameKey] = CreateFrame("Frame", nil, UIParent, frameOverlayTemplate)

  local frame = frames[frameKey]
  local frameOverlay = overlays[frameKey]

  overlays[frameKey]:SetSize(frames[frameKey]:GetWidth(), frames[frameKey]:GetHeight() + 10)
  overlays[frameKey]:SetMovable(true)
  overlays[frameKey]:SetClampedToScreen(true)
  overlays[frameKey]:SetDontSavePosition(true)
  overlays[frameKey].defaultPoint = "CENTER"
  overlays[frameKey].buffsOnTop = true

  local settingsConfig = {
    {
      setting = enum_FrameSpellBarSetting_Icon,
      name = "Show Icon",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      key = "improved_castbars_icon_" .. frame:GetName(),
      getter = function(f)
        local db = GetCastBarTimersDB()
        return db["improved_castbars_icon_" .. frame:GetName()] and 1 or 0
      end,
      setter = function(f, val)
        local db = GetCastBarTimersDB()
        db["improved_castbars_icon_" .. frame:GetName()] = (val == 1)
      end,
    },
  }
  BUII_EditModeUtils:AddScaleSetting(
    settingsConfig,
    enum_FrameSpellBarSetting_Scale,
    "improved_castbars_scale_" .. frames[frameKey]:GetName(),
    function(f, val)
      if frame then
        frame:SetScale(val)
        local db = GetCastBarTimersDB()
        db["improved_castbars_scale_" .. frame:GetName()] = val
      end
      syncFrameSpellBarToOverlay(frame, frameOverlay)
    end
  )
  BUII_EditModeUtils:RegisterSystem(
    overlays[frameKey],
    systemEnum,
    systemName,
    settingsConfig,
    "improved_castbars_" .. frame:GetName(),
    {
      OnApplySettings = function()
        syncFrameSpellBarToOverlay(frame, frameOverlay)
      end,
      OnEditModeEnter = function()
        frame:Show()
        frameOverlay:Show()
        syncFrameSpellBarToOverlay(frame, frameOverlay)
      end,
      OnEditModeExit = function()
        -- frame:Hide()
        frameOverlay:Hide()
        syncFrameSpellBarToOverlay(frame, frameOverlay)
      end,
    }
  )

  if not hooks[frameKey] then
    -- Ensure the actual castbar follows the overlay
    overlays[frameKey]:HookScript("OnUpdate", function()
      if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
        syncFrameSpellBarToOverlay(frame, frameOverlay)
      end
    end)
    -- Prevent Blizzard from moving the frame back
    hooksecurefunc(frames[frameKey], "SetPoint", function(self)
      syncFrameSpellBarToOverlay(self, frameOverlay)
    end)
    hooks[frameKey] = true
  end
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
    timerTextFrame.text:SetText(string.format("%.1f s", timeLeft))
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
    -- PlayerCastingBarFrame.CastTimeText:SetPoint(PlayerCastingBarFrame, nil, nil, -14, -17)
    repositionPlayerCastBarText()
    detachAndSetupCastBar(
      "target",
      "BUIITargetFrameSpellBarEditModeSystemTemplate",
      Enum.EditModeSystem.BUII_TargetFrameSpellBar,
      BUII_HUD_EDIT_MODE_TARGET_FRAME_SPELL_BAR_LABEL
    )

    detachAndSetupCastBar(
      "focus",
      "BUIIFocusFrameSpellBarEditModeSystemTemplate",
      Enum.EditModeSystem.BUII_FocusFrameSpellBar,
      BUII_HUD_EDIT_MODE_FOCUS_FRAME_SPELL_BAR_LABEL
    )
    -- createChildTimerFrame(PlayerCastingBarFrame, -14, -17)
    -- PlayerCastingBarFrame:HookScript("OnUpdate", handlePlayerCastBar_OnUpdate)
    createChildTimerFrame(TargetFrameSpellBar, -16, -16)
    TargetFrameSpellBar:HookScript("OnUpdate", handleTargetSpellBar_OnUpdate)
    createChildTimerFrame(FocusFrameSpellBar, -16, -16)
    FocusFrameSpellBar:HookScript("OnUpdate", handleFocusSpellBar_OnUpdate)
    castBarTimersInitialized = true

    -- if targetFrameSpellBarOverlay then
    --   -- Delay unparenting to ensure it happens after Blizzard's initial layout
    --   C_Timer.After(0, function()
    --     if TargetFrameSpellBar:GetParent() ~= UIParent then
    --       TargetFrameSpellBar:SetParent(UIParent)
    --     end
    --
    --     -- BUII_EditModeUtils:ApplySavedPosition(targetFrameSpellBarOverlay, "castbar_timers")
    --     syncTargetFrameSpellBarToOverlay(TargetFrameSpellBar)
    --   end)
    -- end
  end

  -- Prevent the text from flowing into the castbar timer
  realignSpellNameText()

  -- _G["BUIICastBarTimerPlayerCastingBarFrame"]:Show()
  _G["BUIICastBarTimerTargetFrameSpellBar"]:Show()
  _G["BUIICastBarTimerFocusFrameSpellBar"]:Show()
end

--- Disables castbar timers and hides them
---@return nil
function BUII_CastBarTimersDisable()
  if castBarTimersInitialized then
    restoreSpellNameText()
    -- _G["BUIICastBarTimerPlayerCastingBarFrame"]:Hide()
    _G["BUIICastBarTimerTargetFrameSpellBar"]:Hide()
    _G["BUIICastBarTimerFocusFrameSpellBar"]:Hide()
  end
end

local DB_DEFAULTS = {
  castbar_timers = false,
  ["improved_castbars_TargetFrameSpellBar"] = { scale = 1, pos = { point = "CENTER", x = 0, y = 0 } },
  ["improved_castbars_FocusFrameSpellBar"] = { scale = 1, pos = { point = "CENTER", x = 0, y = 0 } },
}

function BUII_CastBarTimers_InitDB()
  MergeDefaults(BUIIDatabase, DB_DEFAULTS)
end

BUII_RegisterModule({
  dbKey = "castbar_timers",
  enable = BUII_CastBarTimersEnable,
  disable = BUII_CastBarTimersDisable,
  checkboxPath = "defaultUI.CastBarTimers",
})
