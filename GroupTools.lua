local frame = nil
local bRezText = nil
local timerFrame = nil

-- Settings Constants
local enum_GroupToolsSetting_Scale = 20
local enum_GroupToolsSetting_FontSize = 21

local function UpdateBattleRez()
  if not frame then
    return
  end
  local spellChargeInfo = C_Spell.GetSpellCharges(20484)
  local greyCol = "|cFFAAAAAA"
  local redCol = "|cFFB40000"
  local greenCol = "|cFF00FF00"
  local whiteCol = "|cFFFFFFFF"

  -- Apply font size from the single source of truth
  local fontSize = frame.currentFontSize or 12
  if bRezText then
    bRezText:SetFont(BUII_GetFontPath(), fontSize, BUII_GetFontFlags())
    bRezText:SetShadowOffset(BUII_GetFontShadow())
  end

  if spellChargeInfo == nil then
    local crs = { 20484, 391054, 20707, 61999 }
    local crItems = { 221954, 221993, 198428 }
    local found = false
    for _, cr in ipairs(crs) do
      if IsSpellKnown(cr) then
        local crInfo = C_Spell.GetSpellCooldown(cr)
        if crInfo then
          local isReady = false
          pcall(function()
            isReady = (crInfo.startTime == 0)
          end)
          if isReady then
            bRezText:SetText(greyCol .. "BR: " .. greenCol .. "Ready")
          else
            local timeStr = "??:??"
            pcall(function()
              local duration = crInfo.duration
              local startTime = crInfo.startTime
              local remaining = duration - (GetTime() - startTime)
              timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
            end)
            bRezText:SetText(greyCol .. "BR: " .. redCol .. timeStr)
          end
          found = true
          break
        end
      end
    end

    if not found then
      for _, itemID in ipairs(crItems) do
        if C_Item.GetItemCount(itemID) > 0 then
          local start, duration, enable = GetItemCooldown(itemID)
          local isReady = false
          pcall(function()
            isReady = (start == 0)
          end)
          if isReady then
            bRezText:SetText(greyCol .. "BR: " .. greenCol .. "Ready")
          else
            local timeStr = "??:??"
            pcall(function()
              local remaining = duration - (GetTime() - start)
              timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
            end)
            bRezText:SetText(greyCol .. "BR: " .. redCol .. timeStr)
          end
          found = true
          break
        end
      end
    end

    if not found then
      bRezText:SetText(greyCol .. "BR: " .. whiteCol .. "N/A")
    end
    return
  end

  local charges = spellChargeInfo.currentCharges or 0
  local started = spellChargeInfo.cooldownStartTime
  local duration = spellChargeInfo.cooldownDuration
  local maxCharges = spellChargeInfo.maxCharges

  local color = greenCol
  local chargesStr = "?"
  local nextText = ""

  pcall(function()
    chargesStr = tostring(charges)
  end)
  pcall(function()
    if charges < 1 then
      color = redCol
    end
  end)

  pcall(function()
    if started and duration and duration > 0 and maxCharges and charges < maxCharges then
      local remaining = duration - (GetTime() - started)
      if remaining > 0 then
        local timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
        nextText = " " .. greyCol .. "(" .. whiteCol .. timeStr .. greyCol .. ")"
      end
    end
  end)

  bRezText:SetText(greyCol .. "BR: " .. color .. chargesStr .. "|r" .. nextText)
end

local function UpdateVisibility()
  if not frame then
    return
  end
  -- If Edit Mode is open, show the frame
  if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
    frame:Show()
    return
  end

  local inInstance, instanceType = IsInInstance()
  if inInstance and (instanceType == "party" or instanceType == "raid") then
    frame:Show()
  else
    frame:Hide()
  end
end

local function onEvent(self, event)
  UpdateBattleRez()
  UpdateVisibility()
  if event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_START" then
    if timerFrame then
      timerFrame:Show()
    end
  elseif event == "ENCOUNTER_END" then
    if timerFrame then
      timerFrame:Show()
    end
  end
end

local function BUII_GroupTools_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_GroupToolsFrame", UIParent, "BUII_GroupToolsEditModeTemplate")
  frame:SetSize(140, 80)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:Hide()

  -- Default Values
  frame.currentFontSize = 12

  local bRezFrame = CreateFrame("Frame", nil, frame)
  bRezFrame:SetSize(140, 30)
  bRezFrame:SetPoint("TOP", frame, "TOP", 0, 0)

  local bRezIcon = bRezFrame:CreateTexture(nil, "ARTWORK")
  bRezIcon:SetSize(30, 30)
  bRezIcon:SetPoint("LEFT", bRezFrame, "LEFT", 5, 0)
  bRezIcon:SetTexture(136080)
  bRezIcon:SetTexCoord(0, 1, 0, 1)

  bRezText = bRezFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  bRezText:SetFont(BUII_GetFontPath(), 12, BUII_GetFontFlags())
  bRezText:SetPoint("LEFT", bRezIcon, "RIGHT", 5, 0)
  bRezText:SetJustifyH("LEFT")

  local pullBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  pullBtn:SetSize(140, 20)
  pullBtn:SetPoint("TOP", bRezFrame, "BOTTOM", 0, -5)
  pullBtn:SetText("Pull Timer")
  pullBtn:GetFontString():SetFont(BUII_GetFontPath(), 10, BUII_GetFontFlags())
  pullBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  pullBtn:SetScript("OnClick", function(self, button)
    local timer = IsInRaid() and 10 or 5
    if button == "LeftButton" then
      if C_PartyInfo and C_PartyInfo.DoCountdown then
        C_PartyInfo.DoCountdown(timer)
      end
    elseif button == "RightButton" then
      if C_PartyInfo and C_PartyInfo.DoCountdown then
        C_PartyInfo.DoCountdown(0)
      end
    end
  end)

  local rcBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  rcBtn:SetSize(140, 20)
  rcBtn:SetPoint("TOP", pullBtn, "BOTTOM", 0, -5)
  rcBtn:SetText("Ready Check")
  rcBtn:GetFontString():SetFont(BUII_GetFontPath(), 10, BUII_GetFontFlags())
  rcBtn:SetScript("OnClick", function()
    DoReadyCheck()
  end)

  -- Register with EditModeUtils
  local settingsConfig = {
    {
      setting = enum_GroupToolsSetting_Scale,
      name = "Scale",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.5,
      maxValue = 2.0,
      stepSize = 0.05,
      formatter = BUII_EditModeUtils.FormatPercentage,
      getter = function(f)
        return f:GetScale()
      end,
      setter = function(f, val)
        f:SetScale(val)
      end,
    },
    {
      setting = enum_GroupToolsSetting_FontSize,
      name = "BR Font Size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 24,
      stepSize = 1,
      getter = function(f)
        return f.currentFontSize or 12
      end,
      setter = function(f, val)
        f.currentFontSize = val
        UpdateBattleRez()
      end,
      key = "fontSize",
      defaultValue = 12,
    },
  }

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_GroupTools,
    "Group Tools",
    settingsConfig,
    "group_tools",
    {
      OnReset = function(f)
        f.currentFontSize = 12
        UpdateBattleRez()
      end,
      OnApplySettings = function(f)
        UpdateBattleRez()
        UpdateVisibility()
      end,
    }
  )

  timerFrame = CreateFrame("Frame")
  timerFrame:Hide()
  local elapsed = 0
  timerFrame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed > 1.0 then
      UpdateBattleRez()
      elapsed = 0
    end
  end)
end

function BUII_GroupTools_Enable()
  BUII_GroupTools_Initialize()

  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("ENCOUNTER_START")
  frame:RegisterEvent("ENCOUNTER_END")
  frame:RegisterEvent("SPELL_UPDATE_CHARGES")
  frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  frame:SetScript("OnEvent", onEvent)

  -- Initial Update
  BUII_EditModeUtils:ApplySavedPosition(frame, "group_tools")
  UpdateVisibility()
  timerFrame:Show()
  UpdateBattleRez()
end

function BUII_GroupTools_Disable()
  if not frame then
    return
  end
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)
  timerFrame:Hide()
  frame:Hide()
end

function BUII_GroupTools_Refresh()
  if frame then
    UpdateBattleRez()
  end
  -- Note: Buttons are updated when they are clicked or initialized,
  -- but we can't easily reference them globally unless we store them.
  -- For now, UpdateBattleRez handles the main text.
  -- To properly update buttons, we'd need to store them in frame or locals.
end

function BUII_GroupTools_InitDB()
  if BUIIDatabase["group_tools"] == nil then
    BUIIDatabase["group_tools"] = false
  end
end
