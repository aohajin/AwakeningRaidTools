local _, addon = ...

local PhaseTracker = {}
PhaseTracker.name = "PhaseTracker"

local PHASE_SWAP_COOLDOWN = 2.0
local TOLERANCE = 0.2

local configs = {}
local lastSwapTimestamp = 0
local stageListenerInitialized = false

local function ApproximatelyEqual(a, b, tolerance)
	return math.abs(a - b) <= (tolerance or TOLERANCE)
end

-- Shared callback dispatcher
local function FirePhaseCallbacks(cfg, encounterID, newPhase, prevPhase)
	cfg.currentPhase = newPhase
	for _, cb in ipairs(cfg.callbacks) do
		local ok, err = pcall(cb, encounterID, newPhase, prevPhase)
		if not ok then
			print(("ART: PhaseTracker callback error for encounter %d: %s"):format(encounterID, tostring(err)))
		end
	end
end

-- ============================================================
-- Stage-based phase detection (DBM / BigWigs)
-- ============================================================

local function HandleStageEvent(encounterID, newStage)
	local cfg = configs[encounterID]
	if not cfg or not cfg.stages then return end
	if not cfg.stages[newStage] then return end

	local prevPhase = cfg.currentPhase
	if newStage == prevPhase then return end

	local now = GetTime()
	if now - lastSwapTimestamp < PHASE_SWAP_COOLDOWN then return end
	lastSwapTimestamp = now

	addon:Dbg("PhaseTracker", ("stage: %d -> %d (encounter %d)"):format(prevPhase, newStage, encounterID))
	FirePhaseCallbacks(cfg, encounterID, newStage, prevPhase)
end

local function InitStageListener()
	if stageListenerInitialized then return end
	stageListenerInitialized = true

	-- BigWigs: SendMessage("BigWigs_SetStage", module, stage)
	if BigWigs and BigWigs.RegisterMessage then
		local frame = CreateFrame("Frame")
		BigWigs.RegisterMessage(frame, "BigWigs_SetStage", function(_, module, stage)
			if not stage or stage < 1 then return end
			for encounterID, cfg in pairs(configs) do
				if cfg.stages and module and module.IsEncounterID and module:IsEncounterID(encounterID) then
					HandleStageEvent(encounterID, stage)
					return
				end
			end
		end)
		addon:Dbg("PhaseTracker", "BigWigs stage listener registered")
	end

	-- DBM: FireEvent("DBM_SetStage", mod, modId, stage, encounterId, stageTotal)
	if DBM and DBM.RegisterCallback then
		local frame = CreateFrame("Frame")
		DBM.RegisterCallback(frame, "DBM_SetStage", function(event, mod, modId, stage, encounterId)
			if not stage or stage < 1 then return end
			if encounterId and configs[encounterId] and configs[encounterId].stages then
				HandleStageEvent(encounterId, stage)
			end
		end)
		addon:Dbg("PhaseTracker", "DBM stage listener registered")
	end
end

-- ============================================================
-- Public API
-- ============================================================

---
-- @param config.transitions (optional) { {atDuration, phase}, ... } — timeline-based
-- @param config.stages      (optional) { 2, 3, ... } — boss-mod stage-based
function PhaseTracker:RegisterPhaseConfig(encounterID, config)
	if not encounterID or type(config) ~= "table" then
		return
	end

	local cfg = {
		callbacks = {},
		currentPhase = 1,
	}

	-- Timeline-based transitions (ENCOUNTER_TIMELINE_EVENT_ADDED, backward-compatible)
	if config.transitions then
		local sorted = {}
		for _, t in ipairs(config.transitions) do
			sorted[#sorted + 1] = {
				atDuration = t.atDuration,
				phase = t.phase,
				matched = false,
			}
		end
		table.sort(sorted, function(a, b) return a.atDuration < b.atDuration end)
		cfg.transitions = sorted
	end

	-- Boss-mod stage-based detection
	if config.stages then
		cfg.stages = {}
		for _, s in ipairs(config.stages) do
			cfg.stages[s] = true
		end
		InitStageListener()
	end

	configs[encounterID] = cfg
end

function PhaseTracker:RegisterPhaseCallback(encounterID, callback)
	local cfg = configs[encounterID]
	if not cfg or type(callback) ~= "function" then
		return
	end
	cfg.callbacks[#cfg.callbacks + 1] = callback
end

function PhaseTracker:OnEncounterStart(encounterID)
	local cfg = configs[encounterID]
	if cfg then
		cfg.currentPhase = 1
		if cfg.transitions then
			for _, t in ipairs(cfg.transitions) do
				t.matched = false
			end
		end
	end
	lastSwapTimestamp = 0
end

function PhaseTracker:OnEncounterEnd(encounterID)
	if configs[encounterID] then
		configs[encounterID].callbacks = {}
		configs[encounterID].currentPhase = nil
	end
end

function PhaseTracker:HandleTimelineEvent(encounterID, duration)
	local cfg = configs[encounterID]
	if not cfg or not cfg.transitions then
		return
	end

	local now = GetTime()
	if now - lastSwapTimestamp < PHASE_SWAP_COOLDOWN then
		return
	end

	for _, t in ipairs(cfg.transitions) do
		if not t.matched and ApproximatelyEqual(duration, t.atDuration) then
			local prevPhase = cfg.currentPhase
			t.matched = true
			lastSwapTimestamp = now

			FirePhaseCallbacks(cfg, encounterID, t.phase, prevPhase)
			return
		end
	end
end

function PhaseTracker:GetCurrentPhase(encounterID)
	local cfg = configs[encounterID]
	return cfg and cfg.currentPhase or 1
end

addon:RegisterModule("Common.PhaseTracker", PhaseTracker)
