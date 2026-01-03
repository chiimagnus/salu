/// 地图节点
/// 表示地图上的一个房间
public struct MapNode: Identifiable, Sendable {
    public let id: Int              // 节点 ID
    public let floor: Int           // 楼层（Y 坐标）
    public let column: Int          // 列（X 坐标）
    public let roomType: RoomType   // 房间类型
    public var isVisited: Bool      // 是否已访问
    public var isCurrentPosition: Bool  // 是否是当前位置
    public var isAccessible: Bool   // 是否可以访问（玩家能走到）
    
    public init(id: Int, floor: Int, column: Int = 0, roomType: RoomType) {
        self.id = id
        self.floor = floor
        self.column = column
        self.roomType = roomType
        self.isVisited = false
        self.isCurrentPosition = false
        self.isAccessible = false
    }
}
