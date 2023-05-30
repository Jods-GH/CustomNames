local MAJOR_VERSION = "LibCustomNames"
local MINOR_VERSION = 3
if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then error("LibCustomNames failed to initialise")return end

LibCustomNamesDB = LibCustomNamesDB or {}

function lib.Get(name) -- returns custom name if exists, otherwise returns original name
    assert(name, "LibCustomNames: Can't GetCustomName (name is nil)")
	if LibCustomNamesDB[name] then
		return LibCustomNamesDB[name]
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
		LibCustomNamesDB[name] = nil
		return true
	else
		LibCustomNamesDB[name] = customName
		return true
	end
end

function lib.GetList()
    return CopyTable(LibCustomNamesDB)
end

function lib.UnitName(unit)
	assert(unit, "LibCustomNames: Can't get UnitName (unit is nil)")
	assert(UnitExists(unit), "LibCustomNames: Can't GetUnitName (unit does not exist)")
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
	assert(unit, "LibCustomNames: Can't get UnitFullName (unit is nil)")
	assert(UnitExists(unit), "LibCustomNames: Can't GetUnitName (unit does not exist)")
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
	assert(unit, "LibCustomNames: Can't get GetUnitName (unit is nil)")
	assert(UnitExists(unit), "LibCustomNames: Can't GetUnitName (unit does not exist)")
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

SLASH_LibCustomNames1 = '/LCN'
SLASH_LibCustomNames2 = '/lcn'
SLASH_LibCustomNames3 = '/LibCustomNames'
SlashCmdList['LibCustomNames'] = function(msg) -- credit to Ironi
    if string.find(string.lower(msg), "add (.-) to (.-)") then --add
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
        lib.Set(from, to)
        print("Added: " .. from .. " -> " .. to);
	elseif string.find(string.lower(msg), "del (.-)") then --delete
		local _, _, type, from = string.find(msg, "(.-) (.*)")
		if UnitExists(from) then	
			local unitName, unitRealm = UnitName(from)
			local nameToCheck = unitName
			if UnitIsPlayer(from) then
				nameToCheck= unitName .. "-" .. (unitRealm or GetRealmName())
			end
			if nameToCheck and LibCustomNamesDB[nameToCheck] then
				local to =  lib.Get(nameToCheck)
				lib.Set(from)
				print("Deleted: " .. from .. " -> " .. to)
			end
		elseif LibCustomNamesDB[from] then
			local to =  lib.Get(from)
			lib.Set(from)
			print("Deleted: " .. from .. " -> " .. to)
        else
            print("No such name in database")
		end
    elseif string.find(string.lower(msg), "edit (.-)") then --edit
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
		if UnitExists(from) then	
			local unitName, unitRealm = UnitName(from)
			local nameToCheck = unitName
			if UnitIsPlayer(from) then
				nameToCheck= unitName .. "-" .. (unitRealm or GetRealmName())
			end
			if nameToCheck and LibCustomNamesDB[nameToCheck] then
				lib.Set(from, to)
				print("Edited " .. from .. " -> " .. to)
			end
		elseif LibCustomNamesDB[from] then
			lib.Set(from, to)
			print("Edited " .. from .. " -> " .. to)
        else
            print("No such name in database");
		end
	elseif msg == "list" or msg == "l" then
		for k,v in pairs(LibCustomNamesDB) do
			print(k .. " -> " .. v)
		end
	else
		print("LibCustomNames example usage:\rAdding a new name: /lcn add Name to CustomName\rEditing name: /lcn edit Name to CustomName\rDeleting old name: /lcn del Name\rListing every name: /lcn l(ist)")
	end
end
