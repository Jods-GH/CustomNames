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

```lua
LibCustomNames.RegisterCallback(self, "eventName"[, method, [arg]])
LibCustomNames.UnregisterCallback(self, "eventname")
LibCustomNames.UnregisterAllCallbacks(self)
```
