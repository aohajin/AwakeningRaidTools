local _, addon = ...

local Boss = {
    name = "FallenKingSalhadaar",
    encounterId = 3179,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Voidspire.FallenKingSalhadaar", Boss)
