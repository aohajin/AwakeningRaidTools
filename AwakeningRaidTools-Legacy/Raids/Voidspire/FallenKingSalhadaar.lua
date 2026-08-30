local _, addon = ...

local Boss = {
	name = "FallenKingSalhadaar",
	encounterId = 3179,
	mythicOnly = true,
	features = {
		interruptDisplay = {
			type = "toggle",
			default = true,
			labelKey = "OPTIONS_FALLENKING_INTERRUPT_DISPLAY",
			descKey  = "OPTIONS_FALLENKING_INTERRUPT_DISPLAY_DESC",
		},
	},
}

local function IsFeatureEnabled()
	local db = AwakeningRaidToolsDB
	if db and db.encounters and db.encounters[3179] then
		return db.encounters[3179].interruptDisplay ~= false
	end
	return true
end

function Boss:OnMythicEncounterStart()
	self.isActive = true
	if IsFeatureEnabled() then
		local marker = addon.modules and addon.modules["Common.NameplateCastMarker"]
		if marker and type(marker.Enable) == "function" then
			marker:Enable({
				exclude = {"boss1"},
			})
		end
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
