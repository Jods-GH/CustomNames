# LibCustomNames-1.0
Adds Management of Custom Names
# Usage 
```lua
local LibCustomNames= LibStub("LibCustomNames-1.0")
local customName = LibCustomNames:Get(name)
local success = LibCustomNames:Set(name, customName) -- for adding/editing
local success = LibCustomNames:Set(name) -- for deleting
local NameList = LibCustomNames:GetList()
```
