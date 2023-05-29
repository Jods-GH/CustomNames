# LibCustomNames-1.0
Adds Management of Custom Names
##Usage 
```lua
local LibCustomNames= LibStub("LibCustomNames-1.0")
local unitName = LibCustomNames:GetNameForUnit(unit)
local customName = LibCustomNames:GetCustomName(name)
local nameExist = LibCustomNames:CheckCustomName(name)

local success = LibCustomNames:AddCustomName(name, customName)
local success = LibCustomNames:RemoveCustomName(name)
local success = LibCustomNames:EditCustomName(name, customName)
```
