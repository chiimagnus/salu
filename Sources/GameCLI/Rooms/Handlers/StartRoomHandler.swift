import GameCore

/// 起点房间处理器
struct StartRoomHandler: RoomHandling {
    var roomType: RoomType { .start }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        // 显示开场剧情（每层的起点都显示对应章节的剧情）
        // 测试模式下跳过等待
        if !TestMode.isEnabled {
            PrologueScreen.show(floor: runState.floor)
        } else {
            // 测试模式下只打印简短信息
            context.logLine("\(Terminal.dim)【\(L10n.text("测试模式", "Test Mode"))】\(L10n.text("跳过第", "Skip chapter")) \(runState.floor) \(L10n.text("章开场剧情", "prologue"))\(Terminal.reset)")
        }
        
        // 起点完成
        runState.completeCurrentNode()
        return .completedNode
    }
}
