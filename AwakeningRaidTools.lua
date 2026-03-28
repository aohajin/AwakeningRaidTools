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
