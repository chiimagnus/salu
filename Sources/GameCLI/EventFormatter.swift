import GameCore

/// 事件格式化器
/// 将 BattleEvent 转换为带颜色的终端显示字符串
enum EventFormatter {
    
    /// 格式化单个事件为显示字符串
    static func format(_ event: BattleEvent) -> String {
        let L = Localization.shared
        
        switch event {
        case .battleStarted:
            return "\(Terminal.bold)\(Terminal.magenta)⚔️ \(L.battleStarted)\(Terminal.reset)"
            
        case .turnStarted(let turn):
            return "\(Terminal.cyan)══ \(L.turnStartedPrefix)\(turn)\(L.turnStartedSuffix) ══\(Terminal.reset)"
            
        case .energyReset(let amount):
            return "\(Terminal.yellow)⚡ \(L.energyResetTo) \(amount)\(Terminal.reset)"
            
        case .blockCleared(let target, let amount):
            return "\(Terminal.dim)🛡️ \(target) \(amount) \(L.blockCleared)\(Terminal.reset)"
            
        case .drew(_, let cardName):
            return "\(Terminal.green)🃏 \(L.drew) \(cardName)\(Terminal.reset)"
            
        case .shuffled(let count):
            return "\(Terminal.magenta)🔀 \(L.shuffled): \(count)\(L.cardsWord)\(Terminal.reset)"
            
        case .played(_, let cardName, let cost):
            return "\(Terminal.bold)▶️ \(L.played) \(cardName) (◆\(cost))\(Terminal.reset)"
            
        case .damageDealt(let source, let target, let amount, let blocked):
            return formatDamage(source: source, target: target, amount: amount, blocked: blocked)
            
        case .blockGained(let target, let amount):
            return "\(Terminal.cyan)🛡️ \(target) +\(amount) \(L.block)\(Terminal.reset)"
            
        case .handDiscarded(let count):
            return "\(Terminal.dim)🗑️ \(L.discarded) \(count)\(L.handCardsWord)\(Terminal.reset)"
            
        case .enemyIntent(_, _, _):
            return ""  // 不显示，已经在界面上显示了
            
        case .enemyAction(let enemyId, let action):
            return "\(Terminal.red)\(Terminal.bold)👹 \(enemyId) \(action)！\(Terminal.reset)"
            
        case .turnEnded(let turn):
            return "\(Terminal.dim)── \(L.turnStartedPrefix)\(turn)\(L.turnStartedSuffix.replacingOccurrences(of: "开始", with: "结束").replacingOccurrences(of: "Start", with: "End")) ──\(Terminal.reset)"
            
        case .entityDied(_, let name):
            return "\(Terminal.red)\(Terminal.bold)💀 \(name) \(L.defeated)\(Terminal.reset)"
            
        case .battleWon:
            return "\(Terminal.green)\(Terminal.bold)🎉 \(L.victory)\(Terminal.reset)"
            
        case .battleLost:
            return "\(Terminal.red)\(Terminal.bold)💔 \(L.defeat)\(Terminal.reset)"
            
        case .notEnoughEnergy(let required, let available):
            return "\(Terminal.red)⚠️ \(L.notEnoughEnergy): \(L.need) \(required), \(L.have) \(available)\(Terminal.reset)"
            
        case .invalidAction(let reason):
            return "\(Terminal.red)❌ \(reason)\(Terminal.reset)"
        }
    }
    
    /// 格式化伤害事件
    private static func formatDamage(source: String, target: String, amount: Int, blocked: Int) -> String {
        let L = Localization.shared
        
        if blocked > 0 && amount == 0 {
            return "\(Terminal.cyan)🛡️ \(target) \(L.fullyBlocked)\(Terminal.reset)"
        } else if blocked > 0 {
            return "\(Terminal.red)💥 \(source)→\(target) \(amount) \(L.damage)\(Terminal.reset)\(Terminal.cyan)(\(blocked) \(L.block))\(Terminal.reset)"
        } else {
            return "\(Terminal.red)💥 \(source)→\(target) \(amount) \(L.damage)\(Terminal.reset)"
        }
    }
}
