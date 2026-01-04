import Foundation

/// Run 存档存储协议
/// 定义冒险存档的持久化接口，具体实现将在 P7 提供
/// P6 阶段只定义接口，为未来的存档系统预留扩展点
public protocol RunSaveStore: Sendable {
    /// 加载冒险存档
    /// - Throws: 加载失败时抛出错误
    /// - Returns: 存档快照，如果不存在则返回 nil
    func load() throws -> RunSnapshot?
    
    /// 保存冒险存档
    /// - Parameter snapshot: 要保存的冒险快照
    /// - Throws: 保存失败时抛出错误
    func save(_ snapshot: RunSnapshot) throws
    
    /// 清除冒险存档
    /// - Throws: 清除失败时抛出错误
    func clear() throws
}

/// 冒险存档快照（P7 实现，P6 预留）
public struct RunSnapshot: Codable, Sendable {
    public let version: Int
    public let seed: UInt64
    public let floor: Int
    
    // 注意: 这是 P7 的预留接口，P6 阶段不实现具体功能
    // 实际字段将在 P7 完善
}
