local _, addon = ...

local Boss = {
    name = "BelorenChildOfAlar",
    encounterId = 3182,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.MarchOfQuelDanas.BelorenChildOfAlar", Boss)
