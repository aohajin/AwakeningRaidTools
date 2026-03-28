# Agent Rules

## WoW Secret-Value Safety (Required)

- Before using any WoW API in new logic, first check official/current API behavior and confirm whether its return values can be secret values in combat/instance contexts.
- Do not assume classic behavior from old expansions; verify against current version behavior.
- If a return value can be secret, never use it in:
  - boolean tests (`if value then`)
  - comparisons (`==`, `~=`, `<`, `>`, etc.)
  - arithmetic (`+`, `-`, `*`, `/`)
  - table indexing (`map[value]`)
  - string conversion/concatenation (`tostring`, `..`)
- Prefer secret-safe API helpers/patterns when available (for example curve/util conversion helpers) and avoid branching on secret results.
- When uncertain whether a value is secret, treat it as secret and redesign logic first.

## Proven Practices (Current Project)

- Keep `Common/NameplateCastMarker.lua` aligned with the known-good Git version when debugging secret-value regressions.
- Do not add filtering logic that depends on combat identity APIs (`UnitGUID`, `UnitName`, `UnitIsUnit`, boss-token lookups for nameplates) unless secret behavior is verified first.
- For encounter targeting, prefer encounter-level module enable/disable in `Core/Bootstrap.lua` and per-boss module routing, instead of runtime unit-identity matching.
