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
    },
}

local function IsFeatureEnabled(key)
    local db = AwakeningRaidToolsDB
    if db and db.encounters and db.encounters[Boss.encounterId] then
        return db.encounters[Boss.encounterId][key] ~= false
    end
    return true
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

local function RegisterAll()
    if not AuraSoundApiAvailable() then
        addon:Dbg(Boss.name, "aura sound API unavailable, skipping")
        return false
    end
    local registered = 0
    for _, variant in ipairs(BuildVariantList()) do
        if RegisterVariant(variant) then
            registered = registered + 1
        end
    end
    return registered > 0
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

function Boss:OnMythicEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    self.isActive = true
    addon:Dbg(self.name, "start")
    if IsFeatureEnabled("virulenceDirectionSound") then
        RegisterAll()
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
    addon:Dbg(self.name, "end")
    UnregisterAll()
end

function Boss:OnPhaseChange(newPhase, prevPhase)
    -- TODO
end

addon:RegisterModule("Raids.VenomousAbyss.Sszorak", Boss)
