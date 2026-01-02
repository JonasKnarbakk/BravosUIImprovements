local frame = CreateFrame("Frame", "BUII_IonFrame", UIParent)
local soundFile = "Interface\\AddOns\\BravosUIImprovements\\Media\\Sound\\frankly.ogg"

local function onEvent(self, event)
  if event == "PLAYER_DEAD" then
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
      return
    end
    PlaySoundFile(soundFile, "Master")
  end
end

function BUII_Ion_Enable()
  frame:RegisterEvent("PLAYER_DEAD")
  frame:SetScript("OnEvent", onEvent)
end

function BUII_Ion_Disable()
  frame:UnregisterEvent("PLAYER_DEAD")
  frame:SetScript("OnEvent", nil)
end
