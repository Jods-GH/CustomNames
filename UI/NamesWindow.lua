local appName, app = ...
---@class CustomNamesPrivate
local private = app
local lib = LibStub("CustomNames")
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme
local DetailPane = private.DetailPane

local GLOBAL_FRAME_NAME = "CustomNamesWindowFrame"
local COLUMNS_LAYOUT = "CustomNames-Columns"
local DOCK_LAYOUT = "CustomNames-Dock"
local TAB_CHARS = "chars"
local TAB_BTAGS = "btags"
local TAB_GUILD = "guild" -- filled by CustomNames_GuildSync through lib.RegisterTabProvider
local GUILD_ADDON = "CustomNames_GuildSync"
local GUILD_ADDON_URL = "https://www.curseforge.com/wow/addons/customname-guildsync"
local GUILD_KEY_PREFIX = "GuildSync#" -- anonymous accounts of guildmates, only shown on the guild tab
local KIND_CHAR = "char"
local KIND_BTAG = "btag"
-- what the right side of the window shows
local MODE_ENTRY = "entry" -- the selected name, or a hint if nothing is selected
local MODE_ADD = "add"
local MODE_IMPORT = "import"
local MODE_EXPORT = "export"
local variables = {
    width = 760,
    height = 500,
    minWidth = 640,
    minHeight = 400,
    listShare = 0.42, -- part of the window width that is used by the list
    searchWidth = 220,
    barPadding = 6,
    footerPadding = 10,
    maxMatches = 3, -- number of characters named in a row when the search found a btag through them
}

local window ---@type table?
local widgets = {}
local callbackOwner = {}
local state = {
    tab = TAB_CHARS,
    mode = MODE_ENTRY,
    selected = {}, -- [tab] = key of the selected entry
    searchText = "", -- as typed
    search = "", -- trimmed and lowercased
    countText = "", -- shown in the footer while there is no notice
    noticeToken = 0, -- identifies the notice that is shown, so an older timer doesn't remove a newer one
    noticeActive = false,
    revealKey = nil, -- entry the next refresh has to bring into view
    refreshPending = false,
    refreshDetail = false,
    footerFor = nil, -- tab and provider the footer buttons were built for
}

local RefreshFooter -- defined once the buttons can be built

---@return table? provider -- what CustomNames_GuildSync registered for the guild tab
local function GetGuildProvider()
    return lib.GetTabProvider(TAB_GUILD)
end

---@param key string
---@return boolean -- the key is shown on the guild tab
local function IsGuildKey(key)
    if key:sub(1, #GUILD_KEY_PREFIX) == GUILD_KEY_PREFIX then return true end
    local provider = GetGuildProvider()
    return provider and provider.OwnsKey and provider.OwnsKey(key) and true or false
end

---@return string stateKey -- localisation key telling what keeps the guild tab from working
---@return string? url
local function GetGuildInstallState()
    if not C_AddOns.DoesAddOnExist(GUILD_ADDON) then
        return "GuildInstallMissing", GUILD_ADDON_URL
    end
    if C_AddOns.GetAddOnEnableState(GUILD_ADDON, UnitName("player")) == 0 then
        return "GuildInstallDisabled"
    end
    if not C_AddOns.IsAddOnLoaded(GUILD_ADDON) then
        return "GuildInstallReload"
    end
    return "GuildInstallOutdated" -- loaded but never registered, CustomNames or the plugin is too old
end

---@return table tabs -- for the tabs widget
local function BuildTabs()
    local guildText = private.getLocalisation("TabGuild")
    local provider = GetGuildProvider()
    local badge = provider and provider.GetBadge and provider.GetBadge()
    if badge and badge > 0 then
        guildText = guildText .. " " .. Theme.Colorize("(" .. badge .. ")", Theme.colors.accent)
    end
    return {
        { value = TAB_CHARS, text = private.getLocalisation("TabCharacters") },
        { value = TAB_BTAGS, text = private.getLocalisation("TabBattleTags") },
        { value = TAB_GUILD, text = guildText },
    }
end

-- lets escape close the window, the global only exists while the window is open
tinsert(UISpecialFrames, GLOBAL_FRAME_NAME)

local function ShowCount()
    state.noticeActive = false
    if widgets.notice then
        widgets.notice:SetText(Theme.Colorize(state.countText, Theme.colors.muted))
    end
end

---Shows a message in the footer of the window (if it is open) for a few seconds
---@param text string
---@param isError boolean?
local function SetStatus(text, isError)
    if not window then return end
    state.noticeToken = state.noticeToken + 1
    state.noticeActive = true
    local token = state.noticeToken
    widgets.notice:SetText(Theme.Colorize(text, isError and Theme.colors.danger or Theme.colors.text))
    C_Timer.After(Theme.durations.notice, function()
        if window and state.noticeToken == token then
            ShowCount()
        end
    end)
end

local function MatchesSearch(search, ...)
    if search == "" then return true end
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value and tostring(value):lower():find(search, 1, true) then
            return true
        end
    end
    return false
end

---@param key string
---@return boolean -- the key belongs to a btag and not to a character
local function IsBattleTagKey(key)
    return key == private.SELF_BTAG or key:find("#", 1, true) ~= nil
end

---@param chars table -- [Name-Realm] = true
---@return table list -- sorted names
local function SortedChars(chars)
    local list = {}
    for charname in pairs(chars) do
        table.insert(list, charname)
    end
    table.sort(list)
    return list
end

local function BuildCharEntry(name, customName)
    return { key = name, kind = KIND_CHAR, display = name, customName = customName, classFile = private.GetClass(name) }
end

local function BuildBattleTagEntry(btag, value)
    return {
        key = btag,
        kind = KIND_BTAG,
        display = private.GetDisplayName(btag),
        customName = value.name,
        chars = SortedChars(value.chars),
    }
end

---Looks an entry up no matter what the search is
---@param key string?
---@return table? entry -- nil if there is nothing to show for the key
local function GetEntry(key)
    if not key then return nil end
    if IsBattleTagKey(key) then
        local value = private.GetBnetList()[key]
        if key == private.SELF_BTAG then
            -- the own account is always offered, nobody should have to know that it is called self
            return BuildBattleTagEntry(key, value or { chars = {} })
        end
        return value and value.name and BuildBattleTagEntry(key, value) or nil
    end
    local customName = lib.GetCharList()[key]
    return customName and BuildCharEntry(key, customName) or nil
end

---Collects the entries of the selected tab that match the search
---@return table entries -- sorted list of entries, btags found through a character have matchedChars
---@return number shown -- number of names in entries
---@return number total -- number of names before filtering
local function GetEntries()
    local entries, shown, total = {}, 0, 0
    if state.tab == TAB_CHARS then
        for name, customName in pairs(lib.GetCharList()) do
            total = total + 1
            if MatchesSearch(state.search, name, customName) then
                shown = shown + 1
                table.insert(entries, BuildCharEntry(name, customName))
            end
        end
    else
        local bnetList = private.GetBnetList()
        bnetList[private.SELF_BTAG] = bnetList[private.SELF_BTAG] or { chars = {} }
        for btag, value in pairs(bnetList) do
            if (value.name or btag == private.SELF_BTAG) and btag:sub(1, #GUILD_KEY_PREFIX) ~= GUILD_KEY_PREFIX then
                local entry = BuildBattleTagEntry(btag, value)
                local matches = MatchesSearch(state.search, btag, entry.display, value.name)
                if not matches then
                    local matchedChars = {}
                    for _, charname in ipairs(entry.chars) do
                        if MatchesSearch(state.search, charname) then
                            table.insert(matchedChars, charname)
                        end
                    end
                    if #matchedChars > 0 then
                        entry.matchedChars = matchedChars
                        matches = true
                    end
                end
                if value.name then
                    total = total + 1
                    if matches then
                        shown = shown + 1
                    end
                end
                if matches then
                    table.insert(entries, entry)
                end
            end
        end
    end
    table.sort(entries, function(a, b)
        local aIsSelf, bIsSelf = a.key == private.SELF_BTAG, b.key == private.SELF_BTAG
        if aIsSelf ~= bIsSelf then
            return aIsSelf
        end
        return a.display:lower() < b.display:lower()
    end)
    return entries, shown, total
end

---@param chars table -- list of names that matched the search
---@return string text -- the first few of them
local function BuildMatchesText(chars)
    local names = {}
    for index = 1, math.min(#chars, variables.maxMatches) do
        names[index] = private.SplitCharName(chars[index])
    end
    local text = table.concat(names, ", ")
    if #chars > variables.maxMatches then
        text = text .. " +" .. (#chars - variables.maxMatches)
    end
    return text
end

---@param entry table
---@return table item -- row of the list
local function BuildItem(entry)
    if entry.kind == KIND_CHAR then
        local name, realm = private.SplitCharName(entry.key)
        return {
            key = entry.key,
            title = name,
            subtitle = realm,
            value = entry.customName,
            classFile = entry.classFile,
            titleColor = Theme.GetClassColor(entry.classFile),
        }
    end
    local title = entry.display
    local tagName, tagNumber = entry.key:match("^(.-)(#%d+)$")
    if tagName then
        title = tagName .. Theme.Colorize(tagNumber, Theme.colors.muted)
    end
    local subtitle
    if entry.matchedChars then
        subtitle = BuildMatchesText(entry.matchedChars)
    else
        subtitle = private.getLocalisation("CharacterCount"):format(#entry.chars)
    end
    return {
        key = entry.key,
        title = title,
        subtitle = subtitle,
        value = entry.customName or private.getLocalisation("NotSet"),
        valueColor = not entry.customName and Theme.colors.disabled or nil,
    }
end

local function RefreshGuildList()
    local list = widgets.list
    local provider = GetGuildProvider()
    local items, countText = {}, ""
    if provider and provider.GetItems then
        items, countText = provider.GetItems(state.search)
    end
    list:SetItems(items or {})
    list:SetEmptyText(private.getLocalisation(provider and "GuildListEmpty" or "GuildListMissing"))
    list:SetSelected(state.mode == MODE_ENTRY and state.selected[state.tab] or nil, true)
    state.countText = countText or ""
    if not state.noticeActive then
        ShowCount()
    end
end

local function RefreshList()
    if state.tab == TAB_GUILD then
        RefreshGuildList()
        return
    end
    local list = widgets.list
    local entries, shown, total = GetEntries()
    local items = {}
    for index, entry in ipairs(entries) do
        items[index] = BuildItem(entry)
    end
    list:SetItems(items)
    list:SetEmptyText(private.getLocalisation(state.search == "" and "ListEmpty" or "ListNoMatches"))
    list:SetSelected(state.mode == MODE_ENTRY and state.selected[state.tab] or nil, true)

    if state.search == "" then
        state.countText = private.getLocalisation("NamesCount"):format(total)
    else
        state.countText = private.getLocalisation("EntriesCount"):format(shown, total)
    end
    if not state.noticeActive then
        ShowCount()
    end
end

local function RefreshGuildDetail()
    local provider = GetGuildProvider()
    if not provider then
        DetailPane.ShowGuildInstall(GetGuildInstallState())
        return
    end
    local key = state.selected[TAB_GUILD]
    if key and widgets.list:HasKey(key) and provider.ShowDetail then
        provider.ShowDetail(key, DetailPane.Toolkit)
    else
        state.selected[TAB_GUILD] = nil
        if provider.ShowEmpty then
            provider.ShowEmpty(DetailPane.Toolkit)
        else
            DetailPane.ShowEmpty()
        end
    end
end

local function RefreshDetail()
    if state.tab == TAB_GUILD then
        RefreshGuildDetail()
    elseif state.mode == MODE_ADD then
        DetailPane.ShowAdd(state.tab == TAB_BTAGS and KIND_BTAG or KIND_CHAR)
    elseif state.mode == MODE_IMPORT then
        DetailPane.ShowImport()
    elseif state.mode == MODE_EXPORT then
        DetailPane.ShowExport()
    else
        local entry = GetEntry(state.selected[state.tab])
        if entry then
            DetailPane.ShowEntry(entry)
        else
            state.selected[state.tab] = nil
            DetailPane.ShowEmpty()
        end
    end
end

---Rebuilds the window on the next frame, widgets can't be released from inside their own callbacks
---@param detail boolean? -- also rebuild the right side, even if it holds something that isn't saved
local function ScheduleRefresh(detail)
    if not window then return end
    state.refreshDetail = state.refreshDetail or detail or false
    if state.refreshPending then return end
    state.refreshPending = true
    C_Timer.After(0, function()
        state.refreshPending = false
        local detailRequested = state.refreshDetail
        state.refreshDetail = false
        if not window then return end

        -- the guild tab shows how many guildmates wait for an answer, the tabs are only rebuilt when that changes
        local tabs = BuildTabs()
        if tabs[3].text ~= state.guildTabText then
            state.guildTabText = tabs[3].text
            widgets.tabs:SetTabs(tabs)
        end
        widgets.tabs:SetSelected(state.tab, true)
        RefreshFooter()
        RefreshList()
        local revealKey = state.revealKey
        state.revealKey = nil
        if revealKey then
            if not widgets.list:HasKey(revealKey) and state.search ~= "" then
                -- the search hides what has to be shown
                state.searchText, state.search = "", ""
                widgets.searchBox:SetText("")
                RefreshList()
            end
            widgets.list:ScrollToKey(revealKey)
        end

        -- forms are only replaced on request, a name that changes somewhere else must not wipe them
        if detailRequested or (state.mode == MODE_ENTRY and not DetailPane.IsEditing()) then
            RefreshDetail()
        end
    end)
end

---@param key string -- entry that gets selected and brought into view by the next refresh
local function SelectKey(key)
    if IsGuildKey(key) then
        state.tab = TAB_GUILD
    else
        state.tab = IsBattleTagKey(key) and TAB_BTAGS or TAB_CHARS
    end
    state.mode = MODE_ENTRY
    state.selected[state.tab] = key
    state.revealKey = key
end

---@param mode string -- one of the forms
local function ShowForm(mode)
    state.mode = mode
    widgets.list:SetSelected(nil, true)
    RefreshDetail()
end

-- how the right side of the window reports what happened in it
local detailHandlers = {
    ---@param key string? -- entry to select
    ---@param keepDetail boolean? -- the right side shows the result itself
    OnChanged = function(key, keepDetail)
        if key then
            SelectKey(key)
        end
        ScheduleRefresh(not keepDetail)
    end,
    OnNavigate = function(key)
        SelectKey(key)
        ScheduleRefresh(true)
    end,
    -- tab providers select their own keys, which may look like btags
    OnSelectInTab = function(key)
        state.mode = MODE_ENTRY
        state.selected[state.tab] = key
        state.revealKey = key
        ScheduleRefresh(true)
    end,
    OnCancel = function()
        state.mode = MODE_ENTRY
        ScheduleRefresh(true)
    end,
}

---@param parent table
---@param textKey string -- localisation key
---@param variant string
---@param onClick function
local function AddButton(parent, textKey, variant, onClick)
    local button = AceGUI:Create("CustomNames-Button")
    button:SetVariant(variant)
    button:SetText(private.getLocalisation(textKey))
    button:SetCallback("OnClick", onClick)
    parent:AddChild(button)
end

---Fills the footer with the actions of the selected tab, it is only rebuilt when the tab or the provider changes
RefreshFooter = function()
    local footer = widgets.footer
    local provider = state.tab == TAB_GUILD and GetGuildProvider() or nil
    local footerFor = state.tab == TAB_GUILD and (provider or TAB_GUILD) or TAB_CHARS
    if state.footerFor == footerFor then return end
    state.footerFor = footerFor

    footer:PauseLayout()
    footer:ReleaseChildren()
    if state.tab ~= TAB_GUILD then
        AddButton(footer, "AddName", "primary", function()
            ShowForm(MODE_ADD)
        end)
        AddButton(footer, "Import", "ghost", function()
            ShowForm(MODE_IMPORT)
        end)
        AddButton(footer, "Export", "ghost", function()
            ShowForm(MODE_EXPORT)
        end)
    elseif provider and provider.GetFooterButtons then
        for _, info in ipairs(provider.GetFooterButtons() or {}) do
            local button = AceGUI:Create("CustomNames-Button")
            button:SetVariant(info.variant or "ghost")
            button:SetText(info.text)
            button:SetCallback("OnClick", info.onClick)
            footer:AddChild(button)
        end
    end

    local notice = AceGUI:Create("Label")
    notice:SetFontObject(Theme.fonts.small)
    notice:SetJustifyH("RIGHT")
    notice:SetUserData("flex", 1)
    footer:AddChild(notice)
    widgets.notice = notice
    footer:ResumeLayout()
    footer:DoLayout()
    state.noticeActive = false
    ShowCount()
end

---@param dock string
---@param paddingY number
---@param line string -- edge that separates the bar from the rest
---@return table bar -- container whose children are placed next to each other
local function CreateBar(dock, paddingY, line)
    local bar = AceGUI:Create("CustomNames-Pane")
    bar:SetLayout(COLUMNS_LAYOUT)
    bar:SetPadding(Theme.sizes.padding, paddingY)
    bar:SetBackgroundColor(Theme.colors.header)
    bar:SetLines(line)
    bar:SetUserData("dock", dock)
    return bar
end

local function OnWindowClosed(widget)
    lib.UnregisterAllCallbacks(callbackOwner)
    _G[GLOBAL_FRAME_NAME] = nil
    window = nil
    wipe(widgets)
    state.mode = MODE_ENTRY
    state.noticeActive = false
    DetailPane.Detach()
    AceGUI:Release(widget)
end

local function OnNamesChanged()
    ScheduleRefresh()
end

local function CreateWindow()
    -- position and size are saved into this table
    CustomNames = CustomNames or {}
    CustomNames.window = CustomNames.window or {}
    local status = CustomNames.window
    status.width = status.width or variables.width
    status.height = status.height or variables.height

    window = AceGUI:Create("CustomNames-Window")
    window:SetTitle(private.getLocalisation("WindowTitle"))
    window:SetMinSize(variables.minWidth, variables.minHeight)
    window:SetStatusTable(status)
    window:SetLayout(DOCK_LAYOUT)
    window:SetCallback("OnClose", OnWindowClosed)
    window:PauseLayout()
    _G[GLOBAL_FRAME_NAME] = window.frame

    -- tabs and search
    local topBar = CreateBar("TOP", variables.barPadding, "BOTTOM")
    window:AddChild(topBar)

    local tabs = AceGUI:Create("CustomNames-Tabs")
    local tabList = BuildTabs()
    state.guildTabText = tabList[3].text
    tabs:SetTabs(tabList)
    tabs:SetSelected(state.tab, true)
    tabs:SetCallback("OnTabSelected", function(_, _, tab)
        state.tab = tab
        state.mode = MODE_ENTRY
        RefreshFooter()
        RefreshList()
        RefreshDetail()
    end)
    topBar:AddChild(tabs)
    widgets.tabs = tabs

    local spacer = AceGUI:Create("Label")
    spacer:SetUserData("flex", 1)
    topBar:AddChild(spacer)

    local searchBox = AceGUI:Create("CustomNames-EditBox")
    searchBox:SetPlaceholder(private.getLocalisation("Search"))
    searchBox:SetWidth(variables.searchWidth)
    searchBox:SetText(state.searchText)
    searchBox:SetCallback("OnTextChanged", function(_, _, text)
        state.searchText = text or ""
        state.search = strtrim(state.searchText):lower()
        RefreshList()
    end)
    topBar:AddChild(searchBox)
    widgets.searchBox = searchBox

    -- actions that don't belong to a single name, and the place for notices
    local footer = CreateBar("BOTTOM", variables.footerPadding, "TOP")
    window:AddChild(footer)
    widgets.footer = footer
    state.footerFor = nil
    RefreshFooter()

    local list = AceGUI:Create("CustomNames-List")
    list:SetUserData("dock", "LEFT")
    list:SetUserData("dockShare", variables.listShare)
    list:SetCallback("OnSelect", function(_, _, key)
        state.selected[state.tab] = key
        state.mode = MODE_ENTRY
        RefreshDetail()
    end)
    window:AddChild(list)
    widgets.list = list

    local detail = AceGUI:Create("CustomNames-Pane")
    detail:SetLayout(DOCK_LAYOUT)
    detail:SetAutoAdjustHeight(false)
    detail:SetPadding(Theme.sizes.padding + 4, Theme.sizes.padding)
    detail:SetLines("LEFT")
    window:AddChild(detail)
    DetailPane.Attach(detail, detailHandlers)

    window:ResumeLayout()
    window:DoLayout()
    RefreshList()
    RefreshDetail()

    -- names can also change through the api, the cli or friends logging in while the window is open
    lib.RegisterCallback(callbackOwner, "Name_Added", OnNamesChanged)
    lib.RegisterCallback(callbackOwner, "Name_Update", OnNamesChanged)
    lib.RegisterCallback(callbackOwner, "Name_Removed", OnNamesChanged)
end

---Shows a message in the footer of the window (if it is open) for a few seconds
private.SetWindowStatus = SetStatus

---Rebuilds the window (if it is open), forms and unsaved input on the right side are left alone
private.RefreshWindow = function()
    ScheduleRefresh()
end

---@param tab string? -- tab to show, the last one if nil
private.OpenWindow = function(tab)
    if tab then
        state.tab = tab
        state.mode = MODE_ENTRY
    end
    if window then
        window.frame:Raise()
        ScheduleRefresh(true)
        return
    end
    CreateWindow()
end

private.ToggleWindow = function()
    if window then
        window:Hide()
    else
        CreateWindow()
    end
end
