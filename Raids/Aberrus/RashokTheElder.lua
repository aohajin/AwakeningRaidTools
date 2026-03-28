local _, addon = ...

local Boss = {
    name = "RashokTheElder",
    encounterId = 2680,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Aberrus.RashokTheElder", Boss)
