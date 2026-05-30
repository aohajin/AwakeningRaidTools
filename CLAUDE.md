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

### General principle

Secret values **can be freely passed** to Blizzard C APIs. The API handles the secret internally. Most APIs will return secret values when given secret input — those results can still be passed to C widget functions (`SetText`, `SetTexture`, `SetTimerDuration`, etc.). A few APIs (notably `UnitIsUnit`) return **non-secret** results even from secret input.

**Rule: when passing a potentially-secret value to an API, consult the API's documentation for its secret-handling contract.** Do NOT blindly guard with `issecretvalue()` — that may silently break functionality during RWF. Each API falls into one of three categories:

1. **Accepts secret, returns non-secret** — e.g. `UnitIsUnit`. Safe to call without guard.
2. **Accepts secret, returns secret** — e.g. `UnitCastingInfo`, `UnitChannelInfo`. Pass-through is fine; pass results to C widgets.
3. **Does not accept secret** — rare; check docs. Only then add `issecretvalue` guard.

The only things you **cannot** do are Lua-level operations on the value itself: you can't inspect, compare, or transform it.

### Allowed on secret values
- **Store** in variables, upvalues, table values
- **Pass** to any Blizzard C API — safe, API handles it internally
- **Pass** to Lua functions (as argument, return value)
- **Boolean test** on non-boolean types (`if v then`, `v or fallback`) — since the type itself is not secret, nil is falsy and everything else (string/number/table) is truthy
- **Pass to C widget APIs** (`SetText`, `SetTexture`, `SetValue`, `SetTimerDuration`, `SetCooldownFromDurationObject`, etc.)
- `type(secret)` returns the real type (`"string"`, `"number"`, etc.)

### Prohibited on secret values (Lua-level operations)
- **Comparisons** (`==`, `~=`, `<`, `>`, `<=`, `>=`)
- **Arithmetic** (`+`, `-`, `*`, `/`)
- **String operations** — `..`, `tostring()`, `string.format`, `string.concat`, `string.gsub`, etc. — anything that needs to inspect the character data
- **Table key** indexing with secret value (`map[secret]`)
- **Indexed access/assignment** on secret table values (`secret["foo"]`)
- **Length operator** (`#secret`)
- **Calling** a secret value as-if it were a function

### `UnitIsUnit` specific rules

`UnitIsUnit` accepts secret values **only from untainted (Blizzard) code**. Addon code is tainted — passing a secret value as either argument will error. Always guard with `not issecretvalue(unit)` before calling `UnitIsUnit` with any event-derived token.

When both units are non-secret, the token whitelist applies:
- Permitted if either unit is: `"player"`, `"pet"`, `"vehicle"`, `"mouseover"`, `"target"`, `"softenemy"`, `"softfriend"`, `"softinteract"`, `"focus"`, `"none"`, `"npc"`, `"questnpc"`
- Permitted if either unit is a party/raid token and the other is NOT a compound token (`"boss1target"`), nameplate token, or `"targettarget"`/`"focustarget"`

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
