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

    OPTIONS_VOICEPACK = "语音包",
    OPTIONS_VOICEPACK_DEFAULT = "默认（Aloy）",
    OPTIONS_VOICEPACK_PREVIEW = "试听",
    OPTIONS_VOICEPACK_PREVIEW_SOUND = "试听声音",
    OPTIONS_VOICEPACK_PICK_SOUND = "选择声音试听",
    OPTIONS_VOICEPACK_GROUP = "语音包",
    OPTIONS_VOICEPACK_PREVIEW_HINT = "试听：选择声音以试听所选语音包的效果（默认 Aloy）。",
    OPTIONS_VOICEPACK_DESC =
    "Boss 语音使用的语音包。所有语音位于 Media\\VoicePacks\\<语音包名>\\ 下，每个语音包都包含相同的文件名（如 go_left.ogg）。Aloy 是随插件附带的默认语音包。",
    OPTIONS_GENERAL_HEADER = "常规",
    OPTIONS_LEGACY_LOAD_BUTTON = "加载历史团本模块",
    OPTIONS_LEGACY_UNLOAD_BUTTON = "卸载历史团本模块",
    OPTIONS_LEGACY_RELOAD_BUTTON = "重新加载界面",
    OPTIONS_LEGACY_HEADER = "历史团本",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY = "启用打断显示",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY_DESC = "在战斗中于敌方姓名板上显示打断标记。",
    OPTIONS_SSZORAK_VIRULENCE_DIRECTION = "剧毒方向语音",
    OPTIONS_SSZORAK_VIRULENCE_DIRECTION_DESC =
    "获得剧毒 debuff 时播放方向语音。斯索拉克的剧毒有两种技能变体(1297707/1299899)，结束时会向不同方向发射毒液；由客户端匹配光环后播放对应语音(Media/Sounds/go_left.ogg 或 go_right.ogg)。",
    OPTIONS_SSZORAK_COMPASS = "朝向罗盘",
    OPTIONS_SSZORAK_COMPASS_DESC =
    "斯索拉克战斗中显示屏幕中央的八方向标记罗盘(圆形环绕团队标记 1-8)，随你的朝向旋转，作为毒液/放球机制的方向参考。",
    OPTIONS_SSZORAK_COMPASS_PREVIEW = "预览罗盘",
    OPTIONS_SSZORAK_COMPASS_WINDCALL = "风向喊话",
    OPTIONS_SSZORAK_COMPASS_WINDCALL_DESC =
    "罗盘开启时自动监听团队喊话 \"raid_target_N\" 并在对侧标记脉冲。开启本项后预览模式额外显示 {rt1}-{rt6} 发送按钮,供团长广播测试喊话。每次易伤窗口后 20 秒清空标记。",
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
