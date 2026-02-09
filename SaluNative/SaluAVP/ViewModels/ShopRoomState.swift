import GameCore

struct ShopRoomState: Sendable, Equatable {
    let nodeId: String
    var inventory: ShopInventory
    var message: String?

    init(
        nodeId: String,
        inventory: ShopInventory,
        message: String? = nil
    ) {
        self.nodeId = nodeId
        self.inventory = inventory
        self.message = message
    }
}
