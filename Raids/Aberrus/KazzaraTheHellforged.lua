local _, addon = ...

local Boss = {
    name = "KazzaraTheHellforged",
    encounterId = 2688,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Aberrus.KazzaraTheHellforged", Boss)
