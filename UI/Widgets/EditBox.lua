local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

local variables = {
    insetX = 8,
    insetY = 6,
}

---Creates the flat box both kinds of edit boxes are drawn in, with an optional caption above it
---@param frame Frame
---@return Frame field
---@return table border
---@return FontString caption
local function CreateField(frame)
    local caption = Theme.CreateText(frame, "caption", Theme.colors.muted)
    caption:SetPoint("TOPLEFT")
    caption:SetPoint("TOPRIGHT")
    caption:Hide()

    local field = CreateFrame("Frame", nil, frame)
    field:SetPoint("TOPLEFT")
    field:SetPoint("BOTTOMRIGHT")
    field:EnableMouse(true)
    Theme.CreateBackground(field, Theme.colors.field)
    return field, Theme.CreateBorder(field), caption
end

---@param self table -- the widget
---@param text string? -- shown in capitals above the field, nil or empty for no caption
---@return number captionHeight
local function SetCaption(self, text)
    local hasCaption = text ~= nil and text ~= ""
    self.caption:SetText(hasCaption and text:upper() or "")
    self.caption:SetShown(hasCaption)
    local captionHeight = hasCaption and Theme.sizes.caption or 0
    self.field:SetPoint("TOPLEFT", 0, -captionHeight)
    return captionHeight
end

local function Field_OnMouseDown(field)
    field.obj.editbox:SetFocus()
end

local function EditBox_OnEditFocusGained(editbox)
    AceGUI:SetFocus(editbox.obj)
    Theme.SetBorderColor(editbox.obj.border, Theme.colors.accent)
end

local function EditBox_OnEditFocusLost(editbox)
    editbox:HighlightText(0, 0)
    Theme.SetBorderColor(editbox.obj.border, Theme.colors.line)
end

local function EditBox_OnEscapePressed()
    AceGUI:ClearFocus()
end

local function EditBox_OnTextChanged(editbox)
    local self = editbox.obj
    local text = editbox:GetText()
    self.placeholder:SetShown(text == "")
    if text ~= self.lastText then
        self.lastText = text
        self:Fire("OnTextChanged", text)
    end
end

-- methods both kinds of edit boxes share
local sharedMethods = {
    ---@param text string?
    ["SetText"] = function(self, text)
        -- setting the text is not something the user did, so it doesn't fire OnTextChanged
        self.lastText = text or ""
        self.editbox:SetText(self.lastText)
        self.editbox:SetCursorPosition(0)
        self.placeholder:SetShown(self.lastText == "")
    end,

    ---@return string
    ["GetText"] = function(self)
        return self.editbox:GetText()
    end,

    ---@param text string? -- shown while the box is empty
    ["SetPlaceholder"] = function(self, text)
        self.placeholder:SetText(text or "")
    end,

    ["SetFocus"] = function(self)
        self.editbox:SetFocus()
    end,

    ["ClearFocus"] = function(self)
        self.editbox:ClearFocus()
    end,

    ["HighlightText"] = function(self, from, to)
        self.editbox:HighlightText(from, to)
    end,

    ["OnRelease"] = function(self)
        self.editbox:ClearFocus()
        if self.scroller then
            Theme.StopTweens(self.scroller)
        end
    end,
}

-- Single line edit box. Fires OnTextChanged(text) when the user edits it and OnEnterPressed(text)
do
    local Type, Version = "CustomNames-EditBox", 1

    local function EditBox_OnEnterPressed(editbox)
        editbox.obj:Fire("OnEnterPressed", editbox:GetText())
    end

    local methods = {
        ["OnAcquire"] = function(self)
            self:SetWidth(200)
            self:SetLabel()
            self:SetPlaceholder()
            self:SetText()
            self:SetMaxLetters(0)
        end,

        ---@param text string? -- caption above the box
        ["SetLabel"] = function(self, text)
            self:SetHeight(Theme.sizes.control + SetCaption(self, text))
        end,

        ---@param count number -- 0 for no limit
        ["SetMaxLetters"] = function(self, count)
            self.editbox:SetMaxLetters(count or 0)
        end,
    }

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:Hide()
        local field, border, caption = CreateField(frame)
        field:SetScript("OnMouseDown", Field_OnMouseDown)

        local editbox = CreateFrame("EditBox", nil, field)
        editbox:SetPoint("TOPLEFT", variables.insetX, 0)
        editbox:SetPoint("BOTTOMRIGHT", -variables.insetX, 0)
        editbox:SetFontObject(Theme.fonts.body)
        editbox:SetAutoFocus(false)
        editbox:SetScript("OnEditFocusGained", EditBox_OnEditFocusGained)
        editbox:SetScript("OnEditFocusLost", EditBox_OnEditFocusLost)
        editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
        editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
        editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)

        local placeholder = Theme.CreateText(field, "body", Theme.colors.disabled)
        placeholder:SetPoint("LEFT", variables.insetX, 0)
        placeholder:SetPoint("RIGHT", -variables.insetX, 0)

        local widget = {
            frame = frame,
            field = field,
            border = border,
            caption = caption,
            editbox = editbox,
            placeholder = placeholder,
            lastText = "",
            type = Type,
        }
        for method, func in pairs(sharedMethods) do
            widget[method] = func
        end
        for method, func in pairs(methods) do
            widget[method] = func
        end
        field.obj, editbox.obj = widget, widget

        return AceGUI:RegisterAsWidget(widget)
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Edit box for long texts that scrolls. Its height is set from outside. Fires OnTextChanged(text) when the user edits it
do
    local Type, Version = "CustomNames-MultiLineEditBox", 1

    local function UpdateRange(self)
        local viewHeight = self.scrollFrame:GetHeight()
        self.scroller:SetRange(viewHeight, viewHeight + self.scrollFrame:GetVerticalScrollRange())
    end

    local function ScrollFrame_OnSizeChanged(scrollFrame, width)
        scrollFrame.obj.editbox:SetWidth(width)
        UpdateRange(scrollFrame.obj)
    end

    local function ScrollFrame_OnScrollRangeChanged(scrollFrame)
        UpdateRange(scrollFrame.obj)
    end

    local function ScrollFrame_OnMouseWheel(scrollFrame, delta)
        scrollFrame.obj.scroller:ScrollBy(-delta * Theme.sizes.scrollStep)
    end

    ---Keeps the text cursor in view while typing or moving through the text
    local function EditBox_OnCursorChanged(editbox, _, y, _, cursorHeight)
        local scroller = editbox.obj.scroller
        local top, bottom = -y, -y + cursorHeight
        if top < scroller.target then
            scroller:SetOffset(top, true)
        elseif bottom > scroller.target + scroller.viewHeight then
            scroller:SetOffset(bottom - scroller.viewHeight, true)
        end
    end

    local methods = {
        ["OnAcquire"] = function(self)
            self:SetWidth(200)
            self:SetHeight(120)
            self:SetLabel()
            self:SetPlaceholder()
            self:SetText()
            self.scroller:Reset()
        end,

        ---@param text string? -- caption above the box
        ["SetLabel"] = function(self, text)
            SetCaption(self, text)
        end,
    }

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:Hide()
        local field, border, caption = CreateField(frame)
        field:SetScript("OnMouseDown", Field_OnMouseDown)

        local scrollFrame = CreateFrame("ScrollFrame", nil, field)
        scrollFrame:SetPoint("TOPLEFT", variables.insetX, -variables.insetY)
        scrollFrame:SetPoint("BOTTOMRIGHT", -Theme.sizes.scrollBar - 2, variables.insetY)
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnSizeChanged", ScrollFrame_OnSizeChanged)
        scrollFrame:SetScript("OnScrollRangeChanged", ScrollFrame_OnScrollRangeChanged)
        scrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)

        local editbox = CreateFrame("EditBox", nil, scrollFrame)
        editbox:SetMultiLine(true)
        editbox:SetFontObject(Theme.fonts.small)
        editbox:SetAutoFocus(false)
        editbox:SetWidth(100)
        editbox:SetScript("OnEditFocusGained", EditBox_OnEditFocusGained)
        editbox:SetScript("OnEditFocusLost", EditBox_OnEditFocusLost)
        editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
        editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)
        editbox:SetScript("OnCursorChanged", EditBox_OnCursorChanged)
        scrollFrame:SetScrollChild(editbox)

        local placeholder = Theme.CreateText(field, "small", Theme.colors.disabled)
        placeholder:SetPoint("TOPLEFT", variables.insetX, -variables.insetY)
        placeholder:SetPoint("RIGHT", -variables.insetX, 0)

        local widget = {
            frame = frame,
            field = field,
            border = border,
            caption = caption,
            scrollFrame = scrollFrame,
            editbox = editbox,
            placeholder = placeholder,
            lastText = "",
            type = Type,
        }
        widget.scroller = private.CreateScroller(field, function(offset)
            scrollFrame:SetVerticalScroll(offset)
        end)
        for method, func in pairs(sharedMethods) do
            widget[method] = func
        end
        for method, func in pairs(methods) do
            widget[method] = func
        end
        field.obj, scrollFrame.obj, editbox.obj = widget, widget, widget

        return AceGUI:RegisterAsWidget(widget)
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
