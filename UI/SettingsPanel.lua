local appName, app = ...
---@class CustomNamesPrivate
local private = app
local AceGUI = LibStub("AceGUI-3.0")

local variables = {
    buttonWidth = 200,
}

-- the settings panel only links to the window, names are not edited in there
local panel = AceGUI:Create("BlizOptionsGroup")
panel:SetTitle(appName)
panel:SetLayout("List")

panel:SetCallback("OnShow", function(container)
    container:ReleaseChildren()

    local description = AceGUI:Create("Label")
    description:SetText(private.getLocalisation("SettingsDescription"))
    description:SetFontObject(GameFontHighlight)
    description:SetFullWidth(true)
    container:AddChild(description)

    local openButton = AceGUI:Create("Button")
    openButton:SetText(private.getLocalisation("OpenWindow"))
    openButton:SetWidth(variables.buttonWidth)
    openButton:SetCallback("OnClick", function()
        private.OpenWindow()
    end)
    container:AddChild(openButton)
end)

panel:SetCallback("OnHide", function(container)
    container:ReleaseChildren()
end)

panel:SetName(appName)
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel.frame, appName)
    Settings.RegisterAddOnCategory(category)
else
    InterfaceOptions_AddCategory(panel.frame)
end

function CustomNames_AddonCompartmentFunction()
    private.ToggleWindow()
end
