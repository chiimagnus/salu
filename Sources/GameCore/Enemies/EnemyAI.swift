/// 敌人 AI 决策协议
public protocol EnemyAI: Sendable {
    /// 决定下一个行动意图
    func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent
    
    /// 执行当前意图
    func executeIntent(
        intent: EnemyIntent,
        enemy: inout Entity,
        player: inout Entity
    ) -> [BattleEvent]
}
