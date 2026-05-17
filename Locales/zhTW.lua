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

    OPTIONS_GENERAL_HEADER = "一般",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY = "啟用打斷顯示",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY_DESC = "在戰鬥中於敵方姓名板上顯示打斷標記。",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY = "關閉粒子效果（P1-P2）",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY_DESC = "在P1-P2階段將粒子密度降至最低以提高幀數，P3自動恢復。",
}
