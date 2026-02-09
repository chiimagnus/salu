import GameCore

struct ShopRoomState: Sendable, Equatable {
    let nodeId: String
    var inventory: ShopInventory
    var message: String?
    var messageSequence: UInt64

    init(
        nodeId: String,
        inventory: ShopInventory,
        message: String? = nil,
        messageSequence: UInt64 = 0
    ) {
        self.nodeId = nodeId
        self.inventory = inventory
        self.message = message
        self.messageSequence = messageSequence
    }
}
