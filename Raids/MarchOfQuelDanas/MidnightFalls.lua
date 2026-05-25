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
		focusInterruptCounter = {
			type = "toggle",
			default = true,
			labelKey = "OPTIONS_FOCUS_INTERRUPT_COUNTER",
			descKey  = "OPTIONS_FOCUS_INTERRUPT_COUNTER_DESC",
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
local markerFrame = nil

local function CounterReset()
	wipe(trackCounts)
	focusCount = 0
	isInitialized = false
	if resetTimer then resetTimer:Cancel(); resetTimer = nil end
end

local function CounterFullReset()
	CounterReset()
	hasFocus = false
	if markerFrame then markerFrame:Hide() end
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

local function EnsureMarker()
	if not markerFrame then
		local holder = CreateFrame("Frame", nil, UIParent)
		holder:SetSize(52, 52)
		holder:SetFrameStrata("TOOLTIP")
		local bg = holder:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.1, 0.75, 0.2, 0.95)
		local label = holder:CreateFontString(nil, "OVERLAY")
		label:SetFont(STANDARD_TEXT_FONT, 28, "OUTLINE")
		label:SetPoint("CENTER", holder, "CENTER", 0, 0)
		label:SetTextColor(1, 1, 1, 1)
		holder.bg = bg
		holder.label = label
		markerFrame = holder
	end
	return markerFrame
end

local function ShowMarker(count)
	addon:Dbg("MF", ("ShowMarker count=%d"):format(count))
	local namePlate = C_NamePlate.GetNamePlateForUnit("focus")
	if not namePlate then return end
	local marker = EnsureMarker()
	marker:ClearAllPoints()
	marker:SetPoint("CENTER", namePlate, "CENTER", 0, 42)
	marker.label:SetText(tostring(count))
	marker:Show()
end

local function HideMarker()
	if markerFrame then markerFrame:Hide() end
end

local function IsBossToken(unit)
	for _, token in ipairs(BOSS_TOKENS) do
		if unit == token then return true end
	end
	return false
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

local function CounterOnEvent(_, event, unit)
	if not counterActive then return end
	if issecretvalue(unit) then return end

	if event == "UNIT_SPELLCAST_START" then
		if not IsBossToken(unit) then return end
		addon:Dbg("MF", ("START %s hasF=%s init=%s fc=%d"):format(unit, tostring(hasFocus), tostring(isInitialized), focusCount))
		if not hasFocus then
			if not isInitialized then
				InitTracking()
				if GetUnitName("focus", true) then TrySetFocus() end
			end
			if not hasFocus then return end
		end
		if UnitIsUnit(unit, "focus") then
			ShowMarker(focusCount + 1)
		end
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		if not IsBossToken(unit) then return end
		addon:Dbg("MF", ("INTR %s hasF=%s fc=%d"):format(unit, tostring(hasFocus), focusCount))
		if not hasFocus then
			trackCounts[unit] = (trackCounts[unit] or 0) + 1
		elseif UnitIsUnit(unit, "focus") then
			focusCount = focusCount + 1
		end
		if resetTimer then resetTimer:Cancel() end
		StartResetTimer()
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if hasFocus and UnitIsUnit(unit, "focus") then
			HideMarker()
		end
	elseif event == "PLAYER_FOCUS_CHANGED" then
		if not GetUnitName("focus", true) then
			HideMarker(); hasFocus = false; return
		end
		if hasFocus then
			HideMarker(); hasFocus = false; focusCount = 0
		end
		TrySetFocus()
	elseif event == "UNIT_DIED" then
		addon:Dbg("MF", ("DIED: %s hasF=%s"):format(tostring(unit), tostring(hasFocus)))
		if not UnitExists("boss2") then
			HideMarker()
			CounterFullReset()
			return
		end
		if IsBossToken(unit) then trackCounts[unit] = 0 end
		if hasFocus and UnitIsUnit(unit, "focus") then
			HideMarker(); hasFocus = false; focusCount = 0
		end
	end
end

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
	StartResetTimer()
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
	if counterActive then
		CounterStop()
	end
end

addon:RegisterModule("Raids.MarchOfQuelDanas.MidnightFalls", Boss)
