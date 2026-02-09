import GameCore

struct EventRoomState: Sendable, Equatable {
    enum Phase: Sendable, Equatable {
        case choosing
        case chooseUpgrade(optionIndex: Int, indices: [Int], baseResultLines: [String])
        case awaitingBattleResolution(optionIndex: Int, enemyId: EnemyID, baseResultLines: [String])
        case resolved(optionIndex: Int, resultLines: [String])
    }

    let nodeId: String
    let offer: EventOffer
    var phase: Phase
    var message: String?

    init(
        nodeId: String,
        offer: EventOffer,
        phase: Phase = .choosing,
        message: String? = nil
    ) {
        self.nodeId = nodeId
        self.offer = offer
        self.phase = phase
        self.message = message
    }
}
