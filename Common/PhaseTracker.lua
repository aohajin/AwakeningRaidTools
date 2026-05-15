local _, addon = ...

local PhaseTracker = {}
PhaseTracker.name = "PhaseTracker"

local PHASE_SWAP_COOLDOWN = 5.0
local TOLERANCE = 0.2

local configs = {}
local lastSwapTimestamp = 0

local function ApproximatelyEqual(a, b, tolerance)
	return math.abs(a - b) <= (tolerance or TOLERANCE)
end

function PhaseTracker:RegisterPhaseConfig(encounterID, config)
	if not encounterID or type(config) ~= "table" then
		return
	end

	local sorted = {}
	for _, t in ipairs(config.transitions or {}) do
		sorted[#sorted + 1] = {
			atDuration = t.atDuration,
			phase = t.phase,
			matched = false,
		}
	end
	table.sort(sorted, function(a, b) return a.atDuration < b.atDuration end)

	configs[encounterID] = {
		transitions = sorted,
		callbacks = {},
		currentPhase = 1,
	}
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
		for _, t in ipairs(cfg.transitions) do
			t.matched = false
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
			cfg.currentPhase = t.phase
			t.matched = true
			lastSwapTimestamp = now

			for _, cb in ipairs(cfg.callbacks) do
				local ok, err = pcall(cb, encounterID, t.phase, prevPhase)
				if not ok then
					print(("ART: PhaseTracker callback error for encounter %d: %s"):format(encounterID, tostring(err)))
				end
			end
			return
		end
	end
end

function PhaseTracker:GetCurrentPhase(encounterID)
	local cfg = configs[encounterID]
	return cfg and cfg.currentPhase or 1
end

addon:RegisterModule("Common.PhaseTracker", PhaseTracker)
