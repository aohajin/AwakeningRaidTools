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


    OPTIONS_DEBUG_ENABLE = "啟用除錯日誌",
    OPTIONS_DEBUG_ENABLE_DESC = "將除錯日誌寫入SavedVariables。使用 /ficlog 在遊戲內查看，或登出後查看WTF資料夾。",

    OPTIONS_SPEC_GEAR_MISMATCH = "啟用錯誤裝備檢查",

    OPTIONS_GENERAL_HEADER = "一般",
    OPTIONS_LEGACY_LOAD_BUTTON = "載入歷史團本模組",
    OPTIONS_LEGACY_UNLOAD_BUTTON = "卸載歷史團本模組",
    OPTIONS_LEGACY_RELOAD_BUTTON = "重新載入介面",
    OPTIONS_LEGACY_HEADER = "歷史團本",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY = "啟用打斷顯示",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY_DESC = "在戰鬥中於敵方姓名板上顯示打斷標記。",
    OPTIONS_VASHNIK_DIRECTION_CROSS = "方向瞄準線",
    OPTIONS_VASHNIK_DIRECTION_CROSS_DESC = "在螢幕中央顯示隨你朝向旋轉的十字瞄準線，輔助瘟疫浪潮/噴泉機制走位。",
    OPTIONS_VASHNIK_PREVIEW = "預覽瞄準線",
    OPTIONS_VASHNIK_PARTICLE_DENSITY = "關閉粒子特效（整個戰鬥）",
    OPTIONS_VASHNIK_PARTICLE_DENSITY_DESC = "整個戰鬥將粒子密度降至最低以提高幀數，戰鬥結束自動恢復。",
    OPTIONS_FOCUS_INTERRUPT_COUNTER = "顯示焦點打斷計數",
    OPTIONS_FOCUS_INTERRUPT_COUNTER_DESC = "在戰鬥中於焦點目標的姓名板上顯示當前打斷計數。",
    OPTIONS_FIC_NAMEPLATE = "在焦點姓名版上顯示",
    OPTIONS_FIC_NAMEPLATE_DESC = "在焦點目標的姓名版上顯示打斷計數。",
    OPTIONS_FIC_FOCUS_FRAME = "顯示在系統焦點框架的施法條（支援exwindtools）",
    OPTIONS_FIC_FOCUS_FRAME_DESC = "在系統焦點框架的施法條上顯示打斷計數（也支援ExwindTools的焦點施法條）。",
    OPTIONS_CENTER_CAST_BAR = "顯示螢幕中央焦點施法條",
    OPTIONS_CENTER_CAST_BAR_DESC = "在螢幕中央顯示自定義焦點施法條，包含打斷計數。",

    OPTIONS_FIC_EDIT_MODE = "Configure in Edit Mode",
    OPTIONS_FIC_CENTER_SCREEN = "顯示在ART獨立焦點施法條",
    OPTIONS_FIC_CENTER_SCREEN_DESC = "顯示自定義焦點施法條，包含打斷計數。",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY = "關閉粒子效果（P1-P2）",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY_DESC = "在P1-P2階段將粒子密度降至最低以提高幀數，P3自動恢復。",

}
