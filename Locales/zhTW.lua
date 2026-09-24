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

    OPTIONS_VOICEPACK = "語音包",
    OPTIONS_VOICEPACK_DEFAULT = "預設（Aloy）",
    OPTIONS_VOICEPACK_PREVIEW = "試聽",
    OPTIONS_VOICEPACK_PREVIEW_SOUND = "試聽聲音",
    OPTIONS_VOICEPACK_PICK_SOUND = "選擇聲音試聽",
    OPTIONS_VOICEPACK_GROUP = "語音包",
    OPTIONS_VOICEPACK_PREVIEW_HINT = "試聽：選擇聲音以試聽所選語音包的效果（預設 Aloy）。",
    OPTIONS_VOICEPACK_DESC =
    "Boss 語音使用的語音包。所有語音位於 Media\\VoicePacks\\<語音包名>\\ 下，每個語音包都包含相同的檔案名稱（如 go_left.ogg）。Aloy 是隨插件附帶的預設語音包。",
    OPTIONS_GENERAL_HEADER = "一般",
    OPTIONS_LEGACY_LOAD_BUTTON = "載入歷史團本模組",
    OPTIONS_LEGACY_UNLOAD_BUTTON = "卸載歷史團本模組",
    OPTIONS_LEGACY_RELOAD_BUTTON = "重新載入介面",
    OPTIONS_LEGACY_HEADER = "歷史團本",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY = "啟用打斷顯示",
    OPTIONS_FALLENKING_INTERRUPT_DISPLAY_DESC = "在戰鬥中於敵方姓名板上顯示打斷標記。",
    OPTIONS_SSZORAK_VIRULENCE_DIRECTION = "劇毒方向語音",
    OPTIONS_COILEDALTAR_INTERRUPT_COUNTER = "中斷追蹤(焦點)",
    OPTIONS_COILEDALTAR_INTERRUPT_COUNTER_DESC =
    "Lura 式中斷追蹤:boss3 與 boss4 都會讀條,但只顯示你設為焦點的對象的計數。",
    OPTIONS_COILEDALTAR_INTERRUPT_NAMEPLATE = "顯示在姓名板上",
    OPTIONS_COILEDALTAR_INTERRUPT_NAMEPLATE_DESC =
    "在焦點 boss 的姓名板上方顯示計數。",
    OPTIONS_COILEDALTAR_INTERRUPT_FOCUSFRAME = "顯示在焦點施法框架旁",
    OPTIONS_COILEDALTAR_INTERRUPT_FOCUSFRAME_DESC =
    "在焦點施法條旁顯示計數。",
    OPTIONS_COILEDALTAR_INTERRUPT_CASTBAR = "顯示 Art 焦點施法條",
    OPTIONS_COILEDALTAR_INTERRUPT_CASTBAR_DESC =
    "顯示焦點目標的 Art(Lura)施法條及計數,位置在編輯模式中調整。",
    OPTIONS_SSZORAK_WINDCALL_RECEIVE = "報風口喊話條(接收)",
    OPTIONS_SSZORAK_WINDCALL_RECEIVE_DESC =
    "顯示收到的報風口喊話(/raid wN，N=1-6)：每條顯示對側標記(放點名位置)。史詩難度下聊天文本為 secret 時仍可用。",
    OPTIONS_SSZORAK_WINDCALL_PREVIEW = "預覽報風口(條+按鈕)",
    OPTIONS_SSZORAK_WINDCALL_SEND = "報風口按鈕(發送)",
    OPTIONS_SSZORAK_WINDCALL_SEND_DESC =
    "顯示 6 個按鈕(rt1-rt6),點擊即發送 /raid wN(供團長使用)。與接收條相互獨立。",
    OPTIONS_SSZORAK_VIRULENCE_DIRECTION_DESC =
    "獲得劇毒 debuff 時播放方向語音。斯索拉克的劇毒有兩種技能變體(1297707/1299899)，結束時會向不同方向發射毒液；由客戶端匹配光環後播放對應語音(Media/Sounds/go_left.ogg 或 go_right.ogg)。",
    OPTIONS_SSZORAK_EDIT_MODE = "在編輯模式中調整位置",
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
