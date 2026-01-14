import GameCore

/// 房间处理结果
enum RoomRunResult {
    case completedNode       // 正常完成节点
    case runEnded(won: Bool) // 冒险结束（胜利或失败）
    case aborted             // 用户中途退出（返回主菜单，保留存档）
}

/// 战斗循环结果
/// 用于区分战斗是正常结束还是用户中途退出
enum BattleLoopResult {
    case finished   // 战斗正常结束（胜利或失败）
    case aborted    // 用户中途退出（按 q 返回主菜单）
}

/// 战斗房间处理结果
/// 用于战斗类房间（普通/精英/Boss）的内部处理结果
enum BattleHandleResult {
    case won        // 战斗胜利
    case lost       // 战斗失败（玩家 HP 归零）
    case aborted    // 用户中途退出（按 q 返回主菜单）
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
    /// 记录战斗事件（同一套日志系统）
    let logBattleEvents: ([BattleEvent]) -> Void

    /// 记录一条日志（同一套日志系统）
    let logLine: (String) -> Void
    
    /// 战斗循环（复用现有逻辑）
    /// 返回战斗循环结果，区分正常结束和用户中途退出
    let battleLoop: (BattleEngine, UInt64, inout RunState) -> BattleLoopResult
    
    /// 创建敌人（复用现有逻辑）
    let createEnemy: (EnemyID, Int, inout SeededRNG) -> Entity
    
    /// 历史记录服务（用于保存战斗记录）
    let historyService: HistoryService
}
