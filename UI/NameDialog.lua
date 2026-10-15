local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

local GLOBAL_FRAME_NAME = "CustomNamesDialogFrame"
local COLUMNS_LAYOUT = "CustomNames-Columns"
local DOCK_LAYOUT = "CustomNames-Dock"
local KIND_BTAG = "btag"
local variables = {
    width = 360,
    addHeight = 262,
    presetHeight = 222,
    fieldMargin = 14,
    noticeMargin = 6,
}

local dialog ---@type table?

-- lets escape close the dialog, the global only exists while the dialog is open
tinsert(UISpecialFrames, GLOBAL_FRAME_NAME)

---Closes the dialog (if it is open)
private.CloseNameDialog = function()
    if dialog then
        dialog:Hide()
    end
end

---@param parent table
---@param widget table
---@param dock string
---@param margin number?
local function Add(parent, widget, dock, margin)
    widget:SetUserData("dock", dock)
    widget:SetUserData("margin", margin or 0)
    parent:AddChild(widget)
    return widget
end

---Shows the dialog a custom name is typed into. It works without the names window, the unit menus open it.
---With a key the dialog sets the name of exactly that entry, without one the user also types who gets the name
---@param options table -- { key = string? (Name-Realm, BattleTag#1234 or self), kind = "char"|"btag" (what is typed if there is no key) }
private.ShowNameDialog = function(options)
    private.CloseNameDialog()
    local key = options.key
    local isBattleTag = options.kind == KIND_BTAG

    local frame = AceGUI:Create("CustomNames-Window")
    if key then
        frame:SetTitle(private.getLocalisation("DialogSetNameTitle"))
    else
        frame:SetTitle(private.getLocalisation(isBattleTag and "AddBattleTagTitle" or "AddCharacterTitle"))
    end
    frame:SetWidth(variables.width)
    frame:SetHeight(key and variables.presetHeight or variables.addHeight)
    frame:EnableResize(false)
    frame:SetLayout(DOCK_LAYOUT)
    frame:SetCallback("OnClose", function(widget)
        if dialog == widget then
            dialog = nil
            _G[GLOBAL_FRAME_NAME] = nil
        end
        AceGUI:Release(widget)
    end)
    -- the names window uses the same strata and level
    frame.frame:Raise()
    dialog = frame
    _G[GLOBAL_FRAME_NAME] = frame.frame

    local body = AceGUI:Create("CustomNames-Pane")
    body:SetLayout(DOCK_LAYOUT)
    body:SetAutoAdjustHeight(false)
    body:SetPadding(Theme.sizes.padding)
    frame:AddChild(body)
    body:PauseLayout()

    local nameBox
    if key then
        -- characters are shown in the color of their class, if it is known
        local keyLabel = AceGUI:Create("Label")
        keyLabel:SetFontObject(Theme.fonts.heading)
        keyLabel:SetText(Theme.Colorize(private.GetDisplayName(key), Theme.GetClassColor(private.GetClass(key)) or Theme.colors.text))
        Add(body, keyLabel, "TOP")
    else
        nameBox = AceGUI:Create("CustomNames-EditBox")
        nameBox:SetLabel(private.getLocalisation(isBattleTag and "KindBattleTag" or "KindCharacter"))
        nameBox:SetPlaceholder(private.getLocalisation(isBattleTag and "BattleTagLabel" or "NameLabel"))
        Add(body, nameBox, "TOP")
    end

    local customNameBox = AceGUI:Create("CustomNames-EditBox")
    customNameBox:SetLabel(private.getLocalisation("CustomNameLabel"))
    customNameBox:SetText(key and private.GetDirectName(key) or "")
    Add(body, customNameBox, "TOP", variables.fieldMargin)

    -- always holds a line of text so nothing moves once an error is shown
    local errorLabel = AceGUI:Create("Label")
    errorLabel:SetFontObject(Theme.fonts.small)
    errorLabel:SetText(" ")
    Add(body, errorLabel, "TOP", variables.noticeMargin)

    local function ShowError(errorKey)
        errorLabel:SetText(Theme.Colorize(private.getLocalisation(errorKey), Theme.colors.danger))
        body:DoLayout()
    end

    local function Close()
        -- widgets can't be released from inside their own callbacks
        C_Timer.After(0, function()
            if dialog == frame then
                frame:Hide()
            end
        end)
    end

    local function Save()
        local name, errorKey = key, nil
        if not name then
            if isBattleTag then
                name, errorKey = private.NormalizeInputBattleTag(nameBox:GetText())
            else
                name, errorKey = private.NormalizeInputName(nameBox:GetText())
            end
            if not name then
                ShowError(errorKey)
                return
            end
        end
        local customName = strtrim(customNameBox:GetText() or "")
        if customName == "" then
            ShowError("ErrorCustomNameMissing")
            return
        end
        if not private.SetName(name, customName) then
            ShowError("ErrorInvalidName")
            return
        end
        private.SetWindowStatus(private.getLocalisation("StatusSaved"):format(private.GetDisplayName(name), customName))
        private.RefreshWindow()
        Close()
    end

    local buttons = AceGUI:Create("CustomNames-Pane")
    buttons:SetLayout(COLUMNS_LAYOUT)
    Add(body, buttons, "BOTTOM")

    local spacer = AceGUI:Create("Label")
    spacer:SetUserData("flex", 1)
    buttons:AddChild(spacer)

    local cancelButton = AceGUI:Create("CustomNames-Button")
    cancelButton:SetText(private.getLocalisation("Cancel"))
    cancelButton:SetCallback("OnClick", Close)
    buttons:AddChild(cancelButton)

    local saveButton = AceGUI:Create("CustomNames-Button")
    saveButton:SetVariant("primary")
    saveButton:SetText(private.getLocalisation("Save"))
    saveButton:SetCallback("OnClick", Save)
    buttons:AddChild(saveButton)

    if nameBox then
        nameBox:SetCallback("OnEnterPressed", function()
            customNameBox:SetFocus()
        end)
    end
    customNameBox:SetCallback("OnEnterPressed", Save)

    body:ResumeLayout()
    body:DoLayout()

    if nameBox then
        nameBox:SetFocus()
    else
        customNameBox:SetFocus()
        customNameBox:HighlightText()
    end
end
