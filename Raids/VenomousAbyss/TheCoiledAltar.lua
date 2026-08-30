local _, addon = ...

-- Boss 7: The Coiled Altar (Zul'jan + Malacrass)
-- The spirit of Malacrass will not release his grip on Zul'jan so easily. At
-- the Coiled Altar, the shaman commands the warrior to enact the final ritual
-- to unleash Ula'tek on the Amani -- for revenge, and to gain their promised reward.

local Boss = {
    name = "TheCoiledAltar",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3429,
    journalEncounterId = 2883, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        -- Feature skeleton: add one entry per toggleable option, e.g.
        -- sampleFeature = {
        --     type = "toggle",
        --     default = true,
        --     labelKey = "OPTIONS_TheCoiledAltar_SAMPLE",
        --     descKey  = "OPTIONS_TheCoiledAltar_SAMPLE_DESC",
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

addon:RegisterModule("Raids.VenomousAbyss.TheCoiledAltar", Boss)
