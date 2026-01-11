// MARK: - Enemy Registry

/// 敌人注册表
/// 新增敌人的唯一扩展点
public enum EnemyRegistry {
    /// 注册的敌人定义
    private static let defs: [EnemyID: any EnemyDefinition.Type] = [
        // Act 1 Enemies
        JawWorm.id: JawWorm.self,
        Cultist.id: Cultist.self,
        LouseGreen.id: LouseGreen.self,
        LouseRed.id: LouseRed.self,
        SporeBeast.id: SporeBeast.self,
        SlimeSmallAcid.id: SlimeSmallAcid.self,
        SlimeMediumAcid.id: SlimeMediumAcid.self,
        StoneSentinel.id: StoneSentinel.self,
        
        // Act 1 Bosses
        ToxicColossus.id: ToxicColossus.self,
        
        // Act 2 Enemies
        ShadowStalker.id: ShadowStalker.self,
        ClockworkSentinel.id: ClockworkSentinel.self,
        RuneGuardian.id: RuneGuardian.self,
        
        // Act 2 Elites (P2 占卜家序列新增)
        MadProphet.id: MadProphet.self,
        TimeGuardian.id: TimeGuardian.self,
        
        // Act 2 Bosses
        Cipher.id: Cipher.self,  // P2 赛弗
        
        // Act 3 Enemies
        VoidWalker.id: VoidWalker.self,
        DreamParasite.id: DreamParasite.self,
        CycleGuardian.id: CycleGuardian.self,
        
        // Act 3 Bosses
        SequenceProgenitor.id: SequenceProgenitor.self,
    ]
    
    /// 获取敌人定义
    public static func get(_ id: EnemyID) -> (any EnemyDefinition.Type)? {
        return defs[id]
    }
    
    /// 强制获取敌人定义（找不到会崩溃，用于必须存在的敌人）
    public static func require(_ id: EnemyID) -> any EnemyDefinition.Type {
        precondition(defs[id] != nil, "EnemyRegistry: 未找到敌人定义 '\(id.rawValue)'")
        return defs[id]!
    }
}
