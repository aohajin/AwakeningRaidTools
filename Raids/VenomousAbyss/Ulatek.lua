local _, addon = ...

-- Boss 8: Ula'tek (Final Boss)
-- The great shame of the Amani empire. The vast complex of Atal'Utek was created
-- to imprison the weapon that proved to be as much of a threat as the enemy she
-- was intended to destroy. Ula'tek has risen from her ancient slumber and threatens
-- all of Azeroth if she should escape.

local Boss = {
    name = "Ulatek",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3492,
    journalEncounterId = 2895, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        -- Feature skeleton: add one entry per toggleable option, e.g.
        -- sampleFeature = {
        --     type = "toggle",
        --     default = true,
        --     labelKey = "OPTIONS_Ulatek_SAMPLE",
        --     descKey  = "OPTIONS_Ulatek_SAMPLE_DESC",
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

addon:RegisterModule("Raids.VenomousAbyss.Ulatek", Boss)
