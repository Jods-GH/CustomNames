local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")
local Theme = private.Theme

-- Switch with a label next to it. Fires OnValueChanged(value)
local Type, Version = "CustomNames-Toggle", 1
local variables = {
    trackWidth = 30,
    trackHeight = 16,
    knobSize = 10,
    knobInset = 3,
    labelGap = 10,
}

---@param self table
---@param instant boolean? -- don't slide the knob
local function UpdateVisual(self, instant)
    local colors = Theme.colors
    Theme.SetColor(self.track, self.value and colors.accent or colors.lineStrong)
    Theme.SetColor(self.knob, self.value and colors.onAccent or colors.text)
    local from = self.knobOffset or variables.knobInset
    local to = self.value and (variables.trackWidth - variables.knobSize - variables.knobInset) or variables.knobInset
    Theme.Tween(self, "knob", from, to, instant and 0 or Theme.durations.fade, function(offset)
        self.knobOffset = offset
        self.knob:SetPoint("LEFT", self.track, "LEFT", offset, 0)
    end)
end

local function Toggle_OnClick(frame)
    local self = frame.obj
    self.value = not self.value
    PlaySound(self.value and 856 or 857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON / OFF
    AceGUI:ClearFocus()
    UpdateVisual(self)
    self:Fire("OnValueChanged", self.value)
end

local methods = {
    ["OnAcquire"] = function(self)
        self.value, self.knobOffset = false, nil
        self:SetHeight(Theme.sizes.control)
        self:SetWidth(200)
        self:SetLabel()
        UpdateVisual(self, true)
    end,

    ["OnRelease"] = function(self)
        Theme.StopTweens(self)
    end,

    ---@param value boolean
    ["SetValue"] = function(self, value)
        self.value = value and true or false
        UpdateVisual(self, true)
    end,

    ---@return boolean
    ["GetValue"] = function(self)
        return self.value
    end,

    ---@param text string?
    ["SetLabel"] = function(self, text)
        self.label:SetText(text or "")
    end,
}

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:Hide()
    frame:SetScript("OnClick", Toggle_OnClick)

    local track = frame:CreateTexture(nil, "BACKGROUND")
    track:SetSize(variables.trackWidth, variables.trackHeight)
    track:SetPoint("LEFT")

    local knob = frame:CreateTexture(nil, "ARTWORK")
    knob:SetSize(variables.knobSize, variables.knobSize)

    local label = Theme.CreateText(frame, "body")
    label:SetPoint("LEFT", track, "RIGHT", variables.labelGap, 0)
    label:SetPoint("RIGHT")

    local widget = {
        frame = frame,
        track = track,
        knob = knob,
        label = label,
        value = false,
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
