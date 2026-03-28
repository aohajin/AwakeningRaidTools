local _, addon = ...

local Boss = {
    name = "TheAmalgamationChamber",
    encounterId = 2687,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Aberrus.TheAmalgamationChamber", Boss)
