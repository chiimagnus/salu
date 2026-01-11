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
            
        case .drew(let cardId):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.green)🃏 抽到 \(def.name)\(Terminal.reset)"
            
        case .shuffled(let count):
            return "\(Terminal.magenta)🔀 洗牌: \(count)张\(Terminal.reset)"
            
        case .played(let cardId, let cost):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.bold)▶️ 打出 \(def.name) (◆\(cost))\(Terminal.reset)"
            
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
            
        case .statusApplied(let target, let effect, let stacks):
            return "\(Terminal.magenta)✨ \(target) 获得 \(effect) \(stacks) 层\(Terminal.reset)"
            
        case .statusExpired(let target, let effect):
            return "\(Terminal.dim)💨 \(target) 的 \(effect) 已消退\(Terminal.reset)"
            
        // MARK: - 疯狂系统事件（占卜家序列）
            
        case .madnessReduced(let from, let to):
            return "\(Terminal.dim)🌀 疯狂消减: \(from) → \(to)\(Terminal.reset)"
            
        case .madnessThreshold(let level, let effect):
            let color = level >= 3 ? Terminal.red : (level >= 2 ? Terminal.yellow : Terminal.magenta)
            return "\(color)🌀 疯狂阈值 \(level) 触发: \(effect)\(Terminal.reset)"
            
        case .madnessDiscard(let cardId):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.red)🌀 疯狂弃牌: \(def.name)\(Terminal.reset)"
            
        case .madnessCleared(let amount):
            return "\(Terminal.green)🌀 疯狂清除 \(amount) 层\(Terminal.reset)"
            
        // MARK: - 占卜家机制事件 (P1)
            
        case .foresightChosen(let cardId, let fromCount):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.magenta)👁️ 预知 \(fromCount) 张，选择 \(def.name) 入手\(Terminal.reset)"
            
        case .rewindCard(let cardId):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.cyan)⏪ 回溯 \(def.name) 回到手牌\(Terminal.reset)"
            
        case .intentRewritten(let enemyName, let oldIntent, let newIntent):
            return "\(Terminal.yellow)✍️ 改写 \(enemyName)：\(oldIntent) → \(newIntent)\(Terminal.reset)"
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
