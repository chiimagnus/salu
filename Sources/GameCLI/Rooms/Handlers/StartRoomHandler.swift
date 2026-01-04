import GameCore

/// 起点房间处理器
struct StartRoomHandler: RoomHandling {
    var roomType: RoomType { .start }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        // 起点直接完成，无需交互
        runState.completeCurrentNode()
        return .completedNode
    }
}
