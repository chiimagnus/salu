import Foundation

/// 语言枚举
enum Language: String {
    case chinese = "zh"
    case english = "en"
}

/// 国际化管理器
/// 支持中英文切换
final class Localization: @unchecked Sendable {
    
    // MARK: - 单例
    
    static let shared = Localization()
    
    // MARK: - 当前语言
    
    private(set) var currentLanguage: Language = .chinese
    
    private init() {}
    
    /// 切换语言
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }
    
    /// 切换到下一种语言
    func toggleLanguage() {
        currentLanguage = currentLanguage == .chinese ? .english : .chinese
    }
    
    // MARK: - 游戏标题
    
    var gameTitle: String {
        currentLanguage == .chinese ? "杀戮尖塔 CLI" : "Slay the Spire CLI"
    }
    
    var gameSubtitle: String {
        currentLanguage == .chinese ? "杀戮尖塔 CLI 版" : "Slay the Spire CLI"
    }
    
    var languageName: String {
        currentLanguage == .chinese ? "中文" : "English"
    }
    
    // MARK: - 通用词汇
    
    var turn: String { currentLanguage == .chinese ? "第" : "Turn" }
    var turnSuffix: String { currentLanguage == .chinese ? "回合" : "" }
    var cards: String { currentLanguage == .chinese ? "张" : "" }
    var seed: String { currentLanguage == .chinese ? "随机种子" : "Seed" }
    
    // MARK: - 战斗界面
    
    var block: String { currentLanguage == .chinese ? "格挡" : "Block" }
    var damage: String { currentLanguage == .chinese ? "伤害" : "Damage" }
    var intent: String { currentLanguage == .chinese ? "意图" : "Intent" }
    var attack: String { currentLanguage == .chinese ? "攻击" : "Attack" }
    var hand: String { currentLanguage == .chinese ? "手牌" : "Hand" }
    var drawPile: String { currentLanguage == .chinese ? "抽牌堆" : "Draw" }
    var discardPile: String { currentLanguage == .chinese ? "弃牌堆" : "Discard" }
    var eventLog: String { currentLanguage == .chinese ? "事件日志" : "Event Log" }
    
    // MARK: - 卡牌效果
    
    var deal: String { currentLanguage == .chinese ? "造成" : "Deal" }
    var gain: String { currentLanguage == .chinese ? "获得" : "Gain" }
    
    // MARK: - 操作提示
    
    var actions: String { currentLanguage == .chinese ? "操作" : "Actions" }
    var playCard: String { currentLanguage == .chinese ? "出牌" : "Play" }
    var endTurn: String { currentLanguage == .chinese ? "结束回合" : "End" }
    var help: String { currentLanguage == .chinese ? "帮助" : "Help" }
    var language: String { currentLanguage == .chinese ? "语言" : "Lang" }
    var quit: String { currentLanguage == .chinese ? "退出" : "Quit" }
    
    // MARK: - 帮助页面
    
    var helpTitle: String { currentLanguage == .chinese ? "游戏帮助" : "Help" }
    var controlsSection: String { currentLanguage == .chinese ? "操作说明" : "Controls" }
    var rulesSection: String { currentLanguage == .chinese ? "游戏规则" : "Rules" }
    
    var helpPlayCard: String { currentLanguage == .chinese ? "打出第 N 张手牌" : "Play card N" }
    var helpEndTurn: String { currentLanguage == .chinese ? "结束当前回合" : "End current turn" }
    var helpShowHelp: String { currentLanguage == .chinese ? "显示此帮助信息" : "Show this help" }
    var helpSwitchLang: String { currentLanguage == .chinese ? "切换语言" : "Switch language" }
    var helpQuit: String { currentLanguage == .chinese ? "退出游戏" : "Quit game" }
    
    var ruleEnergy: String { currentLanguage == .chinese ? "每回合开始时获得 3 点能量" : "Gain 3 energy each turn" }
    var ruleDraw: String { currentLanguage == .chinese ? "每回合抽 5 张牌" : "Draw 5 cards each turn" }
    var ruleBlock: String { currentLanguage == .chinese ? "格挡在每回合开始时清零" : "Block resets each turn" }
    var ruleDamage: String { currentLanguage == .chinese ? "伤害会先被格挡吸收" : "Block absorbs damage first" }
    var ruleWin: String { currentLanguage == .chinese ? "将敌人 HP 降为 0 即可获胜" : "Reduce enemy HP to 0 to win" }
    
    var pressEnterToReturn: String { currentLanguage == .chinese ? "按 Enter 返回游戏..." : "Press Enter to return..." }
    
    // MARK: - 语言切换页面
    
    var languageTitle: String { currentLanguage == .chinese ? "语言设置" : "Language" }
    var currentLanguageLabel: String { currentLanguage == .chinese ? "当前语言" : "Current" }
    
    // MARK: - 退出页面
    
    var exitMessage: String { currentLanguage == .chinese ? "感谢游玩 SALU！" : "Thanks for playing SALU!" }
    var exitSeeYou: String { currentLanguage == .chinese ? "期待下次再见！" : "See you next time!" }
    
    // MARK: - 战斗结果
    
    var victoryTitle: String { currentLanguage == .chinese ? "战 斗 胜 利" : "V I C T O R Y" }
    var defeatTitle: String { currentLanguage == .chinese ? "战 斗 失 败" : "D E F E A T" }
    var remainingHP: String { currentLanguage == .chinese ? "剩余 HP" : "HP Left" }
    var battleRounds: String { currentLanguage == .chinese ? "战斗回合" : "Rounds" }
    var survivedRounds: String { currentLanguage == .chinese ? "坚持回合" : "Survived" }
    var tryAgain: String { currentLanguage == .chinese ? "再接再厉！下次一定！" : "Try again! You can do it!" }
    
    // MARK: - 事件消息
    
    var battleStarted: String { currentLanguage == .chinese ? "战斗开始！" : "Battle Start!" }
    var turnStartedPrefix: String { currentLanguage == .chinese ? "第 " : "Turn " }
    var turnStartedSuffix: String { currentLanguage == .chinese ? " 回合开始" : " Start" }
    var energyResetTo: String { currentLanguage == .chinese ? "能量恢复至" : "Energy reset to" }
    var blockCleared: String { currentLanguage == .chinese ? "格挡清除" : "block cleared" }
    var drew: String { currentLanguage == .chinese ? "抽到" : "Drew" }
    var shuffled: String { currentLanguage == .chinese ? "洗牌" : "Shuffled" }
    var played: String { currentLanguage == .chinese ? "打出" : "Played" }
    var discarded: String { currentLanguage == .chinese ? "弃置" : "Discarded" }
    var cardsWord: String { currentLanguage == .chinese ? "张" : " cards" }
    var handCardsWord: String { currentLanguage == .chinese ? "张手牌" : " hand cards" }
    var fullyBlocked: String { currentLanguage == .chinese ? "完全格挡了攻击！" : "fully blocked the attack!" }
    var defeated: String { currentLanguage == .chinese ? "被击败！" : "defeated!" }
    var victory: String { currentLanguage == .chinese ? "战斗胜利！" : "Victory!" }
    var defeat: String { currentLanguage == .chinese ? "战斗失败..." : "Defeat..." }
    var notEnoughEnergy: String { currentLanguage == .chinese ? "能量不足" : "Not enough energy" }
    var need: String { currentLanguage == .chinese ? "需" : "Need" }
    var have: String { currentLanguage == .chinese ? "有" : "Have" }
    
    // MARK: - 错误消息
    
    var invalidInput: String { currentLanguage == .chinese ? "请输入有效数字，输入 h 查看帮助" : "Invalid input, press h for help" }
    var invalidChoice: String { currentLanguage == .chinese ? "无效选择" : "Invalid choice" }
    
    // MARK: - 开始游戏
    
    var pressEnterToStart: String { currentLanguage == .chinese ? "按 Enter 开始战斗..." : "Press Enter to start..." }
}

