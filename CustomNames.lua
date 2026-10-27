local appName, private = ...
local lib = LibStub("CustomNames")

-- the ui collects these messages and prints a single line, see private.BeginBatch
lib:RegisterCallback("Name_Added", function(event, name, customName)
	private.ChatOutput(private.getLocalisation("CallbackAdded"):format(name, customName))
end)

lib:RegisterCallback("Name_Removed", function(event, name)
	private.ChatOutput(private.getLocalisation("CallbackRemoved"):format(name))
end)

lib:RegisterCallback("Name_Update", function(event, name, customName, oldCustomName)
	private.ChatOutput(private.getLocalisation("CallbackUpdated"):format(name, customName, oldCustomName))
end)

--- links a character of a bnet friend to their btag and remembers its class (the ui colors the character by it)
---@param battleTag string
---@param gameAccountInfo table? -- BNetGameAccountInfo
local function ProcessGameAccount(battleTag, gameAccountInfo)
	if not gameAccountInfo or not gameAccountInfo.wowProjectID or gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID
	or not gameAccountInfo.characterName or not gameAccountInfo.realmName then return end
	local Character = gameAccountInfo.characterName.."-"..gameAccountInfo.realmName
	if private.IsForever() then
		Character = gameAccountInfo.characterName
		Character = private.FixNameForever(Character)
	end
	if not Character then return end
	if not lib.IsInBnetDatabase(Character) and not lib.IsCharUnlinked(Character, battleTag) then
		lib.AddCharToBtag(Character,battleTag)
	end
	private.RememberClassID(Character, gameAccountInfo.classID)
end

--- looks at every character a bnet friend is online on, not only the one the friendlist shows
---@param friendIndex number
local function ProcessFriend(friendIndex)
	local number = C_BattleNet.GetFriendNumGameAccounts(friendIndex)
	if not number then return end
	local bnetAccountInfo = C_BattleNet.GetFriendAccountInfo(friendIndex)
	if not bnetAccountInfo or not bnetAccountInfo.battleTag then return end
	ProcessGameAccount(bnetAccountInfo.battleTag, bnetAccountInfo.gameAccountInfo)
	for accountIndex = 1, number do
		ProcessGameAccount(bnetAccountInfo.battleTag, C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex))
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

frame:SetScript("OnEvent",function(self,...)
	local event, friendId, isCompanionApp = ...
	if event == "PLAYER_TARGET_CHANGED" then
        private.RememberUnitClass("target")
        return
	elseif event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_INFO_CHANGED" then
		if friendId then
			ProcessFriend(friendId)
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		local name,realm = UnitFullName("player")
		local fullName = name.."-"..realm
		if not lib.IsInBnetDatabase(fullName) and not lib.IsCharUnlinked(fullName, "self") then
			lib.AddCharToBtag(fullName, "self")
		end
		private.RememberPlayerAndGroupClass()
	elseif event=='GROUP_ROSTER_UPDATE' then 
		private.RememberGroupClass()
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
	if strtrim(msg) == "" then --open the window
		private.ToggleWindow()
	elseif string.find(string.lower(msg), "add (.-) to (.-)") then --add
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
		if from and not string.find(from, "#") and not string.find(from, "-") and not string.find(from, "self") then
			
			if not UnitExists(from) and not private.IsForever() then				
				from = from .. "-" .. NormalizedRealmName()
			end
		end
		lib.Set(from, to)
	elseif string.find(string.lower(msg), "del (.-)") then --delete
		local _, _, type, from = string.find(msg, "(.-) (.*)")
		if UnitExists(from) then	
			local unitName, unitRealm = UnitName(from)
			local nameToCheck = unitName
			if UnitIsPlayer(from) and not private.IsForever() then
				nameToCheck= unitName .. "-" .. (unitRealm or NormalizedRealmName())
			elseif private.IsForever() then
				nameToCheck = private.FixNameForever(unitName)
			else
				nameToCheck = unitName .. "-".. unitRealm
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
			print(private.getLocalisation("NoSuchName"))
		end
	elseif string.find(string.lower(msg), "edit (.-)") then --edit
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
		if UnitExists(from) then	
			local unitName, unitRealm = UnitName(from)
			local nameToCheck = unitName
			if UnitIsPlayer(from) and not private.IsForever() then
				nameToCheck= unitName .. "-" .. (unitRealm or NormalizedRealmName())
			elseif private.IsForever() then
				nameToCheck = private.FixNameForever(unitName)
			else
				nameToCheck = unitName .. "-".. unitRealm
			end
			if nameToCheck and lib.isCharInDatabase(nameToCheck) then
				lib.Set(from, to)
			end
		elseif lib.isCharInDatabase(from) then
			lib.Set(from, to)
		elseif lib.IsInBnetDatabase(from) then
			lib.Set(from, to)
		else
			print(private.getLocalisation("NoSuchName"));
		end
	elseif msg == "list" or msg == "l" then
		for k,v in pairs(lib.GetList()) do
			print(k.." -> "..v)
			
		end
	else
		print(private.getLocalisation("CommandUsageHeader"))
		print(private.getLocalisation("CommandUsageWindow"))
		print(private.getLocalisation("CommandUsageAdd"))
		print(private.getLocalisation("CommandUsageEdit"))
		print(private.getLocalisation("CommandUsageDelete"))
		print(private.getLocalisation("CommandUsageList"))
	end
end
