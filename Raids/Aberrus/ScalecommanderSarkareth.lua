local _, addon = ...

local Boss = {
    name = "ScalecommanderSarkareth",
    encounterId = 2685,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Aberrus.ScalecommanderSarkareth", Boss)
