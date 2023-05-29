local MAJOR_VERSION = "LibCustomNames-1.0"
local MINOR_VERSION = 1
if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then error("LibCustomNames failed to initialise")return end

LibCustomNamesDB = LibCustomNamesDB or {}

function lib:Get(name) -- returns custom name if exists, otherwise returns original name
    assert(name, "LibCustomNames: Can't GetCustomName (name is nil)")
	if LibCustomNamesDB[name] then
		return LibCustomNamesDB[name], true
	else
		return name
	end
end

function lib:Set(name, customName)
    assert(name, "LibCustomNames: Can't SetCustomName (name is nil)")
    if not customName then
        LibCustomNamesDB[name] = nil
        return true
    else
        LibCustomNamesDB[name] = customName
        return true
    end
end

function lib:GetList()
    return CopyTable(LibCustomNamesDB)
end
SLASH_LibCustomNames1 = '/LCN'
SLASH_LibCustomNames2 = '/lcn'
SLASH_LibCustomNames3 = '/LibCustomNames'
SlashCmdList['LibCustomNames'] = function(msg) -- credit to Ironi
    if string.find(string.lower(msg), "add (.-) to (.-)") then --add
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
		AddCustomName(from,to)
		print("Added: " .. from .. " -> " .. to);
	elseif string.find(string.lower(msg), "del (.-)") then --delete
		local _, _, type, from = string.find(msg, "(.-) (.*)")
		if CheckCustomName(from) then
			local to =  GetCustomName(from)
			RemoveCustomName(from)
			print("Deleted: " .. from .. " -> " .. to);
        else
            print("No such name in database")
		end
    elseif string.find(string.lower(msg), "edit (.-)") then --edit
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
		if CheckCustomName(from) then
			EditCustomName(from, to)
			print("Edited " .. from .. " -> " .. to);
        else
            print("No such name in database");
		end
	elseif msg == "list" or msg == "l" then
		for k,v in pairs(LibCustomNamesDB) do
			print(k .. " -> " .. v);
		end
	else
		print("LibCustomNames example usage:\rAdding a new name: /lcn add Name to CustomName\rEditing name: /lcn edit Name to CustomName\rDeleting old name: /lcn del Name\rListing every name: /lcn l(ist)")
	end
end
