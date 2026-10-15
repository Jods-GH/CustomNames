local appName, app = ...
---@class CustomNamesPrivate
local private = app
local lib = LibStub("CustomNames")

-- the menu api exists on every supported game version, this is only a safeguard
if not (Menu and Menu.ModifyMenu) then return end

-- unit popup menus that get the CustomNames entries, see UnitPopupManager:RegisterMenu in the blizzard ui.
-- Bosses, arena enemies and pets are left out on purpose, their names are secret or of no use
local MENU_TAGS = {
    -- unit frames
    "MENU_UNIT_SELF",
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_ENEMY_PLAYER",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_RAID",
    "MENU_UNIT_TARGET",
    "MENU_UNIT_FOCUS",
    -- friends list and names in the chat
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_FRIEND_OFFLINE",
    "MENU_UNIT_BN_FRIEND",
    "MENU_UNIT_BN_FRIEND_OFFLINE",
    "MENU_UNIT_RECENT_ALLY",
    "MENU_UNIT_RECENT_ALLY_OFFLINE",
    -- rosters
    "MENU_UNIT_CHAT_ROSTER",
    "MENU_UNIT_GUILD",
    "MENU_UNIT_GUILD_OFFLINE",
    "MENU_UNIT_COMMUNITIES_WOW_MEMBER",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
}

local IsReadable = private.IsReadable

---@param value any
---@return boolean
local function IsReadableText(value)
    return IsReadable(value) and type(value) == "string" and value ~= ""
end

---@param unit UnitToken
---@return boolean isBoss -- also true if it can't be told
local function IsBoss(unit)
    if UnitIsBossMob then
        local isBoss = UnitIsBossMob(unit)
        if not IsReadable(isBoss) or isBoss then return true end
    end
    local classification = UnitClassification(unit)
    return not IsReadable(classification) or classification == "worldboss"
end

---Works out who a unit popup menu was opened for
---@param contextData table? -- context of the menu, filled by UnitPopupManager:OpenMenu
---@return string? charKey -- Name-Realm the character or npc is stored with
---@return string? btag -- BattleTag#1234 or self, if the account is known
local function ResolveTarget(contextData)
    if type(contextData) ~= "table" then return nil end

    local charKey
    local unit = contextData.unit
    if unit then
        if not UnitExists(unit) or IsBoss(unit) then return nil end
        charKey = private.GetNameKeyForUnit(unit)
        if not charKey then return nil end
        -- the ui colors the character by its class if it gets a name
        private.RememberUnitClass(unit)
    elseif not contextData.bnetIDAccount then
        -- the name of a bnet friend is the name of the account, not of a character
        local name, server = contextData.name, contextData.server
        if IsReadableText(name) then
            if not IsReadableText(server) then server = nil end
            if private.IsForever() then
                charKey = (lib.FixNameForever(server and (name .. "-" .. server) or name))
            else
                charKey = name .. "-" .. (server or private.NormalizedRealmName())
            end
        end
    end

    -- the link in the database decides which name is shown, so it wins over the account of the menu
    local btag = charKey and private.GetBattleTagForChar(charKey)
    if not btag then
        local contextTag = contextData.battleTag
        if contextTag == nil and type(contextData.accountInfo) == "table" then
            contextTag = contextData.accountInfo.battleTag
        end
        if IsReadableText(contextTag) and contextTag:match("^[^#%s]+#%d+$") then
            btag = contextTag
        end
    end

    return charKey, btag
end

---@param key string -- Name-Realm, BattleTag#1234 or self
local function RemoveName(key)
    if private.SetName(key) then
        private.SetWindowStatus(private.getLocalisation("StatusRemoved"):format(private.GetDisplayName(key)))
    end
    private.RefreshWindow()
end

local function AddMenuEntries(owner, rootDescription, contextData)
    local charKey, btag = ResolveTarget(contextData)
    if not charKey and not btag then return end

    local charName = charKey and private.GetDirectName(charKey)
    local btagName = btag and private.GetDirectName(btag)

    rootDescription:CreateDivider()
    local submenu = rootDescription:CreateButton(appName)
    if charKey then
        submenu:CreateButton(private.getLocalisation(charName and "MenuChangeName" or "MenuSetName"), function()
            private.ShowNameDialog({ key = charKey })
        end)
    end
    if btag then
        submenu:CreateButton(private.getLocalisation(btagName and "MenuChangeBattleTagName" or "MenuSetBattleTagName"), function()
            -- the game told us that this character belongs to the account, no need to wait for the friendlist
            if charKey and not lib.IsInBnetDatabase(charKey) then
                lib.AddCharToBtag(charKey, btag)
            end
            private.ShowNameDialog({ key = btag })
        end)
    end
    if charName then
        submenu:CreateButton(private.getLocalisation("MenuRemoveName"), function()
            RemoveName(charKey)
        end)
    end
    if btagName then
        submenu:CreateButton(private.getLocalisation("MenuRemoveBattleTagName"), function()
            RemoveName(btag)
        end)
    end
end

for _, tag in ipairs(MENU_TAGS) do
    Menu.ModifyMenu(tag, AddMenuEntries)
end
