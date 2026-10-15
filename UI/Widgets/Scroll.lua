local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

local variables = {
    minThumbHeight = 24,
}

-- A scroller keeps the scroll position of something that is taller than its view and owns the thin scrollbar for it.
-- It is shared by the scroll container below, the list and the multi line edit box

---@class CustomNamesScroller
local ScrollerMixin = {}

---@return number -- the largest offset that still fills the view
function ScrollerMixin:GetMaxOffset()
    return math.max(self.contentHeight - self.viewHeight, 0)
end

---Moves the thumb and tells the owner to move its content
function ScrollerMixin:Refresh()
    self.apply(self.offset)

    local maxOffset = self:GetMaxOffset()
    local barHeight = self.bar:GetHeight()
    if maxOffset <= 0 or barHeight <= 0 then
        self.bar:Hide()
        return
    end
    local thumbHeight = math.max(barHeight * self.viewHeight / self.contentHeight, variables.minThumbHeight)
    thumbHeight = math.min(thumbHeight, barHeight)
    self.thumb:SetHeight(thumbHeight)
    self.thumb:SetPoint("TOP", self.bar, "TOP", 0, -(barHeight - thumbHeight) * self.offset / maxOffset)
    self.bar:Show()
end

---@param offset number -- distance in pixels the content is scrolled down
---@param instant boolean? -- jump instead of gliding there
function ScrollerMixin:SetOffset(offset, instant)
    offset = math.max(math.min(offset, self:GetMaxOffset()), 0)
    self.target = offset
    Theme.Tween(self, "scroll", self.offset, offset, instant and 0 or Theme.durations.scroll, function(value)
        self.offset = value
        self:Refresh()
    end)
end

---@param delta number -- pixels, positive scrolls down
function ScrollerMixin:ScrollBy(delta)
    self:SetOffset(self.target + delta)
end

---@param viewHeight number -- height of the visible part
---@param contentHeight number -- height of everything that can be scrolled through
function ScrollerMixin:SetRange(viewHeight, contentHeight)
    self.viewHeight, self.contentHeight = viewHeight, contentHeight
    if self.target > self:GetMaxOffset() then
        self:SetOffset(self:GetMaxOffset(), true)
    else
        self:Refresh()
    end
end

---Back to the top without any motion
function ScrollerMixin:Reset()
    Theme.StopTweens(self)
    self.offset, self.target = 0, 0
    self:Refresh()
end

local function GetCursorY(bar)
    local _, y = GetCursorPosition()
    return y / bar:GetEffectiveScale()
end

local function Bar_OnUpdate(bar)
    local scroller = bar.scroller
    local track = bar:GetHeight() - scroller.thumb:GetHeight()
    if track <= 0 then return end
    local moved = scroller.dragCursorY - GetCursorY(bar)
    scroller:SetOffset(scroller.dragOffset + moved / track * scroller:GetMaxOffset(), true)
end

local function Bar_OnMouseDown(bar)
    local scroller = bar.scroller
    if scroller.thumb:IsMouseOver() then
        scroller.dragCursorY = GetCursorY(bar)
        scroller.dragOffset = scroller.offset
        bar:SetScript("OnUpdate", Bar_OnUpdate)
    else
        -- a click next to the thumb moves by one page
        local direction = GetCursorY(bar) > (select(2, scroller.thumb:GetCenter()) or 0) and -1 or 1
        scroller:ScrollBy(direction * scroller.viewHeight)
    end
end

local function Bar_OnMouseUp(bar)
    bar:SetScript("OnUpdate", nil)
end

local function Bar_OnEnter(bar)
    Theme.SetColor(bar.scroller.thumb, Theme.colors.muted)
end

local function Bar_OnLeave(bar)
    Theme.SetColor(bar.scroller.thumb, Theme.colors.lineStrong)
end

---@param parent Frame -- the scrollbar is placed along its right edge
---@param apply fun(offset: number) -- called whenever the content has to be moved
---@return CustomNamesScroller
private.CreateScroller = function(parent, apply)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetPoint("TOPRIGHT")
    bar:SetPoint("BOTTOMRIGHT")
    bar:SetWidth(Theme.sizes.scrollBar)
    bar:EnableMouse(true)
    bar:SetScript("OnMouseDown", Bar_OnMouseDown)
    bar:SetScript("OnMouseUp", Bar_OnMouseUp)
    bar:SetScript("OnHide", Bar_OnMouseUp)
    bar:SetScript("OnEnter", Bar_OnEnter)
    bar:SetScript("OnLeave", Bar_OnLeave)
    bar:Hide()

    local thumb = bar:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(Theme.sizes.scrollThumb)
    Theme.SetColor(thumb, Theme.colors.lineStrong)

    local scroller = {
        bar = bar,
        thumb = thumb,
        apply = apply,
        offset = 0,
        target = 0,
        viewHeight = 0,
        contentHeight = 0,
    }
    for method, func in pairs(ScrollerMixin) do
        scroller[method] = func
    end
    bar.scroller = scroller
    return scroller
end

-- Container that scrolls its children if they are taller than it is
local Type, Version = "CustomNames-Scroll", 1

local function Frame_OnMouseWheel(frame, delta)
    frame.obj.scroller:ScrollBy(-delta * Theme.sizes.scrollStep)
end

local methods = {
    ["OnAcquire"] = function(self)
        self.contentHeight = 0
        self:SetWidth(300)
        self:SetHeight(200)
        self.scroller:Reset()
    end,

    ["OnRelease"] = function(self)
        Theme.StopTweens(self.scroller)
    end,

    ["OnWidthSet"] = function(self, width)
        self.content.width = math.max(width - Theme.sizes.scrollBar, 0)
    end,

    ["OnHeightSet"] = function(self, height)
        self.scroller:SetRange(height, self.contentHeight)
    end,

    ["LayoutFinished"] = function(self, _, height)
        self.contentHeight = height or 0
        self.content:SetHeight(math.max(self.contentHeight, 1))
        self.scroller:SetRange(self.frame.height or self.frame:GetHeight() or 0, self.contentHeight)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", Frame_OnMouseWheel)

    local viewport = CreateFrame("Frame", nil, frame)
    viewport:SetPoint("TOPLEFT")
    viewport:SetPoint("BOTTOMRIGHT", -Theme.sizes.scrollBar, 0)
    viewport:SetClipsChildren(true)

    local content = CreateFrame("Frame", nil, viewport)
    content:SetHeight(1)

    local widget = {
        frame = frame,
        content = content,
        contentHeight = 0,
        type = Type,
    }
    widget.scroller = private.CreateScroller(frame, function(offset)
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, offset)
        content:SetPoint("TOPRIGHT", viewport, "TOPRIGHT", 0, offset)
    end)
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
