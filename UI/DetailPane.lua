local appName, app = ...
---@class CustomNamesPrivate
local private = app
local lib = LibStub("CustomNames")
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

-- The right side of the window. It shows one thing at a time: a hint, the selected name,
-- the form to add a name, the import or the export.
-- The widgets in here can't be released from inside their own callbacks, so the pane never rebuilds itself.
-- It tells the window what happened through the handlers and the window shows the next thing a frame later

---@class CustomNamesDetailPane
local DetailPane = {}
private.DetailPane = DetailPane

local COLUMNS_LAYOUT = "CustomNames-Columns"
local DOCK_LAYOUT = "CustomNames-Dock"
local KIND_CHAR = "char"
local KIND_BTAG = "btag"
local variables = {
    captionMargin = 4,
    fieldMargin = 18,
    noticeMargin = 6,
    sectionMargin = 22,
    groupMargin = 12,
    emptyMargin = 60,
    separator = " · ",
}

local container ---@type table? -- pane widget the content is built in
local handlers ---@type table? -- callbacks of the window, see DetailPane.Attach
local shown -- what is on display, used to only fade when something else gets shown
local editing = false -- the user typed something that isn't saved yet
local pendingNotice -- { key = string, text = string } shown once the pane of that key gets rebuilt

---@param widget table
---@param margin number? -- distance to the widget above (or below for BOTTOM)
---@param dock string? -- TOP by default
local function Add(widget, margin, dock)
    widget:SetUserData("dock", dock or "TOP")
    widget:SetUserData("margin", margin or 0)
    container:AddChild(widget)
    return widget
end

---@param text string
---@param fontKey string -- key of Theme.fonts
---@param color table? -- one of Theme.colors
---@return table label
local function CreateLabel(text, fontKey, color)
    local label = AceGUI:Create("Label")
    label:SetFontObject(Theme.fonts[fontKey])
    label:SetText(color and Theme.Colorize(text, color) or text)
    return label
end

---@param text string -- shown in capitals
---@return table label
local function CreateCaption(text)
    return CreateLabel(text:upper(), "caption", Theme.colors.muted)
end

---@param title string
---@param caption string?
local function AddHeader(title, caption)
    Add(CreateLabel(title, "title"))
    if caption then
        Add(CreateCaption(caption), variables.captionMargin)
    end
end

---@return table line -- container whose children are placed next to each other
local function CreateLine()
    local line = AceGUI:Create("CustomNames-Pane")
    line:SetLayout(COLUMNS_LAYOUT)
    return line
end

---@param textKey string -- localisation key
---@param variant string
---@param onClick function
---@return table button
local function CreateButton(textKey, variant, onClick)
    local button = AceGUI:Create("CustomNames-Button")
    button:SetVariant(variant)
    button:SetText(private.getLocalisation(textKey))
    button:SetCallback("OnClick", onClick)
    return button
end

---@return table spacer -- pushes whatever comes after it in a line to the right
local function CreateSpacer()
    local spacer = AceGUI:Create("Label")
    spacer:SetUserData("flex", 1)
    return spacer
end

---@param labelKey string -- localisation key of the caption
---@param placeholderKey string? -- localisation key of the text shown while the box is empty
---@return table editBox
local function CreateEditBox(labelKey, placeholderKey)
    local editBox = AceGUI:Create("CustomNames-EditBox")
    editBox:SetLabel(private.getLocalisation(labelKey))
    if placeholderKey then
        editBox:SetPlaceholder(private.getLocalisation(placeholderKey))
    end
    editBox:SetCallback("OnTextChanged", function()
        editing = true
    end)
    return editBox
end

---@param chars table -- sorted list of the characters linked to a btag
---@return table groups -- for the character grid, one group per realm
local function BuildCharacterGroups(chars)
    -- names on forever have no realm that they could be grouped by
    if private.IsForever() then
        local items = {}
        for index, charname in ipairs(chars) do
            items[index] = { text = charname, classFile = private.GetClass(charname) }
        end
        return { { items = items } }
    end
    local groups = {}
    for groupIndex, group in ipairs(private.GroupCharsByRealm(chars)) do
        local hasRealm = group.realm ~= ""
        local items = {}
        for index, name in ipairs(group.names) do
            local charname = hasRealm and (name .. "-" .. group.realm) or name
            items[index] = { text = name, classFile = private.GetClass(charname), tooltip = charname }
        end
        groups[groupIndex] = { title = hasRealm and group.realm or nil, items = items }
    end
    return groups
end

---@param signature string -- identifies what is shown, the pane fades in when it differs from the last one
local function Begin(signature)
    editing = false
    container:PauseLayout()
    container:ReleaseChildren()
    if shown ~= signature then
        shown = signature
        Theme.FadeIn(DetailPane, container.content)
    end
end

local function Finish()
    container:ResumeLayout()
    container:DoLayout()
end

---@param label table
---@param text string
---@param color table -- one of Theme.colors
local function SetNotice(label, text, color)
    label:SetText(Theme.Colorize(text, color))
    container:DoLayout()
end

---@param container_ table -- pane widget with the dock layout that doesn't adjust its height
---@param handlers_ table -- { OnChanged = fun(key: string?, keepDetail: boolean?), OnNavigate = fun(key: string), OnCancel = fun() }
DetailPane.Attach = function(container_, handlers_)
    container, handlers = container_, handlers_
    shown, editing, pendingNotice = nil, false, nil
end

DetailPane.Detach = function()
    if container then
        Theme.StopTweens(DetailPane)
        container.content:SetAlpha(1)
    end
    container, handlers = nil, nil
end

---@return boolean editing -- the user typed something that isn't saved yet
DetailPane.IsEditing = function()
    return editing
end

DetailPane.ShowEmpty = function()
    Begin("empty")
    local hint = CreateLabel(private.getLocalisation("DetailEmpty"), "body", Theme.colors.muted)
    hint:SetJustifyH("CENTER")
    Add(hint, variables.emptyMargin)
    Finish()
end

---@param entry table -- { key, kind = "char"|"btag", display, customName?, chars = sorted list? (btags), classFile? }
DetailPane.ShowEntry = function(entry)
    Begin("entry:" .. entry.key)
    local key = entry.key

    if entry.kind == KIND_BTAG then
        local count = private.getLocalisation("CharacterCount"):format(#entry.chars)
        local kindKey = key == private.SELF_BTAG and "KindOwnAccount" or "KindBattleTag"
        AddHeader(entry.display, private.getLocalisation(kindKey) .. variables.separator .. count)
    else
        local name, realm = private.SplitCharName(key)
        local title = Theme.Colorize(name, Theme.GetClassColor(entry.classFile) or Theme.colors.text)
        local caption = private.getLocalisation("KindCharacter")
        if realm then
            caption = caption .. variables.separator .. realm
        end
        AddHeader(title, caption)
    end

    local notice
    local customNameBox = Add(CreateEditBox("CustomNameLabel", "NotSet"), variables.fieldMargin)
    customNameBox:SetText(entry.customName)
    customNameBox:SetCallback("OnEnterPressed", function(_, _, text)
        local customName = strtrim(text or "")
        if customName == "" then
            SetNotice(notice, private.getLocalisation("ErrorCustomNameMissing"), Theme.colors.danger)
        elseif customName == entry.customName then
            editing = false
            AceGUI:ClearFocus()
        elseif private.SetName(key, customName) then
            pendingNotice = { key = key, text = private.getLocalisation("Saved") }
            handlers.OnChanged(key)
        else
            SetNotice(notice, private.getLocalisation("ErrorInvalidName"), Theme.colors.danger)
        end
    end)

    if pendingNotice and pendingNotice.key == key then
        notice = CreateLabel(pendingNotice.text, "small", Theme.colors.success)
    else
        notice = CreateLabel(private.getLocalisation("EnterToSave"), "small", Theme.colors.disabled)
    end
    pendingNotice = nil
    Add(notice, variables.noticeMargin)

    if entry.kind == KIND_CHAR then
        local btag = private.GetBattleTagForChar(key)
        if btag then
            local btagName = private.GetDirectName(btag)
            Add(CreateCaption(private.getLocalisation("KindBattleTag")), variables.sectionMargin)
            local line = CreateLine()
            local btagLabel = CreateLabel(private.GetDisplayName(btag), "body")
            btagLabel:SetUserData("flex", 1)
            line:AddChild(btagLabel)
            line:AddChild(CreateButton("ShowBattleTag", "link", function()
                handlers.OnNavigate(btag)
            end))
            Add(line, variables.noticeMargin)
            if btagName then
                local text = private.getLocalisation("OverridesBattleTagName"):format(btagName)
                Add(CreateLabel(text, "small", Theme.colors.muted), variables.noticeMargin)
            end
        end
    end

    -- whatever is docked to the bottom has to be added before the part that fills the rest
    if entry.customName then
        local line = CreateLine()
        line:AddChild(CreateSpacer())
        line:AddChild(CreateButton("RemoveName", "danger", function()
            if private.SetName(key) then
                private.SetWindowStatus(private.getLocalisation("StatusRemoved"):format(entry.display))
            end
            handlers.OnChanged()
        end))
        Add(line, 0, "BOTTOM")
    end

    if entry.kind == KIND_BTAG then
        Add(CreateCaption(private.getLocalisation("LinkedCharacters")), variables.sectionMargin)
        if #entry.chars == 0 then
            local text = private.getLocalisation("NoLinkedCharacters")
            Add(CreateLabel(text, "small", Theme.colors.muted), variables.noticeMargin)
        else
            local scroll = AceGUI:Create("CustomNames-Scroll")
            scroll:SetLayout(DOCK_LAYOUT)
            local grid = AceGUI:Create("CustomNames-CharacterGrid")
            grid:SetGroups(BuildCharacterGroups(entry.chars))
            grid:SetUserData("dock", "TOP")
            scroll:AddChild(grid)
            Add(scroll, variables.noticeMargin, "FILL")
        end
    end

    Finish()
end

---@param kind "char"|"btag" -- what the user is expected to type
DetailPane.ShowAdd = function(kind)
    Begin("add:" .. kind)
    local isBattleTag = kind == KIND_BTAG
    AddHeader(private.getLocalisation(isBattleTag and "AddBattleTagTitle" or "AddCharacterTitle"))
    local hintKey = isBattleTag and "AddBattleTagHint" or "AddCharacterHint"
    Add(CreateLabel(private.getLocalisation(hintKey), "small", Theme.colors.muted), variables.noticeMargin)

    local nameBox = Add(
        CreateEditBox(isBattleTag and "KindBattleTag" or "KindCharacter", isBattleTag and "BattleTagLabel" or "NameLabel"),
        variables.fieldMargin
    )
    local customNameBox = Add(CreateEditBox("CustomNameLabel"), variables.groupMargin)
    local notice = Add(CreateLabel(" ", "small"), variables.noticeMargin)

    local function Save()
        local name, errorKey
        if isBattleTag then
            name, errorKey = private.NormalizeInputBattleTag(nameBox:GetText())
        else
            name, errorKey = private.NormalizeInputName(nameBox:GetText())
        end
        if not name then
            SetNotice(notice, private.getLocalisation(errorKey), Theme.colors.danger)
            return
        end
        local customName = strtrim(customNameBox:GetText() or "")
        if customName == "" then
            SetNotice(notice, private.getLocalisation("ErrorCustomNameMissing"), Theme.colors.danger)
            return
        end
        if not private.SetName(name, customName) then
            SetNotice(notice, private.getLocalisation("ErrorInvalidName"), Theme.colors.danger)
            return
        end
        pendingNotice = { key = name, text = private.getLocalisation("Saved") }
        handlers.OnChanged(name)
    end

    nameBox:SetCallback("OnEnterPressed", function()
        customNameBox:SetFocus()
    end)
    customNameBox:SetCallback("OnEnterPressed", Save)

    local line = CreateLine()
    line:AddChild(CreateButton("Save", "primary", Save))
    line:AddChild(CreateButton("Cancel", "ghost", function()
        handlers.OnCancel()
    end))
    Add(line, variables.groupMargin)

    Finish()
    nameBox:SetFocus()
end

DetailPane.ShowImport = function()
    Begin("import")
    AddHeader(private.getLocalisation("ImportTitle"))
    Add(CreateLabel(private.getLocalisation("ImportHint"), "small", Theme.colors.muted), variables.noticeMargin)

    local importText = AceGUI:Create("CustomNames-MultiLineEditBox")
    importText:SetPlaceholder(private.getLocalisation("ImportBoxLabel"))
    importText:SetCallback("OnTextChanged", function()
        editing = true
    end)

    local overwriteToggle = AceGUI:Create("CustomNames-Toggle")
    overwriteToggle:SetLabel(private.getLocalisation("ImportOverwrite"))
    overwriteToggle:SetValue(true)

    local result = CreateLabel(" ", "small")

    -- added from the bottom up, the text takes what is left in between
    local line = CreateLine()
    line:AddChild(CreateButton("Import", "primary", function()
        local counts, errorKey = private.ImportNames(importText:GetText(), overwriteToggle:GetValue())
        if not counts then
            SetNotice(result, private.getLocalisation(errorKey), Theme.colors.danger)
            return
        end
        editing = false
        local text = private.getLocalisation("ImportResult"):format(counts.added, counts.updated, counts.skipped)
        SetNotice(result, text, Theme.colors.success)
        handlers.OnChanged(nil, true)
    end))
    line:AddChild(CreateButton("Cancel", "ghost", function()
        handlers.OnCancel()
    end))
    Add(line, 0, "BOTTOM")
    Add(result, variables.noticeMargin, "BOTTOM")
    Add(overwriteToggle, variables.noticeMargin, "BOTTOM")
    Add(importText, variables.groupMargin, "FILL")

    Finish()
    importText:SetFocus()
end

DetailPane.ShowExport = function()
    Begin("export")
    AddHeader(private.getLocalisation("ExportTitle"))

    local exportString, errorKey = private.ExportNames()
    if not exportString then
        Add(CreateLabel(private.getLocalisation(errorKey), "small", Theme.colors.danger), variables.noticeMargin)
        Finish()
        return
    end
    Add(CreateLabel(private.getLocalisation("ExportHint"), "small", Theme.colors.muted), variables.noticeMargin)

    local exportText = AceGUI:Create("CustomNames-MultiLineEditBox")
    exportText:SetText(exportString)

    local line = CreateLine()
    line:AddChild(CreateButton("Close", "ghost", function()
        handlers.OnCancel()
    end))
    Add(line, 0, "BOTTOM")
    Add(exportText, variables.groupMargin, "FILL")

    Finish()
    exportText:SetFocus()
    exportText:HighlightText()
end
