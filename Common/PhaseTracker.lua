local _, addon = ...

local PhaseTracker = {}
PhaseTracker.name = "PhaseTracker"

local PHASE_SWAP_COOLDOWN = 2.0
local configs = {}
local lastSwapTimestamp = 0
local stageListenerInitialized = false

-- Wall-clock phase tickers, keyed by encounterID
local tickers = {}

-- Debug flag — set via /artptdebug
PhaseTracker.debugEnabled = false

local function DbgPrint(...)
    if PhaseTracker.debugEnabled then
        print("|cffffff00[PT]|r", ...)
    end
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
-- Wall-clock phase detection (like MRT/NSRT)
-- ============================================================

local function CheckWallClockTransitions(encounterID)
	local cfg = configs[encounterID]
	if not cfg or not cfg.transitions then return end

	local now = GetTime()
	if now - lastSwapTimestamp < PHASE_SWAP_COOLDOWN then return end

	local elapsed = now - cfg.encounterStartTime
	for _, t in ipairs(cfg.transitions) do
		if not t.matched and elapsed >= t.atDuration then
			local prevPhase = cfg.currentPhase
			t.matched = true
			lastSwapTimestamp = now

			print(("|cff00ff00ART PT|r: Phase transition! Enc %d, Phase %d -> %d (at %.1fs)"):format(
				encounterID, prevPhase or 0, t.phase, elapsed))
			FirePhaseCallbacks(cfg, encounterID, t.phase, prevPhase)
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

	print(("|cff00ff00ART PT|r: Stage change! Enc %d, Phase %d -> %d"):format(
		encounterID, prevPhase or 0, newStage))
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
			print(("|cff888888ART|r: BigWigs stage=%s"):format(tostring(stage)))
			for encounterID, cfg in pairs(configs) do
				if cfg.stages and module and module.IsEncounterID and module:IsEncounterID(encounterID) then
					HandleStageEvent(encounterID, stage)
					return
				end
			end
		end)
		DbgPrint("BigWigs stage listener registered")
	end

	-- DBM: FireEvent("DBM_SetStage", mod, modId, stage, encounterId, stageTotal)
	if DBM and DBM.RegisterCallback then
		DBM:RegisterCallback("DBM_SetStage", function(event, mod, modId, stage, encounterId, stageTotal)
			print(("|cff888888ART|r: DBM stage=%s encId=%s"):format(tostring(stage), tostring(encounterId)))
			if not stage or stage < 1 then return end
			if encounterId and configs[encounterId] and configs[encounterId].stages then
				HandleStageEvent(encounterId, stage)
			end
		end)
		DbgPrint("DBM stage listener registered")
	end
end

-- ============================================================
-- Public API
-- ============================================================

---
-- @param config.transitions (optional) { {atDuration, phase}, ... } — wall-clock phase thresholds
-- @param config.stages      (optional) { 2, 3, ... } — boss-mod stage-based
function PhaseTracker:RegisterPhaseConfig(encounterID, config)
	if not encounterID or type(config) ~= "table" then
		return
	end

	local cfg = {
		callbacks = {},
		currentPhase = 1,
		encounterStartTime = 0,
	}

	-- Wall-clock transitions (like MRT/NSRT)
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
	if not cfg then return end

	cfg.currentPhase = 1
	cfg.encounterStartTime = GetTime()
	if cfg.transitions then
		for _, t in ipairs(cfg.transitions) do
			t.matched = false
		end
		-- Start wall-clock ticker (fires every 1s)
		if tickers[encounterID] then
			tickers[encounterID]:Cancel()
		end
		tickers[encounterID] = C_Timer.NewTicker(1, function()
			CheckWallClockTransitions(encounterID)
		end)
	end
	lastSwapTimestamp = 0
end

function PhaseTracker:OnEncounterEnd(encounterID)
	if tickers[encounterID] then
		tickers[encounterID]:Cancel()
		tickers[encounterID] = nil
	end
	if configs[encounterID] then
		configs[encounterID].callbacks = {}
		configs[encounterID].currentPhase = nil
	end
end

function PhaseTracker:GetCurrentPhase(encounterID)
	local cfg = configs[encounterID]
	return cfg and cfg.currentPhase or 1
end

-- Debug API
function PhaseTracker:GetConfigs()
	return configs
end

function PhaseTracker:PrintState()
	print("|cffffff00=== ART PhaseTracker State ===|r")
	print("stageListenerInitialized:", stageListenerInitialized)
	print("BigWigs:", BigWigs ~= nil and "YES" or "NO")
	print("DBM:", DBM ~= nil and "YES" or "NO")
	print("debugEnabled:", PhaseTracker.debugEnabled)
	print("Registered configs:")
	local count = 0
	for eid, cfg in pairs(configs) do
		count = count + 1
		local stages = cfg.stages and "{" .. table.concat(
			(function() local s = {}; for k in pairs(cfg.stages) do s[#s+1]=tostring(k) end; return s end)(), ",") .. "}" or "nil"
		local transitions = cfg.transitions and ("[" .. #cfg.transitions .. " entries]") or "nil"
		print(("  enc=%d  currentPhase=%s  stages=%s  transitions=%s  callbacks=%d"):format(
			eid, tostring(cfg.currentPhase), stages, transitions, #cfg.callbacks))
	end
	if count == 0 then
		print("  (none)")
	end
	print("|cffffff00================================|r")
end

-- Manual test: simulate stage event for active encounter
function PhaseTracker:SimulateStage(stage)
	local eid = addon.activeEncounterID
	if not eid then
		print("|cffff0000ART PT|r: No active encounter! Start a Mythic encounter first.")
		return
	end
	print(("|cffffff00ART PT|r: Simulating stage %d for encounter %d"):format(stage, eid))
	HandleStageEvent(eid, stage)
end

addon:RegisterModule("Common.PhaseTracker", PhaseTracker)
