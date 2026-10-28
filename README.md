[![Discord](https://img.shields.io/badge/Discord-7289da?logo=discord&logoColor=fff&style=for-the-badge)](https://discord.gg/v3gYmYamGJ) 
[![Patreon](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-patreon.vercel.app%2Fapi%3Fusername%3DJodsderechte%26type%3Dpatrons&style=for-the-badge)](https://patreon.com/Jodsderechte) 
[![Twitch](https://custom-icon-badges.demolab.com/badge/-Catch%20me%20Live-lightgrey?style=for-the-badge&logo=Twitch&color=22283D)](https://www.twitch.tv/Jodsderechte)
[![Release][SVG-Release]][Release]
# CustomNames
Adds Management of Custom Names
# Managing names
Open the CustomNames window with `/cn`, through the Addon Compartment (Retail) or with the button under Options -> AddOns -> CustomNames.

* **Right-click** a player or npc (unit frames, friends list, chat, guild and community rosters) and pick **CustomNames** to set, change or remove a name without opening the window. For Battle.net friends the name can be set for the whole BattleTag. Bosses are not supported, their names are not available to addons.
* The window lists your names on the left. Select one to change or remove its name on the right, press Enter to save.
* **Characters** tab: names of single characters (`Name-Realm`) and npcs, colored by class once the character was seen.
* **BattleTags** tab: a name for a BattleTag (`BattleTag#12345`, your own account is always listed) applies to all characters linked to it. The linked characters are shown on the right, grouped by realm.
* **Search** filters the list and also finds a BattleTag by one of its characters. **+ Add name** lets you type a name yourself, **Export** creates a string with all your names and **Import** adds the names of such a string to your list.

The chat commands still work:
```
/cn add Name to CustomName
/cn edit Name to CustomName
/cn del Name
/cn list
```
# Plugins
The **Plugins** tab of the window lists the plugins and addons that show custom names in other parts of the game. It only shows the ones that fit your setup: plugins for the default UI, plugins for addons you have enabled, and addons that support CustomNames on their own. Each entry shows whether it is active, missing, disabled or waiting for a reload. Missing plugins come with a download address and count towards the badge on the tab, unless you tick **Don't suggest this plugin**.

## Adding your addon
Open a pull request that adds an entry to `Data/Plugins.lua`:
```lua
{
    addon = "MyAddon_CustomNames",   -- folder name of the plugin, or of your addon if it supports CustomNames itself
    title = "MyAddon",               -- shown in the list
    description = "Shows custom names in MyAddon.", -- one or two sentences in English
    requires = { "MyAddon" },        -- addons the plugin is for, leave it out for plugins of the default UI
    url = "https://www.curseforge.com/wow/addons/myaddon-customnames", -- download address of the plugin
},
-- or, if your addon uses CustomNames without a plugin:
{ addon = "MyAddon", title = "MyAddon", builtIn = true, description = "Shows custom names in MyAddon." },
```
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
local NameList = Lib.GetCharList() -- returns a list with all names that are set directly on a character or npc (without the names characters get from their btag)
local NameList = Lib.GetLinkedCharacters(name) --- returns all characters linked to a given character or btag

-- NameList Format
NameList = {
	["Name-Realm1"] = "CustomName1",
	["Name-Realm2"] = "CustomName2",
}

-- Bnet api
local isInDatabase = Lib.IsInBnetDatabase(name) -- returns true if the charname is already linked to a bnet account or the btag is known (false otherwise)
local isInDatabase = Lib.isCharInDatabase(name) --returns true if custom name exists for char either through btag or direct otherwise false
local isInDatabase = Lib.isInDatabase(name) --returns true if exists, otherwise returns false. Expects Name-Realm for Players and Name for NPCs. Also allows for the Lookup of battletags in format "Name#1234"

local success = Lib.AddCharToBtag(charname,btag) -- links a char to a Given Btag. Btag should be in format "BattleTag#12345" NOTE: Friends characters get auto linked to their bnet's when they login so this never needs to be called for people on a users friendlist
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


[//]: # (Links)

[Discord]: https://discord.com/invite/v3gYmYamGJ (Join the Discord)
[PayPal]: https://ko-fi.com/jodsderechte (Donate via PayPal)
[Release]: https://github.com/Jodsderechte/CustomNames/releases/latest (Latest release)

[//]: # (Images)
[SVG-Discord]: https://img.shields.io/badge/Discord-7289da?logo=discord&logoColor=fff&style=flat-square
[SVG-PayPal]: https://custom-icon-badges.demolab.com/badge/-Support-lightgrey?style=flat-square&logo=kofi&color=222222
[SVG-Release]: https://badgen.net/github/release/Jodsderechte/CustomNames?style=flat-square
