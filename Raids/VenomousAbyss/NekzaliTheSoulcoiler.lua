local _, addon = ...

-- Boss 1: Nek'zali the Soulcoiler
-- Long ago, the shadow hunter Nek'zali and her followers were entombed for the
-- blasphemous act of summoning Ula'tek. Restored by the very power she unleashed,
-- she calls the other Soulcoilers from their tombs to serve her once more.

local Boss = {
    name = "NekzaliTheSoulcoiler",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3470,
    journalEncounterId = 2888, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        -- Feature skeleton: add one entry per toggleable option, e.g.
        -- sampleFeature = {
        --     type = "toggle",
        --     default = true,
        --     labelKey = "OPTIONS_NekzaliTheSoulcoiler_SAMPLE",
        --     descKey  = "OPTIONS_NekzaliTheSoulcoiler_SAMPLE_DESC",
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

addon:RegisterModule("Raids.VenomousAbyss.NekzaliTheSoulcoiler", Boss)
