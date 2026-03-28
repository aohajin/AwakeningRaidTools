local addonName, addon = ...

addon.name = addonName
addon.modules = addon.modules or {}
addon.encounterModulesByID = addon.encounterModulesByID or {}
addon.activeEncounterID = nil
addon.activeEncounterModules = addon.activeEncounterModules or {}

function addon:RegisterModule(name, module)
    self.modules[name] = module
    module.moduleName = name

    local encounterID = module.encounterId or module.encounterID
    if encounterID then
        self.encounterModulesByID[encounterID] = self.encounterModulesByID[encounterID] or {}
        table.insert(self.encounterModulesByID[encounterID], module)
    end
end

function addon:InitializeModules()
    for _, module in pairs(self.modules) do
        if type(module) == "table" and type(module.OnInitialize) == "function" then
            module:OnInitialize()
        end
    end
end

local function IsMythicRaidDifficulty(difficultyID)
    return difficultyID == 16
end

local function ActivateEncounter(encounterID, encounterName, difficultyID, groupSize)
    addon.activeEncounterID = encounterID
    local modules = addon.encounterModulesByID[encounterID]
    if not modules then
        return
    end

    for i = 1, #modules do
        local module = modules[i]
        module.isActive = true
        addon.activeEncounterModules[module] = true

        if type(module.OnEncounterStart) == "function" then
            module:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
        end
        if type(module.OnMythicEncounterStart) == "function" then
            module:OnMythicEncounterStart(encounterID, encounterName, difficultyID, groupSize)
        end
    end
end

local function DeactivateEncounter(encounterID, encounterName, difficultyID, groupSize, success)
    for module in pairs(addon.activeEncounterModules) do
        local moduleEncounterID = module.encounterId or module.encounterID
        if moduleEncounterID == encounterID then
            if type(module.OnEncounterEnd) == "function" then
                module:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
            end
            if type(module.OnMythicEncounterEnd) == "function" then
                module:OnMythicEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
            end
            module.isActive = false
            addon.activeEncounterModules[module] = nil
        end
    end
    if addon.activeEncounterID == encounterID then
        addon.activeEncounterID = nil
    end
end

local encounterFrame = CreateFrame("Frame")
encounterFrame:RegisterEvent("ENCOUNTER_START")
encounterFrame:RegisterEvent("ENCOUNTER_END")
encounterFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID, groupSize = ...
        if IsMythicRaidDifficulty(difficultyID) then
            print(("ART: [%s] Mythic start (encounterId=%d)"):format(encounterName or "Unknown", encounterID or 0))
            ActivateEncounter(encounterID, encounterName, difficultyID, groupSize)
        end
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, success = ...
        if IsMythicRaidDifficulty(difficultyID) then
            print(("ART: [%s] Mythic end (encounterId=%d, success=%d)"):format(encounterName or "Unknown", encounterID or 0, success or 0))
        end
        DeactivateEncounter(encounterID, encounterName, difficultyID, groupSize, success)
    end
end)
