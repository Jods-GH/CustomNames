local appName, app = ...
---@class CustomNamesPrivate
local private = app
local lib = LibStub("CustomNames")

local EXPORT_PREFIX = "!CN1!"
local EXPORT_VERSION = 1
local variables = {
    maxNameLength = 200,
    maxEntries = 5000,
}

---@return string? battleTag -- the battletag of the player, used to share the "self" entry
local function GetOwnBattleTag()
    if not BNGetInfo then return nil end
    local _, battleTag = BNGetInfo()
    if type(battleTag) == "string" and battleTag ~= "" then
        return battleTag
    end
    return nil
end

local function IsValidText(value)
    return type(value) == "string" and value ~= "" and #value <= variables.maxNameLength
end

-- only names in the Name-Realm format are imported, anything else could be read as a unit token by lib.Set
local function IsValidCharName(value)
    return IsValidText(value) and not value:find("#", 1, true) and value:match("^.+%-.+$") ~= nil
end

local function IsValidBattleTag(value)
    return IsValidText(value) and value:match("^[^#%s]+#%d+$") ~= nil
end

---Serializes all custom names into a string that can be shared
---@return string? exportString
---@return string? errorKey -- localisation key describing why the export failed
private.ExportNames = function()
    if not C_EncodingUtil then return nil, "ImportExportUnsupported" end
    local data = {
        v = EXPORT_VERSION,
        chars = lib.GetCharList(),
        btags = {},
    }
    local ownBattleTag = GetOwnBattleTag()
    for btag, value in pairs(private.GetBnetList()) do
        -- "self" only means something on this account, so it is shared under the real battletag
        local exportTag = btag == private.SELF_BTAG and ownBattleTag or btag
        if value.name and exportTag and exportTag ~= private.SELF_BTAG then
            local chars = {}
            for charname in pairs(value.chars) do
                table.insert(chars, charname)
            end
            table.sort(chars)
            data.btags[exportTag] = { name = value.name, chars = chars }
        end
    end

    local serialized = C_EncodingUtil.SerializeCBOR(data)
    local compressed = C_EncodingUtil.CompressString(serialized)
    return EXPORT_PREFIX .. C_EncodingUtil.EncodeBase64(compressed)
end

---@param text string
---@return table? data
---@return string? errorKey
local function DecodeExportString(text)
    if not C_EncodingUtil then return nil, "ImportExportUnsupported" end
    if type(text) ~= "string" then return nil, "ImportErrorFormat" end
    text = text:gsub("%s+", "")
    if text:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then return nil, "ImportErrorFormat" end

    -- the text was pasted by the user, so getting nothing back is expected and reported in the ui
    local compressed = C_EncodingUtil.DecodeBase64(text:sub(#EXPORT_PREFIX + 1))
    if type(compressed) ~= "string" then return nil, "ImportErrorDecode" end
    local serialized = C_EncodingUtil.DecompressString(compressed)
    if type(serialized) ~= "string" then return nil, "ImportErrorDecode" end
    local data = C_EncodingUtil.DeserializeCBOR(serialized)
    if type(data) ~= "table" then return nil, "ImportErrorDecode" end
    if tonumber(data.v) ~= EXPORT_VERSION then return nil, "ImportErrorFormat" end
    return data
end

---@param result table -- counters
---@param key string -- name passed to lib.Set
---@param customName string
---@param existing string? -- custom name currently in the database
---@param overwrite boolean
local function ApplyName(result, key, customName, existing, overwrite)
    if existing == customName or (existing and not overwrite) then
        result.skipped = result.skipped + 1
    elseif private.SetName(key, customName) then
        if existing then
            result.updated = result.updated + 1
        else
            result.added = result.added + 1
        end
    else
        result.skipped = result.skipped + 1
    end
end

---@param data table -- decoded export string
---@param overwrite boolean
---@return table result -- { added = number, updated = number, skipped = number }
local function ApplyImport(data, overwrite)
    local result = { added = 0, updated = 0, skipped = 0 }
    local processed = 0
    local ownBattleTag = GetOwnBattleTag()

    if type(data.chars) == "table" then
        local charList = lib.GetCharList()
        for name, customName in pairs(data.chars) do
            if processed >= variables.maxEntries then break end
            processed = processed + 1
            if IsValidCharName(name) and IsValidText(customName) then
                ApplyName(result, name, customName, charList[name], overwrite)
            else
                result.skipped = result.skipped + 1
            end
        end
    end

    if type(data.btags) == "table" then
        local bnetList = private.GetBnetList()
        for btag, value in pairs(data.btags) do
            if processed >= variables.maxEntries then break end
            processed = processed + 1
            if IsValidBattleTag(btag) and type(value) == "table" and IsValidText(value.name) then
                local target = btag == ownBattleTag and private.SELF_BTAG or btag
                ApplyName(result, target, value.name, bnetList[target] and bnetList[target].name, overwrite)
                if type(value.chars) == "table" then
                    for _, charname in pairs(value.chars) do
                        if processed >= variables.maxEntries then break end
                        processed = processed + 1
                        -- never move a character that is already linked, the friendlist knows better
                        if IsValidCharName(charname) and not lib.IsInBnetDatabase(charname) then
                            lib.AddCharToBtag(charname, target)
                        end
                    end
                end
            else
                result.skipped = result.skipped + 1
            end
        end
    end

    return result
end

---Imports a string created by private.ExportNames
---@param text string
---@param overwrite boolean -- replace custom names that already exist
---@return table? result -- { added = number, updated = number, skipped = number }
---@return string? errorKey -- localisation key describing why the import failed
private.ImportNames = function(text, overwrite)
    local data, errorKey = DecodeExportString(text)
    if not data then return nil, errorKey end

    -- one line for the whole import instead of one for every name
    local batch = private.BeginBatch()
    local result = ApplyImport(data, overwrite)
    private.EndBatch(batch)
    print(private.getLocalisation("ImportResult"):format(result.added, result.updated, result.skipped))
    return result
end
