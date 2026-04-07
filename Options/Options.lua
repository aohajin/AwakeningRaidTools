local _, addon = ...

local panel = CreateFrame("Frame")
panel.name = "Awakening Raid Tools"
panel:Hide()

panel:SetScript("OnShow", function(self)
    local specGearLabel = (addon.L and addon.L.OPTIONS_SPEC_GEAR_MISMATCH) or "Enable gear mismatch check"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Awakening Raid Tools")

    local checkBox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    checkBox:SetChecked(AwakeningRaidToolsDB and AwakeningRaidToolsDB.SpecGearMismatchEnabled == true)
    checkBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)
    checkBox.Text:SetText(specGearLabel)
    checkBox:HookScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        AwakeningRaidToolsDB.SpecGearMismatchEnabled = checked or nil
        local module = addon.modules["Common.SpecGearMismatchWarning"]
        if module then
            if checked then
                module:Enable()
            else
                module:Disable()
            end
        end
    end)

    self:SetScript("OnShow", nil)
end)

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)
