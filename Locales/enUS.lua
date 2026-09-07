local _, addon = ...

addon.locales = addon.locales or {}
addon.locales.enUS = addon.locales.enUS or {
    STAT_STRENGTH = "Strength",
    STAT_AGILITY = "Agility",
    STAT_INTELLECT = "Intellect",

    SLOT_HEAD = "Head",
    SLOT_NECK = "Neck",
    SLOT_SHOULDER = "Shoulder",
    SLOT_CHEST = "Chest",
    SLOT_WAIST = "Waist",
    SLOT_LEGS = "Legs",
    SLOT_FEET = "Feet",
    SLOT_WRIST = "Wrist",
    SLOT_HAND = "Hands",
    SLOT_FINGER1 = "Ring 1",
    SLOT_FINGER2 = "Ring 2",
    SLOT_TRINKET1 = "Trinket 1",
    SLOT_TRINKET2 = "Trinket 2",
    SLOT_BACK = "Back",
    SLOT_MAINHAND = "Main Hand",
    SLOT_OFFHAND = "Off Hand",

    UNKNOWN_STAT = "Unknown",
    UNKNOWN_SLOT = "Slot %s",
    CENTER_ENTRY = "[%s:%s]",
    CENTER_MSG = "Primary stat mismatch (spec: %s) %s",
    CHAT_ENTRY = "[%s] %s %s",
    CHAT_MSG = "ART: Primary stat mismatch (spec: %s) %s",
    LIST_SEPARATOR = "; ",


    OPTIONS_DEBUG_ENABLE = "Enable debug logging",
    OPTIONS_DEBUG_ENABLE_DESC =
    "Write debug logs to SavedVariables. Use /ficlog to view in-game, or check WTF folder after logout.",

    OPTIONS_SPEC_GEAR_MISMATCH = "Enable gear mismatch check",

    OPTIONS_VOICEPACK = "Voice pack",
    OPTIONS_VOICEPACK_DEFAULT = "Default (Aloy)",
    OPTIONS_VOICEPACK_PREVIEW = "Preview",
    OPTIONS_VOICEPACK_PREVIEW_SOUND = "Preview sound",
    OPTIONS_VOICEPACK_PICK_SOUND = "Select to preview",
    OPTIONS_VOICEPACK_GROUP = "Voice pack",
    OPTIONS_VOICEPACK_PREVIEW_HINT = "Preview: pick a sound to hear it from the selected voice pack (Aloy by default).",
    OPTIONS_VOICEPACK_DESC =
    "Which voice pack to use for boss audio. All voices live under Media\\VoicePacks\\<name>\\ and every pack ships the same file names (e.g. go_left.ogg). Aloy is the default pack bundled with the addon.",
    OPTIONS_GENERAL_HEADER = "General",
    OPTIONS_LEGACY_LOAD_BUTTON = "Load legacy raid modules",
    OPTIONS_LEGACY_UNLOAD_BUTTON = "Unload legacy raid modules",
    OPTIONS_LEGACY_RELOAD_BUTTON = "Reload UI",
    OPTIONS_LEGACY_HEADER = "Legacy Raids",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY = "Enable interrupt display",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY_DESC = "Show interrupt markers on enemy nameplates during the encounter.",
    OPTIONS_SSZORAK_VIRULENCE_DIRECTION = "Virulence direction voice",
    OPTIONS_SSZORAK_VIRULENCE_DIRECTION_DESC =
    "Play a direction voice when you gain Virulence. Sszorak's Virulence has two spell variants (1297707/1299899) that launch poison in different directions; the client matches the aura and plays the bound sound (Media/Sounds/go_left.ogg or go_right.ogg).",
    OPTIONS_SSZORAK_COMPASS = "Facing compass",
    OPTIONS_SSZORAK_COMPASS_DESC =
    "Show a screen-centred 8-direction marker compass that rotates with your facing during Sszorak (raid-target icons 1-8 around the circle). Useful as a direction reference for venom/soak mechanics.",
    OPTIONS_SSZORAK_COMPASS_PREVIEW = "Preview compass",
    OPTIONS_SSZORAK_COMPASS_EDIT_MODE = "Adjust positions in Edit Mode",
    OPTIONS_SSZORAK_COMPASS_EDIT_MODE_DESC =
    "Opens Blizzard's Edit Mode so you can drag the compass, the wind-call buttons and the order table to any screen position.",
    OPTIONS_SSZORAK_COMPASS_WINDCALL = "Wind outlet calls",
    OPTIONS_SSZORAK_COMPASS_WINDCALL_DESC =
    "When the compass is on, wind calls (\"raid_target_N\" in raid chat) pulse the opposite marker automatically. Enable this to also show the {rt1}-{rt6} send buttons (preview) so the leader can broadcast test calls. Marks clear 20s after each damage-amp window.",
    OPTIONS_VASHNIK_DIRECTION_CROSS = "Direction crosshair",
    OPTIONS_VASHNIK_DIRECTION_CROSS_DESC = "Show a screen-centered crosshair that rotates with your facing, to help line up during Plague Wave / fountain mechanics.",
    OPTIONS_VASHNIK_PREVIEW = "Preview crosshair",
    OPTIONS_VASHNIK_PARTICLE_DENSITY = "Disable particle effects (whole fight)",
    OPTIONS_VASHNIK_PARTICLE_DENSITY_DESC = "Set particle density to the minimum for the entire encounter to improve FPS; restored automatically at encounter end.",
    OPTIONS_FOCUS_INTERRUPT_COUNTER = "Show focus interrupt counter",
    OPTIONS_FOCUS_INTERRUPT_COUNTER_DESC =
    "Displays the current interrupt count on your focus target's nameplate during combat.",
    OPTIONS_FIC_NAMEPLATE = "Show on focus nameplate",
    OPTIONS_FIC_NAMEPLATE_DESC = "Display the interrupt counter on the focus target's nameplate during casts.",
    OPTIONS_FIC_FOCUS_FRAME = "Show on focus frame cast bar(supports exwindtools)",
    OPTIONS_FIC_FOCUS_FRAME_DESC =
    "Display the counter on the system focus frame spell bar (also supports ExwindTools focus cast bar).",
    OPTIONS_FIC_EDIT_MODE = "Configure in Edit Mode",
    OPTIONS_FIC_CENTER_SCREEN = "Show on ART focus cast bar",
    OPTIONS_FIC_CENTER_SCREEN_DESC = "Display a custom focus cast bar with interrupt counter..",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY = "Disable particle effects (P1-P2)",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY_DESC =
    "Set particle density to minimum during phases 1-2 to improve frame rate. Restores normal settings in phase 3.",

}
