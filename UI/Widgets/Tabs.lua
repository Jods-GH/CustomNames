local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

-- Text tabs with a line that slides below the selected one. Fires OnTabSelected(value)
local Type, Version = "CustomNames-Tabs", 1
local variables = {
    height = 30,
    gap = 22,
    underlineHeight = 2,
}

local function UpdateColors(self)
    for _, tab in ipairs(self.tabs) do
        local active = tab.value == self.selected or tab.hovered
        Theme.SetTextColor(tab.text, active and Theme.colors.text or Theme.colors.muted)
    end
end

local function MoveUnderline(self, instant)
    local target
    for _, tab in ipairs(self.tabs) do
        if tab:IsShown() and tab.value == self.selected then
            target = tab
        end
    end
    local underline = self.underline
    if not target then
        underline:Hide()
        return
    end
    local fromX, fromWidth = self.underlineX, self.underlineWidth
    local toX, toWidth = target.offset, target:GetWidth()
    underline:Show()
    if instant or not fromX then
        fromX, fromWidth = toX, toWidth
    end
    Theme.Tween(self, "underline", 0, 1, instant and 0 or Theme.durations.glide, function(progress)
        self.underlineX = fromX + (toX - fromX) * progress
        self.underlineWidth = fromWidth + (toWidth - fromWidth) * progress
        underline:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", self.underlineX, 0)
        underline:SetWidth(math.max(self.underlineWidth, 1))
    end)
end

local function Tab_OnClick(tab)
    local self = tab.obj
    if tab.value == self.selected then return end
    PlaySound(841) -- SOUNDKIT.IG_CHARACTER_INFO_TAB
    AceGUI:ClearFocus()
    self:SetSelected(tab.value)
    self:Fire("OnTabSelected", tab.value)
end

local function Tab_OnEnter(tab)
    tab.hovered = true
    UpdateColors(tab.obj)
end

local function Tab_OnLeave(tab)
    tab.hovered = false
    UpdateColors(tab.obj)
end

local function CreateTab(self)
    local tab = CreateFrame("Button", nil, self.frame)
    tab:SetScript("OnClick", Tab_OnClick)
    tab:SetScript("OnEnter", Tab_OnEnter)
    tab:SetScript("OnLeave", Tab_OnLeave)
    tab.obj = self
    tab.text = Theme.CreateText(tab, "heading")
    tab.text:SetPoint("CENTER")
    return tab
end

local methods = {
    ["OnAcquire"] = function(self)
        self.selected, self.underlineX, self.underlineWidth = nil, nil, nil
        self:SetHeight(variables.height)
        self:SetTabs({})
    end,

    ["OnRelease"] = function(self)
        Theme.StopTweens(self)
    end,

    ---@param tabs table -- list of { value = any, text = string }
    ["SetTabs"] = function(self, tabs)
        local offset = 0
        for index, info in ipairs(tabs) do
            local tab = self.tabs[index]
            if not tab then
                tab = CreateTab(self)
                self.tabs[index] = tab
            end
            tab.value, tab.hovered = info.value, false
            tab.text:SetText(info.text)
            tab.offset = offset
            tab:SetSize(math.ceil(tab.text:GetStringWidth()), variables.height)
            tab:ClearAllPoints()
            tab:SetPoint("LEFT", self.frame, "LEFT", offset, 0)
            tab:Show()
            offset = offset + tab:GetWidth() + variables.gap
        end
        for index = #tabs + 1, #self.tabs do
            self.tabs[index]:Hide()
        end
        self:SetWidth(math.max(offset - variables.gap, 1))
        UpdateColors(self)
        MoveUnderline(self, true)
    end,

    ---@param value any
    ---@param instant boolean? -- don't slide the line to the tab
    ["SetSelected"] = function(self, value, instant)
        if value == self.selected and self.underlineX then return end
        self.selected = value
        UpdateColors(self)
        MoveUnderline(self, instant)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local underline = frame:CreateTexture(nil, "ARTWORK")
    underline:SetHeight(variables.underlineHeight)
    Theme.SetColor(underline, Theme.colors.accent)
    underline:Hide()

    local widget = {
        frame = frame,
        underline = underline,
        tabs = {},
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
