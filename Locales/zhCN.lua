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


    OPTIONS_DEBUG_ENABLE = "启用调试日志",
    OPTIONS_DEBUG_ENABLE_DESC = "将调试日志写入SavedVariables。使用 /ficlog 在游戏内查看，或登出后查看WTF文件夹。",

    OPTIONS_SPEC_GEAR_MISMATCH = "启用错误装备检查",

    OPTIONS_GENERAL_HEADER = "常规",
    OPTIONS_LEGACY_LOAD_BUTTON = "加载历史团本模块",
    OPTIONS_LEGACY_UNLOAD_BUTTON = "卸载历史团本模块",
    OPTIONS_LEGACY_RELOAD_BUTTON = "重新加载界面",
    OPTIONS_LEGACY_HEADER = "历史团本",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY = "启用打断显示",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY_DESC = "在战斗中于敌方姓名板上显示打断标记。",
    OPTIONS_VASHNIK_DIRECTION_CROSS = "方向瞄准线",
    OPTIONS_VASHNIK_DIRECTION_CROSS_DESC = "在屏幕中央显示随你朝向旋转的十字瞄准线，辅助瘟疫浪潮/喷泉机制走位。",
    OPTIONS_VASHNIK_PREVIEW = "预览瞄准线",
    OPTIONS_VASHNIK_PARTICLE_DENSITY = "关闭粒子特效（整个战斗）",
    OPTIONS_VASHNIK_PARTICLE_DENSITY_DESC = "整个战斗将粒子密度降至最低以提高帧数，战斗结束自动恢复。",
    OPTIONS_FOCUS_INTERRUPT_COUNTER = "显示焦点打断计数",
    OPTIONS_FOCUS_INTERRUPT_COUNTER_DESC = "在战斗中于焦点目标的姓名板上显示当前打断计数。",
    OPTIONS_FIC_NAMEPLATE = "在焦点姓名版上显示",
    OPTIONS_FIC_NAMEPLATE_DESC = "在焦点目标的姓名版上显示打断计数。",
    OPTIONS_FIC_FOCUS_FRAME = "显示在系统焦点框架的施法条（支持exwindtools）",
    OPTIONS_FIC_FOCUS_FRAME_DESC = "在系统焦点框架的施法条上显示打断计数（也支持ExwindTools的焦点施法条）。",
    OPTIONS_CENTER_CAST_BAR = "显示屏幕中央焦点施法条",
    OPTIONS_CENTER_CAST_BAR_DESC = "在屏幕中央显示自定义焦点施法条，包含打断计数。",

    OPTIONS_FIC_CENTER_SCREEN = "显示在ART独立焦点施法条",
    OPTIONS_FIC_CENTER_SCREEN_DESC = "显示自定义焦点施法条，包含打断计数。",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY = "关闭粒子效果（P1-P2）",
    OPTIONS_MIDNIGHTFALLS_PARTICLE_DENSITY_DESC = "在P1-P2阶段将粒子密度降至最低以提高帧数，P3自动恢复。",

}
