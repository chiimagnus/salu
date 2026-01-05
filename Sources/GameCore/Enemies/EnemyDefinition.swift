// MARK: - Enemy Definition Protocol

/// 敌人定义协议（数据 + AI）
/// 约束：只能产出 EnemyMove（effects 由 BattleEngine 执行并发事件）
public protocol EnemyDefinition: Sendable {
    /// 敌人 ID
    static var id: EnemyID { get }
    
    /// 显示名称（用于 UI）
    static var name: String { get }
    
    /// 生命值范围（生成实例时使用）
    static var hpRange: ClosedRange<Int> { get }
    
    /// AI：根据快照选择下一步行动（可使用 rng，但必须把随机结果固化进 effects）
    ///
    /// - Parameters:
    ///   - selfIndex: 该敌人在当前战斗 `BattleState.enemies` 中的索引（用于把“对自己施加效果”等落到正确目标）
    static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove
}
