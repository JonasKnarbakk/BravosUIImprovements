local addonName, addon = ...
local moveableTotemFrameEnabled = false
local originalParent = nil
local totemFrameOverlay = nil

-- Define global label
_G["BUII_HUD_EDIT_MODE_TOTEM_FRAME_LABEL"] = "Totem Frame"

local function setupTotemFrameOverlay()
    if totemFrameOverlay then return end
    
    local systemEnum = Enum.EditModeSystem.BUII_TotemFrame or 115
    local systemName = BUII_HUD_EDIT_MODE_TOTEM_FRAME_LABEL
    local dbKey = "totem_frame"
    
    totemFrameOverlay = CreateFrame("Frame", "BUIITotemFrameOverlay", UIParent, "BUII_TotemFrameEditModeTemplate")
    totemFrameOverlay:SetSize(120, 40)
    totemFrameOverlay:SetMovable(true)
    totemFrameOverlay:SetClampedToScreen(true)
    totemFrameOverlay:SetDontSavePosition(true)
    
    local settingsConfig = {
        -- Add scale later if needed
    }
    
    BUII_EditModeUtils:RegisterSystem(totemFrameOverlay, systemEnum, systemName, settingsConfig, dbKey, {
        OnApplySettings = function()
            if moveableTotemFrameEnabled and TotemFrame then
                TotemFrame:ClearAllPoints()
                TotemFrame:SetPoint("TOPLEFT", totemFrameOverlay, "TOPLEFT", 0, 0)
            end
        end,
        OnEditModeEnter = function()
            totemFrameOverlay:Show()
            if TotemFrame then
                -- Try to sync size, though TotemFrame might be empty/small if no totems
                local w, h = TotemFrame:GetSize()
                if w < 20 then w = 120 end
                if h < 20 then h = 40 end
                totemFrameOverlay:SetSize(w, h)
                
                TotemFrame:ClearAllPoints()
                TotemFrame:SetPoint("TOPLEFT", totemFrameOverlay, "TOPLEFT", 0, 0)
            end
        end,
        OnEditModeExit = function()
            totemFrameOverlay:Hide()
        end
    })
end

function BUII_MoveableTotemFrame_Enable()
    if not TotemFrame then return end
    moveableTotemFrameEnabled = true
    
    if not originalParent then
        originalParent = TotemFrame:GetParent()
    end
    
    -- Detach from managed container logic
    -- We replace the layoutParent with a dummy object so OnShow/OnHide calls don't crash
    if TotemFrame.layoutParent then
        TotemFrame.originalLayoutParent = TotemFrame.layoutParent
        
        -- Try to remove from the real manager first
        if TotemFrame.layoutParent.RemoveManagedFrame then
            TotemFrame.layoutParent:RemoveManagedFrame(TotemFrame)
        end
        
        -- Dummy manager
        TotemFrame.layoutParent = {
            AddManagedFrame = function() end,
            RemoveManagedFrame = function() end,
            Layout = function() end
        }
    end
    
    TotemFrame:SetParent(UIParent)
    
    local function initOverlay()
        setupTotemFrameOverlay()
        -- Apply saved position
        if totemFrameOverlay then
            BUII_EditModeUtils:ApplySavedPosition(totemFrameOverlay, "totem_frame")
            TotemFrame:ClearAllPoints()
            TotemFrame:SetPoint("TOPLEFT", totemFrameOverlay, "TOPLEFT", 0, 0)
        end
    end

    if C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        initOverlay()
    else
        local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(self, event, arg1)
            if arg1 == "Blizzard_EditMode" then
                initOverlay()
                self:UnregisterAllEvents()
            end
        end)
    end
    
    -- Force layout update of the container we left, so other frames adjust
    if PlayerFrameBottomManagedFramesContainer then
        PlayerFrameBottomManagedFramesContainer:Layout()
    end
end

function BUII_MoveableTotemFrame_Disable()
    moveableTotemFrameEnabled = false
    
    if TotemFrame then
        if originalParent then
            TotemFrame:SetParent(originalParent)
        end
        if TotemFrame.originalLayoutParent then
            TotemFrame.layoutParent = TotemFrame.originalLayoutParent
        end
        
        TotemFrame:ClearAllPoints()
        
        -- Restore layout
        if PlayerFrameBottomManagedFramesContainer then
            PlayerFrameBottomManagedFramesContainer:Layout()
        end
    end
    
    if totemFrameOverlay then
        totemFrameOverlay:Hide()
    end
end

function BUII_MoveableTotemFrame_InitDB()
    if BUIIDatabase["moveable_totem_frame"] == nil then
        BUIIDatabase["moveable_totem_frame"] = false
    end
end