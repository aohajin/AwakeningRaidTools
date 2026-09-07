local _, addon = ...

-- Boss 5: Sszorak
-- A horrifying creature, warped by Ula'tek's toxic venom, Sszorak is a brutal
-- instrument of vengeance. Calling upon the winds that howl deep within Atal'Utek,
-- it tears apart any living creature it encounters.

local Boss = {
    name = "Sszorak",
    -- DungeonEncounterID (ENCOUNTER_START)
    encounterId = 3420,
    journalEncounterId = 2871, -- Encounter Journal ID (EJ_GetEncounterInfo)
    mythicOnly = true,
    features = {
        virulenceDirectionSound = {
            type = "toggle",
            default = true,
            labelKey = "OPTIONS_SSZORAK_VIRULENCE_DIRECTION",
            descKey  = "OPTIONS_SSZORAK_VIRULENCE_DIRECTION_DESC",
        },
        compass = {
            type = "toggle",
            default = false,
            labelKey = "OPTIONS_SSZORAK_COMPASS",
            descKey  = "OPTIONS_SSZORAK_COMPASS_DESC",
            subFeatures = {
                {
                    type = "button",
                    key = "preview",
                    labelKey = "OPTIONS_SSZORAK_COMPASS_PREVIEW",
                    onClick = function()
                        local boss = addon.modules["Raids.VenomousAbyss.Sszorak"]
                        if boss then
                            boss:ToggleCompassPreview()
                        end
                    end,
                },
                {
                    type = "toggle",
                    key = "windCall",
                    labelKey = "OPTIONS_SSZORAK_COMPASS_WINDCALL",
                    descKey  = "OPTIONS_SSZORAK_COMPASS_WINDCALL_DESC",
                    default = false,
                },
            },
        },
    },
}

local function IsFeatureEnabled(key)
    -- Default comes from the feature definition (compass default false), so a
    -- player who never opened the options panel is NOT force-enabled.
    local featureDef = Boss.features and Boss.features[key]
    local default = featureDef and featureDef.default ~= false
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[Boss.encounterId] then
        local val = db.encounters[Boss.encounterId][key]
        if val ~= nil then return val end
    end
    return default
end

-- ============================================================================
-- Virulence direction voice (mythic-only mechanic).
--
-- Virulence (剧毒) exists as two spell IDs: 1297707 and 1299899. The two
-- variants are visually identical (same name/icon) but launch their poison in
-- different directions on expiry. During mythic race (always in effect for
-- mythic raid) the aura spellID is a secret value, so addon Lua cannot
-- distinguish them directly. Instead we use C_UnitAuras.AddAuraSound: we pass
-- the known spellID constants and the client matches the (secret) aura
-- internally, playing the bound sound when the debuff is gained. This is the
-- same approach DBM uses (DBM-Raids-Midnight/TheVenomousAbyss/Sszorak.lua)
-- and is the sanctioned way to trigger sounds from auras without touching
-- secret values.
--
-- Sound keys are logical (see addon.voiceSounds in Core/Bootstrap.lua):
--   go_left  -> 1299899 launches poison to the LEFT
--   go_right -> 1297707 launches poison to the RIGHT (per encounter testing)
-- ============================================================================

local MEDIA_PREFIX = "Interface\\AddOns\\" .. (addon.name or "AwakeningRaidTools") .. "\\media\\"
local VOICEPACK_BASE_DIR = MEDIA_PREFIX .. "VoicePacks\\"

-- Resolve the full path for a logical voice key under the selected pack:
--   Media\VoicePacks\<pack>\<key>.ogg
-- The pack is the saved selection if it is still in addon.voicePacks,
-- otherwise the default pack (Aloy). If the selected pack directory was
-- removed, AddAuraSound silently ignores the missing file at registration,
-- so a stale selection degrades to silence rather than erroring.
local function ResolvePackName()
    local db = AwakeningRaidToolsDB
    local saved = db and db.VoicePack
    local packs = addon.voicePacks or {}
    for _, name in ipairs(packs) do
        if name == saved then return saved end
    end
    return addon.voicePackDefault or (packs[1]) or "Aloy"
end

local function ResolveSoundPath(voiceKey)
    return VOICEPACK_BASE_DIR .. ResolvePackName() .. "\\" .. voiceKey .. ".ogg"
end

-- UnitAuraSoundTrigger.Added == 0
local TRIGGER_ADDED = Enum and Enum.UnitAuraSoundTrigger and Enum.UnitAuraSoundTrigger.Added or 0

local VIRULENCE_VARIANTS = {
    { spellId = 1297707, voiceKey = "go_right" },
    { spellId = 1299899, voiceKey = "go_left" },
}

local function BuildVariantList()
    local list = {}
    for _, variant in ipairs(VIRULENCE_VARIANTS) do
        list[#list + 1] = {
            spellId = variant.spellId,
            soundFileName = ResolveSoundPath(variant.voiceKey),
        }
    end
    return list
end

local auraSoundIDs = {} -- spellId -> auraSoundID

local function AuraSoundApiAvailable()
    return C_UnitAuras
        and type(C_UnitAuras.AddAuraSound) == "function"
        and type(C_UnitAuras.RemoveAuraSound) == "function"
end

local function RegisterVariant(variant)
    local spellId = variant.spellId
    local soundInfo = {
        spellID = spellId,
        unitToken = "player",
        outputChannel = "Master",
        soundFileName = variant.soundFileName,
    }
    local ok, auraSoundID = pcall(C_UnitAuras.AddAuraSound, TRIGGER_ADDED, soundInfo)
    if ok and type(auraSoundID) == "number" then
        auraSoundIDs[spellId] = auraSoundID
        addon:Dbg(Boss.name, ("aura sound registered: spellId=%d id=%s file=%s"):format(
            spellId, tostring(auraSoundID), variant.soundFileName))
        return true
    end
    addon:Dbg(Boss.name, ("aura sound FAILED: spellId=%d err=%s"):format(
        spellId, tostring(ok and auraSoundID or "pcall failed")))
    return false
end

local function UnregisterAll()
    if not auraSoundIDs or next(auraSoundIDs) == nil then
        return
    end
    for spellId, auraSoundID in pairs(auraSoundIDs) do
        if C_UnitAuras and type(C_UnitAuras.RemoveAuraSound) == "function" then
            pcall(C_UnitAuras.RemoveAuraSound, auraSoundID)
        end
        addon:Dbg(Boss.name, ("aura sound removed: spellId=%d"):format(spellId))
    end
    wipe(auraSoundIDs)
end

local function RegisterAll()
    if not AuraSoundApiAvailable() then
        addon:Dbg(Boss.name, "aura sound API unavailable, skipping")
        return false
    end
    local inCombat = InCombatLockdown()
    if next(auraSoundIDs) ~= nil then
        if inCombat then
            -- Keep the working pre-registration (Remove may succeed while a
            -- follow-up Add is rejected in lockdown).
            addon:Dbg(Boss.name, "already registered, in combat; keeping")
            return true
        end
        -- Out of combat with existing bindings: rebuild for idempotency.
        UnregisterAll()
    end
    local registered = 0
    for _, variant in ipairs(BuildVariantList()) do
        if RegisterVariant(variant) then
            registered = registered + 1
        end
    end
    return registered > 0
end

-- Register the aura sounds up-front (login / module init, i.e. OUT of combat):
-- AddAuraSound is rejected by the client when called during combat lockdown
-- (verified by CCAlarm and EllesmereUI implementations), so registering in
-- OnMythicEncounterStart alone would silently fail for many users. We
-- pre-register here, re-register on encounter start as a fallback, and
-- unregister at encounter end. If we are still locked down at init (a /reload
-- during combat), defer once until the player leaves combat.
local regenFrame, regenScheduled = nil, false

-- Defer registration until the player leaves combat. We cannot register
-- events during lockdown (ADDON_ACTION_FORBIDDEN), so poll with OnUpdate —
-- the same approach as Core/Bootstrap.lua RegisterSafeEvents.
local function CancelRegenRetry()
    if regenFrame then
        regenFrame:SetScript("OnUpdate", nil)
        regenFrame:Hide()
    end
    regenScheduled = false
end

local function ScheduleRegenRetry()
    if regenScheduled then return end
    regenScheduled = true
    if not regenFrame then
        regenFrame = CreateFrame("Frame")
        regenFrame:Hide()
    end
    regenFrame:SetScript("OnUpdate", function(self, elapsed)
        if InCombatLockdown() then return end
        self:SetScript("OnUpdate", nil)
        self:Hide()
        regenScheduled = false
        if IsFeatureEnabled("virulenceDirectionSound") then
            RegisterAll()
        end
    end)
    regenFrame:Show()
end


-- ============================================================================

local WIND_CALL_PREFIX = "raid_target_"
local WIND_AMP_TIMES = { 100, 227.1, 354.2 } -- mythic Dig In (damage amp) times
local WIND_CLEAR_AFTER = 20

-- Marker opposite another (rt1<->4, rt2<->5, rt3<->6).
local function OppositeMarker(marker)
    return ((marker + 2) % 6) + 1
end

local chatFrame = nil
local recentCalls = {} -- ordered list of marker numbers (1..6), newest last
local ampClearTimers = {}

local function IsWindCallEnabled()
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[Boss.encounterId] then
        return db.encounters[Boss.encounterId].compass_windCall == true
    end
    return false -- default off
end

-- Parse a raid chat message; returns marker number 1..6 or nil.
local function ParseWindCall(message)
    if type(message) ~= "string" then return nil end
    -- Strict: whole trimmed message must be raid_target_N, N in 1..6
    -- (pattern also rejects leading zeros like "raid_target_01").
    local n = tonumber(message:match("^%s*raid_target_([1-6])%s*$"))
    return n
end

local function RefreshPulses()
    local compass = addon.modules["Common.FacingCompass"]
    if not compass then return end
    -- Opposite targets in call order (表: 1 2 3 / 对侧 rt).
    local oppositeList = {}
    for _, marker in ipairs(recentCalls) do
        oppositeList[#oppositeList + 1] = OppositeMarker(marker)
    end
    if compass.ShowWindTable then
        compass:ShowWindTable(oppositeList)
    end
    -- Keep the on-disc pulses too (visual on the compass itself).
    if compass.ShowCalls then
        local calls = {}
        for _, marker in ipairs(recentCalls) do
            calls[#calls + 1] = { marker = marker }
        end
        compass:ShowCalls(calls)
    end
end

local function OnWindCall(marker)
    -- Dedupe: remove existing entry, append as newest.
    for i = #recentCalls, 1, -1 do
        if recentCalls[i] == marker then
            table.remove(recentCalls, i)
            break
        end
    end
    recentCalls[#recentCalls + 1] = marker
    while #recentCalls > 3 do
        table.remove(recentCalls, 1) -- drop oldest
    end
    addon:Dbg(Boss.name, ("wind call: marker=%d recent=%s"):format(
        marker, table.concat(recentCalls, ",")))
    RefreshPulses()
end

local function ClearAllCalls()
    wipe(recentCalls)
    local compass = addon.modules["Common.FacingCompass"]
    if compass and compass.ClearCalls then compass:ClearCalls() end
    if compass and compass.SetOrderText then compass:SetOrderText("") end
end

local function ChatHandler(self, event, message, sender, _, _, _, _, _, _, _, _, _, guid)
    -- Leaving combat clears the wind marks (covers wipes / encounter reset
    -- where ENCOUNTER_END may not fire cleanly).
    if event == "PLAYER_REGEN_ENABLED" then
        local boss = addon.modules["Raids.VenomousAbyss.Sszorak"]
        if boss and (boss.isActive or boss._windPreview) then
            ClearAllCalls()
        end
        return
    end
    local boss = addon.modules["Raids.VenomousAbyss.Sszorak"]
    -- Active in combat OR in compass wind-call preview.
    if not boss or not (boss.isActive or boss._windPreview) then return end
    -- Listening is the compass's default behaviour (no windCall toggle needed):
    -- any client with the compass feature on hears wind calls.
    local compass = addon.modules["Common.FacingCompass"]
    if not compass or not compass:IsActive() then return end
    local marker = ParseWindCall(message)
    if marker then
        addon:Dbg(Boss.name, ("chat %s from %s: %s -> marker %d"):format(
            event, tostring(sender), tostring(message), marker))
        OnWindCall(marker)
    end
end

-- Register the raid chat listener at login (out of combat; RegisterEvent is
-- forbidden in combat lockdown). If we are mid-combat at init (a /reload
-- during combat) we cannot register now, but a fresh login is out of combat
-- and covers the normal case; the handler checks boss.isActive anyway.
local function StartWindListening()
    if chatFrame then return chatFrame end
    if InCombatLockdown() then
        addon:Dbg(Boss.name, "in combat at init; chat listener deferred to next login")
        return nil
    end
    chatFrame = CreateFrame("Frame")
    chatFrame:RegisterEvent("CHAT_MSG_RAID")
    chatFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    chatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    chatFrame:SetScript("OnEvent", ChatHandler)
    return chatFrame
end

-- Broadcast a marker call on the raid channel (sender buttons). In a group we
-- send and rely on receiving our own message to mark (matches combat). Outside
-- a group (solo preview) we mark locally so preview behaves like combat.
-- SendChatMessage is allowed in combat (raid calls are common mid-fight).
local function SendWindCall(marker)
    local text = WIND_CALL_PREFIX .. marker
    if IsInRaid() then
        SendChatMessage(text, "RAID")
    elseif IsInGroup() then
        SendChatMessage(text, "PARTY")
    else
        -- Solo preview: no channel to echo back; mark directly.
        OnWindCall(marker)
    end
end

-- Schedule clears at each damage-amp + clear-after (relative to encounter
-- start: 100/227.1/354.2 + 20s).
local function ScheduleAmpClears()
    for _, timer in ipairs(ampClearTimers) do
        if timer.Cancel then timer:Cancel() end
    end
    wipe(ampClearTimers)
    local boss = addon.modules["Raids.VenomousAbyss.Sszorak"]
    local base = boss and boss.startTime or GetTime()
    for _, t in ipairs(WIND_AMP_TIMES) do
        local clearAt = t + WIND_CLEAR_AFTER
        local remaining = clearAt - (GetTime() - base)
        if remaining > 0 then
            ampClearTimers[#ampClearTimers + 1] = C_Timer.After(remaining, ClearAllCalls)
        end
    end
end


function Boss:OnInitialize()
    -- Wind-call chat listener (registered out of combat at login).
    StartWindListening()
    local compass = addon.modules["Common.FacingCompass"]
    if compass and compass.SetOnMarkerClicked then
        compass:SetOnMarkerClicked(function(marker)
            SendWindCall(marker)
        end)
    end

    if not IsFeatureEnabled("virulenceDirectionSound") then return end
    if InCombatLockdown() then
        -- /reload happened mid-combat; register once combat ends.
        addon:Dbg(Boss.name, "in combat at init; deferring aura sound register")
        ScheduleRegenRetry()
        return
    end
    RegisterAll()
end

function Boss:ToggleCompassPreview()
    if InCombatLockdown() then
        print("ART: cannot preview the compass in combat")
        return
    end
    local compass = addon.modules["Common.FacingCompass"]
    if not compass then return end
    if compass:IsActive() then
        self._windPreview = nil
        compass:Disable()
        print("ART: facing compass preview off")
    else
        -- FULLSCREEN_DIALOG strata so the preview renders above the DIALOG
        -- settings panel (the panel stays open while previewing).
        compass:Enable("FULLSCREEN_DIALOG")
        -- Preview simulates an Sszorak encounter: chat calls mark markers.
        self._windPreview = true
        wipe(recentCalls)
        ClearAllCalls()
        -- Sender buttons show only when wind-call sending is enabled.
        if IsFeatureEnabled("compass") and IsWindCallEnabled() then
            compass:SetClicksEnabled(true)
        end
        print("ART: facing compass preview on (turn to see markers rotate)")
    end
end

function Boss:OnMythicEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    self.isActive = true
    self.startTime = GetTime()
    addon:Dbg(self.name, "start")
    -- Best-effort re-register (feature toggled on since login, or the
    -- pre-registration was consumed). In combat lockdown this is rejected,
    -- which is fine: OnInitialize / regen retry covered the normal paths.
    if IsFeatureEnabled("virulenceDirectionSound") then
        if InCombatLockdown() and next(auraSoundIDs) == nil then
            ScheduleRegenRetry()
        else
            RegisterAll()
        end
    end
    -- Facing compass (8-direction marker compass rotating with the player).
    if IsFeatureEnabled("compass") then
        local compass = addon.modules["Common.FacingCompass"]
        if compass and compass.Enable then
            compass:Enable()
            -- Sender buttons stay visible the whole fight when sending is on.
            if IsWindCallEnabled() then
                compass:SetClicksEnabled(true)
            end
            -- Wind-call pulses: only listen/show while compass is on.
            wipe(recentCalls)
            ScheduleAmpClears()
        end
    end
    -- Phase tracking: uncomment and fill in transitions once timings are known.
    -- local pt = addon.modules["Common.PhaseTracker"]
    -- if pt then
    --     pt:RegisterPhaseConfig(self.encounterId, { transitions = {
    --         { atDuration = 45.0, phase = 2 },
    --     }})
    --     pt:RegisterPhaseCallback(self.encounterId, function(_, newPhase, prevPhase)
    --         self:OnPhaseChange(newPhase, prevPhase)
    --     end)
    -- end
end

function Boss:OnMythicEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    self.isActive = false
    self.startTime = nil
    addon:Dbg(self.name, "end")
    CancelRegenRetry()
    UnregisterAll()
    ClearAllCalls()
    for _, timer in ipairs(ampClearTimers) do
        if timer.Cancel then timer:Cancel() end
    end
    wipe(ampClearTimers)
    local compass = addon.modules["Common.FacingCompass"]
    if compass and compass.Disable then
        compass:Disable()
    end
end

function Boss:OnPhaseChange(newPhase, prevPhase)
    -- TODO
end

-- Diagnostic for the Virulence direction voice: prints every condition that
-- could stop the sound from playing on a user's machine. Run with /artvoice.
function Boss:DiagnoseVoice()
    local lines = {}
    local function out(fmt, ...)
        lines[#lines + 1] = fmt:format(...)
    end

    out("--- ART Sszorak Virulence voice diagnostic ---")

    -- 1. addon version / module present
    out("module loaded: %s", tostring(addon.modules["Raids.VenomousAbyss.Sszorak"] ~= nil))

    -- 2. feature toggle
    local db = AwakeningRaidToolsDB
    local enc = db and db.encounters and db.encounters[Boss.encounterId]
    local featureVal = enc and enc.virulenceDirectionSound
    out("virulenceDirectionSound: %s", featureVal == nil and "default(true)" or tostring(featureVal))

    -- 3. voice pack resolution + file existence
    local pack = ResolvePackName()
    out("voicePack DB value: %s", tostring(db and db.VoicePack))
    out("voicePack resolved: %s", tostring(pack))
    for _, variant in ipairs(VIRULENCE_VARIANTS) do
        local path = ResolveSoundPath(variant.voiceKey)
        out("  spell %d -> %s (%s)", variant.spellId, variant.voiceKey, path)
    end

    -- 4. API availability
    out("AddAuraSound available: %s", tostring(AuraSoundApiAvailable()))

    -- 5. secret restriction state (informational)
    local secretOK, restricted = pcall(C_Secrets.ShouldAurasBeSecret)
    out("ShouldAurasBeSecret: %s", secretOK and tostring(restricted) or "ERR")

    -- 6. try a live registration (then remove) to surface return value
    local api = AuraSoundApiAvailable()
    if api then
        local probe = VIRULENCE_VARIANTS[1]
        local soundInfo = {
            spellID = probe.spellId,
            unitToken = "player",
            outputChannel = "Master",
            soundFileName = ResolveSoundPath(probe.voiceKey),
        }
        local ok, id = pcall(C_UnitAuras.AddAuraSound, TRIGGER_ADDED, soundInfo)
        out("probe register: ok=%s id=%s", tostring(ok), tostring(id))
        if ok and type(id) == "number" then
            pcall(C_UnitAuras.RemoveAuraSound, id)
        end
    end

    -- 7. conflicting addons
    for _, name in ipairs({ "DBM-Core", "NorthernSkyRaidTools", "DreamForgeTools" }) do
        local _, _, _, loadable = GetAddOnInfo(name)
        out("%s installed: %s", name, tostring(loadable == true))
    end

    for _, line in ipairs(lines) do
        print(line)
    end
end

-- ============================================================================
-- Wind-call system (compass sub-feature): the leader announces the wind
-- outlet marker ("raid_target_N", N=1..6) on /raid; every client with the
-- compass on highlights the OPPOSITE marker (go there for the debuff soak).
--   * Strict match: the whole message must equal "raid_target_N".
--   * Recent 3: dedupe (re-call moves to newest), drop oldest beyond 3.
--   * Clear: at difficulty-amp (Dig In) timestamps +20s (relative to combat).
--   * Broadcast: only when clicks are enabled (preview) — clicking a marker
--     sends "/raid raid_target_N". Combat does not click; it only listens.

addon:RegisterModule("Raids.VenomousAbyss.Sszorak", Boss)
