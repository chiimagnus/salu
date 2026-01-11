// MARK: - Event Registry

/// 事件注册表
/// 新增事件的唯一扩展点（P5）
public enum EventRegistry {
    /// 注册的事件定义
    private static let defs: [EventID: any EventDefinition.Type] = [
        // Seer Sequence
        SeerSequenceChamberEvent.id: SeerSequenceChamberEvent.self,
        SeerTimeRiftEvent.id: SeerTimeRiftEvent.self,
        SeerMadProphetEvent.id: SeerMadProphetEvent.self,
        
        ScavengerEvent.id: ScavengerEvent.self,
        AltarEvent.id: AltarEvent.self,
        TrainingEvent.id: TrainingEvent.self,
    ]
    
    public static func get(_ id: EventID) -> (any EventDefinition.Type)? {
        defs[id]
    }
    
    public static func require(_ id: EventID) -> any EventDefinition.Type {
        precondition(defs[id] != nil, "EventRegistry: 未找到事件定义 '\(id.rawValue)'")
        return defs[id]!
    }
    
    /// 所有已注册事件 ID（按 rawValue 排序，保证确定性）
    public static var allEventIds: [EventID] {
        Array(defs.keys).sorted { $0.rawValue < $1.rawValue }
    }
}


