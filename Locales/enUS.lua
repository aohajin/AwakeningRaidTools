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

    OPTIONS_GENERAL_HEADER = "General",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY = "Enable interrupt display",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY_DESC = "Show interrupt markers on enemy nameplates during the encounter.",
    OPTIONS_FOCUS_INTERRUPT_COUNTER = "Show focus interrupt counter",
    OPTIONS_FOCUS_INTERRUPT_COUNTER_DESC =
    "Displays the current interrupt count on your focus target's nameplate during combat.",
    OPTIONS_FIC_NAMEPLATE = "Show on focus nameplate",
    OPTIONS_FIC_NAMEPLATE_DESC = "Display the interrupt counter on the focus target's nameplate during casts.",
    OPTIONS_FIC_FOCUS_FRAME = "Show on focus frame cast bar(supports exwindtools)",
    OPTIONS_FIC_FOCUS_FRAME_DESC =
    "Display the counter on the system focus frame spell bar (also supports ExwindTools focus cast bar).",
    OPTIONS_FIC_EDIT_MODE = "Configure in Edit Mode",
    OPTIONS_FIC_CENTER_SCREEN = "Show in center of screen",
    OPTIONS_FIC_CENTER_SCREEN_DESC = "Display a large interrupt counter in the upper center of the screen.",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY = "Disable particle effects (P1-P2)",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY_DESC =
    "Set particle density to minimum during phases 1-2 to improve frame rate. Restores normal settings in phase 3.",
}
