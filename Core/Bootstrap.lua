local addonName, addon = ...

addon.name = addonName
addon.modules = addon.modules or {}

-- Expose the shared addon table globally so the optional LoadOnDemand legacy
-- addon (AwakeningRaidTools-Legacy) can register into the same module
-- registry, keeping Options / PhaseTracker / encounter activation intact.
_G[addonName] = addon

function addon:Dbg(moduleName, msg)
    if not (AwakeningRaidToolsDB and AwakeningRaidToolsDB.DebugEnabled) then return end
    local db = AwakeningRaidToolsDB
    if not db.DebugLog then db.DebugLog = {} end
    table.insert(db.DebugLog, ("[%.3f][%s] %s"):format(GetTime(), moduleName, msg))
    if #db.DebugLog > 1000 then table.remove(db.DebugLog, 1) end
end
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
    -- Register for test encounter IDs (temporary)
    if module.testEncounterIds then
        for _, eid in ipairs(module.testEncounterIds) do
            self.encounterModulesByID[eid] = self.encounterModulesByID[eid] or {}
            table.insert(self.encounterModulesByID[eid], module)
        end
    end
end

function addon:InitializeModules()
    for _, module in pairs(self.modules) do
        if type(module) == "table" and type(module.OnInitialize) == "function" then
            module:OnInitialize()
        end
    end
end

-- Register a frame's events from a context that may be inside combat lockdown
-- (e.g. ADDON_LOADED right after a /reload performed during combat). While
-- locked down, RegisterEvent throws ADDON_ACTION_FORBIDDEN, so poll with an
-- OnUpdate and register as soon as combat ends.
function addon:RegisterSafeEvents(frame, events, handler)
    local function doRegister()
        for _, eventName in ipairs(events) do
            frame:RegisterEvent(eventName)
        end
        frame:SetScript("OnEvent", handler)
    end

    if InCombatLockdown() then
        local poll = CreateFrame("Frame")
        poll:SetScript("OnUpdate", function(self)
            if not InCombatLockdown() then
                self:SetScript("OnUpdate", nil)
                doRegister()
            end
        end)
    else
        doRegister()
    end
end

local function IsMythicRaidDifficulty(difficultyID)
    return difficultyID == 16
end

-- Legacy raid modules are gated by their per-raid toggles
-- (AwakeningRaidToolsDB.LegacyRaidEnabled); other modules always activate.
local function IsModuleEnabled(module)
    local moduleName = module.moduleName
    if moduleName then
        local raidKey = moduleName:match("^Raids%.([^%.]+)")
        if raidKey and addon.IsLegacyRaid and addon:IsLegacyRaid(raidKey) then
            local db = AwakeningRaidToolsDB
            return db and db.LegacyRaidEnabled and db.LegacyRaidEnabled[raidKey] == true
        end
    end
    return true
end

local function ActivateEncounter(encounterID, encounterName, difficultyID, groupSize)
    addon.activeEncounterID = encounterID
    local modules = addon.encounterModulesByID[encounterID]
    if not modules then
        return
    end

    for i = 1, #modules do
        local module = modules[i]
        if not IsModuleEnabled(module) then
            addon:Dbg("Bootstrap", ("encounter %d: %s skipped (legacy raid not enabled)"):format(encounterID or 0, tostring(module.moduleName)))
        else
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

    local phaseTracker = addon.modules["Common.PhaseTracker"]
    if phaseTracker then
        phaseTracker:OnEncounterStart(encounterID)
    end
end

local function DeactivateEncounter(encounterID, encounterName, difficultyID, groupSize, success)
    for module in pairs(addon.activeEncounterModules) do
        local moduleEncounterID = module.encounterId or module.encounterID
        local isTest = module.testEncounterIds
        if moduleEncounterID == encounterID or (isTest and tContains(isTest, encounterID)) then
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

    local phaseTracker = addon.modules["Common.PhaseTracker"]
    if phaseTracker then
        phaseTracker:OnEncounterEnd(encounterID)
    end
end

-- Legacy modules are loaded explicitly from the options panel
-- (Core.LegacyLoader toggle); never auto-load them on encounter start.
local function EnsureEncounterModules(encounterID)
    if addon.encounterModulesByID[encounterID] then
        return true
    end
    print(("ART: no module for encounterId %d; enable \"Legacy raid modules\" in the options panel and /reload"):format(encounterID or 0))
    return false
end

local encounterFrame = CreateFrame("Frame")
encounterFrame:RegisterEvent("ENCOUNTER_START")
encounterFrame:RegisterEvent("ENCOUNTER_END")
encounterFrame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
encounterFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID, groupSize = ...
        if IsMythicRaidDifficulty(difficultyID) then
            print(("ART: [%s] Mythic start (encounterId=%d)"):format(encounterName or "Unknown", encounterID or 0))
            if EnsureEncounterModules(encounterID) then
                ActivateEncounter(encounterID, encounterName, difficultyID, groupSize)
            else
                print(("ART: no module for encounterId %d; AwakeningRaidTools-Legacy not loaded"):format(encounterID or 0))
            end
        end
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, success = ...
        if IsMythicRaidDifficulty(difficultyID) then
            print(("ART: [%s] Mythic end (encounterId=%d, success=%d)"):format(encounterName or "Unknown", encounterID or 0, success or 0))
        end
        DeactivateEncounter(encounterID, encounterName, difficultyID, groupSize, success)
    elseif event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
        local encounterID = select(1, ...)
        local duration = select(4, ...)
        if addon.activeEncounterID and addon.activeEncounterID == encounterID then
            local phaseTracker = addon.modules["Common.PhaseTracker"]
            if phaseTracker then
                phaseTracker:HandleTimelineEvent(encounterID, duration)
            end
        end
    end
end)
