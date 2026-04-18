local addonName, addon = ...
---@class BUII_ResourceTrackerEditModeTemplate : BUII_ManagedFrame
---@type Frame|BUII_ResourceTrackerEditModeTemplate|any|nil
local frame = nil
---@class BUII_ResourcePointTemplate : Frame
---@field ProgressBar StatusBar|any
---@field AnimTexture Texture|any
---@field AnimGroup AnimationGroup|any
---@field ScaleAnim Animation|any
---@field Background Texture|any
---@field SetBackdropBorderColor function|any
---@field lastStart number|nil
---@field lastDuration number|nil
---@type BUII_ResourcePointTemplate[]
local points = {}
---@type FontString|nil
local counterText = nil

-- Configuration is now in Core.lua as BUII_ResourceTracker_CONFIG
-- Use BUII_ResourceTracker_GetActiveConfig() to get the current config

local enum_ResourceTrackerSetting_Scale = 60
local enum_ResourceTrackerSetting_TotalWidth = 61
local enum_ResourceTrackerSetting_Spacing = 62
local enum_ResourceTrackerSetting_Height = 63
local enum_ResourceTrackerSetting_ShowText = 64
local enum_ResourceTrackerSetting_ShowDecimal = 65
local enum_ResourceTrackerSetting_FontSize = 66
local enum_ResourceTrackerSetting_ShowBorder = 67
local enum_ResourceTrackerSetting_UseClassColor = 68
local enum_ResourceTrackerSetting_ResourceOpacity = 69
local enum_ResourceTrackerSetting_BackgroundOpacity = 70
local enum_ResourceTrackerSetting_FrameStrata = 71
local enum_ResourceTrackerSetting_HideNativeFrame = 72
local enum_ResourceTrackerSetting_ShowPowerBar = 73
local enum_ResourceTrackerSetting_PowerBarHeight = 74
local enum_ResourceTrackerSetting_PowerBarPadding = 75
local enum_ResourceTrackerSetting_PowerBarShowText = 76
local enum_ResourceTrackerSetting_PowerBarFontSize = 77

local FRAME_STRATA_OPTIONS = {
  { text = "Background", value = 1 },
  { text = "Low", value = 2 },
  { text = "Medium", value = 3 },
  { text = "High", value = 4 },
  { text = "Dialog", value = 5 },
}

local FRAME_STRATA_VALUES = {
  [1] = "BACKGROUND",
  [2] = "LOW",
  [3] = "MEDIUM",
  [4] = "HIGH",
  [5] = "DIALOG",
}

local GetResourceTrackerDB = BUII_ResourceTracker_GetDB
local GetActiveConfig = BUII_ResourceTracker_GetActiveConfig

local GetResourceState = BUII_ResourceTracker_GetResourceState

---@type boolean|nil
local nativeFrameHideHook = nil

local function UpdateNativeFrameVisibility()
  local db = GetResourceTrackerDB()
  local config = GetActiveConfig()

  if not config then
    local _, classFilename = UnitClass("player")
    local rawConfig = BUII_ResourceTracker_CONFIG[classFilename]
    if rawConfig and rawConfig.nativeFrame then
      local nativeFrame = _G[rawConfig.nativeFrame]
      if nativeFrame then
        nativeFrame:Show()
      end
    end
    return
  end

  if not config.nativeFrame then
    return
  end

  local shouldHide = db.resource_tracker_hide_native or false
  local nativeFrame = _G[config.nativeFrame]

  if nativeFrame then
    if shouldHide then
      nativeFrame:Hide()
      if not nativeFrameHideHook then
        nativeFrameHideHook = true
        hooksecurefunc(nativeFrame, "Show", function(self)
          local currentDb = GetResourceTrackerDB()
          if currentDb.resource_tracker_hide_native and GetActiveConfig() then
            self:Hide()
          end
        end)
      end
    else
      nativeFrame:Show()
    end
  end
end

local function UpdatePoints()
  if not frame or frame.isApplyingSettings then
    return
  end

  local db = GetResourceTrackerDB()
  local config = GetActiveConfig()
  local isEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()

  local strataIndex = db.resource_tracker_frame_strata or 2
  local strataValue = FRAME_STRATA_VALUES[strataIndex] or "LOW"
  frame:SetFrameStrata(strataValue)

  if not config and not isEditMode then
    frame:Hide()
    return
  end

  local currentStacks = 0 --[[@as number]]
  local partialFill = 0
  local chargedPoints = nil
  local maxPoints = 5
  local color = { r = 1, g = 1, b = 1 }
  local color2 = nil
  local layered = false

  if isEditMode then
    currentStacks = 3
    partialFill = 0.5
    maxPoints = 5
    if config then
      if config.isBar then
        currentStacks = 50
        partialFill = 0.5
      elseif config.powerType then
        maxPoints = UnitPowerMax("player", config.powerType) or config.maxPoints or 5
      else
        maxPoints = config.maxPoints or 5
      end
      color = config.color
      color2 = config.color2
      layered = config.layered
      if layered then
        currentStacks = 7
      end
      if config.class == "ROGUE" then
        chargedPoints = { 2, 4 }
      end
    else
      color = { r = 1, g = 1, b = 0 }
    end
    frame:Show()
  elseif config then
    if config.maxPoints then
      maxPoints = config.maxPoints
    elseif config.isBar or config.hidePrimary or config.powerType == Enum.PowerType.Mana then
      maxPoints = 0
    elseif config.powerType then
      maxPoints = UnitPowerMax("player", config.powerType) or 0
    else
      maxPoints = 5
    end

    local shouldShow = true
    if maxPoints == 0 and not config.isBar and not config.hidePrimary and not db.resource_tracker_show_power_bar then
      shouldShow = false
    end

    if config.class == "DRUID" then
      local powerType = UnitPowerType("player")
      if powerType ~= Enum.PowerType.Energy then
        shouldShow = false
      end
    end

    if not shouldShow and not isEditMode then
      frame:Hide()
      return
    end

    color = config.color
    color2 = config.color2
    layered = config.layered

    local extraData
    currentStacks, partialFill, extraData = GetResourceState(config)

    if extraData and type(extraData) == "table" and extraData.r then
      color = extraData
    else
      chargedPoints = extraData
    end

    local currentStacksIsSecret = issecretvalue(currentStacks)
    if not currentStacksIsSecret and type(currentStacks) ~= "number" then
      currentStacks = 0
    end

    frame:Show()
    UpdateNativeFrameVisibility()
  end

  if maxPoints > 0 then
    for i = 1, maxPoints do
      if not points[i] then
        points[i] = CreateFrame("Frame", nil, frame, "BUII_ResourcePointTemplate") --[[@as BUII_ResourcePointTemplate]]
      end
    end
  end

  local spacing = db.currentSpacing or 2
  local totalWidth = db.currentTotalWidth or 174
  local height = db.currentHeight or 12
  local showBorder = db.resource_tracker_show_border or false
  local useClassColor = db.resource_tracker_use_class_color or false
  local bgOpacity = tonumber(db.resource_tracker_background_opacity) or 0.5

  local classColor = nil
  if useClassColor then
    local _, classFilename = UnitClass("player")
    local classColorTable = C_ClassColor.GetClassColor(classFilename)
    if classColorTable then
      classColor = { r = classColorTable.r, g = classColorTable.g, b = classColorTable.b }
    end
  end

  local pointWidth = 0
  if maxPoints > 0 then
    pointWidth = (totalWidth - (spacing * (maxPoints - 1))) / maxPoints
  end
  local currentStacksIsSecret = issecretvalue(currentStacks)

  local showPowerBar = db.resource_tracker_show_power_bar

  if config and config.isBar then
    for i = 1, #points do
      points[i]:Hide()
    end

    frame.ResourceBar:Show()
    frame.ResourceBar:ClearAllPoints()
    if showPowerBar then
      frame.ResourceBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    else
      frame.ResourceBar:SetPoint("LEFT", frame, "LEFT", 0, 0)
    end
    frame.ResourceBar:SetSize(totalWidth, height)

    -- Update Textures
    frame.ResourceBar.Background:SetTexture(BUII_GetTexturePath())
    frame.ResourceBar.Background:SetVertexColor(0.1, 0.1, 0.1, bgOpacity)
    frame.ResourceBar.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())

    local drawColor = color
    if classColor then
      drawColor = classColor
    end

    frame.ResourceBar.ProgressBar:SetStatusBarColor(drawColor.r, drawColor.g, drawColor.b, db.currentOpacity or 1)

    if UnitPowerPercent and config.powerType then
      frame.ResourceBar.ProgressBar:SetMinMaxValues(0, 1)
      frame.ResourceBar.ProgressBar:SetValue(UnitPowerPercent("player", config.powerType))
    else
      frame.ResourceBar.ProgressBar:SetMinMaxValues(0, 1)
      frame.ResourceBar.ProgressBar:SetValue(partialFill)
    end

    local borderColor = { r = 0, g = 0, b = 0, a = 0 }
    if showBorder then
      borderColor = { r = 0, g = 0, b = 0, a = 1 }
    end
    frame.ResourceBar:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
  elseif config and config.hidePrimary then
    for i = 1, #points do
      points[i]:Hide()
    end
    frame.ResourceBar.ProgressBar:Hide()
  else
    frame.ResourceBar:Hide()
    for i = 1, #points do
      local point = points[i]
      if i <= maxPoints then
        point:Show()
        point:SetSize(pointWidth, height)
        point:ClearAllPoints()

        -- Simple horizontal layout
        if i == 1 then
          if showPowerBar then
            point:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
          else
            point:SetPoint("LEFT", frame, "LEFT", 0, 0)
          end
        else
          point:SetPoint("LEFT", points[i - 1], "RIGHT", spacing, 0)
        end

        local isCharged = false
        if chargedPoints then
          for _, cpIndex in ipairs(chargedPoints) do
            if cpIndex == i then
              isCharged = true
              break
            end
          end
        end

        local drawColor = color
        local isOvercharge = false
        if not currentStacksIsSecret and layered and currentStacks > maxPoints and i <= (currentStacks - maxPoints) then
          drawColor = color2
          isOvercharge = true
        end

        if classColor and not isOvercharge then
          drawColor = classColor
        end

        if isCharged and config and config.colorCharged then
          drawColor = config.colorCharged
        end

        local borderColor = { r = 0, g = 0, b = 0, a = 0 }
        if isCharged and config and config.colorCharged then
          borderColor = { r = config.colorCharged.r, g = config.colorCharged.g, b = config.colorCharged.b, a = 1 }
        elseif showBorder then
          borderColor = { r = 0, g = 0, b = 0, a = 1 }
        end

        point:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

        point.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())

        if not point.AnimTexture then
          point.AnimTexture = point:CreateTexture(nil, "ARTWORK")
          point.AnimTexture:SetPoint("TOPLEFT", point, "TOPLEFT", 1, -1)
          point.AnimTexture:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", 1, 1)
          point.AnimTexture:SetTexture(BUII_GetTexturePath())

          point.AnimGroup = point.AnimTexture:CreateAnimationGroup()
          point.ScaleAnim = point.AnimGroup:CreateAnimation("Scale")
          point.ScaleAnim:SetOrigin("LEFT", 0, 0)
        end

        local isFull = false
        if not currentStacksIsSecret then
          isFull = (i <= currentStacks)
        end

        local myPartial = 0
        local myPartialData = nil
        if type(partialFill) == "table" then
          if partialFill[i] then
            if type(partialFill[i]) == "table" then
              myPartialData = partialFill[i]
            elseif type(partialFill[i]) == "number" then
              myPartial = partialFill[i]
            end
          end
        elseif type(partialFill) == "number" and i == currentStacks + 1 then
          myPartial = partialFill
        end

        if currentStacksIsSecret then
          point.ProgressBar:SetMinMaxValues(i - 1, i)
          point.ProgressBar:SetValue(currentStacks)
          point.ProgressBar:SetStatusBarColor(drawColor.r, drawColor.g, drawColor.b, db.currentOpacity or 1)
          point.ProgressBar:Show()

          point.AnimGroup:Stop()
          point.AnimTexture:Hide()
          point.lastStart = nil
          point.lastDuration = nil
        elseif isFull then
          point.ProgressBar:SetMinMaxValues(0, 1)
          if point.ProgressBar.ResetSmoothedValue then
            point.ProgressBar:ResetSmoothedValue(1)
          else
            point.ProgressBar:SetValue(1)
          end
          point.ProgressBar:SetStatusBarColor(drawColor.r, drawColor.g, drawColor.b, db.currentOpacity or 1)
          point.ProgressBar:Show()

          point.AnimGroup:Stop()
          point.AnimTexture:Hide()
          point.lastStart = nil
          point.lastDuration = nil
        elseif myPartialData then
          if myPartialData.isQueued then
            if point.ProgressBar.ResetSmoothedValue then
              point.ProgressBar:ResetSmoothedValue(0)
            else
              point.ProgressBar:SetValue(0)
            end
            point.ProgressBar:Hide()
            point.AnimTexture:Hide()
            point.AnimGroup:Stop()
            point.lastStart = nil
            point.lastDuration = nil
          else
            point.ProgressBar:Hide()
            point.AnimTexture:Show()
            point.AnimTexture:SetVertexColor(drawColor.r, drawColor.g, drawColor.b, (db.currentOpacity or 1) * 0.7)

            if myPartialData.start then
              if
                point.lastStart ~= myPartialData.start
                or math.abs((point.lastDuration or 0) - myPartialData.duration) > 0.01
              then
                point.lastStart = myPartialData.start
                point.lastDuration = myPartialData.duration

                local now = GetTime()
                local offset = math.max(0, now - myPartialData.start)

                local totalWidth = pointWidth - 2
                point.AnimTexture:SetWidth(totalWidth)

                point.ScaleAnim:SetScaleFrom(0, 1)
                point.ScaleAnim:SetScaleTo(1, 1)
                point.ScaleAnim:SetDuration(myPartialData.duration)

                point.AnimGroup:Restart(false, offset)
              end
            end
          end
        elseif myPartial > 0 then
          point.AnimGroup:Stop()
          point.AnimTexture:Hide()
          point.lastStart = nil
          point.lastDuration = nil

          if
            point.ProgressBar.SetSmoothedValue
            and not (config.class == "EVOKER" and config.powerType == Enum.PowerType.Essence)
          then
            point.ProgressBar:SetSmoothedValue(myPartial)
          else
            point.ProgressBar:SetValue(myPartial)
          end
          point.ProgressBar:SetStatusBarColor(drawColor.r, drawColor.g, drawColor.b, (db.currentOpacity or 1) * 0.7)
          point.ProgressBar:Show()
        else
          if point.ProgressBar.ResetSmoothedValue then
            point.ProgressBar:ResetSmoothedValue(0)
          else
            point.ProgressBar:SetValue(0)
          end
          point.ProgressBar:Hide()
          point.AnimGroup:Stop()
          point.AnimTexture:Hide()
          point.lastStart = nil
          point.lastDuration = nil
        end

        point.Background:SetTexture(BUII_GetTexturePath())
        point.Background:SetVertexColor(0.1, 0.1, 0.1, bgOpacity)
      else
        point:Hide()
      end
    end
  end

  if showPowerBar then
    local powerBarHeight = db.resource_tracker_power_bar_height or 4
    local padding = db.resource_tracker_power_bar_padding or 2
    local totalFrameHeight = height + padding + powerBarHeight

    frame.PowerBar:ClearAllPoints()
    frame.PowerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(height + padding))

    if frame.PowerBar:GetWidth() ~= totalWidth or frame.PowerBar:GetHeight() ~= powerBarHeight then
      frame.PowerBar:SetSize(totalWidth, powerBarHeight)
    end

    frame.PowerBar:Show()

    local borderColor = { r = 0, g = 0, b = 0, a = 0 }
    if showBorder then
      borderColor = { r = 0, g = 0, b = 0, a = 1 }
    end
    frame.PowerBar:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    frame.PowerBar.Background:SetTexture(BUII_GetTexturePath())
    frame.PowerBar.Background:SetVertexColor(0.1, 0.1, 0.1, bgOpacity)
    frame.PowerBar.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())

    local powerType, powerToken = UnitPowerType("player")
    if config.powerId then
      powerType = config.powerId
    end
    if config.powerKey then
      powerToken = config.powerKey
    end
    local powerColor = PowerBarColor[powerToken] or PowerBarColor[powerType] or { r = 1, g = 1, b = 1 }
    frame.PowerBar.ProgressBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)

    local current = UnitPower("player", powerType)
    local max = UnitPowerMax("player", powerType)

    local powerPercent = UnitPowerPercent("player")
    if not issecretvalue(powerPercent) then
      frame.PowerBar.ProgressBar:SetMinMaxValues(0, 1)
      frame.PowerBar.ProgressBar:SetValue(powerPercent)
    else
      frame.PowerBar.ProgressBar:SetMinMaxValues(0, max)
      frame.PowerBar.ProgressBar:SetValue(current)
    end

    if db.resource_tracker_power_bar_show_text then
      frame.PowerBar.PowerText:Show()
      frame.PowerBar.PowerText:SetText(BUII_FormatNumber(current))
      frame.PowerBar.PowerText:SetFont(
        BUII_GetFontPath(),
        db.resource_tracker_power_bar_font_size or 12,
        BUII_GetFontFlags()
      )
    else
      frame.PowerBar.PowerText:Hide()
    end

    if frame:GetWidth() ~= totalWidth or frame:GetHeight() ~= totalFrameHeight then
      frame:SetSize(totalWidth, totalFrameHeight)
    end
  else
    frame.PowerBar:Hide()
    if frame:GetWidth() ~= totalWidth or frame:GetHeight() ~= height then
      frame:SetSize(totalWidth, height)
    end
  end

  if db.showText and config and not config.hidePrimary then
    counterText:Show()
    counterText:ClearAllPoints()
    if config and config.isBar then
      counterText:SetPoint("CENTER", frame.ResourceBar, "CENTER", 0, 0)
    else
      counterText:SetPoint("CENTER", frame, "TOPLEFT", totalWidth / 2, -height / 2)
    end

    local displayText = ""
    if config and config.isBar then
      displayText = BUII_FormatNumber(currentStacks)
    else
      displayText = tostring(currentStacks)
    end

    if not config or not config.isBar then
      if db.resource_tracker_show_decimal then
        local decimalPart = 0
        if type(partialFill) == "number" then
          decimalPart = partialFill
        elseif type(partialFill) == "table" and partialFill[1] then
          if type(partialFill[1]) == "table" and partialFill[1].progress then
            decimalPart = partialFill[1].progress
          elseif type(partialFill[1]) == "number" then
            decimalPart = partialFill[1]
          end
        end

        if issecretvalue(currentStacks) or issecretvalue(decimalPart) then
          displayText = tostring(currentStacks)
        else
          displayText = string.format("%.1f", currentStacks + decimalPart)
        end
      end
    end
    counterText:SetText(displayText)
    counterText:SetFont(BUII_GetFontPath(), db.currentFontSize or 12, BUII_GetFontFlags())
    counterText:SetShadowOffset(BUII_GetFontShadow())
  else
    counterText:Hide()
  end
end

local function RequestUpdatePoints()
  RunNextFrame(UpdatePoints)
end

local function onEvent(self, event, ...)
  UpdatePoints()
end

local function BUII_ResourceTracker_Initialize()
  if frame then
    return
  end

  frame = CreateFrame("Frame", "BUII_ResourceTrackerFrame", UIParent, "BUII_ResourceTrackerEditModeTemplate")
  frame:SetSize(174, 20)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetDontSavePosition(true)
  frame:EnableMouse(false)
  frame:Hide()

  -- Expose DB selector for EditModeUtils
  frame.GetSettingsDB = GetResourceTrackerDB

  frame.PowerBar = CreateFrame("Frame", nil, frame, "BUII_PowerBarTemplate")
  frame.PowerBar:SetHeight(4)
  frame.PowerBar.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())
  frame.PowerBar:Hide()

  frame.ResourceBar = CreateFrame("Frame", nil, frame, "BUII_PowerBarTemplate")
  frame.ResourceBar:SetAllPoints(frame)
  frame.ResourceBar.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())
  frame.ResourceBar:Hide()

  local textFrame = CreateFrame("Frame", nil, frame)
  textFrame:SetAllPoints(frame)
  textFrame:SetFrameLevel(frame:GetFrameLevel() + 10)

  counterText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  counterText:SetPoint("CENTER", textFrame, "TOPLEFT", 85, -10)
  counterText:SetText("0")

  local config = GetActiveConfig()
  if config and config.class == "EVOKER" and config.powerType == Enum.PowerType.Essence then
    frame:SetScript("OnUpdate", function(self, elapsed)
      if not frame or frame.isApplyingSettings then
        return
      end
      local power = UnitPower("player", config.powerType)
      local partial = 0
      local maxPoints = UnitPowerMax("player", config.powerType)
      if not maxPoints or issecretvalue(maxPoints) then
        maxPoints = config.maxPoints or 5
      end

      if issecretvalue(power) and UnitPowerPercent then
        local percent = UnitPowerPercent("player", config.powerType)
        if percent and not issecretvalue(percent) then
          local floatPower = percent * maxPoints
          power = math.floor(floatPower)
          partial = floatPower - power
        else
          return
        end
      else
        partial = UnitPartialPower("player", config.powerType) or 0
        if issecretvalue(partial) then
          return
        end
        partial = partial / 1000
      end

      local fillIndex = power + 1
      if fillIndex <= maxPoints then
        local point = points[fillIndex]
        if point and point.ProgressBar and point.ProgressBar:IsShown() then
          point.ProgressBar:SetValue(partial)
        end
      end
    end)
  end

  local settingsConfig = {
    {
      setting = enum_ResourceTrackerSetting_TotalWidth,
      name = "Total Width",
      key = "resource_tracker_total_width",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 50,
      maxValue = 500,
      stepSize = 1,
      defaultValue = 174,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentTotalWidth or 174
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentTotalWidth = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_Height,
      name = "Height",
      key = "resource_tracker_height",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 5,
      maxValue = 50,
      stepSize = 1,
      defaultValue = 12,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentHeight or 12
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentHeight = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_Spacing,
      name = "Spacing",
      key = "resource_tracker_spacing",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 10,
      stepSize = 1,
      defaultValue = 2,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentSpacing or 2
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentSpacing = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_ResourceOpacity,
      name = "Resource Opacity",
      key = "resource_tracker_opacity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.1,
      maxValue = 1.0,
      stepSize = 0.1,
      formatter = BUII_EditModeUtils.FormatPercentage,
      defaultValue = 1.0,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentOpacity or 1.0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentOpacity = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_BackgroundOpacity,
      name = "Background Opacity",
      key = "resource_tracker_background_opacity",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0.0,
      maxValue = 1.0,
      stepSize = 0.1,
      formatter = BUII_EditModeUtils.FormatPercentage,
      defaultValue = 0.5,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_background_opacity or 0.5
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_background_opacity = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_ShowText,
      name = "Show Stack Counter",
      key = "resource_tracker_show_stacks",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.showText and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.showText = (val == 1)
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_FontSize,
      name = "Font Size",
      key = "resource_tracker_stacks_font_size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 32,
      stepSize = 1,
      defaultValue = 12,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.currentFontSize or 12
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.currentFontSize = val
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_ShowDecimal,
      name = "Show Decimal",
      key = "resource_tracker_show_decimal",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_show_decimal and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_show_decimal = (val == 1)
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_ShowBorder,
      name = "Show Border",
      key = "resource_tracker_show_border",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_show_border and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_show_border = (val == 1)
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_UseClassColor,
      name = "Use Class Color",
      key = "resource_tracker_use_class_color",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_use_class_color and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_use_class_color = (val == 1)
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_HideNativeFrame,
      name = "Hide Native Frame",
      key = "resource_tracker_hide_native",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_hide_native and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_hide_native = (val == 1)
        UpdateNativeFrameVisibility()
        UpdatePoints()
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_ShowPowerBar,
      name = "Show Power Bar",
      key = "resource_tracker_show_power_bar",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_show_power_bar and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_show_power_bar = (val == 1)
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_PowerBarHeight,
      name = "Power Bar Height",
      key = "resource_tracker_power_bar_height",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 2,
      maxValue = 20,
      stepSize = 1,
      defaultValue = 4,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_power_bar_height or 4
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_power_bar_height = val
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_PowerBarPadding,
      name = "Power Bar Padding",
      key = "resource_tracker_power_bar_padding",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 0,
      maxValue = 20,
      stepSize = 1,
      defaultValue = 2,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_power_bar_padding or 2
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_power_bar_padding = val
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_PowerBarShowText,
      name = "Power Bar Show Text",
      key = "resource_tracker_power_bar_show_text",
      type = Enum.EditModeSettingDisplayType.Checkbox,
      defaultValue = false,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_power_bar_show_text and 1 or 0
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_power_bar_show_text = (val == 1)
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_PowerBarFontSize,
      name = "Power Bar Font Size",
      key = "resource_tracker_power_bar_font_size",
      type = Enum.EditModeSettingDisplayType.Slider,
      minValue = 8,
      maxValue = 32,
      stepSize = 1,
      defaultValue = 12,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_power_bar_font_size or 12
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_power_bar_font_size = val
        if not f.isApplyingSettings then
          RequestUpdatePoints()
        end
      end,
    },
    {
      setting = enum_ResourceTrackerSetting_FrameStrata,
      name = "Frame Strata",
      key = "resource_tracker_frame_strata",
      type = Enum.EditModeSettingDisplayType.Dropdown,
      defaultValue = 2,
      options = FRAME_STRATA_OPTIONS,
      getter = function(f)
        local db = GetResourceTrackerDB()
        return db.resource_tracker_frame_strata or 2
      end,
      setter = function(f, val)
        local db = GetResourceTrackerDB()
        db.resource_tracker_frame_strata = val
        UpdatePoints()
      end,
    },
  }

  BUII_EditModeUtils:AddScaleSetting(
    settingsConfig,
    enum_ResourceTrackerSetting_Scale,
    "Scale",
    "resource_tracker_scale"
  )

  BUII_EditModeUtils:AddCharacterSpecificSetting(settingsConfig, "resource_tracker", UpdatePoints)

  BUII_EditModeUtils:RegisterSystem(
    frame,
    Enum.EditModeSystem.BUII_ResourceTracker,
    "Resource Tracker",
    settingsConfig,
    "resource_tracker",
    {
      OnReset = function(f)
        local db = GetResourceTrackerDB()
        db.currentSpacing = 2
        db.currentOpacity = 1.0
        db.currentTotalWidth = 174
        db.currentHeight = 12
        db.showText = false
        db.currentFontSize = 12
        db.resource_tracker_show_border = false
        db.resource_tracker_use_class_color = false
        db.resource_tracker_frame_strata = 2
        db.resource_tracker_background_opacity = 0.5
        db.resource_tracker_show_power_bar = false
        db.resource_tracker_power_bar_height = 4
        db.resource_tracker_power_bar_padding = 2
        db.resource_tracker_power_bar_show_text = false
        db.resource_tracker_power_bar_font_size = 12
        UpdatePoints()
      end,

      OnApplySettings = function(f)
        UpdatePoints()
      end,
      OnEditModeEnter = function(f)
        UpdatePoints()
      end,
      OnEditModeExit = function(f)
        if not InCombatLockdown() then
          UpdatePoints()
        end
      end,
    }
  )
end

function BUII_ResourceTracker_Enable()
  BUII_ResourceTracker_Initialize()

  frame:RegisterUnitEvent("UNIT_AURA", "player")
  frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
  frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
  frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
  frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
  frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player")
  frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
  frame:RegisterEvent("SPELL_UPDATE_CHARGES")
  frame:RegisterEvent("RUNE_POWER_UPDATE")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", onEvent)
  frame:Show()

  BUII_EditModeUtils:ApplySavedPosition(frame, "resource_tracker")
  UpdatePoints()
  UpdateNativeFrameVisibility()
end

function BUII_ResourceTracker_Disable()
  if not frame then
    return
  end

  frame:UnregisterAllEvents()
  frame:SetScript("OnEvent", nil)
  frame:Hide()

  local _, classFilename = UnitClass("player")
  local config = BUII_ResourceTracker_CONFIG[classFilename]
  if config and config.nativeFrame then
    local nativeFrame = _G[config.nativeFrame]
    if nativeFrame then
      nativeFrame:Show()
    end
  end
end

function BUII_ResourceTracker_Refresh()
  if frame then
    UpdatePoints()
  end
end

local DB_DEFAULTS = {
  resource_tracker = false,
  resource_tracker_shaman = true,
  resource_tracker_demonhunter = true,
  resource_tracker_warlock = true,
  resource_tracker_paladin = true,
  resource_tracker_priest = true,
  resource_tracker_monk = true,
  resource_tracker_deathknight = true,
  resource_tracker_evoker = true,
  resource_tracker_hunter = true,
  resource_tracker_rogue = true,
  resource_tracker_druid = true,
  resource_tracker_mage = true,
  resource_tracker_show_border = false,
  resource_tracker_use_class_color = false,
  resource_tracker_hide_native = false,
  resource_tracker_show_power_bar = false,
  resource_tracker_power_bar_height = 4,
  resource_tracker_power_bar_padding = 2,
  resource_tracker_power_bar_show_text = false,
  resource_tracker_power_bar_font_size = 12,
  resource_tracker_frame_strata = 2,
}

local CHAR_DB_DEFAULTS = {
  resource_tracker_use_char_settings = false,
  resource_tracker_show_border = false,
  resource_tracker_use_class_color = false,
  resource_tracker_hide_native = false,
  resource_tracker_show_power_bar = false,
  resource_tracker_power_bar_height = 4,
  resource_tracker_power_bar_padding = 2,
  resource_tracker_power_bar_show_text = false,
  resource_tracker_power_bar_font_size = 12,
  resource_tracker_frame_strata = 2,
}

function BUII_ResourceTracker_InitDB()
  MergeDefaults(BUIIDatabase, DB_DEFAULTS)
  MergeDefaults(BUIICharacterDatabase, CHAR_DB_DEFAULTS)
end

BUII_RegisterModule({
  dbKey = "resource_tracker",
  enable = BUII_ResourceTracker_Enable,
  disable = BUII_ResourceTracker_Disable,
  refresh = BUII_ResourceTracker_Refresh,
  refreshTexture = true,
  checkboxPath = "weakAura.ResourceTracker",
  alwaysSetChecked = true,
})
