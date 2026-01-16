import GameCore

/// 事件格式化器
/// 将 BattleEvent 转换为带颜色的终端显示字符串
enum EventFormatter {
    
    /// 格式化单个事件为显示字符串
    static func format(_ event: BattleEvent) -> String {
        switch event {
        case .battleStarted:
            return "\(Terminal.bold)\(Terminal.magenta)⚔️ \(L10n.text("战斗开始！", "Battle begins!"))\(Terminal.reset)"
            
        case .turnStarted(let turn):
            return "\(Terminal.cyan)══ \(L10n.text("第", "Turn")) \(turn) \(L10n.text("回合开始", "begins")) ══\(Terminal.reset)"
            
        case .energyReset(let amount):
            return "\(Terminal.yellow)⚡ \(L10n.text("能量恢复至", "Energy restored to")) \(amount)\(Terminal.reset)"
            
        case .blockCleared(let target, let amount):
            return "\(Terminal.dim)🛡️ \(L10n.resolve(target)) \(amount) \(L10n.text("格挡清除", "Block cleared"))\(Terminal.reset)"
            
        case .drew(let cardId):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.green)🃏 \(L10n.text("抽到", "Drew")) \(L10n.resolve(def.name))\(Terminal.reset)"
            
        case .shuffled(let count):
            return "\(Terminal.magenta)🔀 \(L10n.text("洗牌", "Shuffle")): \(count)\(L10n.text("张", " cards"))\(Terminal.reset)"
            
        case .played(_, let cardId, let cost):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.bold)▶️ \(L10n.text("打出", "Played")) \(L10n.resolve(def.name)) (◆\(cost))\(Terminal.reset)"
            
        case .damageDealt(let source, let target, let amount, let blocked):
            return formatDamage(source: source, target: target, amount: amount, blocked: blocked)
            
        case .blockGained(let target, let amount):
            return "\(Terminal.cyan)🛡️ \(L10n.resolve(target)) +\(amount) \(L10n.text("格挡", "Block"))\(Terminal.reset)"
            
        case .handDiscarded(let count):
            return "\(Terminal.dim)🗑️ \(L10n.text("弃置", "Discard")) \(count) \(L10n.text("张手牌", "cards"))\(Terminal.reset)"
            
        case .enemyIntent(_, _, _):
            return ""  // 不显示，已经在界面上显示了
            
        case .enemyAction(let enemyId, let action):
            return "\(Terminal.red)\(Terminal.bold)👹 \(enemyId) \(L10n.resolve(action))！\(Terminal.reset)"
            
        case .turnEnded(let turn):
            return "\(Terminal.dim)── \(L10n.text("第", "Turn")) \(turn) \(L10n.text("回合结束", "ends")) ──\(Terminal.reset)"
            
        case .entityDied(_, let name):
            return "\(Terminal.red)\(Terminal.bold)💀 \(L10n.resolve(name)) \(L10n.text("被击败！", "was defeated!"))\(Terminal.reset)"
            
        case .battleWon:
            return "\(Terminal.green)\(Terminal.bold)🎉 \(L10n.text("战斗胜利！", "Victory!"))\(Terminal.reset)"
            
        case .battleLost:
            return "\(Terminal.red)\(Terminal.bold)💔 \(L10n.text("战斗失败...", "Defeat..."))\(Terminal.reset)"
            
        case .notEnoughEnergy(let required, let available):
            return "\(Terminal.red)⚠️ \(L10n.text("能量不足", "Not enough energy")): \(L10n.text("需", "need")) \(required), \(L10n.text("有", "have")) \(available)\(Terminal.reset)"
            
        case .invalidAction(let reason):
            return "\(Terminal.red)❌ \(L10n.resolve(reason))\(Terminal.reset)"
            
        case .statusApplied(let target, let effect, let stacks):
            return "\(Terminal.magenta)✨ \(L10n.resolve(target)) \(L10n.text("获得", "gains")) \(L10n.resolve(effect)) \(stacks) \(L10n.text("层", "stacks"))\(Terminal.reset)"
            
        case .statusExpired(let target, let effect):
            return "\(Terminal.dim)💨 \(L10n.resolve(target)) \(L10n.text("的", "'s")) \(L10n.resolve(effect)) \(L10n.text("已消退", "has faded"))\(Terminal.reset)"
            
        // MARK: - 疯狂系统事件（占卜家序列）
            
        case .madnessReduced(let from, let to):
            return "\(Terminal.dim)🌀 \(L10n.text("疯狂消减", "Madness reduced")): \(from) → \(to)\(Terminal.reset)"
            
        case .madnessThreshold(let level, let effect):
            let color = level >= 3 ? Terminal.red : (level >= 2 ? Terminal.yellow : Terminal.magenta)
            return "\(color)🌀 \(L10n.text("疯狂阈值", "Madness threshold")) \(level) \(L10n.text("触发", "triggered")): \(L10n.resolve(effect))\(Terminal.reset)"
            
        case .madnessDiscard(let cardId):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.red)🌀 \(L10n.text("疯狂弃牌", "Madness discard")): \(L10n.resolve(def.name))\(Terminal.reset)"
            
        case .madnessCleared(let amount):
            return "\(Terminal.green)🌀 \(L10n.text("疯狂清除", "Madness cleared")) \(amount) \(L10n.text("层", "stacks"))\(Terminal.reset)"
            
        // MARK: - 占卜家机制事件 (P1)
            
        case .foresightChosen(let cardId, let fromCount):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.magenta)👁️ \(L10n.text("预知", "Foresee")) \(fromCount) \(L10n.text("张", "cards"))，\(L10n.text("选择", "choose")) \(L10n.resolve(def.name)) \(L10n.text("入手", "to hand"))\(Terminal.reset)"
            
        case .rewindCard(let cardId):
            let def = CardRegistry.require(cardId)
            return "\(Terminal.cyan)⏪ \(L10n.text("回溯", "Rewind")) \(L10n.resolve(def.name)) \(L10n.text("回到手牌", "back to hand"))\(Terminal.reset)"
            
        case .intentRewritten(let enemyName, let oldIntent, let newIntent):
            return "\(Terminal.yellow)✍️ \(L10n.text("改写", "Rewrite")) \(L10n.resolve(enemyName))：\(L10n.resolve(oldIntent)) → \(L10n.resolve(newIntent))\(Terminal.reset)"
        }
    }
    
    /// 格式化伤害事件
    private static func formatDamage(source: LocalizedText, target: LocalizedText, amount: Int, blocked: Int) -> String {
        if blocked > 0 && amount == 0 {
            return "\(Terminal.cyan)🛡️ \(L10n.resolve(target)) \(L10n.text("完全格挡了攻击！", "fully blocked the attack!"))\(Terminal.reset)"
        } else if blocked > 0 {
            return "\(Terminal.red)💥 \(L10n.resolve(source))→\(L10n.resolve(target)) \(amount) \(L10n.text("伤害", "damage"))\(Terminal.reset)\(Terminal.cyan)(\(blocked) \(L10n.text("格挡", "blocked")))\(Terminal.reset)"
        } else {
            return "\(Terminal.red)💥 \(L10n.resolve(source))→\(L10n.resolve(target)) \(amount) \(L10n.text("伤害", "damage"))\(Terminal.reset)"
        }
    }
}
