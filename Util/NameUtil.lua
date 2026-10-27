local appName, app = ...
---@class CustomNamesPrivate
local private = app
local lib = LibStub("CustomNames")

private.SELF_BTAG = "self"

--- Since GetNormalizedRealmName can return nil we need to gsub GetRealmName ourselfs if need be
---@return string Realm
local function NormalizedRealmName()
    return GetNormalizedRealmName() or GetRealmName():gsub("[%s-]+", "")
end
private.NormalizedRealmName = NormalizedRealmName

---@param value any
---@return boolean readable -- false for secret values, they can't be compared or used as a key
private.IsReadable = function(value)
    if issecretvalue and issecretvalue(value) then return false end
    if canaccessvalue and not canaccessvalue(value) then return false end
    return true
end

---Returns the text a database key is shown with in the ui
---@param key string -- Name-Realm, BattleTag#1234 or self
---@return string display
private.GetDisplayName = function(key)
    if key == private.SELF_BTAG then
        return private.getLocalisation("SelfBattleTag")
    end
    -- accounts of guildmates that didn't share their btag get their name from CustomNames_GuildSync
    local provider = lib.GetTabProvider("guild")
    local display = provider and provider.GetAccountDisplay and provider.GetAccountDisplay(key)
    if display then
        return display
    end
    return key
end

---Splits the database key of a character into the parts the ui shows separately
---@param key string -- Name-Realm
---@return string name -- the whole key if it has no realm (always the case on forever, where names are First-Last)
---@return string? realm
private.SplitCharName = function(key)
    if private.IsForever() then return key, nil end
    local name, realm = key:match("^([^-]+)%-(.+)$")
    if not name then return key, nil end
    return name, realm
end

---Returns the btag a character is linked to.
---Only for the ui of this addon, the api intentionally has no way to look up btags
---@param name string -- Name-Realm
---@return string? btag
private.GetBattleTagForChar = function(name)
    return CustomNamesDB.CharToBnetDB[name]
end

---Returns the custom name that is set directly on a character or btag (names inherited from a btag are not included)
---@param key string -- Name-Realm, BattleTag#1234 or self
---@return string? customName
private.GetDirectName = function(key)
    local customName = CustomNamesDB.CharDB[key]
    if customName then return customName end
    local bnetValue = CustomNamesDB.BnetDB[key]
    return bnetValue and bnetValue.name or nil
end

---Groups character names by their realm, biggest realm first
---@param chars table -- list of names in the format Name-Realm
---@return table groups -- list of { realm = string, names = { Name, ... } }
private.GroupCharsByRealm = function(chars)
    local groups, byRealm = {}, {}
    for _, charname in ipairs(chars) do
        local name, realm = charname:match("^([^-]+)%-(.+)$")
        if not name then
            name, realm = charname, ""
        end
        local group = byRealm[realm]
        if not group then
            group = { realm = realm, names = {} }
            byRealm[realm] = group
            table.insert(groups, group)
        end
        table.insert(group.names, name)
    end
    for _, group in ipairs(groups) do
        table.sort(group.names)
    end
    table.sort(groups, function(a, b)
        if #a.names ~= #b.names then
            return #a.names > #b.names
        end
        return a.realm < b.realm
    end)
    return groups
end

---Returns all known btags with their custom name (if one is set) and the characters linked to them.
---Only for the ui of this addon, the api intentionally has no way to list btags
---@return table list -- [btag] = { name = customName?, chars = { [Name-Realm] = true } }
private.GetBnetList = function()
    local list = {}
    for btag, bnetValue in pairs(CustomNamesDB.BnetDB) do
        list[btag] = {
            name = bnetValue.name,
            chars = bnetValue.chars and CopyTable(bnetValue.chars) or {},
        }
    end
    return list
end

---Returns the database key a unit is looked up with (same rules as lib.UnitName)
---@param unit UnitToken
---@return string? name -- nil if the unit doesn't exist or its name can't be read (secret value)
private.GetNameKeyForUnit = function(unit)
    if not unit or not UnitExists(unit) then return nil end
    local unitName, unitRealm = UnitName(unit)
    if issecretvalue and (issecretvalue(unitName) or issecretvalue(unitRealm)) then return nil end
    if canaccessvalue and not (canaccessvalue(unitName) and canaccessvalue(unitRealm)) then return nil end
    if not unitName then return nil end
    if unitRealm == "" then unitRealm = nil end
    if private.IsForever() then
        if UnitIsPlayer(unit) and unitRealm then
            return private.FixNameForever(unitName .. "-" .. unitRealm)
        end
        return private.FixNameForever(unitName)
    end
    return unitName .. "-" .. (unitRealm or NormalizedRealmName())
end

---Turns text typed by the user into the name that gets passed to lib.Set
---@param input string?
---@return string? name
---@return string? errorKey -- localisation key describing why the input can't be used
private.NormalizeInputName = function(input)
    local name = strtrim(input or "")
    if name == "" then return nil, "ErrorNameMissing" end
    if name:lower() == private.SELF_BTAG then return private.SELF_BTAG end
    if name:find("#", 1, true) then return name end
    if UnitExists(name) then
        local unitKey = private.GetNameKeyForUnit(name)
        if not unitKey then return nil, "ErrorNameNotAccessible" end
        return unitKey
    end
    if private.IsForever() or name:find("-", 1, true) then return name end
    return name .. "-" .. NormalizedRealmName()
end

---Turns text typed by the user into a btag that gets passed to lib.Set
---@param input string?
---@return string? btag
---@return string? errorKey -- localisation key describing why the input can't be used
private.NormalizeInputBattleTag = function(input)
    local btag = strtrim(input or "")
    if btag == "" then return nil, "ErrorNameMissing" end
    if btag:lower() == private.SELF_BTAG then return private.SELF_BTAG end
    if btag:match("^[^#%s]+#%d+$") then return btag end
    return nil, "ErrorInvalidBattleTag"
end

---@return table? batch -- the batch that is collecting chat output right now
local function GetRunningBatch()
    -- a batch only lives for the frame it was started in, so one that was never ended
    -- (because of an error in between) doesn't keep swallowing the chat output
    local batch = private.chatBatch
    if batch and batch.time == GetTime() then
        return batch
    end
    private.chatBatch = nil
    return nil
end

---Prints a message of the name callbacks, or collects it while a batch is running
---@param message string
private.ChatOutput = function(message)
    local batch = GetRunningBatch()
    if batch then
        batch.count = batch.count + 1
        batch.first = batch.first or message
    else
        print(message)
    end
end

---Collects the chat output of the name callbacks instead of printing it, until private.EndBatch is called.
---A btag with many linked characters would otherwise print a line for every single one of them
---@return table? batch -- { count = number, first = string? }, nil if an outer batch is already collecting
private.BeginBatch = function()
    if GetRunningBatch() then return nil end
    local batch = { count = 0, time = GetTime() }
    private.chatBatch = batch
    return batch
end

---@param batch table? -- what private.BeginBatch returned
private.EndBatch = function(batch)
    if batch and private.chatBatch == batch then
        private.chatBatch = nil
    end
end

---Whether a name has one of the formats lib.Set accepts, it raises an error for anything else.
---Only the format is checked, so text typed by the user can be turned down with a message
---@param name any
---@return boolean
private.IsValidName = function(name)
    if type(name) ~= "string" or name == "" then return false end
    if name:lower() == private.SELF_BTAG or name:match("^.-#%d+$") then return true end
    if UnitExists(name) or private.IsForever() or CustomNamesDB.CharDB[name] then return true end
    return name:match("^.+%-.+$") ~= nil
end

---lib.Set for the ui: turns down names in a format lib.Set doesn't know
---and prints a single line to the chat no matter how many characters are affected
---@param name string
---@param customName string? -- nil removes the name
---@return boolean success
private.SetName = function(name, customName)
    if not private.IsValidName(name) then return false end
    local batch = private.BeginBatch()
    local success = lib.Set(name, customName) and true or false
    private.EndBatch(batch)
    if batch then
        if batch.count > 1 then
            local display = private.GetDisplayName(name)
            if customName then
                print(private.getLocalisation("CallbackAddedMany"):format(display, customName, batch.count))
            else
                -- the btag itself is reported in addition to its characters
                print(private.getLocalisation("CallbackRemovedMany"):format(display, batch.count - 1))
            end
        elseif batch.first then
            print(batch.first)
        elseif success and customName then
            -- a btag without linked characters fires no callbacks
            print(private.getLocalisation("CallbackAdded"):format(private.GetDisplayName(name), customName))
        end
    end
    return success
end
