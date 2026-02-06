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
    private var battleNodeId: String?
    private var battleRoomType: RoomType?
    private var pendingGoldEarned: Int?
    private var pendingCardOffer: CardRewardOffer?

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
        battleNodeId = nil
        battleRoomType = nil
        pendingGoldEarned = nil
        pendingCardOffer = nil
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
        _ = battleEngine.handleAction(.playCard(handIndex: handIndex, targetEnemyIndex: nil))
        battleState = battleEngine.state
        finishBattleIfNeeded()
    }

    func endTurn() {
        guard routeIsBattle else { return }
        guard let battleEngine else { return }
        _ = battleEngine.handleAction(.endTurn)
        battleState = battleEngine.state
        finishBattleIfNeeded()
    }

    private var routeIsBattle: Bool {
        if case .battle = route { return true }
        return false
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

        pendingGoldEarned = nil
        pendingCardOffer = nil
        battleState = nil
        battleNodeId = nil
        battleRoomType = nil

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
            pendingGoldEarned = goldEarned
            pendingCardOffer = offer
            route = .cardReward(nodeId: nodeId, roomType: roomTypeForRewards, offer: offer, goldEarned: goldEarned)
        } else {
            self.battleState = nil
            self.battleNodeId = nil
            self.battleRoomType = nil
            pendingGoldEarned = nil
            pendingCardOffer = nil
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
        battleNodeId = nodeId
        battleRoomType = roomType
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
        battleNodeId = nil
        battleRoomType = nil
        pendingGoldEarned = nil
        pendingCardOffer = nil
    }
}
