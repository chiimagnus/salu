/// 战斗历史存储协议
/// 定义战斗记录的持久化接口，具体实现由 CLI 层提供
public protocol BattleHistoryStore: Sendable {
    /// 加载所有战斗记录
    /// - Throws: 加载失败时抛出错误
    /// - Returns: 战斗记录数组
    func load() throws -> [BattleRecord]
    
    /// 追加新的战斗记录
    /// - Parameter record: 要添加的战斗记录
    /// - Throws: 保存失败时抛出错误
    func append(_ record: BattleRecord) throws
    
    /// 清空所有战斗记录
    /// - Throws: 清空失败时抛出错误
    func clear() throws
}
