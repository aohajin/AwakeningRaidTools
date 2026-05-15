local _, addon = ...

local Boss = {
	name = "MidnightFalls",
	encounterId = 3183,
	mythicOnly = true,
	features = {
		particleDensity = {
			type = "toggle",
			default = false,
			labelKey = "OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY",
			descKey  = "OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY_DESC",
		},
	},
}

local savedCVars = {}
local cvarsRestored = false

local function SaveCVars()
	wipe(savedCVars)
	local particle = C_CVar.GetCVar("graphicsParticleDensity")
	if particle ~= nil then
		savedCVars.particle = particle
	end
	local raidParticle = C_CVar.GetCVar("RaidGraphicsParticleDensity")
	if raidParticle ~= nil then
		savedCVars.raidParticle = raidParticle
	end
end

local function DisableParticleCVars()
	C_CVar.SetCVar("graphicsParticleDensity", "0")
	C_CVar.SetCVar("RaidGraphicsParticleDensity", "0")
end

local function RestoreCVars()
	if cvarsRestored then return end
	cvarsRestored = true
	for name, value in pairs(savedCVars) do
		if name == "particle" then
			C_CVar.SetCVar("graphicsParticleDensity", value)
		elseif name == "raidParticle" then
			C_CVar.SetCVar("RaidGraphicsParticleDensity", value)
		end
	end
	wipe(savedCVars)
end

local function IsFeatureEnabled()
	local db = AwakeningRaidToolsDB
	if db and db.encounters and db.encounters[3183] then
		return db.encounters[3183].particleDensity ~= false
	end
	return true
end

function Boss:OnMythicEncounterStart(encounterID)
	self.isActive = true

	local pt = addon.modules and addon.modules["Common.PhaseTracker"]
	if pt then
		pt:RegisterPhaseConfig(self.encounterId, {
			transitions = {
				{ atDuration = 45.0, phase = 2 },
				{ atDuration = 97.0, phase = 3 },
			},
		})
		pt:RegisterPhaseCallback(self.encounterId, function(_, newPhase)
			if newPhase >= 3 then
				if IsFeatureEnabled() then
					RestoreCVars()
				end
			end
		end)
	end

	if IsFeatureEnabled() then
		cvarsRestored = false
		SaveCVars()
		DisableParticleCVars()
	end
end

function Boss:OnMythicEncounterEnd()
	self.isActive = false
	RestoreCVars()
end

addon:RegisterModule("Raids.MarchOfQuelDanas.MidnightFalls", Boss)
