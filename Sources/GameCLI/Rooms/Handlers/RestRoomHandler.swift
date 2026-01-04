import GameCore

/// 休息房间处理器
struct RestRoomHandler: RoomHandling {
    var roomType: RoomType { .rest }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        Screens.showRestOptions(runState: runState)
        
        // 等待输入
        _ = readLine()
        
        // 执行休息
        let healed = runState.restAtNode()
        
        // 显示结果
        Screens.showRestResult(
            healedAmount: healed,
            newHP: runState.player.currentHP,
            maxHP: runState.player.maxHP
        )
        
        _ = readLine()
        
        // 完成节点
        runState.completeCurrentNode()
        return .completedNode
    }
}
