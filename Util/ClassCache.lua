local appName, app = ...
---@class CustomNamesPrivate
local private = app
local lib = LibStub("CustomNames")

-- The ui colors characters by their class. The class of a character is only known while the game shows it to us,
-- so it is remembered here. Only the classes of characters that have a custom name are saved

local seen = {} -- [Name-Realm] = classFile of everybody seen this session
local callbackOwner = {}

---@return table classes -- [Name-Realm] = classFile, part of the saved settings
local function GetSaved()
    CustomNames = CustomNames or {}
    CustomNames.classes = CustomNames.classes or {}
    return CustomNames.classes
end

---@param name string -- Name-Realm
---@return string? classFile -- e.g. MAGE
private.GetClass = function(name)
    return GetSaved()[name] or seen[name]
end

---@param name string? -- Name-Realm
---@param classFile string? -- e.g. MAGE
private.RememberClass = function(name, classFile)
    if not name or not classFile then return end
    seen[name] = classFile
    if lib.isCharInDatabase(name) then
        GetSaved()[name] = classFile
    end
end

---@param name string? -- Name-Realm
---@param classID number?
private.RememberClassID = function(name, classID)
    if not name or not classID then return end
    local _, classFile = GetClassInfo(classID)
    private.RememberClass(name, classFile)
end

---@param unit UnitToken
private.RememberUnitClass = function(unit)
    local name = private.GetNameKeyForUnit(unit)
    if not name then return end
    local isPlayer = UnitIsPlayer(unit)
    if not private.IsReadable(isPlayer) or not isPlayer then return end
    local _, classFile = UnitClass(unit)
    if not private.IsReadable(classFile) then return end
    private.RememberClass(name, classFile)
end

private.RememberGroupClass = function()
    local prefix, count
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        prefix, count = "party", GetNumSubgroupMembers()
    end
    for i = 1, count or 0 do
        private.RememberUnitClass(prefix .. i)
    end
end

private.RememberPlayerAndGroupClass = function()
    private.RememberUnitClass("player")
    private.RememberGroupClass()
end


-- a character that gets its name after it was seen is saved from then on
lib.RegisterCallback(callbackOwner, "Name_Added", function(_, name)
    if seen[name] then
        GetSaved()[name] = seen[name]
    end
end)

lib.RegisterCallback(callbackOwner, "Name_Removed", function(_, name)
    local saved = GetSaved()
    if saved[name] and not lib.isCharInDatabase(name) then
        saved[name] = nil
    end
end)
