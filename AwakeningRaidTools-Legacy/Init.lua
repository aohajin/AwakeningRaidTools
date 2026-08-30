-- AwakeningRaidTools-Legacy init.
--
-- The main addon (AwakeningRaidTools) exposes its shared table as
-- `_G.AwakeningRaidTools` (see Core/Bootstrap.lua) and loads this addon on
-- demand via C_AddOns.LoadAddOn when an old-raid encounter starts.
--
-- This file copies every field of the main addon's table (including table
-- references like `modules` / `encounterModulesByID`) into this addon's own
-- namespace. Boss modules below keep using the stock `local _, addon = ...`
-- header unchanged; their `addon` now resolves to this namespace, which routes
-- every module registry read/write back to the main addon's tables, so
-- Options, PhaseTracker and encounter activation all work untouched.
--
-- `## Dependencies: AwakeningRaidTools` guarantees the main addon is fully
-- loaded before this file runs.
local addon = _G.AwakeningRaidTools
if not addon then
    print("ART-Legacy: AwakeningRaidTools not loaded, legacy raid modules disabled")
    return
end

local _, ns = ...
for k, v in pairs(addon) do
    ns[k] = v
end
