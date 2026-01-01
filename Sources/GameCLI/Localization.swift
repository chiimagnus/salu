import Foundation

/// 语言枚举
enum Language: String {
    case chinese = "zh"
    case english = "en"
}

/// 国际化管理器
/// 支持中英文切换，从 JSON 文件加载语言字符串
final class Localization: @unchecked Sendable {
    
    // MARK: - 单例
    
    static let shared = Localization()
    
    // MARK: - 当前语言
    
    private(set) var currentLanguage: Language = .chinese
    
    // MARK: - 语言字符串字典
    
    private var strings: [String: String] = [:]
    
    // MARK: - 初始化
    
    private init() {
        // 从配置加载保存的语言偏好
        let savedLanguage = ConfigManager.shared.loadLanguagePreference()
        currentLanguage = savedLanguage
        loadLanguageStrings()
    }
    
    // MARK: - 语言切换
    
    /// 切换语言
    func setLanguage(_ language: Language) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        loadLanguageStrings()
        // 保存语言偏好
        ConfigManager.shared.saveLanguagePreference(language)
    }
    
    /// 切换到下一种语言
    func toggleLanguage() {
        let newLanguage = currentLanguage == .chinese ? Language.english : Language.chinese
        setLanguage(newLanguage)
    }
    
    // MARK: - 加载语言文件
    
    /// 从 JSON 文件加载语言字符串
    private func loadLanguageStrings() {
        let fileName = "\(currentLanguage.rawValue).json"
        
        // 尝试从 Bundle.module 加载（SPM 资源）
        if let url = Bundle.module.url(forResource: currentLanguage.rawValue, withExtension: "json") {
            if loadFromFile(url: url) {
                return
            }
        }
        
        // 尝试多个可能的路径（开发/测试环境）
        let possiblePaths = [
            // 开发环境路径
            "Sources/GameCLI/Resources/\(fileName)",
            // 相对于当前工作目录
            "./Sources/GameCLI/Resources/\(fileName)"
        ]
        
        for path in possiblePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                if loadFromFile(url: url) {
                    return
                }
            }
        }
        
        // 如果都找不到，使用内嵌的默认字符串
        loadDefaultStrings()
    }
    
    /// 从文件加载
    private func loadFromFile(url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            strings = try JSONDecoder().decode([String: String].self, from: data)
            return true
        } catch {
            return false
        }
    }
    
    /// 加载默认字符串（备用）
    private func loadDefaultStrings() {
        if currentLanguage == .chinese {
            strings = [
                "game_title": "杀戮尖塔 CLI",
                "game_subtitle": "杀戮尖塔 CLI 版",
                "language_name": "中文",
                "turn": "第",
                "turn_suffix": "回合",
                "cards": "张",
                "seed": "随机种子",
                "block": "格挡",
                "damage": "伤害",
                "intent": "意图",
                "attack": "攻击",
                "hand": "手牌",
                "draw_pile": "抽牌堆",
                "discard_pile": "弃牌堆",
                "event_log": "事件日志",
                "deal": "造成",
                "gain": "获得",
                "actions": "操作",
                "play_card": "出牌",
                "end_turn": "结束回合",
                "help": "帮助",
                "language": "语言",
                "quit": "退出",
                "press_enter_to_start": "按 Enter 开始战斗...",
                "invalid_input": "请输入有效数字，输入 h 查看帮助",
                "invalid_choice": "无效选择"
            ]
        } else {
            strings = [
                "game_title": "Slay the Spire CLI",
                "game_subtitle": "Slay the Spire CLI",
                "language_name": "English",
                "turn": "Turn",
                "turn_suffix": "",
                "cards": "",
                "seed": "Seed",
                "block": "Block",
                "damage": "Damage",
                "intent": "Intent",
                "attack": "Attack",
                "hand": "Hand",
                "draw_pile": "Draw",
                "discard_pile": "Discard",
                "event_log": "Event Log",
                "deal": "Deal",
                "gain": "Gain",
                "actions": "Actions",
                "play_card": "Play",
                "end_turn": "End",
                "help": "Help",
                "language": "Lang",
                "quit": "Quit",
                "press_enter_to_start": "Press Enter to start...",
                "invalid_input": "Invalid input, press h for help",
                "invalid_choice": "Invalid choice"
            ]
        }
    }
    
    // MARK: - 字符串访问
    
    /// 获取本地化字符串
    private func string(_ key: String) -> String {
        return strings[key] ?? key
    }
    
    // MARK: - 游戏标题
    
    var gameTitle: String { string("game_title") }
    var gameSubtitle: String { string("game_subtitle") }
    var languageName: String { string("language_name") }
    
    // MARK: - 通用词汇
    
    var turn: String { string("turn") }
    var turnSuffix: String { string("turn_suffix") }
    var cards: String { string("cards") }
    var seed: String { string("seed") }
    
    // MARK: - 战斗界面
    
    var block: String { string("block") }
    var damage: String { string("damage") }
    var intent: String { string("intent") }
    var attack: String { string("attack") }
    var hand: String { string("hand") }
    var drawPile: String { string("draw_pile") }
    var discardPile: String { string("discard_pile") }
    var eventLog: String { string("event_log") }
    
    // MARK: - 卡牌效果
    
    var deal: String { string("deal") }
    var gain: String { string("gain") }
    
    // MARK: - 操作提示
    
    var actions: String { string("actions") }
    var playCard: String { string("play_card") }
    var endTurn: String { string("end_turn") }
    var help: String { string("help") }
    var language: String { string("language") }
    var quit: String { string("quit") }
    
    // MARK: - 帮助页面
    
    var helpTitle: String { string("help_title") }
    var controlsSection: String { string("controls_section") }
    var rulesSection: String { string("rules_section") }
    var helpPlayCard: String { string("help_play_card") }
    var helpEndTurn: String { string("help_end_turn") }
    var helpShowHelp: String { string("help_show_help") }
    var helpSwitchLang: String { string("help_switch_lang") }
    var helpQuit: String { string("help_quit") }
    var ruleEnergy: String { string("rule_energy") }
    var ruleDraw: String { string("rule_draw") }
    var ruleBlock: String { string("rule_block") }
    var ruleDamage: String { string("rule_damage") }
    var ruleWin: String { string("rule_win") }
    var pressEnterToReturn: String { string("press_enter_to_return") }
    
    // MARK: - 语言切换页面
    
    var languageTitle: String { string("language_title") }
    var currentLanguageLabel: String { string("current_language") }
    var selectLanguage: String { string("select_language") }
    var languageSaved: String { string("language_saved") }
    
    // MARK: - 退出页面
    
    var exitMessage: String { string("exit_message") }
    var exitSeeYou: String { string("exit_see_you") }
    
    // MARK: - 战斗结果
    
    var victoryTitle: String { string("victory_title") }
    var defeatTitle: String { string("defeat_title") }
    var remainingHP: String { string("remaining_hp") }
    var battleRounds: String { string("battle_rounds") }
    var survivedRounds: String { string("survived_rounds") }
    var tryAgain: String { string("try_again") }
    
    // MARK: - 事件消息
    
    var battleStarted: String { string("battle_started") }
    var turnStartedPrefix: String { string("turn_started_prefix") }
    var turnStartedSuffix: String { string("turn_started_suffix") }
    var energyResetTo: String { string("energy_reset_to") }
    var blockCleared: String { string("block_cleared") }
    var drew: String { string("drew") }
    var shuffled: String { string("shuffled") }
    var played: String { string("played") }
    var discarded: String { string("discarded") }
    var cardsWord: String { string("cards_word") }
    var handCardsWord: String { string("hand_cards_word") }
    var fullyBlocked: String { string("fully_blocked") }
    var defeated: String { string("defeated") }
    var victory: String { string("victory") }
    var defeat: String { string("defeat") }
    var notEnoughEnergy: String { string("not_enough_energy") }
    var need: String { string("need") }
    var have: String { string("have") }
    
    // MARK: - 错误消息
    
    var invalidInput: String { string("invalid_input") }
    var invalidChoice: String { string("invalid_choice") }
    
    // MARK: - 开始游戏
    
    var pressEnterToStart: String { string("press_enter_to_start") }
    var welcomeTitle: String { string("welcome_title") }
    var welcomeSubtitle: String { string("welcome_subtitle") }
    var pressEnterToContinue: String { string("press_enter_to_continue") }
}

