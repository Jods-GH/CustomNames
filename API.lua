local MAJOR_VERSION = "LibCustomNames"
local MINOR_VERSION = 4
if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
if not lib then error("LibCustomNames failed to initialise")return end

CustomNamesDB = CustomNamesDB or {}
CustomNamesDB.CharDB = CustomNamesDB.CharDB or {}
CustomNamesDB.BnetDB = CustomNamesDB.BnetDB or {}
CustomNamesDB.CharToBnetDB = CustomNamesDB.CharToBnetDB or {}

---returns custom name if exists, otherwise returns original name. Expects Name-Realm for Players and Name for NPCs. Also allows for the Lookup of battletags in format ""
---@param name string
---@return string name
function lib.Get(name)
    assert(name, "LibCustomNames: Can't Get Custom Name (name is nil)")
	if CustomNamesDB.CharDB[name] then
		return CustomNamesDB.CharDB[name]	
	elseif CustomNamesDB.BnetDB[name] and CustomNamesDB.BnetDB[name].name then
		return CustomNamesDB.BnetDB[name].name
	elseif CustomNamesDB.CharToBnetDB[name] and CustomNamesDB.BnetDB[CustomNamesDB.CharToBnetDB[name]] and CustomNamesDB.BnetDB[CustomNamesDB.CharToBnetDB[name]].name then
		return CustomNamesDB.BnetDB[CustomNamesDB.CharToBnetDB[name]].name	
	else
		return name
	end
end
---returns true if custom name exists, otherwise returns nil
---@param name string
---@return boolean? exists
function lib.IsCharInBnetDatabase(name)
	assert(name, "LibCustomNames: Can't check if Name is in BnetDatabase (name is nil)")
	if CustomNamesDB.CharToBnetDB[name] then
		return true
	else
		return nil
	end
end
---links a character name to a btag
---@param charname string
---@param btag string
---@return boolean? success
function  lib.AddCharToBtag(charname,btag)
	assert(charname, "LibCustomNames: Can't addCharToBtag (charname is nil)")
	assert(btag, "LibCustomNames: Can't addCharToBtag (btag is nil)")
	CustomNamesDB.CharToBnetDB[charname] = btag	
	CustomNamesDB.BnetDB[btag] = CustomNamesDB.BnetDB[btag] or {}
	CustomNamesDB.BnetDB[btag][charname] = true
	if CustomNamesDB.BnetDB[btag] and CustomNamesDB.BnetDB[btag].name then
		lib.callbacks:Fire("Name_Added", charname, CustomNamesDB.BnetDB[btag].name)
	end
	return true
end

local function SetBnet(btag,customName)
	if not customName then
		CustomNamesDB.BnetDB[btag].name = nil
		for charname in pairs (CustomNamesDB.BnetDB[btag]) do
			if charname ~= "name" then	
				lib.callbacks:Fire("Name_Removed", charname)
			end
		end
		lib.callbacks:Fire("Name_Removed", btag)
		return true
	else
		CustomNamesDB.BnetDB[btag].name = customName
		if CustomNamesDB.BnetDB[btag] and CustomNamesDB.BnetDB[btag].name then
			for charname in pairs (CustomNamesDB.BnetDB[btag]) do
				if charname ~= "name" then	
					lib.callbacks:Fire("Name_Update", charname, customName, CustomNamesDB.BnetDB[btag].name)
				end
			end
		else 
			for charname in pairs (CustomNamesDB.BnetDB[btag]) do
				if charname ~= "name" then					
					lib.callbacks:Fire("Name_Added", charname, customName)
				end
			end
		end
		return true
	end
end

---Setting Names accepts units aswell as Names in the format of Name-Realm (for players) or just Name (for npcs) and Btag in format "BattleTag#12345"
---@param name any
---@param customName string
---@return boolean? success
function lib.Set(name, customName)
    assert(name, "LibCustomNames: Can't SetCustomName (name is nil)")
	if UnitExists(name) then	
		local unitName, unitRealm = UnitName(name)
		if UnitIsPlayer(name) then
			name = unitName .. "-" .. (unitRealm or GetRealmName())
		else
			name = unitName
		end
	elseif name:match("^%a+#%d+$") then
		return SetBnet(name,customName)
	else
		assert(name:match("^(.+)-(.+)$"), "LibCustomNames: Can't set custom Name (name is not in the correct format Name-Realm)")
	end
	if not customName then
		lib.callbacks:Fire("Name_Removed", name)
		CustomNamesDB.CharDB[name] = nil
		return true
	else
		if CustomNamesDB.CharDB[name] then
			lib.callbacks:Fire("Name_Update", name, customName, CustomNamesDB.CharDB[name])
		else 
			lib.callbacks:Fire("Name_Added", name, customName)
		end
		CustomNamesDB.CharDB[name] = customName
		return true
	end
end
---Returns a list of all custom names
---@return table
function lib.GetList()
    return CopyTable(CustomNamesDB)
end
---behaves equivalent to UnitName(unit)
---@param unit UnitToken
---@return string? name
---@return string? realm
function lib.UnitName(unit)
	if not unit or not UnitExists(unit) then return nil,nil end
	local unitName, unitRealm = UnitName(unit)
	local nameToCheck = unitName .. "-" .. (unitRealm or GetRealmName())
	local customName = lib.Get(nameToCheck)
	if customName ~= nameToCheck then
		return customName,unitRealm
	else
		return unitName,unitRealm
	end
end
---behaves equivalent to UnitFullName(unit)
---@param unit UnitToken
---@return string? name
---@return string? realm
function lib.UnitFullName(unit)
	if not unit or not UnitExists(unit) then return nil,nil end
	local unitName, unitRealm = UnitFullName(unit)
	local nameToCheck
	if UnitIsPlayer(unit) then
		nameToCheck = unitName .. "-" .. (unitRealm or GetRealmName())
	else
		nameToCheck= unitName
	end
	local customName = lib.Get(nameToCheck)
	if customName ~= nameToCheck then
		return customName,unitRealm
	else
		return unitName,unitRealm
	end
end
---behaves equivalent to UnitFullName(unit)
---@param unit UnitToken
---@param showServerName boolean
---@return string? name
function lib.GetUnitName(unit,showServerName)
	if not unit or not UnitExists(unit) then return nil end
	local unitName, unitRealm = UnitFullName(unit)	
	local nameToCheck
	if UnitIsPlayer(unit) then
		nameToCheck = unitName .. "-" .. (unitRealm or GetRealmName())
	else
		nameToCheck= unitName
	end
	if not nameToCheck then return nil end
	local customName = lib.Get(nameToCheck)
	local realmRelationship = UnitRealmRelationship(unit)
	if realmRelationship == LE_REALM_RELATION_SAME or not realmRelationship then
		if customName ~= nameToCheck then
			return customName
		else
			return unitName
		end
	elseif realmRelationship == LE_REALM_RELATION_VIRTUAL then
		if customName ~= nameToCheck then
			if showServerName then
				return customName .. "-" .. unitRealm
			else
				return customName
			end
		else
			return unitName .. "-" .. unitRealm
		end
	else --LE_REALM_RELATION_COALESCED 
		if customName ~= nameToCheck then
			if showServerName then
				return customName .. "-" .. unitRealm
			else
				return customName.." (*)"
			end
		else 
			if showServerName then
				return unitName .. "-" .. unitRealm
			else
				return unitName.." (*)"
			end
		end
	end
end
