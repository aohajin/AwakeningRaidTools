local _, addon = ...

local Boss = {
	name = "MidnightFalls",
	encounterId = 3183,
	mythicOnly = true,
	-- TODO: remove after testing
	testEncounterIds = {2590},
	features = {
		particleDensity = {
			type = "toggle",
			default = false,
			labelKey = "OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY",
			descKey  = "OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY_DESC",
		},
		focusInterruptCounter = {
			type = "toggle",
			default = true,
			labelKey = "OPTIONS_FOCUS_INTERRUPT_COUNTER",
			descKey  = "OPTIONS_FOCUS_INTERRUPT_COUNTER_DESC",
			subFeatures = {
				nameplate = {
					type = "toggle",
					default = true,
					labelKey = "OPTIONS_FIC_NAMEPLATE",
					descKey  = "OPTIONS_FIC_NAMEPLATE_DESC",
				},
				focusFrame = {
					type = "toggle",
					default = false,
					labelKey = "OPTIONS_FIC_FOCUS_FRAME",
					descKey  = "OPTIONS_FIC_FOCUS_FRAME_DESC",
				},
				centerScreen = {
					type = "toggle",
					default = false,
					labelKey = "OPTIONS_FIC_CENTER_SCREEN",
					descKey  = "OPTIONS_FIC_CENTER_SCREEN_DESC",
				},
			},
		},
	},
}

local function IsBossFeatureEnabled(key)
	local db = AwakeningRaidToolsDB
	if db and db.encounters and db.encounters[3183] then
		return db.encounters[3183][key] ~= false
	end
	return true
end

local function IsSubFeatureEnabled(parentKey, subKey, default)
	local db = AwakeningRaidToolsDB
	if db and db.encounters and db.encounters[3183] then
		local val = db.encounters[3183][parentKey .. "_" .. subKey]
		if val ~= nil then return val end
	end
	return default ~= false
end

-- ============================================================
-- Particle Density
-- ============================================================

local savedCVars = {}
local cvarsRestored = false

local function SaveCVars()
	wipe(savedCVars)
	local particle = C_CVar.GetCVar("graphicsParticleDensity")
	if particle ~= nil then savedCVars.particle = particle end
	local raidParticle = C_CVar.GetCVar("RaidGraphicsParticleDensity")
	if raidParticle ~= nil then savedCVars.raidParticle = raidParticle end
	addon:Dbg("MF", ("CVar save: particle=%s raid=%s"):format(
		tostring(savedCVars.particle), tostring(savedCVars.raidParticle)))
end

local function DisableParticleCVars()
	addon:Dbg("MF", "CVar disable: particle=0 raid=0")
	C_CVar.SetCVar("graphicsParticleDensity", "0")
	C_CVar.SetCVar("RaidGraphicsParticleDensity", "0")
end

local function RestoreCVars()
	addon:Dbg("MF", ("CVar restore called: restored=%s saved=(%s,%s)"):format(
		tostring(cvarsRestored), tostring(savedCVars.particle), tostring(savedCVars.raidParticle)))
	if cvarsRestored then return end
	cvarsRestored = true
	if savedCVars.particle then
		addon:Dbg("MF", ("CVar restore particle -> %s"):format(savedCVars.particle))
		C_CVar.SetCVar("graphicsParticleDensity", savedCVars.particle)
	end
	if savedCVars.raidParticle then
		addon:Dbg("MF", ("CVar restore raid -> %s"):format(savedCVars.raidParticle))
		C_CVar.SetCVar("RaidGraphicsParticleDensity", savedCVars.raidParticle)
	end
	wipe(savedCVars)
end

-- ============================================================
-- Focus Interrupt Counter (P1 only)
-- ============================================================

local BOSS_TOKENS = {"boss2", "boss3", "boss4", "boss5"}
local RESET_TIMEOUT = 30

local trackCounts = {}
local focusCount = 0
local hasFocus = false
local isInitialized = false
local counterActive = false

local resetTimer = nil
local counterEventFrame = nil

-- Layer 1: basic helpers (no local deps)
local function IsBossToken(unit)
	for _, token in ipairs(BOSS_TOKENS) do
		if unit == token then return true end
	end
	return false
end

local function CounterReset()
	wipe(trackCounts)
	focusCount = 0
	isInitialized = false
	if resetTimer then resetTimer:Cancel(); resetTimer = nil end
end

-- Layer 2: functions that depend on Layer 1
local function CounterFullReset()
	CounterReset()
	hasFocus = false
	local counter = addon.modules["Common.Counter"]
	if counter then counter:Hide() end
	local castBar = addon.modules["Common.CastBar"]
	if castBar then castBar:Hide() end
end

local function CounterStop()
	addon:Dbg("MF", "counter: stop (phase change)")
	if counterEventFrame then
		counterEventFrame:UnregisterEvent("UNIT_SPELLCAST_START")
		counterEventFrame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		counterEventFrame:UnregisterEvent("UNIT_SPELLCAST_STOP")
		counterEventFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		counterEventFrame:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		counterEventFrame:UnregisterEvent("UNIT_DIED")
	end
	CounterFullReset()
	counterActive = false
end

local function StartResetTimer()
	if resetTimer then resetTimer:Cancel() end
	resetTimer = C_Timer.NewTimer(RESET_TIMEOUT, function()
		addon:Dbg("MF", "counter: timeout reset")
		CounterReset()
		hasFocus = false
	end)
end

local function InitTracking()
	for _, token in ipairs(BOSS_TOKENS) do
		if trackCounts[token] == nil then trackCounts[token] = 0 end
	end
	isInitialized = true
	StartResetTimer()
end

local function TrySetFocus()
	local focusUnit = nil
	for i = 1, 5 do
		local token = "boss" .. i
		if UnitExists(token) and UnitIsUnit(token, "focus") then
			focusUnit = token; break
		end
	end
	if not focusUnit or not IsBossToken(focusUnit) then return false end
	focusCount = trackCounts[focusUnit] or 0
	addon:Dbg("MF", ("focus set: token=%s count=%d"):format(focusUnit, focusCount))
	hasFocus = true
	return true
end

-- Layer 3: Display & event handler (depends on Layers 1-2 + modules)
local function DisplayCounter(count)
	local counter = addon.modules["Common.Counter"]
	if not counter then return end

	if IsSubFeatureEnabled("focusInterruptCounter", "nameplate", true) then
		local np = C_NamePlate.GetNamePlateForUnit("focus")
		addon:Dbg("MF", ("np=%s"):format(tostring(np)))
		if np then
			counter:SetAnchor("np", np, "CENTER", "CENTER", 0, 42)
			counter:Show("np", count)
		end
	end
	if IsSubFeatureEnabled("focusInterruptCounter", "focusFrame", false) then
		if _G.ExFocusCastAnchor and _G.ExFocusCastAnchor:IsShown() then
			counter:SetAnchor("ff", _G.ExFocusCastAnchor, "RIGHT", "LEFT", -6, 0)
			counter:Show("ff", count)
		elseif FocusFrameSpellBar then
			counter:SetAnchor("ff", FocusFrameSpellBar, "LEFT", "LEFT", -56, 0)
			counter:Show("ff", count)
		end
	end
	if IsSubFeatureEnabled("focusInterruptCounter", "centerScreen", false) then
		local castBar = addon.modules["Common.CastBar"]
		if castBar then
			castBar:SetAnchor(UIParent, "CENTER", "CENTER", 0, 200)
			castBar:Show("focus")
			local icon = castBar:GetIconFrame()
			if icon then
				counter:SetAnchor("center", icon, "RIGHT", "LEFT", -8, 0)
			end
		end
		counter:Show("center", count, 1.5)
	end
end

local function CounterOnEvent(_, event, unit)
	if not counterActive then return end
	if event == "UNIT_SPELLCAST_START" then
		if issecretvalue(unit) or not IsBossToken(unit) then return end
		addon:Dbg("MF", ("START %s hasF=%s fc=%d"):format(unit, tostring(hasFocus), focusCount))
		if not hasFocus then
			if not isInitialized then InitTracking(); TrySetFocus() end
			if not hasFocus then return end
		end
		if UnitIsUnit(unit, "focus") then
			DisplayCounter(focusCount + 1)

		end
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		if issecretvalue(unit) or not IsBossToken(unit) then return end
		addon:Dbg("MF", ("INTR %s hasF=%s fc=%d"):format(unit, tostring(hasFocus), focusCount))
		if not hasFocus then
			if not issecretvalue(unit) then
				trackCounts[unit] = (trackCounts[unit] or 0) + 1
			end
		elseif not issecretvalue(unit) and UnitIsUnit(unit, "focus") then
			focusCount = focusCount + 1
		end
		if resetTimer then resetTimer:Cancel() end
		StartResetTimer()
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if hasFocus and not issecretvalue(unit) and UnitIsUnit(unit, "focus") then
			local counter = addon.modules["Common.Counter"]
			if counter then counter:Hide() end
			local castBar = addon.modules["Common.CastBar"]
			if castBar then castBar:Hide() end
		end
	elseif event == "PLAYER_FOCUS_CHANGED" then
		if not GetUnitName("focus", true) then
			CounterFullReset(); hasFocus = false; return
		end
		if hasFocus then CounterFullReset(); hasFocus = false; focusCount = 0 end
		TrySetFocus()
		if hasFocus and (UnitCastingInfo("focus") or UnitChannelInfo("focus")) then
			DisplayCounter(focusCount + 1)
		end
	elseif event == "UNIT_DIED" then
		addon:Dbg("MF", ("DIED: %s hasF=%s"):format(tostring(unit), tostring(hasFocus)))
		if not UnitExists("boss2") then
			CounterFullReset(); return
		end
		if not issecretvalue(unit) and IsBossToken(unit) then trackCounts[unit] = 0 end
		if hasFocus and not issecretvalue(unit) and UnitIsUnit(unit, "focus") then
			CounterFullReset(); hasFocus = false; focusCount = 0
		end
	end
end

-- Layer 4: module lifecycle (depends on all above)
local function CounterStart()
	addon:Dbg("MF", "counter: start")
	if not counterEventFrame then
		counterEventFrame = CreateFrame("Frame")
		counterEventFrame:SetScript("OnEvent", CounterOnEvent)
	end
	counterEventFrame:RegisterEvent("UNIT_SPELLCAST_START")
	counterEventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	counterEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
	counterEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	counterEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	counterEventFrame:RegisterEvent("UNIT_DIED")
	CounterFullReset()
	counterActive = true
end

-- ============================================================
-- Encounter lifecycle
-- ============================================================

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
			addon:Dbg("MF", ("phase: %d -> %d"):format((newPhase - 1), newPhase))
			if newPhase >= 2 and IsBossFeatureEnabled("focusInterruptCounter") then
				CounterStop()
			end
			if newPhase >= 3 and IsBossFeatureEnabled("particleDensity") then
				RestoreCVars()
			end
		end)
	end

	if IsBossFeatureEnabled("particleDensity") then
		cvarsRestored = false
		SaveCVars()
		DisableParticleCVars()
	end

	if IsBossFeatureEnabled("focusInterruptCounter") then
		CounterStart()
	end
end

function Boss:OnMythicEncounterEnd()
	self.isActive = false
	RestoreCVars()
	if counterActive then CounterStop() end
end

addon:RegisterModule("Raids.MarchOfQuelDanas.MidnightFalls", Boss)
