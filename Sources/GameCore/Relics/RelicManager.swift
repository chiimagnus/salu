// MARK: - Relic Manager

/// 遗物管理器
/// 管理玩家持有的遗物，处理触发事件
public struct RelicManager: Sendable {
    /// 持有的遗物 ID 列表
    private var relicIds: [RelicID] = []
    
    /// 初始化
    public init() {}
    
    /// 初始化并添加初始遗物
    public init(relics: [RelicID]) {
        self.relicIds = relics
    }
    
    /// 添加遗物
    public mutating func add(_ relicId: RelicID) {
        guard !relicIds.contains(relicId) else { return }
        relicIds.append(relicId)
    }
    
    /// 移除遗物
    public mutating func remove(_ relicId: RelicID) {
        relicIds.removeAll { $0 == relicId }
    }
    
    /// 是否拥有指定遗物
    public func has(_ relicId: RelicID) -> Bool {
        relicIds.contains(relicId)
    }
    
    /// 获取所有持有的遗物 ID
    public var all: [RelicID] {
        relicIds
    }
    
    /// 战斗触发：收集所有遗物产出的 BattleEffect（由 BattleEngine 执行）
    /// - Parameters:
    ///   - trigger: 触发点
    ///   - snapshot: 战斗快照
    /// - Returns: 所有遗物产出的效果列表
    public func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        var effects: [BattleEffect] = []
        
        for relicId in relicIds {
            guard let def = RelicRegistry.get(relicId) else { continue }
            effects.append(contentsOf: def.onBattleTrigger(trigger, snapshot: snapshot))
        }
        
        return effects
    }
}
