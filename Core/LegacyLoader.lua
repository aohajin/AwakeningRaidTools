local _, addon = ...

-- Two-level gating for the legacy addon:
--   1. A stateful button in the options panel (Load/Unload legacy raid
--      modules) loads the whole AwakeningRaidTools-Legacy addon on demand.
--      Until it is loaded, the per-raid section below is not shown.
--   2. Per-raid toggles (AwakeningRaidToolsDB.LegacyRaidEnabled[raidKey])
--      control activation at ENCOUNTER_START (see Core/Bootstrap.lua
--      IsModuleEnabled). Disabling a raid only suspends its boss modules; the
--      boss feature settings are kept in the DB and come back when re-enabled.
local LegacyLoader = {
    name = "LegacyLoader",
}

local LEGACY_ADDON_NAME = "AwakeningRaidTools-Legacy"
local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo

-- Raids shipped in the legacy addon. Keep in sync with RAID_ORDER_LEGACY in
-- Options/Options.lua.
local LEGACY_RAIDS = {
    Voidspire = true,
    Dreamrift = true,
    MarchOfQuelDanas = true,
}

function addon:IsLegacyRaid(raidKey)
    return LEGACY_RAIDS[raidKey] == true
end

function LegacyLoader:OnInitialize()
    if AwakeningRaidToolsDB and AwakeningRaidToolsDB.LegacyEnabled then
        self:Enable()
    end
end

-- Called by the "Load legacy raid modules" button. LoadAddOn is synchronous;
-- when it returns, the legacy modules are already registered into the shared
-- addon table.
function LegacyLoader:Enable()
    if addon.legacyLoaded then
        return true
    end
    local loaded = LoadAddOn(LEGACY_ADDON_NAME)
    if loaded then
        addon.legacyLoaded = true
        AwakeningRaidToolsDB.LegacyEnabled = true
        addon:Dbg("LegacyLoader", LEGACY_ADDON_NAME .. " loaded")
        print("ART: legacy raid modules loaded")
    else
        local _, _, _, loadable, loadReason = GetAddOnInfo(LEGACY_ADDON_NAME)
        local why = loadReason or (loadable and "load failed" or "not installed")
        addon:Dbg("LegacyLoader", ("LoadAddOn(%s) failed: %s"):format(LEGACY_ADDON_NAME, tostring(why)))
        print(("ART: unable to load %s (%s)"):format(LEGACY_ADDON_NAME, tostring(why)))
    end
    -- Refresh the options panel so the per-raid section shows up on success.
    if addon.RebuildOptionsPanel then
        addon.RebuildOptionsPanel()
    end
    return addon.legacyLoaded
end

-- Called by the "Unload legacy raid modules" button. Loaded addons cannot be
-- unloaded at runtime, so this only records the intent; the legacy addon is
-- left out after the next /reload.
function LegacyLoader:Disable()
    AwakeningRaidToolsDB.LegacyEnabled = nil
    if addon.legacyLoaded then
        print("ART: legacy raid modules will unload after /reload")
    end
    -- Refresh the options panel: unload button grayed out + reload button.
    if addon.RebuildOptionsPanel then
        addon.RebuildOptionsPanel()
    end
end

addon:RegisterModule("Core.LegacyLoader", LegacyLoader)
