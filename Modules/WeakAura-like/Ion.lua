---@type Frame
local frame = CreateFrame("Frame", "BUII_IonFrame", UIParent)
---@type string
local soundFile = "Interface\\AddOns\\BravosUIImprovements\\Media\\Sound\\frankly.ogg"

--- Handles player death event for Ion mode
---@param self Frame
---@param event string
---@return nil
local function onEvent(self, event)
  if event == "PLAYER_DEAD" then
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
      return
    end
    PlaySoundFile(soundFile, "Master")
  end
end

--- Enables Ion mode sound on player death
---@return nil
function BUII_Ion_Enable()
  frame:RegisterEvent("PLAYER_DEAD")
  frame:SetScript("OnEvent", onEvent)
end

--- Disables Ion mode
---@return nil
function BUII_Ion_Disable()
  frame:UnregisterEvent("PLAYER_DEAD")
  frame:SetScript("OnEvent", nil)
end

--- Initializes Ion mode setting defaults into the DB
---@return nil
function BUII_Ion_InitDB()
  if BUIIDatabase["ion_mode"] == nil then
    BUIIDatabase["ion_mode"] = false
  end
end
