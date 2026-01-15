/// 卡牌奖励卡池（P1）
public enum CardPool {
    /// 可作为战斗奖励的卡牌 ID 列表（按 rawValue 排序，保证确定性）
    ///
    /// 当前策略（P1）：
    /// - 排除 `starter` 稀有度的卡牌（起始牌不进入奖励池）
    public static func rewardableCardIds() -> [CardID] {
        CardRegistry.allCardIds
            .filter { id in
                let def = CardRegistry.require(id)
                // 排除：起始牌、消耗性卡牌（原“消耗品”，不作为战斗奖励出现）
                return def.rarity != .starter && def.type != .consumable
            }
        }
    }
