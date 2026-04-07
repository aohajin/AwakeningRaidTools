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

    OPTIONS_SPEC_GEAR_MISMATCH = "Enable gear mismatch check",
}
