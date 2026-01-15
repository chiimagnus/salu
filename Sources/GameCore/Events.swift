/// 战斗事件
/// 用于记录战斗中发生的所有事件，便于 UI 展示和测试断言
public enum BattleEvent: Sendable, Equatable {
    /// 战斗开始
    case battleStarted
    
    /// 回合开始
    case turnStarted(turn: Int)
    
    /// 能量重置
    case energyReset(amount: Int)
    
    /// 格挡清除
    case blockCleared(target: String, amount: Int)
    
    /// 抽牌
    case drew(cardId: CardID)
    
    /// 洗牌（弃牌堆洗回抽牌堆）
    case shuffled(count: Int)
    
    /// 打出卡牌
    case played(cardInstanceId: String, cardId: CardID, cost: Int)
    
    /// 造成伤害
    case damageDealt(source: String, target: String, amount: Int, blocked: Int)
    
    /// 获得格挡
    case blockGained(target: String, amount: Int)
    
    /// 手牌弃置（回合结束时）
    case handDiscarded(count: Int)
    
    /// 敌人意图
    case enemyIntent(enemyId: String, action: String, damage: Int)
    
    /// 敌人行动
    case enemyAction(enemyId: String, action: String)
    
    /// 回合结束
    case turnEnded(turn: Int)
    
    /// 实体死亡
    case entityDied(entityId: String, name: String)
    
    /// 战斗胜利
    case battleWon
    
    /// 战斗失败
    case battleLost
    
    /// 能量不足（尝试出牌失败）
    case notEnoughEnergy(required: Int, available: Int)
    
    /// 无效操作
    case invalidAction(reason: String)
    
    /// 获得状态效果
    case statusApplied(target: String, effect: String, stacks: Int)
    
    /// 状态效果过期
    case statusExpired(target: String, effect: String)
    
    // MARK: - 疯狂系统事件（占卜家序列）
    
    /// 疯狂消减（回合结束时）
    case madnessReduced(from: Int, to: Int)
    
    /// 疯狂阈值触发
    case madnessThreshold(level: Int, effect: String)
    
    /// 疯狂导致弃牌
    case madnessDiscard(cardId: CardID)
    
    /// 疯狂被清除
    case madnessCleared(amount: Int)
    
    // MARK: - 占卜家机制事件 (P1)
    
    /// 预知选择
    case foresightChosen(cardId: CardID, fromCount: Int)
    
    /// 回溯卡牌
    case rewindCard(cardId: CardID)
    
    /// 意图被改写
    case intentRewritten(enemyName: String, oldIntent: String, newIntent: String)
}

/// 事件描述（用于 CLI 显示）
extension BattleEvent {
    public var description: String {
        switch self {
        case .battleStarted:
            return "⚔️ 战斗开始！"
            
        case .turnStarted(let turn):
            return "═══════════ 第 \(turn) 回合 ═══════════"
            
        case .energyReset(let amount):
            return "⚡ 能量恢复至 \(amount)"
            
        case .blockCleared(let target, let amount):
            return "🛡️ \(target) 的格挡 \(amount) 已清除"
            
        case .drew(let cardId):
            let def = CardRegistry.require(cardId)
            return "🃏 抽到 \(def.name)"
            
        case .shuffled(let count):
            return "🔀 洗牌：\(count) 张牌从弃牌堆洗入抽牌堆"
            
        case .played(_, let cardId, let cost):
            let def = CardRegistry.require(cardId)
            return "▶️ 打出 \(def.name)（消耗 \(cost) 能量）"
            
        case .damageDealt(let source, let target, let amount, let blocked):
            if blocked > 0 {
                return "💥 \(source) 对 \(target) 造成 \(amount) 伤害（\(blocked) 被格挡）"
            } else {
                return "💥 \(source) 对 \(target) 造成 \(amount) 伤害"
            }
            
        case .blockGained(let target, let amount):
            return "🛡️ \(target) 获得 \(amount) 格挡"
            
        case .handDiscarded(let count):
            return "🗑️ 弃置 \(count) 张手牌"
            
        case .enemyIntent(_, let action, let damage):
            return "👁️ 敌人意图：\(action)（\(damage) 伤害）"
            
        case .enemyAction(let enemyId, let action):
            return "👹 \(enemyId) 执行 \(action)"
            
        case .turnEnded(let turn):
            return "───────── 第 \(turn) 回合结束 ─────────"
            
        case .entityDied(_, let name):
            return "💀 \(name) 已死亡"
            
        case .battleWon:
            return "🎉 战斗胜利！"
            
        case .battleLost:
            return "💔 战斗失败..."
            
        case .notEnoughEnergy(let required, let available):
            return "⚠️ 能量不足：需要 \(required)，当前 \(available)"
            
        case .invalidAction(let reason):
            return "❌ 无效操作：\(reason)"
            
        case .statusApplied(let target, let effect, let stacks):
            return "✨ \(target) 获得 \(effect) \(stacks) 层"
            
        case .statusExpired(let target, let effect):
            return "💨 \(target) 的 \(effect) 已消退"
            
        // MARK: - 疯狂系统事件
            
        case .madnessReduced(let from, let to):
            return "🌀 疯狂消减：\(from) → \(to)"
            
        case .madnessThreshold(let level, let effect):
            return "🌀 疯狂阈值 \(level) 触发：\(effect)"
            
        case .madnessDiscard(let cardId):
            let def = CardRegistry.require(cardId)
            return "🌀 疯狂导致弃牌：\(def.name)"
            
        case .madnessCleared(let amount):
            if amount == 0 {
                return "🌀 疯狂完全消除"
            } else {
                return "🌀 疯狂消除 \(amount) 层"
            }
            
        // MARK: - 占卜家机制事件
            
        case .foresightChosen(let cardId, let fromCount):
            let def = CardRegistry.require(cardId)
            return "👁️ 预知 \(fromCount) 张，选择 \(def.name) 入手"
            
        case .rewindCard(let cardId):
            let def = CardRegistry.require(cardId)
            return "⏪ 回溯 \(def.name) 回到手牌"
            
        case .intentRewritten(let enemyName, let oldIntent, let newIntent):
            return "✍️ 改写 \(enemyName) 的意图：\(oldIntent) → \(newIntent)"
        }
    }
}
