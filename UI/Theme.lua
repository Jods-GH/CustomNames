local appName, app = ...
---@class CustomNamesPrivate
local private = app

-- Everything that decides how the ui looks lives in here, the widgets only read from it

---@class CustomNamesTheme
local Theme = {}
private.Theme = Theme

Theme.colors = {
    background = { 0.055, 0.063, 0.078, 0.97 },
    header = { 0.075, 0.086, 0.106, 1 },
    field = { 0.035, 0.041, 0.051, 1 },
    hover = { 1, 1, 1, 0.045 },
    line = { 1, 1, 1, 0.09 },
    lineStrong = { 1, 1, 1, 0.2 },
    text = { 0.9, 0.92, 0.95, 1 },
    muted = { 0.55, 0.59, 0.65, 1 },
    disabled = { 0.35, 0.38, 0.42, 1 },
    accent = { 0, 0.68, 1, 1 }, -- the one colour that stands out, change it here
    accentSoft = { 0, 0.68, 1, 0.13 },
    onAccent = { 0.02, 0.05, 0.08, 1 }, -- text on top of the accent colour
    danger = { 1, 0.38, 0.38, 1 },
    dangerSoft = { 1, 0.38, 0.38, 0.12 },
    success = { 0.4, 0.85, 0.55, 1 },
}

Theme.sizes = {
    padding = 16,
    gap = 8,
    control = 28, -- height of buttons and fields
    row = 42,
    header = 40,
    caption = 16, -- height of the caption above a field
    scrollBar = 10, -- width that is reserved for the scrollbar
    scrollThumb = 4,
    scrollStep = 60, -- pixels per tick of the mouse wheel
    classIcon = 20,
}

Theme.durations = {
    fade = 0.18,
    glide = 0.22,
    scroll = 0.25,
    notice = 4, -- seconds a notice stays visible
}

local variables = {
    fonts = {
        title = { name = "CustomNamesFontTitle", size = 18 },
        heading = { name = "CustomNamesFontHeading", size = 14 },
        body = { name = "CustomNamesFontBody", size = 13 },
        small = { name = "CustomNamesFontSmall", size = 11 },
        caption = { name = "CustomNamesFontCaption", size = 10 },
    },
    classTexture = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
    classIconCrop = 0.02, -- cuts off the border that is baked into the class icons
}

-- the fonts are copies of a font of the game, so every locale keeps a font that has its letters
Theme.fonts = {}
for key, info in pairs(variables.fonts) do
    local font = CreateFont(info.name)
    font:CopyFontObject(GameFontHighlight)
    local file, _, flags = font:GetFont()
    font:SetFont(file, info.size, flags)
    font:SetTextColor(unpack(Theme.colors.text))
    font:SetShadowColor(0, 0, 0, 0)
    Theme.fonts[key] = font
end

---@param texture Texture|Line
---@param color table -- one of Theme.colors
Theme.SetColor = function(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

---@param fontString FontString
---@param color table -- one of Theme.colors
Theme.SetTextColor = function(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

---@param text string
---@param color table -- one of Theme.colors
---@return string text -- wrapped in a color escape sequence
Theme.Colorize = function(text, color)
    local r, g, b = math.floor(color[1] * 255 + 0.5), math.floor(color[2] * 255 + 0.5), math.floor(color[3] * 255 + 0.5)
    return ("|cff%02x%02x%02x%s|r"):format(r, g, b, text)
end

---Fills a frame with a flat colour
---@param frame Frame
---@param color table -- one of Theme.colors
---@param layer string? -- draw layer, BACKGROUND by default
---@return Texture
Theme.CreateBackground = function(frame, color, layer)
    local texture = frame:CreateTexture(nil, layer or "BACKGROUND")
    texture:SetAllPoints()
    Theme.SetColor(texture, color)
    return texture
end

---Creates a line of one screen pixel along an edge of a frame
---@param frame Frame
---@param edge "TOP"|"BOTTOM"|"LEFT"|"RIGHT"
---@param color table? -- one of Theme.colors, Theme.colors.line by default
---@return Texture
Theme.CreateEdge = function(frame, edge, color)
    local texture = frame:CreateTexture(nil, "BORDER")
    Theme.SetColor(texture, color or Theme.colors.line)
    if edge == "TOP" or edge == "BOTTOM" then
        texture:SetPoint(edge .. "LEFT")
        texture:SetPoint(edge .. "RIGHT")
        PixelUtil.SetHeight(texture, 1, 1)
    else
        texture:SetPoint("TOP" .. edge)
        texture:SetPoint("BOTTOM" .. edge)
        PixelUtil.SetWidth(texture, 1, 1)
    end
    return texture
end

---Creates a border of one screen pixel around a frame
---@param frame Frame
---@param color table? -- one of Theme.colors, Theme.colors.line by default
---@return table border -- list of the four textures, recolor it with Theme.SetBorderColor
Theme.CreateBorder = function(frame, color)
    return {
        Theme.CreateEdge(frame, "TOP", color),
        Theme.CreateEdge(frame, "BOTTOM", color),
        Theme.CreateEdge(frame, "LEFT", color),
        Theme.CreateEdge(frame, "RIGHT", color),
    }
end

---@param border table -- created by Theme.CreateBorder
---@param color table -- one of Theme.colors
Theme.SetBorderColor = function(border, color)
    for _, texture in ipairs(border) do
        Theme.SetColor(texture, color)
    end
end

---@param frame Frame
---@param fontKey string -- key of Theme.fonts
---@param color table? -- one of Theme.colors, the color of the font by default
---@return FontString -- left aligned and cut off instead of wrapped
Theme.CreateText = function(frame, fontKey, color)
    local fontString = frame:CreateFontString(nil, "ARTWORK")
    fontString:SetFontObject(Theme.fonts[fontKey])
    fontString:SetJustifyH("LEFT")
    fontString:SetWordWrap(false)
    if color then
        Theme.SetTextColor(fontString, color)
    end
    return fontString
end

---@param classFile string? -- e.g. MAGE
---@return table? color -- usable like one of Theme.colors
Theme.GetClassColor = function(classFile)
    local color = classFile and RAID_CLASS_COLORS[classFile]
    if not color then return nil end
    return { color.r, color.g, color.b, 1 }
end

---Shows the icon of a class in a texture
---@param texture Texture
---@param classFile string? -- e.g. MAGE
---@return boolean shown -- false if there is no icon for the class, the texture is hidden then
Theme.SetClassIcon = function(texture, classFile)
    local coords = classFile and CLASS_ICON_TCOORDS[classFile]
    if not coords then
        texture:Hide()
        return false
    end
    local crop = variables.classIconCrop
    texture:SetTexture(variables.classTexture)
    texture:SetTexCoord(coords[1] + crop, coords[2] - crop, coords[3] + crop, coords[4] - crop)
    texture:Show()
    return true
end

-- motion: values are moved from one number to another over time, everything animated goes through here
local tweens = {} -- [owner] = { [key] = tween }
local finished = {}
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(_, elapsed)
    for owner, ownerTweens in pairs(tweens) do
        for key, tween in pairs(ownerTweens) do
            tween.elapsed = tween.elapsed + elapsed
            local progress = math.min(tween.elapsed / tween.duration, 1)
            -- fast at the start and slow at the end
            local eased = 1 - (1 - progress) ^ 4
            tween.apply(tween.from + (tween.to - tween.from) * eased)
            if progress >= 1 then
                table.insert(finished, { owner = owner, key = key, tween = tween })
            end
        end
    end
    -- callbacks may start new tweens, so they run after the loop over the running ones
    for i = #finished, 1, -1 do
        local entry = table.remove(finished, i)
        local ownerTweens = tweens[entry.owner]
        if ownerTweens and ownerTweens[entry.key] == entry.tween then
            ownerTweens[entry.key] = nil
            if not next(ownerTweens) then
                tweens[entry.owner] = nil
            end
            if entry.tween.onFinish then
                entry.tween.onFinish()
            end
        end
    end
    if not next(tweens) then
        driver:Hide()
    end
end)

---Moves a value from one number to another over time
---@param owner table -- usually the widget, see Theme.StopTweens
---@param key string -- a new tween replaces the running one with the same owner and key
---@param from number
---@param to number
---@param duration number -- seconds
---@param apply fun(value: number)
---@param onFinish function?
Theme.Tween = function(owner, key, from, to, duration, apply, onFinish)
    if duration <= 0 or from == to then
        if tweens[owner] then
            tweens[owner][key] = nil
        end
        apply(to)
        if onFinish then
            onFinish()
        end
        return
    end
    tweens[owner] = tweens[owner] or {}
    tweens[owner][key] = { from = from, to = to, duration = duration, elapsed = 0, apply = apply, onFinish = onFinish }
    driver:Show()
end

---Stops all running tweens of an owner without finishing them
---@param owner table
Theme.StopTweens = function(owner)
    tweens[owner] = nil
end

---@param owner table
---@param frame Frame
---@param duration number? -- Theme.durations.fade by default
Theme.FadeIn = function(owner, frame, duration)
    frame:SetAlpha(0)
    Theme.Tween(owner, "fade", 0, 1, duration or Theme.durations.fade, function(alpha)
        frame:SetAlpha(alpha)
    end)
end
