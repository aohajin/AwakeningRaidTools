local addonName, addon = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        AwakeningRaidToolsDB = AwakeningRaidToolsDB or {}
        if type(addon.InitializeModules) == "function" then
            addon:InitializeModules()
        end
    end
end)

SLASH_ART1 = "/art"
SlashCmdList["ART"] = function()
    if addon.optionsCategory then
        Settings.OpenToCategory(addon.optionsCategory:GetID())
    end
end

SLASH_FICLOG1 = "/ficlog"
SlashCmdList["FICLOG"] = function()
    local log = AwakeningRaidToolsDB and AwakeningRaidToolsDB.DebugLog
    if not log or #log == 0 then
        print("ART: Debug log is empty. Enable debug logging in options first.")
        return
    end

    -- Reuse or create once
    local f = _G.ARTDebugLogFrame
    if not f then
        f = CreateFrame("Frame", "ARTDebugLogFrame", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(700, 500)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetScript("OnHide", function() end)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.title:SetPoint("TOP", 0, -15)

        local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 12, -35)
        sf:SetPoint("BOTTOMRIGHT", -30, 40)
        f.scrollFrame = sf

        f.edit = CreateFrame("EditBox", nil, sf)
        f.edit:SetMultiLine(true)
        f.edit:SetMaxLetters(0)
        f.edit:SetFontObject("ChatFontNormal")
        f.edit:SetWidth(sf:GetWidth() - 20)
        f.edit:SetCursorPosition(0)
        f.edit:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(f.edit)

        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetPoint("BOTTOM", 0, 15)
        close:SetText("Close")
        close:SetSize(80, 24)
        close:SetScript("OnClick", function() f:Hide() end)
    end

    f.title:SetText("ART Debug Log (" .. #log .. " entries)")
    f.edit:SetText(table.concat(log, "\n", math.max(1, #log - 499), #log))
    f:Show()
end
