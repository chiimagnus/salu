import GameCore

/// 房间处理结果
enum RoomRunResult {
    case completedNode      // 正常完成节点
    case runEnded(won: Bool) // 冒险结束（胜利或失败）
}

/// 房间处理器协议
/// 每个房间类型都有一个对应的 handler 负责执行该房间的完整流程
protocol RoomHandling {
    var roomType: RoomType { get }
    
    /// 执行房间流程
    /// - Parameters:
    ///   - node: 当前地图节点
    ///   - runState: 冒险状态（可变，允许修改）
    ///   - context: 共享上下文（事件管理、CLI 辅助等）
    /// - Returns: 房间执行结果
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult
}

/// 房间上下文
/// 提供各个 handler 需要的共享功能（事件管理、CLI 输入输出等）
struct RoomContext {
    /// 添加事件到事件日志
    let appendEvents: ([BattleEvent]) -> Void
    
    /// 清空事件日志
    let clearEvents: () -> Void
    
    /// 战斗循环（复用现有逻辑）
    let battleLoop: (BattleEngine, UInt64) -> Void
    
    /// 创建敌人（复用现有逻辑）
    let createEnemy: (EnemyID, inout SeededRNG) -> Entity
    
    /// 历史记录服务（用于保存战斗记录）
    let historyService: HistoryService
}
