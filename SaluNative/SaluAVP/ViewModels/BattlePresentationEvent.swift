import Foundation
import GameCore

enum PlayedCardDestinationPile: String, Sendable, Equatable {
    case discard
    case exhaust
}

struct PlayedCardPresentationContext: Sendable, Equatable {
    let sourceHandIndex: Int
    let destinationPile: PlayedCardDestinationPile
    let targetEnemyEntityId: String?
}

/// AVP 表现层使用的战斗事件包装，包含稳定序号以支持动画队列消费。
struct BattlePresentationEvent: Sendable, Equatable {
    let sequence: Int
    let event: BattleEvent
    let playedCardContext: PlayedCardPresentationContext?

    init(
        sequence: Int,
        event: BattleEvent,
        playedCardContext: PlayedCardPresentationContext? = nil
    ) {
        self.sequence = sequence
        self.event = event
        self.playedCardContext = playedCardContext
    }
}
