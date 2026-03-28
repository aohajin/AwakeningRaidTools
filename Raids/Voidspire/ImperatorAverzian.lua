local _, addon = ...

local Boss = {
    name = "ImperatorAverzian",
    encounterId = 3176,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Voidspire.ImperatorAverzian", Boss)
