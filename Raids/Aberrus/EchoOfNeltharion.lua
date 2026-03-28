local _, addon = ...

local Boss = {
    name = "EchoOfNeltharion",
    encounterId = 2684,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Aberrus.EchoOfNeltharion", Boss)
