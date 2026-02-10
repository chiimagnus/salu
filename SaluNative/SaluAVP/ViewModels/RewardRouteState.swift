import GameCore

struct RewardRouteState: Sendable, Equatable {
    enum Phase: Sendable, Equatable {
        case relic
        case card
    }

    struct RelicReward: Sendable, Equatable {
        let relicId: RelicID
        let source: RelicDropSource
    }

    let nodeId: String
    let roomType: RoomType
    let goldEarned: Int
    let cardOffer: CardRewardOffer
    let relicReward: RelicReward?
    var phase: Phase

    init(
        nodeId: String,
        roomType: RoomType,
        goldEarned: Int,
        cardOffer: CardRewardOffer,
        relicReward: RelicReward?
    ) {
        self.nodeId = nodeId
        self.roomType = roomType
        self.goldEarned = goldEarned
        self.cardOffer = cardOffer
        self.relicReward = relicReward
        self.phase = (relicReward == nil) ? .card : .relic
    }
}

