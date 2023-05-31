local lib = LibStub("LibCustomNames")

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
			if nameToCheck and nameToCheck ~= lib.Get(nameToCheck) then
				local to =  lib.Get(nameToCheck)
				lib.Set(from)
				print("Deleted: " .. from .. " -> " .. to)
			end
		elseif from ~= lib.Get(from) then
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
			if nameToCheck and nameToCheck ~= lib.Get(nameToCheck) then
				lib.Set(from, to)
				print("Edited " .. from .. " -> " .. to)
			end
		elseif from ~= lib.Get(from) then
			lib.Set(from, to)
			print("Edited " .. from .. " -> " .. to)
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
