local appName, app = ...
---@class CustomNamesPrivate
local private = app

local STATE_MISSING = "missing"
local STATE_DISABLED = "disabled"
local STATE_RELOAD = "reload" -- enabled, but only loaded after the next reload
local STATE_LOADED = "loaded"

---@param name string -- folder name of the addon
---@return "missing"|"disabled"|"reload"|"loaded" state
private.GetAddOnState = function(name)
    if not C_AddOns.DoesAddOnExist(name) then
        return STATE_MISSING
    end
    if C_AddOns.GetAddOnEnableState(name, UnitName("player")) == 0 then
        return STATE_DISABLED
    end
    if not C_AddOns.IsAddOnLoaded(name) then
        return STATE_RELOAD
    end
    return STATE_LOADED
end

---@param name string
---@return boolean -- the addon is installed and enabled
local function IsAddOnUsed(name)
    local state = private.GetAddOnState(name)
    return state ~= STATE_MISSING and state ~= STATE_DISABLED
end

---@param entry table -- of private.Plugins
---@return boolean -- the entry concerns the addons the player uses
local function IsRelevant(entry)
    if entry.builtIn then
        return IsAddOnUsed(entry.addon)
    end
    if not entry.requires then return true end
    for _, name in ipairs(entry.requires) do
        if IsAddOnUsed(name) then
            return true
        end
    end
    return false
end

---@return table dismissed -- [addon] = true for plugins the player doesn't want suggested
local function GetDismissed()
    CustomNames = CustomNames or {}
    CustomNames.dismissedPlugins = CustomNames.dismissedPlugins or {}
    return CustomNames.dismissedPlugins
end

---@param addon string
---@return boolean
private.IsPluginDismissed = function(addon)
    return GetDismissed()[addon] == true
end

---@param addon string
---@param dismissed boolean -- stop suggesting the plugin
private.SetPluginDismissed = function(addon, dismissed)
    GetDismissed()[addon] = dismissed or nil
end

---@param item table -- of private.GetRelevantPlugins
---@return boolean -- the plugin should be installed, enabled or loaded and the player didn't dismiss it
private.IsPluginSuggested = function(item)
    return not item.entry.builtIn and item.state ~= STATE_LOADED and not item.dismissed
end

---@return table items -- { entry, state, dismissed } for every entry of private.Plugins that concerns the player
private.GetRelevantPlugins = function()
    local items = {}
    for _, entry in ipairs(private.Plugins) do
        if IsRelevant(entry) then
            table.insert(items, {
                entry = entry,
                state = private.GetAddOnState(entry.addon),
                dismissed = private.IsPluginDismissed(entry.addon),
            })
        end
    end
    return items
end

---@return number count -- plugins that are suggested to the player
private.GetPluginBadge = function()
    local count = 0
    for _, item in ipairs(private.GetRelevantPlugins()) do
        if private.IsPluginSuggested(item) then
            count = count + 1
        end
    end
    return count
end
