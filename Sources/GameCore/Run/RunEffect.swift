/// Run 维度效果（P5：事件系统）
///
/// 用于在“非战斗房间”（如事件）中对冒险状态产生影响。
/// 约束：纯逻辑；可测试；不依赖 Foundation；可复现（随机应在上层派生 seed 后再决定数值）。
public enum RunEffect: Sendable, Equatable {
    // MARK: - Economy
    
    /// 获得金币
    case gainGold(amount: Int)
    
    /// 失去金币（会被 clamp 到 0）
    case loseGold(amount: Int)
    
    // MARK: - HP
    
    /// 回复生命（不超过最大生命）
    case heal(amount: Int)
    
    /// 受到伤害（不低于 0；到 0 则冒险失败）
    case takeDamage(amount: Int)
    
    // MARK: - Deck / Relics
    
    /// 获得一张卡牌（以 cardId 表示）
    case addCard(cardId: CardID)
    
    /// 获得一件遗物
    case addRelic(relicId: RelicID)

    // MARK: - Status (P5: 事件可影响玩家状态)

    /// 对玩家状态施加层数变化（可正可负）
    case applyStatus(statusId: StatusID, stacks: Int)

    /// 直接设置玩家状态层数（<=0 视为移除）
    case setStatus(statusId: StatusID, stacks: Int)

    // MARK: - Consumables (P5: 事件奖励消耗品)

    /// 获得一个消耗品（若槽位已满则可能失败，见 RunState.apply 实现）
    case addConsumable(consumableId: ConsumableID)
    
    // MARK: - Upgrade
    
    /// 升级牌组中指定索引的卡牌（需要该卡可升级）
    case upgradeCard(deckIndex: Int)
}


