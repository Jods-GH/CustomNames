# CustomNames
Adds Management of Custom Names
# Usage 
```lua
local LibCustomNames= LibStub("LibCustomNames")
local customName = LibCustomNames.Get(name)
local success = LibCustomNames.Set(name, customName) -- for adding/editing accepts units aswell as Names in the format of Name-Realm (for players) or just Name (for npcs)
local success = LibCustomNames.Set(name) -- for deleting accepts units aswell as Names in the format of Name-Realm (for players) or just Name (for npcs)
local NameList = LibCustomNames.GetList() -- returns a copy of the DataBaseTable
local customName = LibCustomNames.UnitName(unit) -- behaves equivalent to normal UnitName()
local customName = LibCustomNames.UnitFullName(unit) -- behaves equivalent to normal UnitFullName()
local customName = LibCustomNames.GetUnitName(unit,showServerName) -- behaves equivalent to normal GetUnitName()
```
# Callbacks

event names: Name_Removed , Name_Update, Name_Added

Name_Removed (Name) -- will return the name in the database that got removed (This is in format Name-Realm for all player characters and Name for npc's as returned by UnitName())
Name_Updated (Name,newName,oldName) -- will return the name in the database (This is in format Name-Realm for all player characters and Name for npc's as returned by UnitName()), the new CustomName the database was updated to and the old CustomName as it was previously returned by the Getter functions
Name_Added (Name, customName) -- will return the name in the database (This is in format Name-Realm for all player characters and Name for npc's as returned by UnitName()) aswell as the CustomName that was added

```lua
LibCustomNames.RegisterCallback(self, "eventName"[, method, [arg]])
LibCustomNames.UnregisterCallback(self, "eventname")
LibCustomNames.UnregisterAllCallbacks(self)
```
