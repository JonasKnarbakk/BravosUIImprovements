local frame = CreateFrame("Frame", "BUII_GroupToolsFrame", UIParent)
frame:SetSize(140, 80) -- Adjusted height to fit elements
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(false) -- Enabled via Edit Mode or for buttons
frame:Hide()

-- Background (Optional, for visibility during edit mode or always?)
-- The WA had individual backgrounds for buttons. I'll make container invisible but buttons visible.

-- 1. Battle Rez Monitor
local bRezFrame = CreateFrame("Frame", nil, frame)
bRezFrame:SetSize(140, 30)
bRezFrame:SetPoint("TOP", frame, "TOP", 0, 0)

local bRezIcon = bRezFrame:CreateTexture(nil, "ARTWORK")
bRezIcon:SetSize(30, 30)
bRezIcon:SetPoint("LEFT", bRezFrame, "LEFT", 5, 0)
bRezIcon:SetTexture(136080) -- Rebirth Icon
bRezIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

local bRezText = bRezFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bRezText:SetFont(BUII_GetFontPath(), 12, "OUTLINE")
bRezText:SetPoint("LEFT", bRezIcon, "RIGHT", 5, 0)
bRezText:SetJustifyH("LEFT")

-- 2. Pull Timer Button
local pullBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
pullBtn:SetSize(140, 20)
pullBtn:SetPoint("TOP", bRezFrame, "BOTTOM", 0, -5)
pullBtn:SetText("Pull Timer")
pullBtn:GetFontString():SetFont(BUII_GetFontPath(), 10, "OUTLINE")

pullBtn:SetScript("OnClick", function(self, button)
  local timer = 5 -- Default dungeon
  if UnitInRaid("player") then
    timer = 10
  end

  if button == "LeftButton" then
    if C_PartyInfo and C_PartyInfo.DoCountdown then
      C_PartyInfo.DoCountdown(timer)
    end
  elseif button == "RightButton" then
    if C_PartyInfo and C_PartyInfo.DoCountdown then
      C_PartyInfo.DoCountdown(0) -- Cancel
    end
  end
end)
pullBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

-- 3. Ready Check Button
local rcBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
rcBtn:SetSize(140, 20)
rcBtn:SetPoint("TOP", pullBtn, "BOTTOM", 0, -5)
rcBtn:SetText("Ready Check")
rcBtn:GetFontString():SetFont(BUII_GetFontPath(), 10, "OUTLINE")

rcBtn:SetScript("OnClick", function()
  DoReadyCheck()
end)

-- Edit Mode Selection
local selection = CreateFrame("Frame", nil, frame, "EditModeSystemSelectionTemplate")
selection:SetAllPoints(frame)
selection:Hide()
frame.Selection = selection

frame.Selection.GetLabelText = function()
  return "Group Tools"
end
frame.Selection.CheckShowInstructionalTooltip = function()
  return false
end

function frame:OnDragStart()
  if EditModeManagerFrame then
    EditModeManagerFrame:SelectSystem(frame)
  end
  frame.Selection:ShowSelected()
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:StartMoving()
end

function frame:OnDragStop()
  frame.Selection:ShowHighlighted()
  frame:StopMovingOrSizing()
  frame:SetMovable(false)
  frame:SetClampedToScreen(false)
  local point, _, relativePoint, x, y = frame:GetPoint()
  BUIIDatabase["group_tools_pos"] = { point = point, relativePoint = relativePoint, x = x, y = y }
end

-- Logic for Battle Rez
local function UpdateBattleRez()
  local spellChargeInfo = C_Spell.GetSpellCharges(20484)
  local greyCol = "|cFFAAAAAA"
  local redCol = "|cFFB40000"
  local greenCol = "|cFF00FF00"
  local whiteCol = "|cFFFFFFFF"

  if spellChargeInfo == nil then
    -- Individual cooldowns to check (not in raid/M+ environment usually)
    local crs = { 20484, 391054, 20707, 61999 } -- Rebirth, Intercession, Soulstone, Raise Ally
    local crItems = { 221954, 221993, 198428 } -- TWW jumper cables
    local found = false
    for _, cr in ipairs(crs) do
      if IsSpellKnown(cr) then
        local crInfo = C_Spell.GetSpellCooldown(cr)
        if crInfo then
          if crInfo.startTime == 0 then
            bRezText:SetText(greyCol .. "BR: " .. greenCol .. "Ready")
          else
            local duration = crInfo.duration
            local startTime = crInfo.startTime
            local remaining = duration - (GetTime() - startTime)
            local timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
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
          if start == 0 then
            bRezText:SetText(greyCol .. "BR: " .. greenCol .. "Ready")
          else
            local remaining = duration - (GetTime() - start)
            local timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
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

  -- Raid / M+ Shared Charges
  local charges = spellChargeInfo.currentCharges or 0
  local started = spellChargeInfo.cooldownStartTime
  local duration = spellChargeInfo.cooldownDuration
  local maxCharges = spellChargeInfo.maxCharges

  -- Update Text
  local color = (charges < 1) and redCol or greenCol
  local nextText = ""

  if started and duration and duration > 0 and charges < maxCharges then
    local remaining = duration - (GetTime() - started)
    if remaining > 0 then
      local timeStr = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
      nextText = " " .. greyCol .. "(" .. whiteCol .. timeStr .. greyCol .. ")"
    end
  end

  bRezText:SetText(greyCol .. "BR: " .. color .. charges .. "|r" .. nextText)
end

local function UpdateVisibility()
  local inInstance, instanceType = IsInInstance()
  if inInstance and (instanceType == "party" or instanceType == "raid") then
    frame:Show()
  else
    frame:Hide()
  end
end

-- Update Loop for Timer
local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
local elapsed = 0
timerFrame:SetScript("OnUpdate", function(self, dt)
  elapsed = elapsed + dt
  if elapsed > 1.0 then
    UpdateBattleRez()
    elapsed = 0
  end
end)

local function onEvent(self, event)
  UpdateBattleRez()
  UpdateVisibility()
  if event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_START" then
    timerFrame:Show()
  elseif event == "ENCOUNTER_END" then
    -- Keep showing for a bit or hide? WA hides it conditionally.
    -- We'll keep updating it as it's useful in M+ between pulls.
    timerFrame:Show()
  end
end

-- Edit Mode Hooks
local function editMode_OnEnter()
  frame:EnableMouse(true)
  frame:Show()
  frame.Selection:Show()
  frame.Selection:ShowHighlighted()
end

local function editMode_OnExit()
  frame:EnableMouse(false)
  frame.Selection:Hide()
  UpdateVisibility()
end

function BUII_GroupTools_Enable()
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("ENCOUNTER_START")
  frame:RegisterEvent("ENCOUNTER_END")
  frame:RegisterEvent("SPELL_UPDATE_CHARGES")
  frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  frame:SetScript("OnEvent", onEvent)

  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_GroupTools_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUII_GroupTools_OnExit")

  if BUIIDatabase["group_tools_pos"] then
    local pos = BUIIDatabase["group_tools_pos"]
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
  end

  UpdateVisibility()
  timerFrame:Show()
  UpdateBattleRez()
end

function BUII_GroupTools_Disable()
  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)
  timerFrame:Hide()

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_GroupTools_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUII_GroupTools_OnExit")

  frame:Hide()
end
