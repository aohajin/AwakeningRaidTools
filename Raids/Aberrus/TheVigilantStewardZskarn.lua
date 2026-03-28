local _, addon = ...

local Boss = {
    name = "TheVigilantStewardZskarn",
    encounterId = 2689,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Aberrus.TheVigilantStewardZskarn", Boss)
