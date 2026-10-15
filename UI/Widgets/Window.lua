local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

-- Top level container: flat panel with a title, a close button and an optional resize grip.
-- Fires OnClose when it gets hidden
local Type, Version = "CustomNames-Window", 1
local variables = {
    width = 400,
    height = 300,
    minWidth = 240,
    minHeight = 160,
    closeSize = 28,
    crossInset = 9,
    crossThickness = 1.5,
    gripSize = 16,
    gripTexture = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up",
    gripAlpha = 0.5,
}

---Remembers where the window is, in the format AceGUI uses for its own windows
local function SaveStatus(self)
    local frame, status = self.frame, self.status or self.localstatus
    status.width = frame:GetWidth()
    status.height = frame:GetHeight()
    status.top = frame:GetTop() or status.top
    status.left = frame:GetLeft() or status.left
end

local function ApplyStatus(self)
    local frame, status = self.frame, self.status or self.localstatus
    self:SetWidth(math.max(status.width or variables.width, self.minWidth))
    self:SetHeight(math.max(status.height or variables.height, self.minHeight))
    frame:ClearAllPoints()
    if status.top and status.left then
        frame:SetPoint("TOP", UIParent, "BOTTOM", 0, status.top)
        frame:SetPoint("LEFT", UIParent, "LEFT", status.left, 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER")
    end
end

local function Frame_OnHide(frame)
    frame:StopMovingOrSizing()
    SaveStatus(frame.obj)
    frame.obj:Fire("OnClose")
end

local function Frame_OnMouseDown()
    AceGUI:ClearFocus()
end

local function Header_OnMouseDown(header)
    header.obj.frame:StartMoving()
    AceGUI:ClearFocus()
end

local function Grip_OnMouseDown(grip)
    grip.obj.frame:StartSizing("BOTTOMRIGHT")
    AceGUI:ClearFocus()
end

local function StopMovingOrSizing(region)
    region.obj.frame:StopMovingOrSizing()
    SaveStatus(region.obj)
end

local function Close_OnClick(button)
    PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
    button.obj:Hide()
end

local function Close_OnEnter(button)
    for _, line in ipairs(button.lines) do
        Theme.SetColor(line, Theme.colors.text)
    end
end

local function Close_OnLeave(button)
    for _, line in ipairs(button.lines) do
        Theme.SetColor(line, Theme.colors.muted)
    end
end

local methods = {
    ["OnAcquire"] = function(self)
        self.frame:SetParent(UIParent)
        self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetTitle()
        self:SetMinSize(variables.minWidth, variables.minHeight)
        self:EnableResize(true)
        ApplyStatus(self)
        self:Show()
    end,

    ["OnRelease"] = function(self)
        Theme.StopTweens(self)
        self.frame:SetAlpha(1)
        self.status = nil
        wipe(self.localstatus)
    end,

    ["Show"] = function(self)
        self.frame:Show()
        Theme.FadeIn(self, self.frame)
    end,

    ["Hide"] = function(self)
        self.frame:Hide()
    end,

    ---@param title string?
    ["SetTitle"] = function(self, title)
        self.title:SetText(title or "")
    end,

    ---@param status table -- size and position are read from and saved into this table
    ["SetStatusTable"] = function(self, status)
        self.status = status
        ApplyStatus(self)
    end,

    ---@param width number
    ---@param height number
    ["SetMinSize"] = function(self, width, height)
        self.minWidth, self.minHeight = width, height
        if self.frame.SetResizeBounds then
            self.frame:SetResizeBounds(width, height)
        else
            self.frame:SetMinResize(width, height)
        end
    end,

    ---@param enabled boolean
    ["EnableResize"] = function(self, enabled)
        self.grip:SetShown(enabled and true or false)
    end,

    ["OnWidthSet"] = function(self, width)
        self.content.width = math.max(width - 2, 0)
    end,

    ["OnHeightSet"] = function(self, height)
        self.content.height = math.max(height - Theme.sizes.header - 1, 0)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:SetToplevel(true)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetScript("OnHide", Frame_OnHide)
    frame:SetScript("OnMouseDown", Frame_OnMouseDown)
    Theme.CreateBackground(frame, Theme.colors.background)
    Theme.CreateBorder(frame, Theme.colors.lineStrong)

    -- the header is what the window is dragged with
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(Theme.sizes.header - 1)
    header:EnableMouse(true)
    header:SetScript("OnMouseDown", Header_OnMouseDown)
    header:SetScript("OnMouseUp", StopMovingOrSizing)
    Theme.CreateBackground(header, Theme.colors.header)

    local title = Theme.CreateText(header, "title")
    title:SetPoint("LEFT", Theme.sizes.padding, 0)
    title:SetPoint("RIGHT", -variables.closeSize - Theme.sizes.gap, 0)

    -- there is no close icon that exists on every game version, so the cross is drawn
    local close = CreateFrame("Button", nil, header)
    close:SetSize(variables.closeSize, variables.closeSize)
    close:SetPoint("RIGHT", -(Theme.sizes.header - variables.closeSize) / 2, 0)
    close:SetScript("OnClick", Close_OnClick)
    close:SetScript("OnEnter", Close_OnEnter)
    close:SetScript("OnLeave", Close_OnLeave)
    close.lines = {}
    for index, points in ipairs({ { "TOPLEFT", "BOTTOMRIGHT" }, { "BOTTOMLEFT", "TOPRIGHT" } }) do
        local inset = variables.crossInset
        local line = close:CreateLine(nil, "ARTWORK")
        line:SetThickness(variables.crossThickness)
        line:SetStartPoint(points[1], close, inset, index == 1 and -inset or inset)
        line:SetEndPoint(points[2], close, -inset, index == 1 and inset or -inset)
        Theme.SetColor(line, Theme.colors.muted)
        close.lines[index] = line
    end

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(variables.gripSize, variables.gripSize)
    grip:SetPoint("BOTTOMRIGHT", -1, 1)
    grip:SetFrameLevel(frame:GetFrameLevel() + 10)
    grip:SetScript("OnMouseDown", Grip_OnMouseDown)
    grip:SetScript("OnMouseUp", StopMovingOrSizing)
    local gripTexture = grip:CreateTexture(nil, "OVERLAY")
    gripTexture:SetAllPoints()
    gripTexture:SetTexture(variables.gripTexture)
    gripTexture:SetDesaturated(true)
    gripTexture:SetAlpha(variables.gripAlpha)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 1, -Theme.sizes.header)
    content:SetPoint("BOTTOMRIGHT", -1, 1)

    local widget = {
        frame = frame,
        content = content,
        title = title,
        grip = grip,
        localstatus = {},
        minWidth = variables.minWidth,
        minHeight = variables.minHeight,
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    header.obj, close.obj, grip.obj = widget, widget, widget

    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
