local lib = LibStub("CustomNames")

lib:RegisterCallback("Name_Added", function(event, name, customName)
	print("Added: " .. name .. " is now Renamed to " .. customName)
end)

lib:RegisterCallback("Name_Removed", function(event, name)
	print("Deleted: " .. name .. " is no longer Renamed")
end)

lib:RegisterCallback("Name_Update", function(event, name, customName, oldCustomName)
	print("Edited: " .. name .. " is now Renamed to " .. customName .. " (was " .. oldCustomName .. ")")
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent",function(self,...)
	local event, friendId, isCompanionApp = ...
	if event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_INFO_CHANGED" then
		if friendId then
			local number = C_BattleNet.GetFriendNumGameAccounts(friendId)
			if number then
				local bnetAccountInfo = C_BattleNet.GetFriendAccountInfo(friendId)
				if bnetAccountInfo and bnetAccountInfo.gameAccountInfo and bnetAccountInfo.gameAccountInfo.wowProjectID and bnetAccountInfo.gameAccountInfo.wowProjectID == WOW_PROJECT_MAINLINE 
				and bnetAccountInfo.gameAccountInfo.characterName and bnetAccountInfo.gameAccountInfo.realmName and bnetAccountInfo.battleTag then
					local Character = bnetAccountInfo.gameAccountInfo.characterName.."-"..bnetAccountInfo.gameAccountInfo.realmName
					if Character and not  lib.IsCharInBnetDatabase(Character) and bnetAccountInfo.battleTag then
						lib.AddCharToBtag(Character,bnetAccountInfo.battleTag)
					end
				end
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		local name,realm = UnitFullName("player")
		local fullName = name.."-"..realm
		if not lib.IsCharInBnetDatabase(fullName) then
			lib.AddCharToBtag(fullName, "self")
		end
	end
end)




--- Since GetNormalizedRealmName can return nil we need to gsub GetRealmName ourselfs if need be
---@return string Realm
local function NormalizedRealmName()
	return GetNormalizedRealmName() or GetRealmName():gsub("[%s-]+", "")
end

SLASH_CustomNames1 = '/CN'
SLASH_CustomNames2 = '/cn'
SLASH_CustomNames3 = '/CustomNames'
SlashCmdList['CustomNames'] = function(msg) -- credit to Ironi
	if string.find(string.lower(msg), "add (.-) to (.-)") then --add
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
		lib.Set(from, to)
	elseif string.find(string.lower(msg), "del (.-)") then --delete
		local _, _, type, from = string.find(msg, "(.-) (.*)")
		if UnitExists(from) then	
			local unitName, unitRealm = UnitName(from)
			local nameToCheck = unitName
			if UnitIsPlayer(from) then
				nameToCheck= unitName .. "-" .. (unitRealm or NormalizedRealmName())
			end
			if nameToCheck and lib.isCharInDatabase(nameToCheck) then
				local to =  lib.Get(nameToCheck)
				lib.Set(from)
			end
		elseif lib.isCharInDatabase(from) then
			local to =  lib.Get(from)
			lib.Set(from)
		elseif lib.IsInBnetDatabase(from) then
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
				nameToCheck= unitName .. "-" .. (unitRealm or NormalizedRealmName())
			end
			if nameToCheck and lib.isCharInDatabase(nameToCheck) then
				lib.Set(from, to)
			end
		elseif lib.isCharInDatabase(from) then
			lib.Set(from, to)
		elseif lib.IsInBnetDatabase(from) then
			lib.Set(from, to)
		else
			print("No such name in database");
		end
	elseif msg == "list" or msg == "l" then
		for k,v in pairs(lib.GetList()) do
			print(k.." -> "..v)
			
		end
	else
		print("CustomNames example usage:\rAdding a new name: /cn add Name to CustomName\rEditing name: /cn edit Name to CustomName\rDeleting old name: /cn del Name\rListing every name: /cn l(ist)")
	end
end
