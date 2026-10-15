local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

-- Flat button. Fires OnClick
local Type, Version = "CustomNames-Button", 1
local VARIANT_PRIMARY = "primary" -- filled with the accent colour, for the main action
local VARIANT_GHOST = "ghost" -- outlined, for everything else
local VARIANT_DANGER = "danger" -- text only, for actions that remove something
local VARIANT_LINK = "link" -- text only, for navigation
local variables = {
    padding = 14,
    linkPadding = 2,
    primaryHover = { 1, 1, 1, 0.14 },
}

local function UpdateVisual(self)
    local variant, colors = self.variant, Theme.colors
    local hovered = self.hovered and not self.disabled
    local textColor, backgroundColor, borderColor

    if variant == VARIANT_PRIMARY then
        textColor = colors.onAccent
        backgroundColor = self.disabled and colors.line or colors.accent
    elseif variant == VARIANT_DANGER then
        textColor = colors.danger
        backgroundColor = hovered and colors.dangerSoft or nil
    elseif variant == VARIANT_LINK then
        textColor = hovered and colors.text or colors.accent
    else
        textColor = colors.text
        backgroundColor = hovered and colors.hover or nil
        borderColor = hovered and colors.lineStrong or colors.line
    end
    if self.disabled then
        textColor = colors.disabled
    end

    Theme.SetTextColor(self.text, textColor)
    self.background:SetShown(backgroundColor ~= nil)
    if backgroundColor then
        Theme.SetColor(self.background, backgroundColor)
    end
    self.overlay:SetShown(hovered and variant == VARIANT_PRIMARY)
    for _, texture in ipairs(self.border) do
        texture:SetShown(borderColor ~= nil)
    end
    if borderColor then
        Theme.SetBorderColor(self.border, borderColor)
    end
end

local function UpdateWidth(self)
    if not self.autoWidth then return end
    local padding = self.variant == VARIANT_LINK and variables.linkPadding or variables.padding
    self:SetWidth(math.ceil(self.text:GetStringWidth()) + padding * 2)
end

local function Button_OnClick(frame)
    PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
    AceGUI:ClearFocus()
    frame.obj:Fire("OnClick")
end

local function Button_OnEnter(frame)
    frame.obj.hovered = true
    UpdateVisual(frame.obj)
end

local function Button_OnLeave(frame)
    frame.obj.hovered = false
    UpdateVisual(frame.obj)
end

local methods = {
    ["OnAcquire"] = function(self)
        self.variant, self.autoWidth, self.disabled, self.hovered = VARIANT_GHOST, true, false, false
        self.frame:Enable()
        self:SetHeight(Theme.sizes.control)
        self:SetText()
    end,

    ---@param text string?
    ["SetText"] = function(self, text)
        self.text:SetText(text or "")
        UpdateWidth(self)
        UpdateVisual(self)
    end,

    ---@param variant "primary"|"ghost"|"danger"|"link"
    ["SetVariant"] = function(self, variant)
        self.variant = variant
        UpdateWidth(self)
        UpdateVisual(self)
    end,

    ---@param autoWidth boolean -- size the button to its text (default), otherwise the width has to be set
    ["SetAutoWidth"] = function(self, autoWidth)
        self.autoWidth = autoWidth
        UpdateWidth(self)
    end,

    ---@param disabled boolean
    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled and true or false
        self.frame:SetEnabled(not self.disabled)
        UpdateVisual(self)
    end,
}

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:Hide()
    frame:SetScript("OnClick", Button_OnClick)
    frame:SetScript("OnEnter", Button_OnEnter)
    frame:SetScript("OnLeave", Button_OnLeave)

    local text = Theme.CreateText(frame, "body")
    text:SetPoint("CENTER")

    local widget = {
        frame = frame,
        text = text,
        background = Theme.CreateBackground(frame, Theme.colors.accent),
        overlay = Theme.CreateBackground(frame, variables.primaryHover, "BORDER"),
        border = Theme.CreateBorder(frame),
        variant = VARIANT_GHOST,
        autoWidth = true,
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
