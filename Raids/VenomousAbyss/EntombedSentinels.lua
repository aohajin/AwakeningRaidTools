local _, addon = ...

-- Boss 2: Entombed Sentinels
-- The Blood and Breath of Ula'tek bar the way to Vashnik's inner sanctum.
-- Ancient golems that long stood guard within the vaults, now corrupted by the
-- venom of the nightmarish monster they imprisoned.

local Boss = {
    name = "EntombedSentinels",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3445,
    journalEncounterId = 2874, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        -- Feature skeleton: add one entry per toggleable option, e.g.
        -- sampleFeature = {
        --     type = "toggle",
        --     default = true,
        --     labelKey = "OPTIONS_EntombedSentinels_SAMPLE",
        --     descKey  = "OPTIONS_EntombedSentinels_SAMPLE_DESC",
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

addon:RegisterModule("Raids.VenomousAbyss.EntombedSentinels", Boss)
