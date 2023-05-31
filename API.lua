local MAJOR_VERSION = "LibCustomNames"
local MINOR_VERSION = 3
if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
if not lib then error("LibCustomNames failed to initialise")return end

CustomNamesDB = CustomNamesDB or {}
CustomNamesDB.CharDB = CustomNamesDB.CharDB or {}
CustomNamesDB.BnetDB = CustomNamesDB.BnetDB or {}
CustomNamesDB.BnetDB = CustomNamesDB.BnetDB or {}

function lib.Get(name) -- returns custom name if exists, otherwise returns original name
    assert(name, "LibCustomNames: Can't GetCustomName (name is nil)")
	if CustomNamesDB[name] then
		return CustomNamesDB[name]
	else
		return name
	end
end
function lib.Set(name, customName)
    assert(name, "LibCustomNames: Can't SetCustomName (name is nil)")
	if UnitExists(name) then	
		local unitName, unitRealm = UnitName(name)
		if UnitIsPlayer(name) then
			name = unitName .. "-" .. (unitRealm or GetRealmName())
		else
			name = unitName
		end
	else
		assert(name:match("^(.+)-(.+)$"), "LibCustomNames: Can't set custom Name (name is not in the correct format Name-Realm)")
	end
	if not customName then
		lib.callbacks:Fire("Name_Removed", name)
		CustomNamesDB[name] = nil
		return true
	else
		if CustomNamesDB[name] then
			lib.callbacks:Fire("Name_Update", name, customName, CustomNamesDB[name])
		else 
			lib.callbacks:Fire("Name_Added", name, customName)
		end
		CustomNamesDB[name] = customName
		return true
	end
end

function lib.GetList()
    return CopyTable(CustomNamesDB)
end

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

function lib.GetUnitName(unit,showServerName)
	if not unit or not UnitExists(unit) then return nil,nil end
	local unitName, unitRealm = UnitFullName(unit)	
	local nameToCheck
	if UnitIsPlayer(unit) then
		nameToCheck = unitName .. "-" .. (unitRealm or GetRealmName())
	else
		nameToCheck= unitName
	end
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
