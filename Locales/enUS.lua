local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceLocale = LibStub("AceLocale-3.0")

local L = AceLocale:NewLocale(appName, "enUS", true)

if L then
    -- chat output
    L["CallbackAdded"] = "Added: %s is now Renamed to %s"
    L["CallbackRemoved"] = "Deleted: %s is no longer Renamed"
    L["CallbackUpdated"] = "Edited: %s is now Renamed to %s (was %s)"
    L["NoSuchName"] = "No such name in database"
    L["CommandUsageHeader"] = "CustomNames example usage:"
    L["CommandUsageWindow"] = "Opening the window: /cn"
    L["CommandUsageAdd"] = "Adding a new name: /cn add Name to CustomName"
    L["CommandUsageEdit"] = "Editing name: /cn edit Name to CustomName"
    L["CommandUsageDelete"] = "Deleting old name: /cn del Name"
    L["CommandUsageList"] = "Listing every name: /cn l(ist)"

    -- window
    L["WindowTitle"] = "CustomNames"
    L["TabCharacters"] = "Characters"
    L["TabBattleTags"] = "BattleTags"
    L["NameLabel"] = "Name-Realm or unit (e.g. target)"
    L["BattleTagLabel"] = "BattleTag#1234 or self"
    L["CustomNameLabel"] = "Custom name"
    L["Add"] = "Add"
    L["Delete"] = "Delete"
    L["UseTarget"] = "Use target"
    L["PickGroupMember"] = "Pick a group member"
    L["NoGroupMembers"] = "Not in a group"
    L["PickKnownBattleTag"] = "Pick a known BattleTag"
    L["NoKnownBattleTags"] = "No unnamed BattleTags known"
    L["Search"] = "Search"
    L["Import"] = "Import"
    L["Export"] = "Export"
    L["EntriesCount"] = "%d of %d names shown"
    L["ListEmpty"] = "No names yet. Add one above."
    L["ListNoMatches"] = "No names match your search."
    L["SelfBattleTag"] = "You (all your characters)"
    L["LinkedCharacters"] = "Linked characters: %s"
    L["NoLinkedCharacters"] = "No linked characters known yet"

    -- status bar
    L["StatusSaved"] = "%s is now shown as %s"
    L["StatusRemoved"] = "%s is no longer renamed"
    L["ErrorNameMissing"] = "Enter a name first."
    L["ErrorCustomNameMissing"] = "Enter a custom name first."
    L["ErrorInvalidName"] = "That name can't be used. Use Name-Realm, a unit like target, or BattleTag#1234."
    L["ErrorInvalidBattleTag"] = "Use the format BattleTag#1234 or self."
    L["ErrorNoTarget"] = "You have no target."
    L["ErrorNameNotAccessible"] = "That unit's name isn't available right now."

    -- import / export
    L["ExportTitle"] = "Export names"
    L["ExportHint"] = "Press Ctrl+C to copy the text"
    L["ExportFailed"] = "The names could not be exported."
    L["ImportTitle"] = "Import names"
    L["ImportBoxLabel"] = "Paste an export string"
    L["ImportOverwrite"] = "Overwrite names that already exist"
    L["ImportResult"] = "Import finished: %d added, %d updated, %d skipped."
    L["ImportErrorFormat"] = "This is not a CustomNames export string."
    L["ImportErrorDecode"] = "The export string is damaged and could not be read."
    L["ImportExportUnsupported"] = "Import and export are not supported on this game version."

    -- settings panel
    L["SettingsDescription"] = "Manage custom names for characters and BattleTags."
    L["OpenWindow"] = "Open CustomNames"

    private.localisation = L
end
