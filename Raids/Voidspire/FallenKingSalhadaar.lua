local _, addon = ...

local Boss = {
    name = "FallenKingSalhadaar",
    encounterId = 3179,
    mythicOnly = true,
}

function Boss:OnMythicEncounterStart()
    self.isActive = true
    local marker = addon.modules and addon.modules["Common.NameplateCastMarker"]
    if marker and type(marker.Enable) == "function" then
        marker:Enable({
            exclude = {"boss1"},
        })
    end
end

function Boss:OnMythicEncounterEnd()
    self.isActive = false
    local marker = addon.modules and addon.modules["Common.NameplateCastMarker"]
    if marker and type(marker.Disable) == "function" then
        marker:Disable()
    end
end

addon:RegisterModule("Raids.Voidspire.FallenKingSalhadaar", Boss)
