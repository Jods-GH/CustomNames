# CustomNames
Adds Management of Custom Names
# Usage 
```lua
local Lib = LibStub("CustomNames")

-- Setting Names both accept units aswell as Names in the format of Name-Realm (for players) or just Name (for npcs) and Btag in format "BattleTag#12345"
local success = Lib.Set(name, customName) -- for adding/editing 
local success = Lib.Set(name) -- for deleting 
-- Getting Names
local customName = Lib.Get(name) -- this works both for Get(Charname) and Get(Btag)
local customName = Lib.UnitName(unit) -- behaves equivalent to normal UnitName()
local customName = Lib.UnitFullName(unit) -- behaves equivalent to normal UnitFullName()
local customName = Lib.UnitNameUnmodified(unit) -- behaves equivalent to normal UnitNameUnmodified()
local customName = Lib.GetUnitName(unit,showServerName) -- behaves equivalent to normal GetUnitName()
local NameList = Lib.GetList() -- returns a list with all Database entrys

-- NameList Format
NameList = {
	["Name-Realm1"] = "CustomName1",
	["Name-Realm2"] = "CustomName2",
}

-- Bnet api
local isInDatabase = Lib.isCharInBnetDatabase(name) -- returns true if the charname is already linked to a bnet account (nil otherwise)
local success = Lib.addCharToBtag(charname,btag) -- links a char to a Given Btag. Btag should be in format "BattleTag#12345"
```
# Callbacks

event names: Name_Removed , Name_Update, Name_Added <br/>

Name_Removed (Name) -- will return the name in the database that got removed  <br />
Name_Updated (Name, newCustomName, oldCustomName) -- will return the name in the database, the new CustomName the database was updated to and the old CustomName as it was previously returned by the Getter functions <br />
Name_Added (Name, customName) -- will return the name in the database aswell as the CustomName that was added <br />

Name is always in the format Name-Realm for all player characters and Name for npc's as returned by UnitName()
```lua
Lib.RegisterCallback(self, "eventName"[, method, [arg]])
Lib.UnregisterCallback(self, "eventname")
Lib.UnregisterAllCallbacks(self)
```

# Example:

```lua
Lib:RegisterCallback("Name_Added", function(event, name, customName)
	print("Added: " .. name .. " is now Renamed to " .. customName) -- this will print whenever a new Name is added 
end)
```
Check CustomNames.lua for more code examples.
