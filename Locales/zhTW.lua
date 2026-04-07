local _, addon = ...

addon.locales = addon.locales or {}
addon.locales.zhTW = addon.locales.zhTW or {
    STAT_STRENGTH = "力量",
    STAT_AGILITY = "敏捷",
    STAT_INTELLECT = "智力",

    SLOT_HEAD = "頭部",
    SLOT_NECK = "頸部",
    SLOT_SHOULDER = "肩部",
    SLOT_CHEST = "胸部",
    SLOT_WAIST = "腰部",
    SLOT_LEGS = "腿部",
    SLOT_FEET = "腳部",
    SLOT_WRIST = "手腕",
    SLOT_HAND = "手部",
    SLOT_FINGER1 = "戒指1",
    SLOT_FINGER2 = "戒指2",
    SLOT_TRINKET1 = "飾品1",
    SLOT_TRINKET2 = "飾品2",
    SLOT_BACK = "披風",
    SLOT_MAINHAND = "主手",
    SLOT_OFFHAND = "副手",

    UNKNOWN_STAT = "未知",
    UNKNOWN_SLOT = "槽位%s",
    CENTER_ENTRY = "[%s:%s]",
    CENTER_MSG = "主屬性不匹配（當前專精:%s） %s",
    CHAT_ENTRY = "[%s] %s %s",
    CHAT_MSG = "ART: 主屬性不匹配（當前專精:%s） %s",
    LIST_SEPARATOR = "；",

    OPTIONS_SPEC_GEAR_MISMATCH = "啟用錯誤裝備檢查",
}
