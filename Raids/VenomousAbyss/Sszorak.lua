local _, addon = ...

-- Boss 5: Sszorak
-- A horrifying creature, warped by Ula'tek's toxic venom, Sszorak is a brutal
-- instrument of vengeance. Calling upon the winds that howl deep within Atal'Utek,
-- it tears apart any living creature it encounters.

local Boss = {
    name = "Sszorak",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3420,
    journalEncounterId = 2871, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        -- Feature skeleton: add one entry per toggleable option, e.g.
        -- sampleFeature = {
        --     type = "toggle",
        --     default = true,
        --     labelKey = "OPTIONS_Sszorak_SAMPLE",
        --     descKey  = "OPTIONS_Sszorak_SAMPLE_DESC",
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

addon:RegisterModule("Raids.VenomousAbyss.Sszorak", Boss)
