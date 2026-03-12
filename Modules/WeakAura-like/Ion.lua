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

local DB_DEFAULTS = {
  ion_mode = false,
}

function BUII_Ion_InitDB()
  MergeDefaults(BUIIDatabase, DB_DEFAULTS)
end
