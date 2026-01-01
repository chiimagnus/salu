/// 战斗统计（在战斗过程中累积）
/// 用于记录战斗过程中的各项数据，生成战绩报告
public struct BattleStats: Sendable {
    public var cardsPlayed: Int = 0
    public var strikesPlayed: Int = 0      // 攻击类卡牌
    public var defendsPlayed: Int = 0      // 防御类卡牌
    public var skillsPlayed: Int = 0       // 技能类卡牌
    public var totalDamageDealt: Int = 0   // 对敌人造成的伤害
    public var totalDamageTaken: Int = 0   // 受到的伤害
    public var totalBlockGained: Int = 0   // 获得的格挡
    
    public init() {}
}

