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

During RWF/competitive periods, some API return values become "secret" — opaque tokens that cannot be inspected or manipulated in Lua. Use `issecretvalue(v)` to test, `canaccessvalue(v)` to check if you have permission.

### Allowed on secret values (tainted code)
- **Store** in variables, upvalues, table values
- **Pass** to Lua functions and C functions that accept secrets
- **Boolean test** on non-boolean types (`if v then`, `v or fallback`) — since the type itself is not secret, nil is falsy and everything else (string/number/table) is truthy
- **Concatenation** on string/number secrets (`..`, `string.format`, `string.concat`)
- **Pass to C widget APIs** that accept secrets (`SetText`, `SetTexture`, `SetValue`, `SetTimerDuration`, `SetCooldownFromDurationObject`, etc.)
- `type(secret)` returns the real type (`"string"`, `"number"`, etc.)

### Prohibited on secret values
- **Comparisons** (`==`, `~=`, `<`, `>`, `<=`, `>=`)
- **Arithmetic** (`+`, `-`, `*`, `/`)
- **Table key** indexing with secret value (`map[secret]`)
- **Indexed access/assignment** on secret table values (`secret["foo"]`)
- **Length operator** (`#secret`)
- **Calling** a secret value as-if it were a function
- **String conversion** via `tostring()`

### `UnitIsUnit` specific rules
- Permitted if either unit is: `"player"`, `"pet"`, `"vehicle"`, `"mouseover"`, `"target"`, `"softenemy"`, `"softfriend"`, `"softinteract"`, `"focus"`, `"none"`, `"npc"`, `"questnpc"`
- Permitted if either unit is a party/raid token and the other is NOT a compound token (`"boss1target"`), nameplate token, or `"targettarget"`/`"focustarget"`
- Secret values are NOT accepted as arguments — add `not issecretvalue(unit)` guard before calling

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

## WA String Decode

When a user pastes a WeakAuras/M33kAura export string (`WA:2!...`), run:

```
node scripts/decode-wa.js "<WA:2!...>"
```

This decodes the EncodeForPrint → zlib deflate chain and extracts readable text (aura name, triggers, custom code, config options). Does not require the game client — works purely in Node.js with no dependencies beyond `zlib` (built-in).

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
