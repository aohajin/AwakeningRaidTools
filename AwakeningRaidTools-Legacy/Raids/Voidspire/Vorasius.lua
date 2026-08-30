local _, addon = ...

local Boss = {
    name = "Vorasius",
    encounterId = 3177,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Voidspire.Vorasius", Boss)
