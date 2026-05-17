---
description: Decode WeakAuras or M33kAura export strings (WA:2! format). When user pastes a WA string starting with "WA:2!" or "WA:2", or asks to decode an aura export, use this skill.
argument-hint: [WA:2!...string]
disable-model-invocation: false
---

Decode the provided WeakAuras/M33kAura export string to reveal what it does.

## How to decode

Run the project's decode script:

```!
node scripts/decode-wa.js "$ARGUMENTS"
```

## How to present results

After running the script, read the output and summarize the aura:

1. **Name and version** — what this aura calls itself
2. **Trigger conditions** — when it activates (encounter ID, boss mod stage, spell cast, debuff type, etc.)
3. **What it does** — the core behavior (custom code logic, CVar changes, etc.)
4. **Configuration options** — any user-configurable toggles or dropdowns
5. **Key observations** — anything surprising, risky, or worth noting about the implementation

## Technical background

- The `WA:2!` format uses: LibSerialize → LibDeflate:CompressDeflate → LibDeflate:EncodeForPrint
- `scripts/decode-wa.js` reverses this chain (DecodeForPrint → zlib inflate → text extraction)
- The output is partial — LibSerialize binary markers are stripped, leaving the readable text portions
- Encounter IDs can be cross-referenced with the boss modules in `Raids/`
