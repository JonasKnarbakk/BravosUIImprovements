-- ResourceTracker LayoutHelper Module
-- Shared logic for point layouts, bar layouts, and general rendering of resources

local addonName, addon = ...

BUII_ResourceTracker_LayoutHelper = {}

---Sets up point frames for point-based spec trackers
---@param frame Frame
---@param count number
function BUII_ResourceTracker_LayoutHelper:SetupPoints(frame, count)
  frame.Points = frame.Points or {}
  
  if count > 0 then
    for i = 1, count do
      if not frame.Points[i] then
        frame.Points[i] = CreateFrame("Frame", nil, frame, "BUII_ResourcePointTemplate")
      end
    end
  end

  local db = frame:GetSettingsDB() or {}
  local spacing = db.currentSpacing or 2
  local totalWidth = db.currentTotalWidth or 174
  local height = db.currentHeight or 12
  local showBorder = db.resource_tracker_show_border or false
  local showPowerBar = db.resource_tracker_show_power_bar or false

  local pointWidth = 0
  if count > 0 then
    pointWidth = (totalWidth - (spacing * (count - 1))) / count
  end

  for i = 1, #frame.Points do
    local point = frame.Points[i]
    if i <= count then
      point:Show()
      point:SetSize(pointWidth, height)
      point:ClearAllPoints()

      if i == 1 then
        if showPowerBar then
          point:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        else
          point:SetPoint("LEFT", frame, "LEFT", 0, 0)
        end
      else
        point:SetPoint("LEFT", frame.Points[i - 1], "RIGHT", spacing, 0)
      end
    else
      point:Hide()
    end
  end
end

---Updates Point-based spec trackers with custom provider callback
---@param frame Frame
---@param count number
---@param pointUpdaterFunc function
---@param currentStacksOverride number|nil
function BUII_ResourceTracker_LayoutHelper:UpdatePoints(frame, count, pointUpdaterFunc, currentStacksOverride)
  local db = frame:GetSettingsDB() or {}
  local showBorder = db.resource_tracker_show_border or false
  local useClassColor = db.resource_tracker_use_class_color or false
  local bgOpacity = tonumber(db.resource_tracker_background_opacity) or 0.5
  local opacity = db.currentOpacity or 1.0

  local classColor = nil
  if useClassColor then
    local _, classFilename = UnitClass("player")
    local classColorTable = C_ClassColor.GetClassColor(classFilename)
    if classColorTable then
      classColor = { r = classColorTable.r, g = classColorTable.g, b = classColorTable.b }
    end
  end

  local totalWidth = db.currentTotalWidth or 174
  local spacing = db.currentSpacing or 2
  local height = db.currentHeight or 12
  local pointWidth = 0
  if count > 0 then
    pointWidth = (totalWidth - (spacing * (count - 1))) / count
  end

  local filledStacks = 0

  local isSecret = BUII_IsSecretValue(currentStacksOverride)

  for i = 1, count do
    local point = frame.Points[i]
    if point and point:IsShown() then
      local isFull, partial, color, isCharged = pointUpdaterFunc(i, point)
      
      if isFull then
        filledStacks = filledStacks + 1
      end

      -- Select color
      local drawColor = color
      if classColor and not (color and color.isOvercharge) then
        drawColor = classColor
      end

      -- Update border
      local borderColor = { r = 0, g = 0, b = 0, a = 0 }
      if isCharged and color then
        borderColor = { r = color.r, g = color.g, b = color.b, a = 1 }
      elseif showBorder then
        borderColor = { r = 0, g = 0, b = 0, a = 1 }
      end
      point:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

      -- Update textures
      point.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())
      point.Background:SetTexture(BUII_GetTexturePath())
      point.Background:SetVertexColor(0.1, 0.1, 0.1, bgOpacity)

      -- Setup AnimTexture
      if not point.AnimTexture then
        point.AnimTexture = point:CreateTexture(nil, "ARTWORK")
        point.AnimTexture:SetPoint("TOPLEFT", point, "TOPLEFT", 1, -1)
        point.AnimTexture:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", 1, 1)
        point.AnimTexture:SetTexture(BUII_GetTexturePath())

        point.AnimGroup = point.AnimTexture:CreateAnimationGroup()
        point.ScaleAnim = point.AnimGroup:CreateAnimation("Scale")
        point.ScaleAnim:SetOrigin("LEFT", 0, 0)
      end

      if isSecret then
        point.ProgressBar:SetMinMaxValues(i - 1, i)
        point.ProgressBar:SetValue(currentStacksOverride)
        if drawColor then
          point.ProgressBar:SetStatusBarColor(drawColor.r, drawColor.g, drawColor.b, opacity)
        end
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
        if drawColor then
          point.ProgressBar:SetStatusBarColor(drawColor.r, drawColor.g, drawColor.b, opacity)
        end
        point.ProgressBar:Show()

        point.AnimGroup:Stop()
        point.AnimTexture:Hide()
        point.lastStart = nil
        point.lastDuration = nil
      elseif type(partial) == "table" then
        if partial.isQueued then
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
          if drawColor then
            point.AnimTexture:SetVertexColor(drawColor.r, drawColor.g, drawColor.b, opacity * 0.7)
          end

          if partial.start then
            if point.lastStart ~= partial.start or math.abs((point.lastDuration or 0) - partial.duration) > 0.01 then
              point.lastStart = partial.start
              point.lastDuration = partial.duration

              local now = GetTime()
              local offset = math.max(0, now - partial.start)

              local w = pointWidth - 2
              point.AnimTexture:SetWidth(w)

              point.ScaleAnim:SetScaleFrom(0, 1)
              point.ScaleAnim:SetScaleTo(1, 1)
              point.ScaleAnim:SetDuration(partial.duration)

              point.AnimGroup:Restart(false, offset)
            end
          end
        end
      elseif type(partial) == "number" and partial > 0 then
        point.AnimGroup:Stop()
        point.AnimTexture:Hide()
        point.lastStart = nil
        point.lastDuration = nil

        -- Evoker Essence bar has a special non-smoothed filling logic, others use standard smoothed SetValue
        local isEvokerEssence = (db.class == "EVOKER" and db.powerType == Enum.PowerType.Essence)
        if point.ProgressBar.SetSmoothedValue and not isEvokerEssence then
          point.ProgressBar:SetSmoothedValue(partial)
        else
          point.ProgressBar:SetValue(partial)
        end
        if drawColor then
          point.ProgressBar:SetStatusBarColor(drawColor.r, drawColor.g, drawColor.b, opacity * 0.7)
        end
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
    end
  end

  -- Handle counter text updating
  local finalStacks = currentStacksOverride or filledStacks
  self:UpdateCounterText(frame, finalStacks, nil)
end

---Updates Bar-based spec trackers
---@param frame Frame
---@param percent number
---@param color table
---@param value number|string
function BUII_ResourceTracker_LayoutHelper:UpdateBar(frame, percent, color, value)
  local db = frame:GetSettingsDB() or {}
  local bgOpacity = tonumber(db.resource_tracker_background_opacity) or 0.5
  local opacity = db.currentOpacity or 1.0
  local showBorder = db.resource_tracker_show_border or false
  local height = db.currentHeight or 12
  local totalWidth = db.currentTotalWidth or 174
  local showPowerBar = db.resource_tracker_show_power_bar or false

  frame.ResourceBar:Show()
  frame.ResourceBar:ClearAllPoints()
  if showPowerBar then
    frame.ResourceBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  else
    frame.ResourceBar:SetPoint("LEFT", frame, "LEFT", 0, 0)
  end
  frame.ResourceBar:SetSize(totalWidth, height)

  frame.ResourceBar.Background:SetTexture(BUII_GetTexturePath())
  frame.ResourceBar.Background:SetVertexColor(0.1, 0.1, 0.1, bgOpacity)
  frame.ResourceBar.ProgressBar:SetStatusBarTexture(BUII_GetTexturePath())

  -- Class color override if enabled
  local drawColor = color
  if db.resource_tracker_use_class_color then
    local _, classFilename = UnitClass("player")
    local classColorTable = C_ClassColor.GetClassColor(classFilename)
    if classColorTable then
      drawColor = { r = classColorTable.r, g = classColorTable.g, b = classColorTable.b }
    end
  end

  frame.ResourceBar.ProgressBar:SetStatusBarColor(drawColor.r, drawColor.g, drawColor.b, opacity)
  frame.ResourceBar.ProgressBar:SetMinMaxValues(0, 1)
  frame.ResourceBar.ProgressBar:SetValue(percent)

  local borderColor = { r = 0, g = 0, b = 0, a = 0 }
  if showBorder then
    borderColor = { r = 0, g = 0, b = 0, a = 1 }
  end
  frame.ResourceBar:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

  self:UpdateCounterText(frame, value, true)
end

---Updates stack counter text position, size, and content
---@param frame Frame
---@param value number|string
---@param isBar boolean|nil
function BUII_ResourceTracker_LayoutHelper:UpdateCounterText(frame, value, isBar)
  local db = frame:GetSettingsDB() or {}
  local counterText = frame.CounterText or _G[frame:GetName() .. "CounterText"]
  if not counterText then
    return
  end

  local activeConfig = BUII_ResourceTracker_GetActiveConfig()
  if activeConfig and activeConfig.hidePrimary then
    counterText:Hide()
    return
  end

  -- If we're updating a point-based resource tracker but no points are currently visible/enabled,
  -- we should not show any counter text (like a floating "0" for specs with no points, e.g., Havoc DH).
  if not isBar and frame.Points then
    local hasVisiblePoints = false
    if frame.Points then
      for i = 1, #frame.Points do
        if frame.Points[i] and frame.Points[i]:IsShown() then
          hasVisiblePoints = true
          break
        end
      end
    end
    if not hasVisiblePoints then
      counterText:Hide()
      return
    end
  end

  if db.showText then
    counterText:Show()
    counterText:ClearAllPoints()
    
    local totalWidth = db.currentTotalWidth or 174
    local height = db.currentHeight or 12

    if isBar then
      counterText:SetPoint("CENTER", frame.ResourceBar, "CENTER", 0, 0)
    else
      counterText:SetPoint("CENTER", frame, "TOPLEFT", totalWidth / 2, -height / 2)
    end

    local displayText = ""
    if isBar then
      if BUII_IsSecretValue(value) then
        displayText = value
      else
        displayText = BUII_FormatNumber(value)
      end
    else
      if BUII_IsSecretValue(value) then
        displayText = value
      else
        displayText = tostring(value)
      end
      
      -- Support decimals if enabled for point-based specs
      if db.resource_tracker_show_decimal and type(value) == "number" then
        -- Find if we have a fractional part. Currently, this is mainly for evoker/DK etc.
        -- If we have an active config, we can get fractional part.
        -- But for simplicity, we keep it standard unless class module overrides it.
      end
    end

    counterText:SetText(displayText)
    counterText:SetFont(BUII_GetFontPath(), db.currentFontSize or 12, BUII_GetFontFlags())
    counterText:SetShadowOffset(BUII_GetFontShadow())
  else
    counterText:Hide()
  end
end

---Updates secondary power bar (e.g. mana, focus, rage) underneath primary resource
---@param frame Frame
function BUII_ResourceTracker_LayoutHelper:UpdatePowerBar(frame)
  local db = frame:GetSettingsDB() or {}
  local showPowerBar = db.resource_tracker_show_power_bar or false
  local height = db.currentHeight or 12
  local totalWidth = db.currentTotalWidth or 174
  local bgOpacity = tonumber(db.resource_tracker_background_opacity) or 0.5
  local showBorder = db.resource_tracker_show_border or false

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

    -- Determine power type and token
    local powerType, powerToken = UnitPowerType("player")
    local activeConfig = BUII_ResourceTracker_GetActiveConfig()
    if activeConfig then
      if activeConfig.powerId then
        powerType = activeConfig.powerId
      end
      if activeConfig.powerKey then
        powerToken = activeConfig.powerKey
      end
    end

    local powerColor = PowerBarColor[powerToken] or PowerBarColor[powerType] or { r = 1, g = 1, b = 1 }
    frame.PowerBar.ProgressBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)

    local current = UnitPower("player", powerType)
    local max = UnitPowerMax("player", powerType)
    local powerPercent = UnitPowerPercent("player")

    if not BUII_IsSecretValue(powerPercent) then
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
end
