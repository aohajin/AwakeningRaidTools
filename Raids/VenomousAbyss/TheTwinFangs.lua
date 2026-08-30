local _, addon = ...

-- Boss 6: The Twin Fangs (Vexhul & Ithraz)
-- The first of Ula'tek's blood, Vexhul and Ithraz brood beneath a roiling sea
-- of venom deep within the vault of Atal'Utek. Any foolish enough to enter the
-- prison's inner chamber risk their monstrous jaws and toxic strikes.

local Boss = {
    name = "TheTwinFangs",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3421,
    journalEncounterId = 2887, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        -- Feature skeleton: add one entry per toggleable option, e.g.
        -- sampleFeature = {
        --     type = "toggle",
        --     default = true,
        --     labelKey = "OPTIONS_TheTwinFangs_SAMPLE",
        --     descKey  = "OPTIONS_TheTwinFangs_SAMPLE_DESC",
        -- },
    },
}

function Boss:OnMythicEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    self.isActive = true
    addon:Dbg(self.name, "start")
    -- Phase tracking: uncomment and fill in transitions once timings are known.
    -- local pt = addon.modules["Common.PhaseTracker"]
    -- if pt then
    --     pt:RegisterPhaseConfig(self.encounterId, { transitions = {
    --         { atDuration = 45.0, phase = 2 },
    --     }})
    --     pt:RegisterPhaseCallback(self.encounterId, function(_, newPhase, prevPhase)
    --         self:OnPhaseChange(newPhase, prevPhase)
    --     end)
    -- end
end

function Boss:OnMythicEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    self.isActive = false
    addon:Dbg(self.name, "end")
end

function Boss:OnPhaseChange(newPhase, prevPhase)
    -- TODO
end

addon:RegisterModule("Raids.VenomousAbyss.TheTwinFangs", Boss)
