local _, addon = ...

local Boss = {
    name = "LightblindedVanguard",
    encounterId = 3180,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Voidspire.LightblindedVanguard", Boss)
