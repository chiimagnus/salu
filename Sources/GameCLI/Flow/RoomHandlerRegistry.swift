import GameCore

/// 房间处理器注册表
/// 根据房间类型选择对应的 handler
struct RoomHandlerRegistry {
    private let handlers: [RoomType: any RoomHandling]
    
    init(handlers: [any RoomHandling]) {
        var dict: [RoomType: any RoomHandling] = [:]
        for handler in handlers {
            dict[handler.roomType] = handler
        }
        self.handlers = dict
    }
    
    /// 获取指定房间类型的处理器
    func handler(for roomType: RoomType) -> (any RoomHandling)? {
        handlers[roomType]
    }
    
    /// 创建默认注册表（包含所有标准房间类型）
    static func makeDefault() -> RoomHandlerRegistry {
        RoomHandlerRegistry(handlers: [
            StartRoomHandler(),
            BattleRoomHandler(),
            EliteRoomHandler(),
            RestRoomHandler(),
            ShopRoomHandler(),
            EventRoomHandler(),
            BossRoomHandler()
        ])
    }
}
