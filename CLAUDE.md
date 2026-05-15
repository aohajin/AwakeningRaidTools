# Awakening Raid Tools (ART)

Mythic-only WoW raid utility addon.

## Architecture

- `Core/Bootstrap.lua` — module system (`RegisterModule`), encounter lifecycle (`ENCOUNTER_START`/`END`, difficulty gate at Mythic), event hub
- `AwakeningRaidTools.lua` — entry point, `ADDON_LOADED` → `InitializeModules`
- `Common/` — reusable modules: `PhaseTracker`, `NameplateCastMarker`, `SpecGearMismatchWarning`
- `Raids/<Raid>/<Boss>.lua` — per-boss encounter modules (self-declare `features` table, implement `OnMythicEncounterStart`/`End`)
- `Options/Options.lua` — settings panel, auto-discovers boss features via `addon.modules`
- `Locales/` — enUS base + zhCN/zhTW overrides, merged into `addon.L`

### Module pattern

Boss modules declare a `features` table to expose toggles in the options panel:

```lua
features = {
    featureName = {
        type = "toggle",
        default = true,
        labelKey = "LOCALE_KEY",
        descKey  = "LOCALE_KEY_DESC",
    },
},
```

### Saved variable

`AwakeningRaidToolsDB` — nested structure:

```lua
AwakeningRaidToolsDB = {
    SpecGearMismatchEnabled = true,          -- legacy flat key
    encounters = {
        [encounterId] = { featureName = true },
    },
}
```

## WoW Secret-Value Safety (Required)

- Before using any WoW API in new logic, verify whether its return values can be secret in combat/instance contexts.
- If a return value can be secret, never use it in: boolean tests, comparisons, arithmetic, table indexing, or string conversion.
- Prefer secret-safe API helpers/patterns when available.
- Do not add filtering logic that depends on combat identity APIs (`UnitGUID`, `UnitName`, `UnitIsUnit`, boss-token lookups for nameplates) unless secret behavior is verified first.
- For encounter targeting, prefer encounter-level module enable/disable and per-boss module routing instead of runtime unit-identity matching.
- Keep `Common/NameplateCastMarker.lua` aligned with the known-good Git version when debugging secret-value regressions.

## PhaseTracker

`Common/PhaseTracker.lua` provides reusable boss phase detection via `ENCOUNTER_TIMELINE_EVENT_ADDED` (official Blizzard API since DF 10.0, no BigWigs/DBM dependency).

Boss modules register phase configs and callbacks in `OnMythicEncounterStart`:

```lua
local pt = addon.modules["Common.PhaseTracker"]
pt:RegisterPhaseConfig(encounterId, {
    transitions = {
        { atDuration = 45.0, phase = 2 },
        { atDuration = 97.0, phase = 3 },
    },
})
pt:RegisterPhaseCallback(encounterId, function(_, newPhase, prevPhase)
    -- handle phase transition
end)
```

Transitions are matched forward-only with `ApproximatelyEqual(duration, target, 0.2)` tolerance. A 5s swap cooldown prevents rapid re-triggers.

## Version Bump and Release

### Bump checklist

1. Update `## Version:` in `AwakeningRaidTools.toc`
2. Update `CHANGELOG.md` at repo root (gitignored; see format below)
3. Commit, then tag: `git tag v<version>`
4. Push: `git push && git push --tags`

### CHANGELOG format

```markdown
# Awakening Raid Tools

## [v0.2.3](https://github.com/aohajin/AwakeningRaidTools/tree/v0.2.3) (YYYY-MM-DD)
[Full Changelog](https://github.com/aohajin/AwakeningRaidTools/compare/v0.2.2...v0.2.3)

- brief change summary
```

### Release automation

Pushing a `v*` tag triggers `.github/workflows/main.yml` → `BigWigsMods/packager@v2`. The packager reads `.toc` (version, interface) and `.pkgmeta` (`package-as: AwakeningRaidTools`), builds a zip, and publishes a GitHub release.

- `.release/` is a gitignored build artifact directory
- `release.sh` is the BigWigs community packager script (used by CI, can also run locally)
