import Foundation
import GameCore

struct RunTrace: Codable, Sendable, Equatable {
    static let currentVersion = 1

    struct Entry: Codable, Sendable, Equatable, Identifiable {
        let id: Int
        let action: Action

        init(id: Int, action: Action) {
            self.id = id
            self.action = action
        }
    }

    enum Action: Codable, Sendable, Equatable {
        case selectNode(nodeId: String)

        case selectEnemy(entityId: String)
        case playCard(handIndex: Int, targetEnemyEntityId: String?)
        case endTurn

        case chooseRelicReward(take: Bool)
        case chooseCardReward(cardId: String?) // nil = skip
        case continueAfterChapterEnd

        case restHeal
        case restUpgrade(deckIndex: Int)

        case shopBuyCard(offerIndex: Int)
        case shopBuyRelic(offerIndex: Int)
        case shopBuyConsumable(offerIndex: Int)
        case shopRemoveCard(deckIndex: Int)
        case leaveShop

        case eventChooseOption(optionIndex: Int)
        case eventChooseUpgrade(deckIndex: Int)
        case eventSkipUpgrade
        case eventComplete
    }

    let version: Int
    let seed: UInt64
    private(set) var entries: [Entry]

    init(seed: UInt64, entries: [Entry] = []) {
        self.version = Self.currentVersion
        self.seed = seed
        self.entries = entries
    }

    mutating func append(_ action: Action) {
        entries.append(Entry(id: entries.count, action: action))
    }
}

