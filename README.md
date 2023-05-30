# LibCustomNames-1.0
Adds Management of Custom Names
# Usage 
```lua
local LibCustomNames= LibStub("LibCustomNames")
local customName = LibCustomNames.Get(name)
local success = LibCustomNames.Set(name, customName) -- for adding/editing accepts units aswell as Names in the format of Name-Realm (for players) or just Name (for npcs)
local success = LibCustomNames.Set(name) -- for deleting accepts units aswell as Names in the format of Name-Realm (for players) or just Name (for npcs)
local NameList = LibCustomNames.GetList() -- returns a copy of the DataBaseTable
local customName = lib.UnitName(unit) -- behaves equivalent to normal UnitName()
local customName = lib.UnitFullName(unit) -- behaves equivalent to normal UnitFullName()
local customName = lib.GetUnitName(unit,showServerName) -- behaves equivalent to normal GetUnitName()
```
