local _, addon = ...

addon.locales = addon.locales or {}
addon.locales.zhCN = addon.locales.zhCN or {
    STAT_STRENGTH = "力量",
    STAT_AGILITY = "敏捷",
    STAT_INTELLECT = "智力",

    SLOT_HEAD = "头部",
    SLOT_NECK = "颈部",
    SLOT_SHOULDER = "肩部",
    SLOT_CHEST = "胸部",
    SLOT_WAIST = "腰部",
    SLOT_LEGS = "腿部",
    SLOT_FEET = "脚部",
    SLOT_WRIST = "手腕",
    SLOT_HAND = "手部",
    SLOT_FINGER1 = "戒指1",
    SLOT_FINGER2 = "戒指2",
    SLOT_TRINKET1 = "饰品1",
    SLOT_TRINKET2 = "饰品2",
    SLOT_BACK = "披风",
    SLOT_MAINHAND = "主手",
    SLOT_OFFHAND = "副手",

    UNKNOWN_STAT = "未知",
    UNKNOWN_SLOT = "槽位%s",
    CENTER_ENTRY = "[%s:%s]",
    CENTER_MSG = "主属性不匹配（当前专精:%s） %s",
    CHAT_ENTRY = "[%s] %s %s",
    CHAT_MSG = "ART: 主属性不匹配（当前专精:%s） %s",
    LIST_SEPARATOR = "；",

    OPTIONS_SPEC_GEAR_MISMATCH = "启用错误装备检查",
}
