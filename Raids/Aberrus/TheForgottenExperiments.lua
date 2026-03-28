local _, addon = ...

local Boss = {
    name = "TheForgottenExperiments",
    encounterId = 2693,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Aberrus.TheForgottenExperiments", Boss)
