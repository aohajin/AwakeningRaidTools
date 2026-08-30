local _, addon = ...

local Boss = {
    name = "VaelgorAndEzzorak",
    encounterId = 3178,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Voidspire.VaelgorAndEzzorak", Boss)
