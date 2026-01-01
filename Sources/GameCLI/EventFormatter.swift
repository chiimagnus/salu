import GameCore

/// 事件格式化器
/// 将 BattleEvent 转换为带颜色的终端显示字符串
enum EventFormatter {
    
    /// 格式化单个事件为显示字符串
    static func format(_ event: BattleEvent) -> String {
        switch event {
        case .battleStarted:
            return "\(Terminal.bold)\(Terminal.magenta)⚔️ 战斗开始！\(Terminal.reset)"
            
        case .turnStarted(let turn):
            return "\(Terminal.cyan)══ 第 \(turn) 回合开始 ══\(Terminal.reset)"
            
        case .energyReset(let amount):
            return "\(Terminal.yellow)⚡ 能量恢复至 \(amount)\(Terminal.reset)"
            
        case .blockCleared(let target, let amount):
            return "\(Terminal.dim)🛡️ \(target) \(amount) 格挡清除\(Terminal.reset)"
            
        case .drew(_, let cardName):
            return "\(Terminal.green)🃏 抽到 \(cardName)\(Terminal.reset)"
            
        case .shuffled(let count):
            return "\(Terminal.magenta)🔀 洗牌: \(count)张\(Terminal.reset)"
            
        case .played(_, let cardName, let cost):
            return "\(Terminal.bold)▶️ 打出 \(cardName) (◆\(cost))\(Terminal.reset)"
            
        case .damageDealt(let source, let target, let amount, let blocked):
            return formatDamage(source: source, target: target, amount: amount, blocked: blocked)
            
        case .blockGained(let target, let amount):
            return "\(Terminal.cyan)🛡️ \(target) +\(amount) 格挡\(Terminal.reset)"
            
        case .handDiscarded(let count):
            return "\(Terminal.dim)🗑️ 弃置 \(count)张手牌\(Terminal.reset)"
            
        case .enemyIntent(_, _, _):
            return ""  // 不显示，已经在界面上显示了
            
        case .enemyAction(let enemyId, let action):
            return "\(Terminal.red)\(Terminal.bold)👹 \(enemyId) \(action)！\(Terminal.reset)"
            
        case .turnEnded(let turn):
            return "\(Terminal.dim)── 第 \(turn) 回合结束 ──\(Terminal.reset)"
            
        case .entityDied(_, let name):
            return "\(Terminal.red)\(Terminal.bold)💀 \(name) 被击败！\(Terminal.reset)"
            
        case .battleWon:
            return "\(Terminal.green)\(Terminal.bold)🎉 战斗胜利！\(Terminal.reset)"
            
        case .battleLost:
            return "\(Terminal.red)\(Terminal.bold)💔 战斗失败...\(Terminal.reset)"
            
        case .notEnoughEnergy(let required, let available):
            return "\(Terminal.red)⚠️ 能量不足: 需 \(required), 有 \(available)\(Terminal.reset)"
            
        case .invalidAction(let reason):
            return "\(Terminal.red)❌ \(reason)\(Terminal.reset)"
        }
    }
    
    /// 格式化伤害事件
    private static func formatDamage(source: String, target: String, amount: Int, blocked: Int) -> String {
        if blocked > 0 && amount == 0 {
            return "\(Terminal.cyan)🛡️ \(target) 完全格挡了攻击！\(Terminal.reset)"
        } else if blocked > 0 {
            return "\(Terminal.red)💥 \(source)→\(target) \(amount) 伤害\(Terminal.reset)\(Terminal.cyan)(\(blocked) 格挡)\(Terminal.reset)"
        } else {
            return "\(Terminal.red)💥 \(source)→\(target) \(amount) 伤害\(Terminal.reset)"
        }
    }
}
