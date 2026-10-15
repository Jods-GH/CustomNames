local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

-- Plain container. Can have a padding, a background and lines along its edges
local Type, Version = "CustomNames-Pane", 1

local function UpdateContent(self)
    local content = self.content
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", self.paddingX, -self.paddingY)
    content:SetPoint("BOTTOMRIGHT", -self.paddingX, self.paddingY)
    content.width = math.max(self.outerWidth - self.paddingX * 2, 0)
    content.height = math.max(self.outerHeight - self.paddingY * 2, 0)
end

local methods = {
    ["OnAcquire"] = function(self)
        self.paddingX, self.paddingY = 0, 0
        self:SetBackgroundColor(nil)
        self:SetLines()
        self:SetWidth(300)
        self:SetHeight(100)
    end,

    ---@param x number -- space left and right of the children
    ---@param y number? -- space above and below the children, same as x by default
    ["SetPadding"] = function(self, x, y)
        self.paddingX, self.paddingY = x, y or x
        UpdateContent(self)
    end,

    ---@param color table? -- one of Theme.colors, nil for no background
    ["SetBackgroundColor"] = function(self, color)
        if color then
            Theme.SetColor(self.background, color)
        end
        self.background:SetShown(color ~= nil)
    end,

    ---@param ... string -- edges that get a line: TOP, BOTTOM, LEFT, RIGHT
    ["SetLines"] = function(self, ...)
        for _, texture in pairs(self.edges) do
            texture:Hide()
        end
        for i = 1, select("#", ...) do
            self.edges[select(i, ...)]:Show()
        end
    end,

    ["OnWidthSet"] = function(self, width)
        self.outerWidth = width
        UpdateContent(self)
    end,

    ["OnHeightSet"] = function(self, height)
        self.outerHeight = height
        UpdateContent(self)
    end,

    ["LayoutFinished"] = function(self, _, height)
        if self.noAutoHeight then return end
        self:SetHeight((height or 0) + self.paddingY * 2)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local content = CreateFrame("Frame", nil, frame)

    local widget = {
        frame = frame,
        content = content,
        background = Theme.CreateBackground(frame, Theme.colors.background),
        edges = {
            TOP = Theme.CreateEdge(frame, "TOP"),
            BOTTOM = Theme.CreateEdge(frame, "BOTTOM"),
            LEFT = Theme.CreateEdge(frame, "LEFT"),
            RIGHT = Theme.CreateEdge(frame, "RIGHT"),
        },
        paddingX = 0,
        paddingY = 0,
        outerWidth = 0,
        outerHeight = 0,
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
