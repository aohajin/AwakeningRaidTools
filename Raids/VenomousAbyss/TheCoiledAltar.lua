local _, addon = ...

-- Boss 7: The Coiled Altar (Zul'jan + Malacrass)
-- The spirit of Malacrass will not release his grip on Zul'jan so easily. At
-- the Coiled Altar, the shaman commands the warrior to enact the final ritual
-- to unleash Ula'tek on the Amani -- for revenge, and to gain their promised reward.
--
-- Interrupt tracker: both boss3 and boss4 cast, but the count is only shown
-- for the one the player has set as FOCUS (Lura behaviour). The Art (Lura) cast
-- bar likewise tracks only the focus target.

local Boss = {
    name = "TheCoiledAltar",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3429,
    journalEncounterId = 2883, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        interruptCounter = {
            type = "toggle",
            default = true,
            labelKey = "OPTIONS_COILEDALTAR_INTERRUPT_COUNTER",
            descKey  = "OPTIONS_COILEDALTAR_INTERRUPT_COUNTER_DESC",
            subFeatures = {
                {
                    type = "toggle",
                    key = "nameplate",
                    default = true,
                    labelKey = "OPTIONS_COILEDALTAR_INTERRUPT_NAMEPLATE",
                    descKey  = "OPTIONS_COILEDALTAR_INTERRUPT_NAMEPLATE_DESC",
                },
                {
                    type = "toggle",
                    key = "castBar",
                    default = false,
                    labelKey = "OPTIONS_COILEDALTAR_INTERRUPT_CASTBAR",
                    descKey  = "OPTIONS_COILEDALTAR_INTERRUPT_CASTBAR_DESC",
                },
                {
                    type = "toggle",
                    key = "focusFrame",
                    default = false,
                    labelKey = "OPTIONS_COILEDALTAR_INTERRUPT_FOCUSFRAME",
                    descKey  = "OPTIONS_COILEDALTAR_INTERRUPT_FOCUSFRAME_DESC",
                },
            },
        },
    },
}

-- Only these bosses are tracked; the count is kept per boss and shown for
-- whichever one is focused. No timeout: a boss's count resets only when it dies
-- (or the encounter ends).
local BOSS_TOKENS = { boss3 = true, boss4 = true }

local function IsFeatureEnabled(key)
    local featureDef = Boss.features and Boss.features[key]
    local default = featureDef and featureDef.default ~= false
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[Boss.encounterId] then
        local val = db.encounters[Boss.encounterId][key]
        if val ~= nil then return val end
    end
    return default
end

local function IsSubFeatureEnabled(parentKey, subKey, default)
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[Boss.encounterId] then
        local val = db.encounters[Boss.encounterId][parentKey .. "_" .. subKey]
        if val ~= nil then return val end
    end
    return default ~= false
end

-- Unit tokens that may be passed to UnitIsUnit from tainted code.
local SAFE_UNIT_TOKENS = {
    player = true, pet = true, vehicle = true, mouseover = true,
    target = true, focus = true, none = true, npc = true, questnpc = true,
    softenemy = true, softfriend = true, softinteract = true,
    boss1 = true, boss2 = true, boss3 = true, boss4 = true, boss5 = true,
}

local function IsSafeUnitToken(unit)
    return type(unit) == "string" and SAFE_UNIT_TOKENS[unit] == true
end

local function IsBossToken(unit)
    return type(unit) == "string" and BOSS_TOKENS[unit] == true
end

local trackCounts = {} -- [unit] = successful interrupts on that boss
local hasFocus = false
local counterActive = false
local counterEventFrame

local function Counter()
    return addon.modules["Common.Counter"]
end

local function CounterReset()
    wipe(trackCounts)
end

local function CounterFullReset()
    CounterReset()
    hasFocus = false
    local counter = Counter()
    if counter then
        counter:Hide("np")
        counter:Hide("ff")
        counter:Hide("cb")
    end
    local castBar = addon.modules["Common.CastBar"]
    if castBar then castBar:Hide() end
end

-- Which of the tracked bosses the player has focused (nil if none).
local function FocusedBossToken()
    for i = 1, 5 do
        local token = "boss" .. i
        if BOSS_TOKENS[token] and UnitExists(token) and UnitIsUnit(token, "focus") then
            return token
        end
    end
    return nil
end

local function TrySetFocus()
    local token = FocusedBossToken()
    if not token then return false end
    hasFocus = true
    addon:Dbg(Boss.name, ("focus set: %s (count=%d)"):format(token, trackCounts[token] or 0))
    return true
end

-- Current count for the focused boss (kept per boss, so changing focus keeps it).
local function FocusCount()
    local token = FocusedBossToken()
    if not token then return 0 end
    return trackCounts[token] or 0
end

-- Show the count in every enabled position (all anchored to the FOCUS unit).
local function DisplayCounter(count)
    local counter = Counter()
    if not counter then return end

    if IsSubFeatureEnabled("interruptCounter", "nameplate", true) then
        local np = C_NamePlate and C_NamePlate.GetNamePlateForUnit
            and C_NamePlate.GetNamePlateForUnit("focus")
        if np then
            counter:SetAnchor("np", np, "CENTER", "CENTER", 0, 42)
            counter:Show("np", count)
        end
    end
    if IsSubFeatureEnabled("interruptCounter", "focusFrame", false) then
        local anchor = FocusFrameSpellBar or _G.FocusFrame
        if anchor then
            counter:SetAnchor("ff", anchor, "LEFT", "LEFT", -56, 0)
            counter:Show("ff", count)
        end
    end
    if IsSubFeatureEnabled("interruptCounter", "castBar", false) then
        local castBar = addon.modules["Common.CastBar"]
        if castBar then
            castBar:Show("focus")
            local icon = castBar:GetIconFrame()
            if icon then counter:SetAnchor("cb", icon, "RIGHT", "LEFT", -8, 0) end
            counter:Show("cb", count)
        end
    end
end

local function HideDisplay()
    local counter = Counter()
    if counter then
        counter:Hide("np")
        counter:Hide("ff")
        counter:Hide("cb")
    end
    local castBar = addon.modules["Common.CastBar"]
    if castBar then castBar:Hide() end
end

local function CounterOnEvent(_, event, unit)
    if not counterActive then return end

    if event == "UNIT_SPELLCAST_START" then
        if not issecretvalue(unit) and not IsBossToken(unit) then return end
        if not hasFocus and not TrySetFocus() then return end
        if IsSafeUnitToken(unit) and UnitIsUnit(unit, "focus") then
            DisplayCounter(FocusCount() + 1)
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        if not issecretvalue(unit) and not IsBossToken(unit) then return end
        if IsSafeUnitToken(unit) and BOSS_TOKENS[unit] then
            trackCounts[unit] = (trackCounts[unit] or 0) + 1
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if hasFocus and IsSafeUnitToken(unit) and UnitIsUnit(unit, "focus") then
            HideDisplay()
        end
    elseif event == "UNIT_DIED" then
        -- The event's unit argument is a GUID, not a token: reset whichever
        -- tracked boss no longer exists (i.e. just died).
        if not issecretvalue(unit) then
            for token in pairs(BOSS_TOKENS) do
                if not UnitExists(token) then trackCounts[token] = 0 end
            end
            if not UnitExists("focus") then CounterFullReset() end
        end
    elseif event == "PLAYER_FOCUS_CHANGED" then
        if not GetUnitName("focus", true) then
            hasFocus = false
            HideDisplay()
            return
        end
        hasFocus = false
        TrySetFocus()
    end
end

local function CounterStart()
    addon:Dbg(Boss.name, "counter: start")
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
    counterActive = true
    CounterFullReset()
    TrySetFocus()
end

local function CounterStop()
    addon:Dbg(Boss.name, "counter: stop")
    if counterEventFrame then counterEventFrame:UnregisterAllEvents() end
    CounterFullReset()
    counterActive = false
end

function Boss:OnMythicEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    self.isActive = true
    addon:Dbg(self.name, "start")
    if IsFeatureEnabled("interruptCounter") then
        CounterStart()
    end
end

function Boss:OnMythicEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    self.isActive = false
    addon:Dbg(self.name, "end")
    if counterActive then CounterStop() end
end

function Boss:OnPhaseChange(newPhase, prevPhase)
    -- TODO
end

addon:RegisterModule("Raids.VenomousAbyss.TheCoiledAltar", Boss)
