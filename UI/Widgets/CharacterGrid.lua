local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

-- Shows characters as cells with their class icon and their name in the color of their class.
-- The cells are placed in as many columns as fit and can be grouped below headings.
-- The widget is as tall as its content, put it into a scroll container.
-- A group is { title = string?, items = { { text = string, classFile = string?, tooltip = string? }, ... } }
local Type, Version = "CustomNames-CharacterGrid", 1
local variables = {
    minCellWidth = 150,
    cellHeight = 24,
    cellGap = 4,
    cellPadding = 4,
    iconSize = 16,
    iconGap = 7,
    unknownSize = 4, -- size of the dot that stands in for the icon of an unknown class
    headingHeight = 24,
    groupGap = 12,
}

local function Cell_OnEnter(cell)
    cell.hover:Show()
    if cell.tooltip then
        GameTooltip:SetOwner(cell, "ANCHOR_TOP")
        GameTooltip:SetText(cell.tooltip)
        GameTooltip:Show()
    end
end

local function Cell_OnLeave(cell)
    cell.hover:Hide()
    GameTooltip:Hide()
end

local function CreateCell(self)
    local cell = CreateFrame("Frame", nil, self.frame)
    cell:SetHeight(variables.cellHeight)
    cell:EnableMouse(true)
    cell:SetScript("OnEnter", Cell_OnEnter)
    cell:SetScript("OnLeave", Cell_OnLeave)

    cell.hover = Theme.CreateBackground(cell, Theme.colors.hover)
    cell.hover:Hide()

    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetSize(variables.iconSize, variables.iconSize)
    cell.icon:SetPoint("LEFT", variables.cellPadding, 0)

    cell.unknown = cell:CreateTexture(nil, "ARTWORK")
    cell.unknown:SetSize(variables.unknownSize, variables.unknownSize)
    cell.unknown:SetPoint("CENTER", cell.icon, "CENTER")
    Theme.SetColor(cell.unknown, Theme.colors.lineStrong)

    cell.text = Theme.CreateText(cell, "body")
    cell.text:SetPoint("LEFT", cell.icon, "RIGHT", variables.iconGap, 0)
    cell.text:SetPoint("RIGHT", -variables.cellPadding, 0)
    return cell
end

---@param cell Frame
---@param item table
local function UpdateCell(cell, item)
    local classColor = Theme.GetClassColor(item.classFile)
    cell.unknown:SetShown(not Theme.SetClassIcon(cell.icon, item.classFile))
    cell.text:SetText(item.text)
    Theme.SetTextColor(cell.text, classColor or Theme.colors.muted)
    cell.tooltip = item.tooltip and Theme.Colorize(item.tooltip, classColor or Theme.colors.text) or nil
end

---Places headings and cells for the current width and makes the widget as tall as they need
local function Layout(self)
    local width = self.gridWidth
    local gap = variables.cellGap
    local columns = math.max(math.floor((width + gap) / (variables.minCellWidth + gap)), 1)
    local cellWidth = math.max((width - gap * (columns - 1)) / columns, 1)

    local usedCells, usedHeadings, y = 0, 0, 0
    for groupIndex, group in ipairs(self.groups) do
        if groupIndex > 1 then
            y = y + variables.groupGap
        end
        if group.title then
            usedHeadings = usedHeadings + 1
            local heading = self.headings[usedHeadings]
            if not heading then
                heading = Theme.CreateText(self.frame, "body")
                heading:SetHeight(variables.headingHeight)
                self.headings[usedHeadings] = heading
            end
            local count = Theme.Colorize(tostring(#group.items), Theme.colors.muted)
            heading:SetText(group.title .. "  " .. count)
            heading:ClearAllPoints()
            heading:SetPoint("TOPLEFT", self.frame, "TOPLEFT", variables.cellPadding, -y)
            heading:SetPoint("RIGHT", self.frame, "RIGHT")
            heading:Show()
            y = y + variables.headingHeight
        end
        for itemIndex, item in ipairs(group.items) do
            usedCells = usedCells + 1
            local cell = self.cells[usedCells]
            if not cell then
                cell = CreateCell(self)
                self.cells[usedCells] = cell
            end
            UpdateCell(cell, item)
            local column = (itemIndex - 1) % columns
            local row = math.floor((itemIndex - 1) / columns)
            cell:SetWidth(cellWidth)
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", self.frame, "TOPLEFT", column * (cellWidth + gap), -(y + row * variables.cellHeight))
            cell:Show()
        end
        y = y + math.ceil(#group.items / columns) * variables.cellHeight
    end

    for index = usedCells + 1, #self.cells do
        self.cells[index]:Hide()
    end
    for index = usedHeadings + 1, #self.headings do
        self.headings[index]:Hide()
    end
    self:SetHeight(math.max(y, 1))
end

local methods = {
    ["OnAcquire"] = function(self)
        self.groups = {}
        self:SetWidth(300)
    end,

    ["OnRelease"] = function(self)
        self.groups = {}
    end,

    ---@param groups table -- list of groups, see the top of this file
    ["SetGroups"] = function(self, groups)
        self.groups = groups
        Layout(self)
    end,

    ["OnWidthSet"] = function(self, width)
        self.gridWidth = width
        Layout(self)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local widget = {
        frame = frame,
        cells = {},
        headings = {},
        groups = {},
        gridWidth = 0,
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
