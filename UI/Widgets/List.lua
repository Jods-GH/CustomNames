local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

-- Selectable list that only creates as many rows as fit into its view, no matter how many items it holds.
-- An item is { key = any, title = string, subtitle = string?, value = string?, classFile = string?,
-- titleColor = table?, valueColor = table? }.
-- Fires OnSelect(key) when the user clicks a row
local Type, Version = "CustomNames-List", 1
local variables = {
    paddingX = 14,
    iconGap = 8,
    textGap = 10,
    valueShare = 0.4, -- part of the row width that is reserved for the value
    lineOffset = 2, -- distance of title and subtitle from the middle of the row
    selectionBarWidth = 3,
    emptyTextOffset = 20, -- slightly above the middle of the list
}

local function Row_OnClick(row)
    local self = row.obj
    if not row.item then return end
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    AceGUI:ClearFocus()
    self:SetSelected(row.item.key)
    self:Fire("OnSelect", row.item.key)
end

local function Row_OnEnter(row)
    row.hover:Show()
end

local function Row_OnLeave(row)
    row.hover:Hide()
end

---The levels decide what is drawn on top: the selection is below the rows, the scrollbar above them
local function UpdateFrameLevels(self)
    local level = self.viewport:GetFrameLevel()
    self.selection:SetFrameLevel(level + 1)
    for _, row in ipairs(self.rows) do
        row:SetFrameLevel(level + 2)
    end
    self.scroller.bar:SetFrameLevel(level + 5)
end

local function CreateRow(self)
    local row = CreateFrame("Button", nil, self.viewport)
    row:SetHeight(Theme.sizes.row)
    row:SetFrameLevel(self.viewport:GetFrameLevel() + 2)
    row:SetScript("OnClick", Row_OnClick)
    row:SetScript("OnEnter", Row_OnEnter)
    row:SetScript("OnLeave", Row_OnLeave)
    row.obj = self

    row.hover = Theme.CreateBackground(row, Theme.colors.hover)
    row.hover:Hide()
    Theme.CreateEdge(row, "BOTTOM")

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(Theme.sizes.classIcon, Theme.sizes.classIcon)
    row.icon:SetPoint("LEFT", variables.paddingX, 0)

    row.title = Theme.CreateText(row, "body")
    row.subtitle = Theme.CreateText(row, "small", Theme.colors.muted)
    row.value = Theme.CreateText(row, "body")
    row.value:SetJustifyH("RIGHT")
    row.value:SetPoint("RIGHT", -variables.paddingX, 0)
    return row
end

---@param row Button
---@param item table
---@param width number -- width of the row
local function UpdateRow(row, item, width)
    local left = variables.paddingX
    if Theme.SetClassIcon(row.icon, item.classFile) then
        left = left + Theme.sizes.classIcon + variables.iconGap
    end

    local valueWidth = math.floor(width * variables.valueShare)
    row.value:SetWidth(valueWidth)
    row.value:SetText(item.value or "")
    Theme.SetTextColor(row.value, item.valueColor or Theme.colors.text)

    local textWidth = math.max(width - left - valueWidth - variables.paddingX - variables.textGap, 1)
    row.title:ClearAllPoints()
    row.title:SetWidth(textWidth)
    row.title:SetText(item.title or "")
    Theme.SetTextColor(row.title, item.titleColor or Theme.colors.text)
    row.subtitle:ClearAllPoints()
    if item.subtitle and item.subtitle ~= "" then
        row.title:SetPoint("BOTTOMLEFT", row, "LEFT", left, variables.lineOffset)
        row.subtitle:SetPoint("TOPLEFT", row, "LEFT", left, -variables.lineOffset)
        row.subtitle:SetWidth(textWidth)
        row.subtitle:SetText(item.subtitle)
        row.subtitle:Show()
    else
        row.title:SetPoint("LEFT", row, "LEFT", left, 0)
        row.subtitle:Hide()
    end
end

---Places the rows that are in view, called whenever the list scrolls or changes
local function Render(self)
    local viewport, rowHeight = self.viewport, Theme.sizes.row
    local offset = self.scroller.offset
    local first = math.floor(offset / rowHeight) + 1
    local visible = self.viewHeight > 0 and math.ceil(self.viewHeight / rowHeight) + 1 or 0

    for slot = 1, math.max(visible, #self.rows) do
        local index = first + slot - 1
        local item = slot <= visible and self.items[index] or nil
        local row = self.rows[slot]
        if item then
            if not row then
                row = CreateRow(self)
                self.rows[slot] = row
            end
            if row.item ~= item or row.width ~= self.viewWidth then
                UpdateRow(row, item, self.viewWidth)
                row.item, row.width = item, self.viewWidth
            end
            local y = offset - (index - 1) * rowHeight
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, y)
            row:SetPoint("TOPRIGHT", viewport, "TOPRIGHT", 0, y)
            row:Show()
        elseif row then
            row.item = nil
            row:Hide()
        end
    end

    local selection = self.selection
    if self.selectionPosition then
        local y = offset - (self.selectionPosition - 1) * rowHeight
        selection:ClearAllPoints()
        selection:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, y)
        selection:SetPoint("TOPRIGHT", viewport, "TOPRIGHT", 0, y)
        selection:Show()
    else
        selection:Hide()
    end

    self.emptyText:SetShown(#self.items == 0)
end

local function UpdateRange(self)
    self.scroller:SetRange(self.viewHeight, #self.items * Theme.sizes.row)
end

local methods = {
    ["OnAcquire"] = function(self)
        self.items, self.indexByKey = {}, {}
        self.selectedKey, self.selectionPosition = nil, nil
        self:SetEmptyText()
        self:SetWidth(200)
        self:SetHeight(200)
        self.scroller:Reset()
    end,

    ["OnRelease"] = function(self)
        Theme.StopTweens(self)
        Theme.StopTweens(self.scroller)
        self.items, self.indexByKey = {}, {}
        for _, row in ipairs(self.rows) do
            row.item = nil
            row:Hide()
        end
    end,

    -- AceGUI moves the frame to its new parent in here, which is when the frame levels change
    ["SetParent"] = function(self, parent)
        AceGUI.WidgetBase.SetParent(self, parent)
        UpdateFrameLevels(self)
    end,

    ---@param items table -- list of items, see the top of this file. The selection is kept if its key is still there
    ["SetItems"] = function(self, items)
        self.items = items
        self.indexByKey = {}
        for index, item in ipairs(items) do
            self.indexByKey[item.key] = index
        end
        Theme.StopTweens(self)
        self.selectionPosition = self.indexByKey[self.selectedKey]
        UpdateRange(self)
    end,

    ---@param key any? -- nil removes the selection
    ---@param instant boolean? -- don't glide to the new row
    ["SetSelected"] = function(self, key, instant)
        self.selectedKey = key
        local index = key ~= nil and self.indexByKey[key] or nil
        local from = self.selectionPosition
        if not index or not from or instant then
            Theme.StopTweens(self)
            self.selectionPosition = index
            Render(self)
            return
        end
        Theme.Tween(self, "selection", from, index, Theme.durations.glide, function(position)
            self.selectionPosition = position
            Render(self)
        end)
    end,

    ---@return any? key
    ["GetSelected"] = function(self)
        return self.selectedKey
    end,

    ---@param key any
    ---@return boolean -- the list holds an item with that key
    ["HasKey"] = function(self, key)
        return self.indexByKey[key] ~= nil
    end,

    ---Scrolls just far enough to bring an item into view
    ---@param key any
    ["ScrollToKey"] = function(self, key)
        local index = self.indexByKey[key]
        if not index then return end
        local rowHeight = Theme.sizes.row
        local top, bottom = (index - 1) * rowHeight, index * rowHeight
        if top < self.scroller.target then
            self.scroller:SetOffset(top)
        elseif bottom > self.scroller.target + self.viewHeight then
            self.scroller:SetOffset(bottom - self.viewHeight)
        end
    end,

    ---@param text string? -- shown while the list has no items
    ["SetEmptyText"] = function(self, text)
        self.emptyText:SetText(text or "")
    end,

    ["OnWidthSet"] = function(self, width)
        self.viewWidth = math.max(width - Theme.sizes.scrollBar, 0)
        self.emptyText:SetWidth(math.max(self.viewWidth - variables.paddingX * 2, 1))
        Render(self)
    end,

    ["OnHeightSet"] = function(self, height)
        self.viewHeight = height
        UpdateRange(self)
    end,
}

local function Frame_OnMouseWheel(frame, delta)
    frame.obj.scroller:ScrollBy(-delta * Theme.sizes.scrollStep)
end

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", Frame_OnMouseWheel)

    local viewport = CreateFrame("Frame", nil, frame)
    viewport:SetPoint("TOPLEFT")
    viewport:SetPoint("BOTTOMRIGHT", -Theme.sizes.scrollBar, 0)
    viewport:SetClipsChildren(true)

    -- one highlight for the whole list that glides to the selected row
    local selection = CreateFrame("Frame", nil, viewport)
    selection:SetHeight(Theme.sizes.row)
    selection:Hide()
    Theme.CreateBackground(selection, Theme.colors.accentSoft)
    local selectionBar = selection:CreateTexture(nil, "ARTWORK")
    selectionBar:SetPoint("TOPLEFT")
    selectionBar:SetPoint("BOTTOMLEFT")
    selectionBar:SetWidth(variables.selectionBarWidth)
    Theme.SetColor(selectionBar, Theme.colors.accent)

    local emptyText = Theme.CreateText(frame, "body", Theme.colors.muted)
    emptyText:SetPoint("CENTER", viewport, "CENTER", 0, variables.emptyTextOffset)
    emptyText:SetJustifyH("CENTER")
    emptyText:SetWordWrap(true)

    local widget = {
        frame = frame,
        viewport = viewport,
        selection = selection,
        emptyText = emptyText,
        rows = {},
        items = {},
        indexByKey = {},
        viewWidth = 0,
        viewHeight = 0,
        type = Type,
    }
    widget.scroller = private.CreateScroller(frame, function()
        Render(widget)
    end)
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
