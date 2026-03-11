local actionBarHookSet = false

--- Experimental function to fix action bar minimum padding setting
---@return nil
local function experimentalFixPaddingMinSetting()
  -- Set icon padding to 0
  -- EditModePresetLayoutManager:GetModernSystemMap()[Enum.EditModeSystem.ActionBar][
  -- 	 Enum.EditModeActionBarSystemIndices.MainBar]["settings"][4] = 0
  -- -- verify value
  -- for key, value in pairs(EditModePresetLayoutManager:GetModernSystemMap()[Enum.EditModeSystem.ActionBar][
  -- 	Enum.EditModeActionBarSystemIndices.MainBar]["settings"]) do
  -- 	print("Key: ", key, " Value: ", value)
  -- end
  -- EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[Enum.EditModioeSystem.ActionBar][5] = {
  -- 	minValue = 0,
  -- }

  -- local kiddos = { MainMenuBar:GetChildren() };
  -- for _, child in ipairs(kiddos) do
  -- 	if child.SetPadding ~= nil then
  -- 		 print(child:GetName(), " can set padding!")
  -- 	else
  -- 		print(child:GetName(), " can't set padding :(")
  -- 		local grand_kiddos = { child:GetChildren() };
  -- 		for _, grand_child in ipairs(grand_kiddos) do

  -- 			if grand_child.SetPadding ~= nil then
  -- 				 print(grand_child:GetName(), " can set padding!")
  -- 			else
  -- 				print(grand_child:GetName(), " can't set padding :(")
  -- 			end
  -- 		end
  -- 	end
  -- end

  local layout
  if true then
    layout = GridLayoutUtil.CreateStandardGridLayout(stride, buttonPadding, buttonPadding, xMultiplier, yMultiplier)
  else
    layout = GridLayoutUtil.CreateVerticalGridLayout(stride, buttonPadding, buttonPadding, xMultiplier, yMultiplier)
  end
end

--- Sets the button padding for a specific action bar
---@param actionBar Frame|any
---@param padding number
---@return nil
local function setButtonPaddingOnActionBar(actionBar, padding)
  if padding < actionBar.minButtonPadding then
    actionBar.minButtonPadding = padding
  end
  actionBar.buttonPadding = padding

  if actionBar.UpdateGridLayout then
    actionBar:UpdateGridLayout()
  end
end

--- OnUpdate handler for action bars to enforce padding
---@param self Frame|any
---@param arg1 any
---@param ... any
---@return nil
local function actionBar_OnUpdate(self, arg1, ...)
  if self.minButtonPadding ~= 0 then
    self.minButtonPadding = 0
    self.buttonPadding = 0
    -- Call show to make the changes take effect visually
    -- self:Show()
  end
end

--- Disables the overlay border for a given action bar
---@param actionBarName string
---@return nil
local function disableBorderOnActionBar(actionBarName)
  for i = 0, 12 do
    local button = _G[actionBarName .. "Button" .. i]
    if button then
      button:DisableDrawLayer("OVERLAY")
    end
  end
end

--- Enables the overlay border for a given action bar
---@param actionBarName string
---@return nil
local function enableBorderOnActionBar(actionBarName)
  for i = 0, 12 do
    local button = _G[actionBarName .. "Button" .. i]
    if button then
      button:EnableDrawLayer("OVERLAY")
    end
  end
end

--- Enables the experimental no-padding feature for action bars
---@return nil
function BUII_ActionBarsImprovedNoPaddingEnable()
  -- if not actionBarHookSet then
  -- 	StanceBar:HookScript("OnUpdate", actionBar_OnUpdate)
  -- 	MainMenuBar:HookScript("OnUpdate", actionBar_OnUpdate)
  -- 	MultiBarLeft:HookScript("OnUpdate", actionBar_OnUpdate)
  -- 	MultiBarRight:HookScript("OnUpdate", actionBar_OnUpdate)
  -- 	MultiBarBottomLeft:HookScript("OnUpdate", actionBar_OnUpdate)
  -- 	MultiBarBottomRight:HookScript("OnUpdate", actionBar_OnUpdate)
  -- 	actionBarHookSet = true
  -- end

  experimentalFixPaddingMinSetting()

  -- BUIIDatabase["no_action_bar_padding"] = true

  -- setButtonPaddingOnActionBar(StanceBar, 0)
  -- setButtonPaddingOnActionBar(MainMenuBar, 0)
  -- setButtonPaddingOnActionBar(MultiBarLeft, 0)
  -- setButtonPaddingOnActionBar(MultiBarRight, 0)
  -- setButtonPaddingOnActionBar(MultiBarBottomLeft, 0)
  -- setButtonPaddingOnActionBar(MultiBarBottomRight, 0)

  -- disableBorderOnActionBar("Stance")
  -- disableBorderOnActionBar("Action")
  -- disableBorderOnActionBar("MultiBarLeft")
  -- disableBorderOnActionBar("MultiBarRight")
  -- disableBorderOnActionBar("MultiBarBottomLeft")
  -- disableBorderOnActionBar("MultiBarBottomRight")
end

--- Disables the no-padding feature for action bars
---@return nil
function BUII_ActionBarsImprovedNoPaddingDisable()
  BUIIDatabase["no_action_bar_padding"] = false
  -- enableBorderOnActionBar("Stance")
  -- enableBorderOnActionBar("Action")
  -- enableBorderOnActionBar("MultiBarLeft")
  -- enableBorderOnActionBar("MultiBarRight")
  -- enableBorderOnActionBar("MultiBarBottomLeft")
  -- enableBorderOnActionBar("MultiBarBottomRight")
end
