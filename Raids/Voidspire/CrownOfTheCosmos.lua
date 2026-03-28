local _, addon = ...

local Boss = {
    name = "CrownOfTheCosmos",
    encounterId = 3181,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Voidspire.CrownOfTheCosmos", Boss)
