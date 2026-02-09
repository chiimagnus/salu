import Foundation
import SwiftUI
import GameCore

@MainActor
@Observable
final class RunSession {
    enum Route: Equatable, Sendable {
        case map
        case room(nodeId: String, roomType: RoomType)
        case battle(nodeId: String, roomType: RoomType)
        case cardReward(nodeId: String, roomType: RoomType, offer: CardRewardOffer, goldEarned: Int)
        case runOver(lastNodeId: String, won: Bool, floor: Int)
    }

    var seedText: String = ""
    private(set) var seed: UInt64?
    var lastError: String?
    var runState: RunState?
    var route: Route = .map
    private(set) var battleEngine: BattleEngine?
    private(set) var battleState: BattleState?
    private(set) var battleEvents: [BattleEvent] = []
    private var battleNodeId: String?
    private var battleRoomType: RoomType?
    private var lastConsumedBattleEventIndex: Int = 0
    private var playedCardContextsBySequence: [Int: PlayedCardPresentationContext] = [:]

    func startNewRun() {
        let seed: UInt64
        if seedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            seed = Self.generateSeed()
        } else if let parsed = UInt64(seedText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            seed = parsed
        } else {
            lastError = "Invalid seed. Please enter a UInt64 number."
            return
        }

        self.seed = seed
        runState = RunState.newRun(seed: seed)
        seedText = String(seed)
        lastError = nil
        battleEngine = nil
        battleState = nil
        battleEvents = []
        battleNodeId = nil
        battleRoomType = nil
        lastConsumedBattleEventIndex = 0
        playedCardContextsBySequence = [:]
        route = .map
    }

    func selectAccessibleNode(_ nodeId: String) {
        guard var runState else { return }
        guard runState.enterNode(nodeId) else { return }

        self.runState = runState

        guard let node = runState.map.node(withId: nodeId) else {
            lastError = "Node not found: \(nodeId)"
            return
        }

        switch node.roomType {
        case .battle, .elite, .boss:
            startBattle(nodeId: nodeId, roomType: node.roomType)
        default:
            route = .room(nodeId: nodeId, roomType: node.roomType)
        }
    }

    func completeCurrentRoomAndReturnToMap() {
        let lastNodeId: String?
        if case .room(let nodeId, _) = route {
            lastNodeId = nodeId
        } else {
            lastNodeId = nil
        }

        guard var runState else { return }
        runState.completeCurrentNode()
        self.runState = runState

        if runState.isOver, let lastNodeId {
            route = .runOver(lastNodeId: lastNodeId, won: runState.won, floor: runState.floor)
        } else {
            route = .map
        }
    }

    func playCard(handIndex: Int) {
        guard routeIsBattle else { return }
        guard let battleEngine else { return }
        guard battleEngine.pendingInput == nil else { return }
        guard battleEngine.state.hand.indices.contains(handIndex) else { return }
        let eventStartIndex = battleEngine.events.count
        _ = battleEngine.handleAction(.playCard(handIndex: handIndex, targetEnemyIndex: nil))
        syncBattleStateFromEngine()
        capturePlayedCardContexts(startIndex: eventStartIndex, sourceHandIndex: handIndex)
        finishBattleIfNeeded()
    }

    func endTurn() {
        guard routeIsBattle else { return }
        guard let battleEngine else { return }
        guard battleEngine.pendingInput == nil else { return }
        _ = battleEngine.handleAction(.endTurn)
        syncBattleStateFromEngine()
        finishBattleIfNeeded()
    }

    private var routeIsBattle: Bool {
        if case .battle = route { return true }
        return false
    }

    func submitForesightChoice(index: Int) {
        guard routeIsBattle else { return }
        guard let battleEngine else { return }
        _ = battleEngine.submitForesightChoice(index: index)
        syncBattleStateFromEngine()
        finishBattleIfNeeded()
    }

    func consumeNewBattleEvents() -> [BattleEvent] {
        let startIndex = lastConsumedBattleEventIndex
        let newEvents = consumeNewBattleEventSlice()
        let consumedEnd = startIndex + newEvents.count
        if consumedEnd > startIndex {
            for sequence in startIndex..<consumedEnd {
                playedCardContextsBySequence.removeValue(forKey: sequence)
            }
        }
        return Array(newEvents)
    }

    func consumeNewBattlePresentationEvents() -> [BattlePresentationEvent] {
        let startIndex = lastConsumedBattleEventIndex
        let newEvents = consumeNewBattleEventSlice()
        return newEvents.enumerated().map { offset, event in
            let sequence = startIndex + offset
            let context = playedCardContextsBySequence.removeValue(forKey: sequence)
            return BattlePresentationEvent(
                sequence: sequence,
                event: event,
                playedCardContext: context
            )
        }
    }

    func chooseCardReward(_ cardId: CardID?) {
        guard case .cardReward(let nodeId, let roomType, let offer, let goldEarned) = route else { return }
        guard var runState else { return }

        if let cardId {
            guard offer.choices.contains(cardId) else { return }
            runState.addCardToDeck(cardId: cardId)
        } else {
            guard offer.canSkip else { return }
        }

        runState.completeCurrentNode()
        self.runState = runState

        battleState = nil
        battleEvents = []
        battleNodeId = nil
        battleRoomType = nil
        lastConsumedBattleEventIndex = 0
        playedCardContextsBySequence = [:]

        if runState.isOver {
            route = .runOver(lastNodeId: nodeId, won: runState.won, floor: runState.floor)
        } else {
            _ = roomType
            _ = goldEarned
            route = .map
        }
    }

    private func finishBattleIfNeeded() {
        guard let battleEngine, battleEngine.state.isOver else { return }
        guard var runState else { return }

        let nodeId = battleNodeId ?? runState.currentNodeId ?? "unknown"
        let roomTypeForRewards = battleRoomType ?? .battle
        runState.updateFromBattle(playerHP: battleEngine.state.player.currentHP)
        self.runState = runState

        // Freeze the final battle state for UI (reward panel), but release the engine.
        self.battleEvents = battleEngine.events
        self.battleEngine = nil

        if battleEngine.state.playerWon == true {
            let rewardContext = RewardContext(
                seed: runState.seed,
                floor: runState.floor,
                currentRow: runState.currentRow,
                nodeId: nodeId,
                roomType: roomTypeForRewards
            )
            let goldEarned = GoldRewardStrategy.generateGoldReward(context: rewardContext)
            runState.gold += goldEarned
            self.runState = runState

            let offer = RewardGenerator.generateCardReward(context: rewardContext)
            route = .cardReward(nodeId: nodeId, roomType: roomTypeForRewards, offer: offer, goldEarned: goldEarned)
        } else {
            self.battleState = nil
            self.battleEvents = []
            self.battleNodeId = nil
            self.battleRoomType = nil
            self.lastConsumedBattleEventIndex = 0
            self.playedCardContextsBySequence = [:]
            route = .runOver(lastNodeId: nodeId, won: false, floor: runState.floor)
        }
    }

    private func startBattle(nodeId: String, roomType: RoomType) {
        guard let runState else { return }

        let battleSeed = SeedDerivation.battleSeed(runSeed: runState.seed, floor: runState.floor, nodeId: nodeId)
        var rng = SeededRNG(seed: battleSeed)

        let enemyId: EnemyID
        switch roomType {
        case .battle:
            let encounter: EnemyEncounter
            switch runState.floor {
            case 1:
                encounter = Act1EncounterPool.randomWeak(rng: &rng)
            case 2:
                encounter = Act2EncounterPool.randomWeak(rng: &rng)
            default:
                encounter = Act3EncounterPool.randomWeak(rng: &rng)
            }
            enemyId = encounter.enemyIds.first ?? "jaw_worm"

        case .elite:
            switch runState.floor {
            case 1:
                enemyId = Act1EnemyPool.randomMedium(rng: &rng)
            case 2:
                enemyId = Act2EnemyPool.randomMedium(rng: &rng)
            default:
                enemyId = Act3EnemyPool.randomMedium(rng: &rng)
            }

        case .boss:
            switch runState.floor {
            case 1:
                enemyId = "toxic_colossus"
            case 2:
                enemyId = "cipher"
            default:
                enemyId = "sequence_progenitor"
            }

        default:
            lastError = "Not a battle room: \(roomType.rawValue)"
            return
        }

        let enemy = createEnemy(enemyId: enemyId, instanceIndex: 0, rng: &rng)
        let engine = BattleEngine(
            player: runState.player,
            enemies: [enemy],
            deck: runState.deck,
            relicManager: runState.relicManager,
            seed: battleSeed
        )
        engine.startBattle()

        battleEngine = engine
        battleState = engine.state
        battleEvents = engine.events
        battleNodeId = nodeId
        battleRoomType = roomType
        lastConsumedBattleEventIndex = 0
        playedCardContextsBySequence = [:]
        route = .battle(nodeId: nodeId, roomType: roomType)
    }

    private static func generateSeed() -> UInt64 {
        UInt64(Date().timeIntervalSince1970 * 1000)
    }

    func resetToControlPanel() {
        runState = nil
        route = .map
        lastError = nil
        battleEngine = nil
        battleState = nil
        battleEvents = []
        battleNodeId = nil
        battleRoomType = nil
        lastConsumedBattleEventIndex = 0
        playedCardContextsBySequence = [:]
    }

    private func consumeNewBattleEventSlice() -> ArraySlice<BattleEvent> {
        guard lastConsumedBattleEventIndex < battleEvents.count else { return [] }
        let range = lastConsumedBattleEventIndex..<battleEvents.count
        lastConsumedBattleEventIndex = battleEvents.count
        return battleEvents[range]
    }

    private func syncBattleStateFromEngine() {
        guard let battleEngine else { return }
        battleState = battleEngine.state
        battleEvents = battleEngine.events
        if battleEvents.count < lastConsumedBattleEventIndex {
            lastConsumedBattleEventIndex = 0
            playedCardContextsBySequence = [:]
        }
        playedCardContextsBySequence = playedCardContextsBySequence.filter { $0.key < battleEvents.count }
    }

    private func capturePlayedCardContexts(startIndex: Int, sourceHandIndex: Int) {
        guard startIndex < battleEvents.count else { return }
        let newEvents = battleEvents[startIndex..<battleEvents.count]
        for (offset, event) in newEvents.enumerated() {
            guard case .played(_, let cardId, _) = event else { continue }
            let destinationPile = destinationPileForPlayedCard(cardId: cardId)
            playedCardContextsBySequence[startIndex + offset] = PlayedCardPresentationContext(
                sourceHandIndex: sourceHandIndex,
                destinationPile: destinationPile
            )
        }
    }

    private func destinationPileForPlayedCard(cardId: CardID) -> PlayedCardDestinationPile {
        let definition = CardRegistry.require(cardId)
        return definition.type == .consumable ? .exhaust : .discard
    }
}
