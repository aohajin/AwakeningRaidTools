local _, addon = ...

-- Single-source gating for the legacy addon:
--   AwakeningRaidToolsDB.LegacyRaidEnabled[raidKey]  (per-raid boolean)
-- is the ONLY persisted state. "Load the legacy addon" is derived from it:
-- any raid enabled -> load on login; none enabled -> do not load.
-- Boss activation at ENCOUNTER_START checks the same per-raid flag
-- (see Core/Bootstrap.lua IsModuleEnabled). There is no separate master
-- switch anymore.
local LegacyLoader = {
    name = "LegacyLoader",
}

local LEGACY_RAID_KEYS = { "Voidspire", "Dreamrift", "MarchOfQuelDanas" }
local LEGACY_ADDON_NAME = "AwakeningRaidTools-Legacy"
local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo

function addon:IsLegacyRaid(raidKey)
    for _, key in ipairs(LEGACY_RAID_KEYS) do
        if key == raidKey then return true end
    end
    return false
end

-- True when any legacy raid is enabled in the saved DB.
local function AnyLegacyRaidEnabled()
    local db = AwakeningRaidToolsDB
    if not (db and db.LegacyRaidEnabled) then return false end
    for _, key in ipairs(LEGACY_RAID_KEYS) do
        if db.LegacyRaidEnabled[key] then return true end
    end
    return false
end

-- Load the legacy addon if the DB enables any legacy raid. LoadAddOn is
-- synchronous; the boss modules then register into the shared addon table.
function LegacyLoader:OnInitialize()
    if AnyLegacyRaidEnabled() then
        self:LoadIfNeeded()
    end
end

-- LoadAddOn the legacy addon (idempotent). Does not touch the DB; enabling a
-- raid (options checkbox) is what records intent, and this only materialises
-- the modules so boss options / encounters can use them after a reload.
function LegacyLoader:LoadIfNeeded()
    if addon.legacyLoaded then
        return true
    end
    local loaded = LoadAddOn(LEGACY_ADDON_NAME)
    if loaded then
        addon.legacyLoaded = true
        addon:Dbg("LegacyLoader", LEGACY_ADDON_NAME .. " loaded")
        print("ART: legacy raid modules loaded")
    else
        local _, _, _, loadable, loadReason = GetAddOnInfo(LEGACY_ADDON_NAME)
        local why = loadReason or (loadable and "load failed" or "not installed")
        addon:Dbg("LegacyLoader", ("LoadAddOn(%s) failed: %s"):format(LEGACY_ADDON_NAME, tostring(why)))
        print(("ART: unable to load %s (%s)"):format(LEGACY_ADDON_NAME, tostring(why)))
    end
    return addon.legacyLoaded
end

-- Kept for callers that used the old name; delegates to LoadIfNeeded.
LegacyLoader.Enable = LegacyLoader.LoadIfNeeded

addon:RegisterModule("Core.LegacyLoader", LegacyLoader)
