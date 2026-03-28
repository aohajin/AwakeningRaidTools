local addonName, addon = ...

addon.name = addonName
addon.modules = addon.modules or {}

function addon:RegisterModule(name, module)
    self.modules[name] = module
end

function addon:InitializeModules()
    for _, module in pairs(self.modules) do
        if type(module) == "table" and type(module.OnInitialize) == "function" then
            module:OnInitialize()
        end
    end
end

local function DumpRaidEncounters()
    if type(EJ_GetNumTiers) ~= "function" then
        print("|cffff7f00ART:|r Encounter Journal API not available.")
        return
    end

    local currentTier = EJ_GetCurrentTier()
    if not currentTier or currentTier <= 0 then
        currentTier = EJ_GetNumTiers()
    end
    EJ_SelectTier(currentTier)

    print(string.format("|cffff7f00ART:|r Dumping raid encounters for tier %d", currentTier))

    local numInstances = EJ_GetNumInstances() or 0
    for i = 1, numInstances do
        local instanceName, _, _, _, _, _, _, journalInstanceID = EJ_GetInstanceByIndex(i, true)
        if instanceName and journalInstanceID then
            EJ_SelectInstance(journalInstanceID)
            local numEncounters = EJ_GetNumEncounters() or 0
            print(string.format("|cff00ff00[%s]|r instanceID=%d encounters=%d", instanceName, journalInstanceID, numEncounters))
            for encounterIndex = 1, numEncounters do
                local encounterName, _, encounterID = EJ_GetEncounterInfoByIndex(encounterIndex, journalInstanceID)
                print(string.format("  - %s | encounterID=%s", encounterName or "Unknown", tostring(encounterID)))
            end
        end
    end
end

SLASH_AWAKENINGRAIDTOOLSDUMP1 = "/artdump"
SlashCmdList.AWAKENINGRAIDTOOLSDUMP = DumpRaidEncounters
