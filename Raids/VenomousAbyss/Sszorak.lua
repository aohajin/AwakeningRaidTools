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
        -- Wind-outlet call strip (DFT WindOctagon style). The compass DISC is
        -- gone (minimap-rotation API no longer permitted), but this strip only
        -- needs the chat listener + C-API icon rendering, so it still works.
        -- Receive (strip) and send (button panel) toggle independently.
        windCallReceive = {
            type = "toggle",
            default = false,
            labelKey = "OPTIONS_SSZORAK_WINDCALL_RECEIVE",
            descKey  = "OPTIONS_SSZORAK_WINDCALL_RECEIVE_DESC",
        },
        windCallSend = {
            type = "toggle",
            default = false,
            labelKey = "OPTIONS_SSZORAK_WINDCALL_SEND",
            descKey  = "OPTIONS_SSZORAK_WINDCALL_SEND_DESC",
            -- Preview + Edit Mode live here as one group. They are enabled
            -- (not greyed) only while receive and/or send is on; preview shows
            -- exactly what is ticked. enabledWhen is attached below.
            subFeatures = {
                {
                    type = "button",
                    key = "preview",
                    labelKey = "OPTIONS_SSZORAK_WINDCALL_PREVIEW",
                    onClick = function()
                        local boss = addon.modules["Raids.VenomousAbyss.Sszorak"]
                        if boss then
                            boss:ToggleReceivePreview()
                        end
                    end,
                },
                {
                    type = "button",
                    key = "editMode",
                    labelKey = "OPTIONS_SSZORAK_EDIT_MODE",
                    onClick = function()
                        if EditModeManagerFrame then
                            ShowUIPanel(EditModeManagerFrame)
                        end
                    end,
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

-- Preview / Edit Mode buttons (under the send toggle) are only enabled while
-- at least one of the two wind-call toggles is on; otherwise they grey out.
do
    local sendDef = Boss.features and Boss.features.windCallSend
    if sendDef and sendDef.subFeatures then
        for _, subDef in ipairs(sendDef.subFeatures) do
            subDef.enabledWhen = function()
                return IsFeatureEnabled("windCallReceive")
                    or IsFeatureEnabled("windCallSend")
            end
        end
    end
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

local WIND_AMP_TIMES = { 100, 227.1, 354.2 } -- mythic Dig In (damage amp) times
local WIND_CLEAR_AFTER = 20

local chatFrame = nil
local ampClearTimers = {}

-- Wind calls are shown NSRT-style: each incoming chat message is appended to
-- the compass call strip, and the message text is rendered straight into a
-- C API (SetFormattedText) — we never read/parse it, so it keeps working even
-- while chat messages are secret during competitive lockdown.

local function OnWindCall(text)
    local compass = addon.modules["Common.WindCall"]
    if compass and compass.AddWindCall then
        compass:AddWindCall(text)
    end
end

local function ClearAllCalls()
    local compass = addon.modules["Common.WindCall"]
    if compass and compass.ClearWindCalls then compass:ClearWindCalls() end
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
    if not boss or not (boss.isActive or boss._windPreview) then
        addon:Dbg(Boss.name, ("chat %s ignored: boss inactive (isActive=%s preview=%s)"):format(
            event, tostring(boss and boss.isActive), tostring(boss and boss._windPreview)))
        return
    end
    -- Listening is the compass's default behaviour (no windCall toggle needed):
    -- any client with the compass feature on hears wind calls.
    local compass = addon.modules["Common.WindCall"]
    if not compass or not compass:IsReceiveEnabled() then
        addon:Dbg(Boss.name, ("chat %s ignored: compass inactive"):format(event))
        return
    end
    -- NSRT-style: do NOT parse the text (it may be secret); hand it straight
    -- to the compass, which renders it into a C API. Guard every tostring with
    -- issecretvalue: sender can be secret too during lockdown. Dbg no-ops
    -- unless debug logging is on, but the guard keeps it safe either way.
    local function safeStr(v)
        if v == nil then return "nil" end
        if issecretvalue and issecretvalue(v) then return "<secret>" end
        return tostring(v)
    end
    addon:Dbg(Boss.name, ("chat %s from %s -> call (secret=%s)"):format(
        safeStr(event), safeStr(sender), safeStr(issecretvalue and issecretvalue(message))))
    OnWindCall(message)
end

-- Register the raid chat listener at login (out of combat; RegisterEvent is
-- forbidden in combat lockdown). If we are mid-combat at init (a /reload
-- during combat) we cannot register now, but a fresh login is out of combat
-- and covers the normal case; the handler checks boss.isActive anyway.
local function StartWindListening()
    if chatFrame then return chatFrame end
    chatFrame = CreateFrame("Frame")
    -- Only channels a leader would call on (raid / raid-warning / instance),
    -- plus /say so the feature can be tested without a group.
    addon:RegisterSafeEvents(chatFrame, {
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_INSTANCE_CHAT",
        "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_SAY",
        "PLAYER_REGEN_ENABLED",
    }, ChatHandler)
    return chatFrame
end

-- Wind calls are announced by the raid LEADER via a chat macro, e.g.
--   /raid w6      ("w" + marker number 1..6)
-- The addon only listens (the send panel is optional): every client with the
-- receive toggle on appends the call to its strip. The text is never parsed
-- (rendered into a C API), so it also works while chat messages are secret.

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

    if not IsFeatureEnabled("virulenceDirectionSound") then return end
    if InCombatLockdown() then
        -- /reload happened mid-combat; register once combat ends.
        addon:Dbg(Boss.name, "in combat at init; deferring aura sound register")
        ScheduleRegenRetry()
        return
    end
    RegisterAll()
end

-- Preview the receive (call strip) / send (button panel) outside an encounter.
local function PreviewGuard()
    if InCombatLockdown() then
        print("ART: cannot preview in combat")
        return false
    end
    return true
end

-- Single preview toggle for the wind-call feature. Shows exactly what is
-- ticked: receive and/or send. If neither is ticked the button is greyed out
-- (handled by the options predicate), so this is only reachable when on.
function Boss:ToggleReceivePreview()
    if not PreviewGuard() then return end
    local windCall = addon.modules["Common.WindCall"]
    if not windCall then return end
    if windCall:IsReceiveEnabled() or windCall:IsSendEnabled() then
        windCall:SetReceiveEnabled(false)
        windCall:SetSendEnabled(false)
        self._windPreview = nil
        print("ART: wind-call preview off")
    else
        if IsFeatureEnabled("windCallReceive") then
            windCall:SetReceiveEnabled(true)
        end
        if IsFeatureEnabled("windCallSend") then
            windCall:SetSendEnabled(true)
        end
        self._windPreview = true
        ClearAllCalls()
        print("ART: wind-call preview on (test with /raid w6 or /s w6)")
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
    -- Wind-outlet call strip (DFT style). Needs no minimap rotation; only the
    -- chat listener + C-API icon rendering.
    -- Wind-outlet calls: receive (strip) and send (button panel) toggle
    -- independently. Neither needs minimap rotation.
    local compass = addon.modules["Common.WindCall"]
    if compass then
        if IsFeatureEnabled("windCallReceive") then
            compass:SetReceiveEnabled(true)
            ClearAllCalls()
            ScheduleAmpClears()
        end
        if IsFeatureEnabled("windCallSend") then
            compass:SetSendEnabled(true)
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
    local compass = addon.modules["Common.WindCall"]
    if compass and compass.SetReceiveEnabled then
        self._windPreview = nil
        compass:SetReceiveEnabled(false)
        compass:SetSendEnabled(false)
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
        if ok then
            local idDesc
            local idType = type(id)
            if idType == "number" and not (issecretvalue and issecretvalue(id)) then
                idDesc = tostring(id)
            else
                idDesc = "<" .. tostring(idType) .. (issecretvalue and issecretvalue(id) and ":secret>" or ">")
            end
            out("probe register: ok=true id=%s", idDesc)
            if type(id) == "number" then
                pcall(C_UnitAuras.RemoveAuraSound, id)
            end
        else
            out("probe register: ok=false (%s)", tostring(id))
        end
    end

    -- 7. conflicting addons
    local GetAddOnInfoCompat = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
    for _, name in ipairs({ "DBM-Core", "NorthernSkyRaidTools", "DreamForgeTools" }) do
        local _, _, _, loadable = GetAddOnInfoCompat(name)
        out("%s installed: %s", name, tostring(loadable == true))
    end

    for _, line in ipairs(lines) do
        print(line)
    end
end

-- ============================================================================
-- Wind-call system (compass sub-feature), NSRT-style: the leader announces
-- each wind outlet with a chat macro (e.g. "/raid w6"); every client with the
-- compass on appends it to the call strip (order 1..4 + raid-target icon).
--   * No parsing: the chat text is handed straight to a C API, so it works
--     even while messages are secret during competitive (chat) lockdown.
--   * Clear: at difficulty-amp (Dig In) timestamps +20s (relative to combat)
--     and on leaving combat.
--   * Listening only (no in-addon sender).

addon:RegisterModule("Raids.VenomousAbyss.Sszorak", Boss)
