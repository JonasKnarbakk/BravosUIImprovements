-- ResourceTracker Core Module
-- Shared logic for configuration and resource state retrieval

local addonName, addon = ...

BUII_ResourceTracker_CONFIG = {}

---@return table
function BUII_ResourceTracker_GetDB()
  return BUII_EditModeUtils:GetDB("resource_tracker") or {}
end

---@return table|nil
function BUII_ResourceTracker_GetActiveConfig()
  local db = BUII_ResourceTracker_GetDB()
  local _, classFilename = UnitClass("player")
  local specId = PlayerUtil.GetCurrentSpecID()
  local specIndex = GetSpecialization()

  local settingKey = "resource_tracker_" .. string.lower(classFilename)
  if db and db[settingKey] == false then
    return nil
  end

  local configs = BUII_ResourceTracker_CONFIG[classFilename]
  if not configs then
    return nil
  end

  if not configs[1] then
    configs = { configs }
  end

  for _, config in ipairs(configs) do
    if not config.spec or config.spec == specId or config.spec == specIndex then
      local activeConfig = CopyTable(config)
      activeConfig.class = classFilename

      if classFilename == "DEATHKNIGHT" and activeConfig.specs and activeConfig.specs[specId] then
        activeConfig.color = activeConfig.specs[specId]
      end

      return activeConfig
    end
  end

  return nil
end

---@param config table|nil
---@return number currentStacks, number|table partialFill, any extraData
function BUII_ResourceTracker_GetResourceState(config)
  if not config then
    return 0, 0, nil
  end

  if not BUII_ResourceHandlers then
    return 0, 0, nil
  end

  local handlerName = config.handler
  if handlerName then
    local handler = BUII_ResourceHandlers[handlerName]
    if handler then
      return handler(config)
    end
  end

  return 0, 0, nil
end

BUII_ResourceTracker_DB_DEFAULTS = {
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

BUII_ResourceTracker_CHAR_DB_DEFAULTS = {
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
