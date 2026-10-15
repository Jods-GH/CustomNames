local AceGUI = LibStub("AceGUI-3.0")

local variables = {
    spacing = 8,
}

---Places all children next to each other in a single line that never wraps.
---Children with the user data "flex" share the width that is left over by the others,
---the user data "paddingLeft" of the container indents the line
AceGUI:RegisterLayout("CustomNames-Columns", function(content, children)
    local container = content.obj
    local padding = container:GetUserData("paddingLeft") or 0
    local width = (content.width or content:GetWidth() or 0) - padding

    local fixedWidth, flexTotal = 0, 0
    for i = 1, #children do
        local child = children[i]
        local flex = child:GetUserData("flex")
        if flex then
            flexTotal = flexTotal + flex
        else
            fixedWidth = fixedWidth + (child.frame.width or child.frame:GetWidth() or 0)
        end
    end
    local flexWidth = math.max(width - fixedWidth - variables.spacing * (#children - 1), 0)

    local offset, height = padding, 0
    for i = 1, #children do
        local child = children[i]
        local frame = child.frame
        local flex = child:GetUserData("flex")
        local childWidth = frame.width or frame:GetWidth() or 0
        if flex then
            childWidth = flexWidth * flex / flexTotal
            child:SetWidth(childWidth)
        end
        frame:ClearAllPoints()
        frame:SetPoint("LEFT", content, "LEFT", offset, 0)
        frame:Show()
        if child.DoLayout then
            child:DoLayout()
        end
        offset = offset + childWidth + variables.spacing
        height = math.max(height, frame.height or frame:GetHeight() or 0)
    end

    if container.LayoutFinished then
        container:LayoutFinished(nil, height)
    end
end)

---Lets the children claim the edges of the container one after another, in the order they were added.
---The user data "dock" of a child is TOP, BOTTOM, LEFT, RIGHT or FILL (default), a child that fills takes what is left.
---Children at the top and bottom keep their height, children at the sides keep their width
---or get the part of the free width given by the user data "dockShare" (0 - 1).
---The user data "margin" keeps a distance to whatever was docked before (above and below for a child that fills)
AceGUI:RegisterLayout("CustomNames-Dock", function(content, children)
    local width = content.width or content:GetWidth() or 0
    local height = content.height or content:GetHeight() or 0
    local left, right, top, bottom = 0, 0, 0, 0

    for i = 1, #children do
        local child = children[i]
        local frame = child.frame
        local dock = child:GetUserData("dock") or "FILL"
        local margin = child:GetUserData("margin") or 0
        local freeWidth = math.max(width - left - right, 0)
        local freeHeight = math.max(height - top - bottom, 0)

        frame:ClearAllPoints()
        frame:Show()
        if dock == "TOP" or dock == "BOTTOM" then
            child:SetWidth(freeWidth)
            if child.DoLayout then
                child:DoLayout()
            end
            local childHeight = frame.height or frame:GetHeight() or 0
            if dock == "TOP" then
                frame:SetPoint("TOPLEFT", content, "TOPLEFT", left, -(top + margin))
                top = top + margin + childHeight
            else
                frame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", left, bottom + margin)
                bottom = bottom + margin + childHeight
            end
        elseif dock == "LEFT" or dock == "RIGHT" then
            local share = child:GetUserData("dockShare")
            local childWidth = share and math.floor(freeWidth * share) or frame.width or frame:GetWidth() or 0
            child:SetWidth(childWidth)
            child:SetHeight(freeHeight)
            if dock == "LEFT" then
                frame:SetPoint("TOPLEFT", content, "TOPLEFT", left + margin, -top)
                left = left + margin + childWidth
            else
                frame:SetPoint("TOPRIGHT", content, "TOPRIGHT", -(right + margin), -top)
                right = right + margin + childWidth
            end
            if child.DoLayout then
                child:DoLayout()
            end
        else
            frame:SetPoint("TOPLEFT", content, "TOPLEFT", left, -(top + margin))
            child:SetWidth(freeWidth)
            child:SetHeight(math.max(freeHeight - margin * 2, 0))
            if child.DoLayout then
                child:DoLayout()
            end
        end
    end

    -- lets containers that size themselves to their children (like the scroll container) stack things with margins
    local container = content.obj
    if container.LayoutFinished then
        container:LayoutFinished(nil, top + bottom)
    end
end)
