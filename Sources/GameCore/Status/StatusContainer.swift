// MARK: - Status Container

/// 状态容器（纯数据结构）
/// 约束：只存储状态数据，不产生事件/效果
public struct StatusContainer: Sendable, Equatable {
    private var stacksById: [StatusID: Int] = [:]
    
    public init() {}
    
    /// 获取指定状态的层数
    public func stacks(of id: StatusID) -> Int {
        return stacksById[id] ?? 0
    }
    
    /// 应用状态（增加或减少层数）
    /// - Parameters:
    ///   - id: 状态 ID
    ///   - stacks: 层数变化（正数增加，负数减少）
    public mutating func apply(_ id: StatusID, stacks: Int) {
        guard stacks != 0 else { return }
        
        let newValue = (stacksById[id] ?? 0) + stacks
        
        if newValue <= 0 {
            stacksById.removeValue(forKey: id)
        } else {
            stacksById[id] = newValue
        }
    }
    
    /// 设置状态层数（直接设置，而不是增减）
    public mutating func set(_ id: StatusID, stacks: Int) {
        if stacks <= 0 {
            stacksById.removeValue(forKey: id)
        } else {
            stacksById[id] = stacks
        }
    }
    
    /// 移除状态
    public mutating func remove(_ id: StatusID) {
        stacksById.removeValue(forKey: id)
    }
    
    /// 获取所有状态（按 ID 排序，保证确定性）
    public var all: [(id: StatusID, stacks: Int)] {
        return stacksById.map { ($0.key, $0.value) }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }
    
    /// 是否有任何状态
    public var hasAny: Bool {
        return !stacksById.isEmpty
    }
    
    /// 清空所有状态
    public mutating func clear() {
        stacksById.removeAll()
    }
}
