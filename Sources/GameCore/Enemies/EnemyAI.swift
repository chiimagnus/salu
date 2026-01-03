/// 敌人 AI 决策协议
/// 每种敌人实现自己的决策逻辑
public protocol EnemyAI: Sendable {
    /// 决定下一个行动意图
    /// - Parameters:
    ///   - enemy: 敌人实体
    ///   - player: 玩家实体
    ///   - turn: 当前回合数
    ///   - rng: 随机数生成器
    /// - Returns: 敌人意图
    func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent
}

/// AI 工厂
/// 根据敌人种类创建对应的 AI 实例
public enum EnemyAIFactory {
    public static func create(for kind: EnemyKind) -> any EnemyAI {
        switch kind {
        case .jawWorm:
            return JawWormAI()
        case .cultist:
            return CultistAI()
        case .louseGreen, .louseRed:
            return LouseAI()
        case .slimeMediumAcid:
            return SlimeAI()
        case .slimeBossSmall:
            return SlimeBossAI()
        }
    }
}

