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
    L["CallbackAddedMany"] = "Added: %s is now Renamed to %s (%d characters)"
    L["CallbackRemovedMany"] = "Deleted: %s is no longer Renamed (%d characters)"
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
    L["Search"] = "Search"
    L["AddName"] = "+ Add name"
    L["Import"] = "Import"
    L["Export"] = "Export"
    L["NamesCount"] = "%d names"
    L["EntriesCount"] = "%d of %d names shown"
    L["ListEmpty"] = "No names yet. Add one below or right-click a player."
    L["ListNoMatches"] = "No names match your search."
    L["SelfBattleTag"] = "Your account"
    L["CharacterCount"] = "%d characters"
    L["NotSet"] = "Not set"

    -- the selected name
    L["DetailEmpty"] = "Select a name on the left.\n\nTo give somebody a name, right-click them and pick CustomNames."
    L["KindCharacter"] = "Character"
    L["KindBattleTag"] = "BattleTag"
    L["KindOwnAccount"] = "This account"
    L["CustomNameLabel"] = "Custom name"
    L["EnterToSave"] = "Press Enter to save"
    L["Saved"] = "Saved"
    L["RemoveName"] = "Remove"
    L["ShowBattleTag"] = "Show"
    L["OverridesBattleTagName"] = "The custom name above replaces the BattleTag name %s for this character."
    L["LinkedCharacters"] = "Linked characters"
    L["NoLinkedCharacters"] = "No linked characters known yet. They are added when they are seen online."

    -- adding a name
    L["AddCharacterTitle"] = "Add a character"
    L["AddBattleTagTitle"] = "Add a BattleTag"
    L["AddCharacterHint"] = "Type the name with its realm. Without a realm your own realm is used."
    L["AddBattleTagHint"] = "The name applies to every character of that account."
    L["DialogSetNameTitle"] = "Set custom name"
    L["NameLabel"] = "Name-Realm"
    L["BattleTagLabel"] = "BattleTag#1234"
    L["Save"] = "Save"
    L["Cancel"] = "Cancel"
    L["Close"] = "Close"

    -- right-click menu of players and npcs
    L["MenuSetName"] = "Set custom name"
    L["MenuChangeName"] = "Change custom name"
    L["MenuSetBattleTagName"] = "Set name for BattleTag (all characters)"
    L["MenuChangeBattleTagName"] = "Change name for BattleTag (all characters)"
    L["MenuRemoveName"] = "Remove custom name"
    L["MenuRemoveBattleTagName"] = "Remove BattleTag name"

    -- status messages
    L["StatusSaved"] = "%s is now shown as %s"
    L["StatusRemoved"] = "%s is no longer renamed"
    L["ErrorNameMissing"] = "Enter a name first."
    L["ErrorCustomNameMissing"] = "Enter a custom name first."
    L["ErrorInvalidName"] = "That name can't be used. Use Name-Realm, a unit like target, or BattleTag#1234."
    L["ErrorInvalidBattleTag"] = "Use the format BattleTag#1234."
    L["ErrorNameNotAccessible"] = "That unit's name isn't available right now."

    -- import / export
    L["ExportTitle"] = "Export names"
    L["ExportHint"] = "Press Ctrl+C to copy the text"
    L["ImportTitle"] = "Import names"
    L["ImportHint"] = "Adds the names of an export string to your list."
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
