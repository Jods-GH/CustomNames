local appName, app = ...
---@class CustomNamesPrivate
local private = app

-- Everything listed on the plugins tab of the window. Add your addon here through a pull request.
--   addon       folder name of the addon that brings the support: the plugin, or the addon itself if builtIn is set
--   title       shown in the list
--   description one or two sentences in English
--   requires    folder names of the addons the plugin is for, the entry is shown once one of them is enabled.
--               Leave it out for plugins of the default UI. Entries with builtIn don't need it
--   builtIn     the addon supports CustomNames on its own, there is nothing to install
--   url         where the plugin can be downloaded, not needed for builtIn entries
-- The order doesn't matter, the list is sorted when it is shown.
-- Forks of an addon get their own entry with their own folder name
private.Plugins = {
    -- plugins for the default UI
    {
        addon = "CustomNames_Chat",
        title = "Chat",
        description = "Shows custom names in the chat.",
        url = "https://www.curseforge.com/wow/addons/customnames-chat",
    },
    {
        addon = "CustomNames_Guild",
        title = "Guild",
        description = "Shows custom names in the guild and community rosters.",
        url = "https://www.curseforge.com/wow/addons/customnames-guild",
    },
    {
        addon = "CustomNames_BnetToast",
        title = "Battle.net toasts",
        description = "Shows custom names in the toasts that pop up when Battle.net friends come online.",
        url = "https://www.curseforge.com/wow/addons/customnames-bnettoast",
    },

    -- plugins for other addons
    {
        addon = "CustomNames_ElvUI",
        title = "ElvUI",
        requires = { "ElvUI" },
        description = "Adds tags with custom names to the ElvUI unit frames.",
        url = "https://www.curseforge.com/wow/addons/customnames-elvui",
    },
    {
        addon = "CustomNames_MRT",
        title = "MRT",
        requires = { "MRT" },
        description = "Shows custom names in Method Raid Tools.",
        url = "https://www.curseforge.com/wow/addons/customnames-mrt",
    },

    -- addons that support CustomNames on their own
    {
        addon = "DBM-Core",
        title = "Deadly Boss Mods",
        builtIn = true,
        description = "Shows custom names in its warnings and timers.",
    },
    {
        addon = "WeakAuras",
        title = "WeakAuras",
        builtIn = true,
        description = "Unit Formating will show custom names.",
    },
    {
        addon = "M33kAuras",
        title = "M33kAuras",
        builtIn = true,
        description = "Unit Formating will show custom names.",
    },
    {
        addon = "ForeverAuras",
        title = "ForeverAuras",
        builtIn = true,
        description = "Unit Formating will show custom names.",
    },
    {
        addon = "BetterFriendlist",
        title = "BetterFriendlist",
        builtIn = true,
        description = "Shows custom names in the friends list.",
    },
    {
        addon = "AbilityTimeline",
        title = "Better Timeline",
        builtIn = true,
        description = "Shows custom names on the timeline.",
    },
    {
        addon = "GroupFinderRIO",
        title = "GroupFinderRio",
        builtIn = true,
        description = "Shows custom names in the group finder.",
    },
    {
        addon = "MPlusQOL",
        title = "MPlusQOL",
        builtIn = true,
        description = "Shows custom names in its Mythic+ additions.",
    },
     {
        addon = "EllesmereUI",
        title = "EllesmereUI",
        builtIn = true,
        description = "Shows custom names in EllesmereUI unit frames.",
    },
}
