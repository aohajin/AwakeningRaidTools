local _, addon = ...

local Boss = {
    name = "MidnightFalls",
    encounterId = 3183,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.MarchOfQuelDanas.MidnightFalls", Boss)
