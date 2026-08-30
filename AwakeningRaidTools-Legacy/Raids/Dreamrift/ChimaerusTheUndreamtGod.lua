local _, addon = ...

local Boss = {
    name = "ChimaerusTheUndreamtGod",
    encounterId = 3306,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
end

addon:RegisterModule("Raids.Dreamrift.ChimaerusTheUndreamtGod", Boss)
