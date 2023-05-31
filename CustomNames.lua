local lib = LibStub("LibCustomNames")

SLASH_LibCustomNames1 = '/LCN'
SLASH_LibCustomNames2 = '/lcn'
SLASH_LibCustomNames3 = '/LibCustomNames'

lib:RegisterCallback("Name_Added", function(event, name, customName)
	print("Added: " .. name .. " is now Renamed to " .. customName)
end)

lib:RegisterCallback("Name_Removed", function(event, name)
	print("Deleted: " .. name .. " is no longer Renamed")
end)

lib:RegisterCallback("Name_Update", function(event, name, customName, oldCustomName)
	print("Edited: " .. name .. " is now Renamed to " .. customName .. " (was " .. oldCustomName .. ")")
end)


local isNameinDatabase = function(name)
	if lib.Get(name) ~= name then
		return true
	else
		return false
	end
end
SlashCmdList['LibCustomNames'] = function(msg) -- credit to Ironi
    if string.find(string.lower(msg), "add (.-) to (.-)") then --add
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
        lib.Set(from, to)
	elseif string.find(string.lower(msg), "del (.-)") then --delete
		local _, _, type, from = string.find(msg, "(.-) (.*)")
		if UnitExists(from) then	
			local unitName, unitRealm = UnitName(from)
			local nameToCheck = unitName
			if UnitIsPlayer(from) then
				nameToCheck= unitName .. "-" .. (unitRealm or GetRealmName())
			end
			if nameToCheck and isNameinDatabase(nameToCheck) then
				local to =  lib.Get(nameToCheck)
				lib.Set(from)
			end
		elseif isNameinDatabase(from) then
			local to =  lib.Get(from)
			lib.Set(from)
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
			if nameToCheck and isNameinDatabase(nameToCheck) then
				lib.Set(from, to)
			end
		elseif isNameinDatabase(from) then
			lib.Set(from, to)
        else
            print("No such name in database");
		end
	elseif msg == "list" or msg == "l" then
		for k,v in pairs(lib.GetList()) do
			print(k .. " -> " .. v)
		end
	else
		print("LibCustomNames example usage:\rAdding a new name: /lcn add Name to CustomName\rEditing name: /lcn edit Name to CustomName\rDeleting old name: /lcn del Name\rListing every name: /lcn l(ist)")
	end
end
