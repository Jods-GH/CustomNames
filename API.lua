local MAJOR_VERSION = "CustomNames"
local MINOR_VERSION = 4
if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
---@class CustomNames
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
if not lib then error("CustomNames failed to initialise")return end
CustomNamesDB = CustomNamesDB or {}
CustomNamesDB.CharDB = CustomNamesDB.CharDB or {}
CustomNamesDB.BnetDB = CustomNamesDB.BnetDB or {}
CustomNamesDB.CharToBnetDB = CustomNamesDB.CharToBnetDB or {}
local CharDB,BnetDB,CharToBnetDB
local loadedFrame = CreateFrame("Frame");
loadedFrame:RegisterEvent("ADDON_LOADED");
loadedFrame:SetScript("OnEvent", function(self, event, addon)
  	if(event == "ADDON_LOADED") then
		if(addon == MAJOR_VERSION) then
			CharDB = CustomNamesDB.CharDB
			BnetDB = CustomNamesDB.BnetDB
			CharToBnetDB = CustomNamesDB.CharToBnetDB
		end
	end
end)


--- Since GetNormalizedRealmName can return nil we need to gsub GetRealmName ourselfs if need be
---@return string Realm
local function NormalizedRealmName()
	return GetNormalizedRealmName() or GetRealmName():gsub("[%s-]+", "")
end
---returns custom name if exists, otherwise returns original name. Expects Name-Realm for Players and Name for NPCs. Also allows for the Lookup of battletags in format "Name#1234"
---@param name string
---@return string name
function lib.Get(name)
	if issecretvalue then
		assert(not issecretvalue(name), "CustomNames: Can't get name (name is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(name), "CustomNames: Can't get name (no access to value)")
	end
	assert(name, "CustomNames: Can't Get Custom Name (name is nil)")
	local nameToCheck = name
	if not (name:match( "^.-%-.-$") or name:match("^%a+#%d+$")) then -- add realm if it isn't in btag format and doesn't exist
		nameToCheck = name .. "-" .. NormalizedRealmName()
	end
	if CharDB[nameToCheck] then
		return CharDB[nameToCheck]	
	elseif BnetDB[nameToCheck] and BnetDB[nameToCheck].name then
		return BnetDB[nameToCheck].name
	elseif CharToBnetDB[nameToCheck] and BnetDB[CharToBnetDB[nameToCheck]] and BnetDB[CharToBnetDB[nameToCheck]].chars 
	and BnetDB[CharToBnetDB[nameToCheck]].chars[nameToCheck] and BnetDB[CharToBnetDB[nameToCheck]].name then
		return BnetDB[CharToBnetDB[nameToCheck]].name	
	else
		return name
	end
end
---returns true if custom name exists, otherwise returns nil
---@param name string
---@return boolean? exists
---@deprecated
function lib.IsCharInBnetDatabase(name)
	return lib.IsInBnetDatabase(name)
end
---returns true if custom name exists for char or btag, otherwise returns false
---@param name string
---@return boolean exists
function lib.IsInBnetDatabase(name)
	if issecretvalue then
		assert(not issecretvalue(name), "CustomNames: Can't check if Name is in BnetDatabase (name is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(name), "CustomNames: Can't check if Name is in BnetDatabase (no access to value)")
	end
	assert(name, "CustomNames: Can't check if Name is in BnetDatabase (name is nil)")
	if CharToBnetDB[name] then
		return true
	elseif BnetDB[name] then
		return true
	else
		return false
	end
end

---returns true if custom name exists for char either through btag or direct otherwise false
---@param name string
---@return boolean exists
function lib.isCharInDatabase(name)
	if issecretvalue then
		assert(not issecretvalue(name), "CustomNames: Can't check if name is in database (name is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(name), "CustomNames: Can't check if name is in database (no access to value)")
	end
	assert(name, "CustomNames: Can't Get Custom Name (name is nil)")
	local isInCharDb = CharDB[name] and true or false
	local isInBnetDb = CharToBnetDB[name] and true or false
	return isInCharDb or isInBnetDb
end

---returns true if exists, otherwise returns false. Expects Name-Realm for Players and Name for NPCs. Also allows for the Lookup of battletags in format "Name#1234"
---@param name string
---@return boolean exists
function lib.isInDatabase(name)
	if issecretvalue then
		assert(not issecretvalue(name), "CustomNames: Can't check if name is in database (name is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(name), "CustomNames: Can't check if name is in database (no access to value)")
	end
	assert(name, "CustomNames: Can't Get Custom Name (name is nil)")
	local nameToCheck = name
	if not (name:match( "^.-%-.-$") or name:match("^%a+#%d+$")) then -- add realm if it isn't in btag format and doesn't exist
		nameToCheck = name .. "-" .. NormalizedRealmName()
	end
	if CharDB[nameToCheck] then
		return true	
	elseif BnetDB[nameToCheck] and BnetDB[nameToCheck].name then
		return true
	elseif CharToBnetDB[nameToCheck] and BnetDB[CharToBnetDB[nameToCheck]] and BnetDB[CharToBnetDB[nameToCheck]].chars 
	and BnetDB[CharToBnetDB[nameToCheck]].chars[nameToCheck] and BnetDB[CharToBnetDB[nameToCheck]].name then
		return true	
	else
		return false
	end
end

---returns true if name is a "battletag" includes self so can't be used to check if a name is in the database
---@param name any
---@return boolean
local function isBtag(name)
	if issecretvalue then
		assert(not issecretvalue(name), "CustomNames: Can't check if string is btag (name is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(name), "CustomNames: Can't check if string is btag (no access to value)")
	end
	if not name then return false end
	return name:match("^%a+#%d+$") or name:match("^self$") -- self is a special case for the current player
end

---returns all characters linked to a given btag
---@param btag string
--- @return table list -- of characters in fullname format Name-Realm
local function GetCharactersInBtag(btag)
	if issecretvalue then
		assert(not issecretvalue(btag), "CustomNames: Can't Get Characters in Btag (btag is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(btag), "CustomNames: Can't Get Characters in Btag (no access to value)")
	end
	assert(btag, "CustomNames: Can't Get Characters in Btag (btag is nil)")
	if not BnetDB[btag] or not BnetDB[btag].chars then
		return {}
	end
	local chars = {}
	for charname in pairs (BnetDB[btag].chars) do
		chars[charname] = lib.Get(charname)
	end
	return chars
end

--- returns all characters linked to a given character or btag
--- @param name any -- needs to be character name in format Name-Realm or battletag in format "Name#1234"
--- @return table -- list of characters in fullname format Name-Realm
function lib.GetLinkedCharacters(name)
	if issecretvalue then
		assert(not issecretvalue(name), "CustomNames: Can't Get Linked Charachter (name is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(name), "CustomNames: Can't Get Linked Charachter (no access to value)")
	end
	assert(name, "CustomNames: Can't Get Linked Characters (name is nil)")
	if isBtag(name) then
		return GetCharactersInBtag(name)
	end
	local btag = CharToBnetDB[name]
	if not btag then
		return {}
	end
	return GetCharactersInBtag(btag)
end


---links a character name to a btag
---@param charname string
---@param btag string
---@return boolean? success
function  lib.AddCharToBtag(charname,btag)
	if issecretvalue then
		assert(not issecretvalue(charname), "CustomNames: Can't Add char to btag (name is a secret value)")
		assert(not issecretvalue(btag), "CustomNames: Can't Add char to btag (btag is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(charname), "CustomNames: Can't Add char to btag (no access to value)")
		assert(canaccessvalue(btag), "CustomNames: Can't Add char to btag (no access to value)")
	end
	assert(charname, "CustomNames: Can't add char to btag (charname is nil)")
	assert(btag, "CustomNames: Can't add char to btag (btag is nil)")
	CharToBnetDB[charname] = btag	
	BnetDB[btag] = BnetDB[btag] or {}
	BnetDB[btag].chars = BnetDB[btag].chars or {}
	BnetDB[btag].chars[charname] = true
	if BnetDB[btag] and BnetDB[btag].name then
		lib.callbacks:Fire("Name_Added", charname, BnetDB[btag].name)
	end
	return true
end
---lib.set but for btags
---@param btag string
---@param customName string
---@return boolean? success
local function SetBnet(btag,customName)
	if issecretvalue then
		assert(not issecretvalue(btag), "CustomNames: Can't Set Btag (btag is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(btag), "CustomNames: Can't Set Bnet (no access to value)")
	end
	if not btag then return end
	if not customName then
		BnetDB[btag].name = nil
		for charname in pairs (BnetDB[btag]) do
			if charname ~= "name" then	
				lib.callbacks:Fire("Name_Removed", charname)
			end
		end
		lib.callbacks:Fire("Name_Removed", btag)
		return true
	else
		if BnetDB[btag] and BnetDB[btag].name then
			local tempname = BnetDB[btag].name
			BnetDB[btag].name = customName
			if BnetDB[btag].chars then
				for charname in pairs (BnetDB[btag].chars) do
					lib.callbacks:Fire("Name_Update", charname, customName, tempname)
				end
			end
		else 
			BnetDB[btag] = BnetDB[btag] or {}
			BnetDB[btag].name = customName
			if BnetDB[btag].chars then
				for charname in pairs (BnetDB[btag].chars) do			
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
    assert(name, "CustomNames: Can't SetCustomName (name is nil)")
	if issecretvalue and issecretvalue(unit) or canaccessvalue and not canaccessvalue(unit) then return UnitName(unit) end
	if issecretvalue then
		assert(not issecretvalue(name), "CustomNames: Can't Set Custom Name (name is a secret value)")
	end
	if canaccessvalue then
		assert(canaccessvalue(name), "CustomNames: Can't Set Custom Name (no access to value)")
	end
	if UnitExists(name) then	
		local unitName, unitRealm = UnitName(name)
		if UnitIsPlayer(name) then
			name = unitName .. "-" .. (unitRealm or NormalizedRealmName())
		else
			name = unitName
		end
	elseif name:match("^(.-)#(%d+)$") then
		return SetBnet(name,customName)
	elseif name:lower():trim():match("self") then
		return SetBnet("self",customName)
	else
		assert(name:match("^(.+)-(.+)$"), "CustomNames: Can't set custom Name (name is not in one of the formats UnitToken, Name-Realm or BattleTag#12345)")
	end
	if not customName then
		CharDB[name] = nil
		lib.callbacks:Fire("Name_Removed", name)
		return true
	else
		if CharDB[name] then
			local tempname = CharDB[name]
			CharDB[name] = customName
			lib.callbacks:Fire("Name_Update", name, customName, tempname)
		else 
			CharDB[name] = customName
			lib.callbacks:Fire("Name_Added", name, customName)
		end
		return true
	end
end
---Returns a list of all custom names
---@return table
function lib.GetList()
	local list = CopyTable(CharDB)
	for btag,BnetValue in pairs (BnetDB) do
		if BnetValue.name and BnetValue.chars then
			for Charname in pairs (BnetValue.chars) do
				if not list[Charname] and BnetValue.chars[Charname] then
					list[Charname] = BnetValue.name
				end
			end
		end
	end
	return list
end
---behaves equivalent to UnitName(unit)
---@param unit UnitToken
---@return string? name
---@return string? realm
function lib.UnitName(unit)
	if issecretvalue and issecretvalue(unit) or canaccessvalue and not canaccessvalue(unit) then return UnitName(unit) end
	if not unit or not UnitExists(unit) then return UnitName(unit) end
	local unitName, unitRealm = UnitName(unit)
	local nameToCheck = unitName .. "-" .. (unitRealm or NormalizedRealmName())
	local customName = lib.Get(nameToCheck)
	if customName ~= nameToCheck then
		return customName,unitRealm
	else
		return unitName,unitRealm
	end
end
---behaves equivalent to UnitNameUnmodified(unit)
---@param unit UnitToken
---@return string? name
---@return string? realm
function lib.UnitNameUnmodified(unit)
	if issecretvalue and issecretvalue(unit) or canaccessvalue and not canaccessvalue(unit) then return UnitNameUnmodified(unit) end
	if not unit or not UnitExists(unit) then return UnitNameUnmodified(unit) end
	local unitName, unitRealm = UnitNameUnmodified(unit)
	local nameToCheck = unitName .. "-" .. (unitRealm or NormalizedRealmName())
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
	if issecretvalue and issecretvalue(unit) or canaccessvalue and not canaccessvalue(unit) then return UnitFullName(unit) end
	if not unit or not UnitExists(unit) then return UnitFullName(unit) end
	local unitName, unitRealm = UnitFullName(unit)
	local nameToCheck
	if UnitIsPlayer(unit) then
		nameToCheck = unitName .. "-" .. (unitRealm or NormalizedRealmName())
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
	if issecretvalue and issecretvalue(unit) or canaccessvalue and not canaccessvalue(unit) then return GetUnitName(unit, showServerName) end
	if not unit or not UnitExists(unit) then return GetUnitName(unit, showServerName) end
	local unitName, unitRealm = UnitFullName(unit)	
	local nameToCheck
	if UnitIsPlayer(unit) then
		nameToCheck = unitName .. "-" .. (unitRealm or NormalizedRealmName())
	else
		nameToCheck= unitName
	end
	if not nameToCheck then 
		return GetUnitName(unit, showServerName)
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
