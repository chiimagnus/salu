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

    private enum BattleSource: Sendable, Equatable {
        case mapNode
        case eventFollowUp
    }

    private struct EventBattleContext: Sendable {
        let nodeId: String
        let optionIndex: Int
        let enemyId: EnemyID
        let baseResultLines: [String]
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
    private(set) var selectedEnemyIndex: Int?
    private(set) var battleTargetHint: String?
    private(set) var restRoomMessage: String?
    private(set) var shopRoomState: ShopRoomState?
    private(set) var eventRoomState: EventRoomState?
    private var shopMessageSequence: UInt64 = 0
    private var battleSource: BattleSource = .mapNode
    private var eventBattleContext: EventBattleContext?

    var selectedEnemyDisplayName: String? {
        guard let battleState, let selectedEnemyIndex else { return nil }
        guard battleState.enemies.indices.contains(selectedEnemyIndex) else { return nil }
        return battleState.enemies[selectedEnemyIndex].name.resolved(for: .zhHans)
    }

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
        selectedEnemyIndex = nil
        battleTargetHint = nil
        restRoomMessage = nil
        shopRoomState = nil
        eventRoomState = nil
        shopMessageSequence = 0
        battleSource = .mapNode
        eventBattleContext = nil
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
            clearRoomState(clearEventBattleContext: true)
            startBattle(nodeId: nodeId, roomType: node.roomType, source: .mapNode)
        default:
            prepareRoomState(nodeId: nodeId, roomType: node.roomType, runState: runState)
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
        clearRoomState(clearEventBattleContext: true)

        if runState.isOver, let lastNodeId {
            route = .runOver(lastNodeId: lastNodeId, won: runState.won, floor: runState.floor)
        } else {
            route = .map
        }
    }

    func restHeal() {
        guard case .room(_, .rest) = route else { return }
        guard var runState else { return }
        _ = runState.restAtNode()
        self.runState = runState
        restRoomMessage = nil
        completeCurrentRoomAndReturnToMap()
    }

    func restUpgradeCard(deckIndex: Int) {
        guard case .room(_, .rest) = route else { return }
        guard var runState else { return }
        guard runState.upgradeCard(at: deckIndex) else {
            restRoomMessage = "该卡牌无法升级"
            return
        }

        self.runState = runState
        restRoomMessage = nil
        completeCurrentRoomAndReturnToMap()
    }

    func restTalkToAira() {
        guard case .room(_, .rest) = route else { return }
        guard let runState else { return }

        let dialogue = RestPointDialogues.getAiraDialogue(floor: runState.floor)
        var lines = [
            dialogue.title.resolved(for: .zhHans),
            dialogue.content.resolved(for: .zhHans)
        ]
        if let effect = dialogue.effect?.resolved(for: .zhHans), !effect.isEmpty {
            lines.append("效果：\(effect)")
        }
        restRoomMessage = lines.joined(separator: "\n\n")
    }

    func leaveShopRoom() {
        guard case .room(_, .shop) = route else { return }
        completeCurrentRoomAndReturnToMap()
    }

    func buyShopCard(at offerIndex: Int) {
        guard case .room(let nodeId, .shop) = route else { return }
        guard var runState else { return }
        var shopState = ensureShopRoomState(nodeId: nodeId, runState: runState)

        guard shopState.inventory.cardOffers.indices.contains(offerIndex) else {
            setShopMessage("无效的卡牌编号", in: &shopState)
            shopRoomState = shopState
            return
        }

        let offer = shopState.inventory.cardOffers[offerIndex]
        guard runState.gold >= offer.price else {
            setShopMessage("金币不足，无法购买该卡牌", in: &shopState)
            shopRoomState = shopState
            return
        }

        runState.gold -= offer.price
        runState.addCardToDeck(cardId: offer.cardId)
        var cardOffers = shopState.inventory.cardOffers
        cardOffers.remove(at: offerIndex)
        shopState.inventory = ShopInventory(
            cardOffers: cardOffers,
            relicOffers: shopState.inventory.relicOffers,
            consumableOffers: shopState.inventory.consumableOffers,
            removeCardPrice: shopState.inventory.removeCardPrice
        )
        setShopMessage("购买成功：\(CardRegistry.require(offer.cardId).name.resolved(for: .zhHans))", in: &shopState)
        self.runState = runState
        shopRoomState = shopState
    }

    func buyShopRelic(at offerIndex: Int) {
        guard case .room(let nodeId, .shop) = route else { return }
        guard var runState else { return }
        var shopState = ensureShopRoomState(nodeId: nodeId, runState: runState)

        guard shopState.inventory.relicOffers.indices.contains(offerIndex) else {
            setShopMessage("无效的遗物编号", in: &shopState)
            shopRoomState = shopState
            return
        }

        let offer = shopState.inventory.relicOffers[offerIndex]
        guard runState.gold >= offer.price else {
            setShopMessage("金币不足，无法购买该遗物", in: &shopState)
            shopRoomState = shopState
            return
        }

        runState.gold -= offer.price
        runState.relicManager.add(offer.relicId)
        var relicOffers = shopState.inventory.relicOffers
        relicOffers.remove(at: offerIndex)
        shopState.inventory = ShopInventory(
            cardOffers: shopState.inventory.cardOffers,
            relicOffers: relicOffers,
            consumableOffers: shopState.inventory.consumableOffers,
            removeCardPrice: shopState.inventory.removeCardPrice
        )
        let relicDef = RelicRegistry.require(offer.relicId)
        setShopMessage("购买成功：\(relicDef.icon) \(relicDef.name.resolved(for: .zhHans))", in: &shopState)
        self.runState = runState
        shopRoomState = shopState
    }

    func buyShopConsumable(at offerIndex: Int) {
        guard case .room(let nodeId, .shop) = route else { return }
        guard var runState else { return }
        var shopState = ensureShopRoomState(nodeId: nodeId, runState: runState)

        guard shopState.inventory.consumableOffers.indices.contains(offerIndex) else {
            setShopMessage("无效的消耗性卡牌编号", in: &shopState)
            shopRoomState = shopState
            return
        }

        let offer = shopState.inventory.consumableOffers[offerIndex]
        guard runState.gold >= offer.price else {
            setShopMessage("金币不足，无法购买该消耗性卡牌", in: &shopState)
            shopRoomState = shopState
            return
        }

        guard runState.addConsumableCardToDeck(cardId: offer.cardId) else {
            setShopMessage("消耗性卡牌槽位已满（最多 \(RunState.maxConsumableCardSlots)）", in: &shopState)
            shopRoomState = shopState
            return
        }

        runState.gold -= offer.price
        setShopMessage("购买成功：\(CardRegistry.require(offer.cardId).name.resolved(for: .zhHans))", in: &shopState)
        self.runState = runState
        shopRoomState = shopState
    }

    func removeCardInShop(deckIndex: Int) {
        guard case .room(let nodeId, .shop) = route else { return }
        guard var runState else { return }
        var shopState = ensureShopRoomState(nodeId: nodeId, runState: runState)

        guard runState.deck.indices.contains(deckIndex) else {
            setShopMessage("无效的卡牌编号", in: &shopState)
            shopRoomState = shopState
            return
        }

        let price = shopState.inventory.removeCardPrice
        guard runState.gold >= price else {
            setShopMessage("金币不足，无法删牌", in: &shopState)
            shopRoomState = shopState
            return
        }

        let removedCard = runState.deck[deckIndex]
        runState.removeCardFromDeck(at: deckIndex)
        runState.gold -= price
        setShopMessage("删牌成功：\(CardRegistry.require(removedCard.cardId).name.resolved(for: .zhHans))", in: &shopState)
        self.runState = runState
        shopRoomState = shopState
    }

    func chooseEventOption(_ optionIndex: Int) {
        guard case .room(let nodeId, .event) = route else { return }
        guard var runState else { return }
        var eventState = ensureEventRoomState(nodeId: nodeId, runState: runState)
        guard case .choosing = eventState.phase else { return }
        guard eventState.offer.options.indices.contains(optionIndex) else {
            eventState.message = "无效的事件选项"
            eventRoomState = eventState
            return
        }

        let option = eventState.offer.options[optionIndex]
        var failureLines: [String] = []
        for effect in option.effects {
            guard runState.apply(effect) else {
                failureLines.append(eventApplyFailureLine(for: effect))
                continue
            }
        }
        self.runState = runState

        if runState.isOver {
            clearRoomState(clearEventBattleContext: true)
            route = .runOver(lastNodeId: nodeId, won: false, floor: runState.floor)
            return
        }

        let baseResultLines = buildEventResultLines(option: option, additional: failureLines)

        if let followUp = option.followUp {
            switch followUp {
            case .chooseUpgradeableCard(let indices):
                let validIndices = indices.filter { index in
                    runState.deck.indices.contains(index)
                    && RunState.upgradedCard(from: runState.deck[index]) != nil
                }
                if validIndices.isEmpty {
                    var lines = baseResultLines
                    lines.append("没有可升级的卡牌")
                    eventState.phase = .resolved(optionIndex: optionIndex, resultLines: lines)
                } else {
                    eventState.phase = .chooseUpgrade(
                        optionIndex: optionIndex,
                        indices: validIndices,
                        baseResultLines: baseResultLines
                    )
                }
                eventState.message = nil
                eventRoomState = eventState

            case .startEliteBattle(let enemyId):
                eventState.phase = .awaitingBattleResolution(
                    optionIndex: optionIndex,
                    enemyId: enemyId,
                    baseResultLines: baseResultLines
                )
                eventState.message = nil
                eventRoomState = eventState
                eventBattleContext = EventBattleContext(
                    nodeId: nodeId,
                    optionIndex: optionIndex,
                    enemyId: enemyId,
                    baseResultLines: baseResultLines
                )
                startBattle(
                    nodeId: nodeId,
                    roomType: .elite,
                    forcedEnemyIds: [enemyId],
                    source: .eventFollowUp
                )
            }
            return
        }

        eventState.phase = .resolved(optionIndex: optionIndex, resultLines: baseResultLines)
        eventState.message = nil
        eventRoomState = eventState
    }

    func chooseEventUpgradeCard(deckIndex: Int) {
        guard case .room(let nodeId, .event) = route else { return }
        guard var runState else { return }
        var eventState = ensureEventRoomState(nodeId: nodeId, runState: runState)
        guard case .chooseUpgrade(let optionIndex, let indices, let baseResultLines) = eventState.phase else { return }
        guard indices.contains(deckIndex), runState.deck.indices.contains(deckIndex) else {
            eventState.message = "请选择有效的升级目标"
            eventRoomState = eventState
            return
        }

        let card = runState.deck[deckIndex]
        guard let cardDef = CardRegistry.get(card.cardId), let upgradedId = cardDef.upgradedId else {
            eventState.message = "该卡牌无法升级"
            eventRoomState = eventState
            return
        }
        guard runState.upgradeCard(at: deckIndex) else {
            eventState.message = "升级失败，请重试"
            eventRoomState = eventState
            return
        }

        let upgradedDef = CardRegistry.require(upgradedId)
        var lines = baseResultLines
        lines.append("升级：\(cardDef.name.resolved(for: .zhHans)) -> \(upgradedDef.name.resolved(for: .zhHans))")
        eventState.phase = .resolved(optionIndex: optionIndex, resultLines: lines)
        eventState.message = nil
        self.runState = runState
        eventRoomState = eventState
    }

    func skipEventUpgradeChoice() {
        guard case .room(let nodeId, .event) = route else { return }
        guard let runState else { return }
        var eventState = ensureEventRoomState(nodeId: nodeId, runState: runState)
        guard case .chooseUpgrade(let optionIndex, _, let baseResultLines) = eventState.phase else { return }

        var lines = baseResultLines
        lines.append("你放弃了升级")
        eventState.phase = .resolved(optionIndex: optionIndex, resultLines: lines)
        eventState.message = nil
        eventRoomState = eventState
    }

    func completeEventRoom() {
        guard case .room(_, .event) = route else { return }
        guard let eventRoomState else { return }
        guard case .resolved = eventRoomState.phase else { return }
        completeCurrentRoomAndReturnToMap()
    }

    func playCard(handIndex: Int) {
        guard routeIsBattle else { return }
        guard let battleEngine else { return }
        guard battleEngine.pendingInput == nil else { return }
        guard battleEngine.state.hand.indices.contains(handIndex) else { return }
        let targetEnemyIndex = resolveTargetEnemyIndex(
            for: battleEngine.state.hand[handIndex],
            in: battleEngine.state
        )
        guard case .resolved(let resolvedTargetEnemyIndex) = targetEnemyIndex else {
            return
        }
        let eventStartIndex = battleEngine.events.count
        let succeeded = battleEngine.handleAction(
            .playCard(
                handIndex: handIndex,
                targetEnemyIndex: resolvedTargetEnemyIndex
            )
        )
        syncBattleStateFromEngine()
        capturePlayedCardContexts(startIndex: eventStartIndex, sourceHandIndex: handIndex)
        if succeeded {
            battleTargetHint = nil
        } else {
            captureInvalidActionHint(from: battleEngine.events, startIndex: eventStartIndex)
        }
        finishBattleIfNeeded()
    }

    func endTurn() {
        guard routeIsBattle else { return }
        guard let battleEngine else { return }
        guard battleEngine.pendingInput == nil else { return }
        _ = battleEngine.handleAction(.endTurn)
        syncBattleStateFromEngine()
        battleTargetHint = nil
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

    func selectEnemyTarget(index: Int) {
        guard routeIsBattle else { return }
        guard let battleState else { return }
        guard battleState.enemies.indices.contains(index) else { return }
        guard battleState.enemies[index].isAlive else {
            battleTargetHint = "目标已失效，请重新选择"
            return
        }

        if selectedEnemyIndex == index {
            selectedEnemyIndex = nil
        } else {
            selectedEnemyIndex = index
        }
        battleTargetHint = nil
    }

    func selectEnemyTarget(entityId: String) {
        guard let battleState else { return }
        guard let index = battleState.enemies.firstIndex(where: { $0.id == entityId }) else { return }
        selectEnemyTarget(index: index)
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

        clearBattleState(preserveSnapshot: false)

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
        let battleSource = self.battleSource
        runState.updateFromBattle(playerHP: battleEngine.state.player.currentHP)
        self.runState = runState

        if battleEngine.state.playerWon == true {
            if battleSource == .eventFollowUp {
                resolveEventEliteBattleVictory(nodeId: nodeId)
                return
            }

            // Freeze the final battle state for UI (reward panel), but release the engine.
            self.battleEvents = battleEngine.events
            clearBattleState(preserveSnapshot: true)
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
            clearBattleState(preserveSnapshot: false)
            clearRoomState(clearEventBattleContext: true)
            route = .runOver(lastNodeId: nodeId, won: false, floor: runState.floor)
        }
    }

    private func startBattle(
        nodeId: String,
        roomType: RoomType,
        forcedEnemyIds: [EnemyID]? = nil,
        source: BattleSource
    ) {
        guard let runState else { return }

        let battleSeed = SeedDerivation.battleSeed(runSeed: runState.seed, floor: runState.floor, nodeId: nodeId)
        var rng = SeededRNG(seed: battleSeed)

        let enemyIds: [EnemyID]
        if let forcedEnemyIds {
            enemyIds = forcedEnemyIds
        } else {
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
                enemyIds = encounter.enemyIds

            case .elite:
                switch runState.floor {
                case 1:
                    enemyIds = [Act1EnemyPool.randomMedium(rng: &rng)]
                case 2:
                    enemyIds = [Act2EnemyPool.randomMedium(rng: &rng)]
                default:
                    enemyIds = [Act3EnemyPool.randomMedium(rng: &rng)]
                }

            case .boss:
                switch runState.floor {
                case 1:
                    enemyIds = ["toxic_colossus"]
                case 2:
                    enemyIds = ["cipher"]
                default:
                    enemyIds = ["sequence_progenitor"]
                }

            default:
                lastError = "Not a battle room: \(roomType.rawValue)"
                return
            }
        }

        guard !enemyIds.isEmpty else {
            lastError = "No enemies available for battle start."
            return
        }

        let enemies = enemyIds.enumerated().map { instanceIndex, enemyId in
            createEnemy(enemyId: enemyId, instanceIndex: instanceIndex, rng: &rng)
        }
        let engine = BattleEngine(
            player: runState.player,
            enemies: enemies,
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
        selectedEnemyIndex = enemies.count == 1 ? 0 : nil
        battleTargetHint = nil
        battleSource = source
        if source == .mapNode {
            eventBattleContext = nil
        }
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
        selectedEnemyIndex = nil
        battleTargetHint = nil
        restRoomMessage = nil
        shopRoomState = nil
        eventRoomState = nil
        battleSource = .mapNode
        eventBattleContext = nil
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
        sanitizeSelectedEnemyIndex()
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

    private enum TargetResolution {
        case resolved(Int?)
        case missingTarget
    }

    private func resolveTargetEnemyIndex(for card: Card, in state: BattleState) -> TargetResolution {
        let definition = CardRegistry.require(card.cardId)
        guard definition.targeting == .singleEnemy else { return .resolved(nil) }

        let aliveEnemyIndices = state.enemies.indices.filter { state.enemies[$0].isAlive }
        guard !aliveEnemyIndices.isEmpty else {
            battleTargetHint = "没有可选目标"
            return .missingTarget
        }

        if aliveEnemyIndices.count == 1, let only = aliveEnemyIndices.first {
            selectedEnemyIndex = only
            return .resolved(only)
        }

        guard let selectedEnemyIndex, aliveEnemyIndices.contains(selectedEnemyIndex) else {
            battleTargetHint = "该牌需要选择目标：请先点击敌人"
            return .missingTarget
        }
        return .resolved(selectedEnemyIndex)
    }

    private func sanitizeSelectedEnemyIndex() {
        guard let battleState else {
            selectedEnemyIndex = nil
            return
        }

        if let selectedEnemyIndex {
            let isValid = battleState.enemies.indices.contains(selectedEnemyIndex)
                && battleState.enemies[selectedEnemyIndex].isAlive
            if !isValid {
                self.selectedEnemyIndex = nil
                battleTargetHint = "目标已失效，请重新选择"
            }
        }

        if selectedEnemyIndex == nil {
            let aliveEnemyIndices = battleState.enemies.indices.filter { battleState.enemies[$0].isAlive }
            if aliveEnemyIndices.count == 1, let only = aliveEnemyIndices.first {
                selectedEnemyIndex = only
            }
        }
    }

    private func captureInvalidActionHint(from events: [BattleEvent], startIndex: Int) {
        guard startIndex < events.count else { return }
        for event in events[startIndex..<events.count].reversed() {
            guard case .invalidAction(let reason) = event else { continue }
            battleTargetHint = reason.resolved(for: .zhHans)
            return
        }
    }

    private func clearRoomState(clearEventBattleContext: Bool) {
        restRoomMessage = nil
        shopRoomState = nil
        eventRoomState = nil
        if clearEventBattleContext {
            eventBattleContext = nil
        }
    }

    private func prepareRoomState(nodeId: String, roomType: RoomType, runState: RunState) {
        restRoomMessage = nil
        eventBattleContext = nil

        switch roomType {
        case .rest:
            shopRoomState = nil
            eventRoomState = nil

        case .shop:
            let context = ShopContext(
                seed: runState.seed,
                floor: runState.floor,
                currentRow: runState.currentRow,
                nodeId: nodeId,
                ownedRelicIds: runState.relicManager.all
            )
            shopRoomState = ShopRoomState(
                nodeId: nodeId,
                inventory: ShopInventory.generate(context: context)
            )
            eventRoomState = nil

        case .event:
            let context = EventContext(
                seed: runState.seed,
                floor: runState.floor,
                currentRow: runState.currentRow,
                nodeId: nodeId,
                playerMaxHP: runState.player.maxHP,
                playerCurrentHP: runState.player.currentHP,
                gold: runState.gold,
                deck: runState.deck,
                relicIds: runState.relicManager.all
            )
            eventRoomState = EventRoomState(
                nodeId: nodeId,
                offer: EventGenerator.generate(context: context)
            )
            shopRoomState = nil

        default:
            shopRoomState = nil
            eventRoomState = nil
        }
    }

    private func ensureShopRoomState(nodeId: String, runState: RunState) -> ShopRoomState {
        if let shopRoomState, shopRoomState.nodeId == nodeId {
            return shopRoomState
        }
        let context = ShopContext(
            seed: runState.seed,
            floor: runState.floor,
            currentRow: runState.currentRow,
            nodeId: nodeId,
            ownedRelicIds: runState.relicManager.all
        )
        let generated = ShopRoomState(
            nodeId: nodeId,
            inventory: ShopInventory.generate(context: context)
        )
        self.shopRoomState = generated
        return generated
    }

    private func ensureEventRoomState(nodeId: String, runState: RunState) -> EventRoomState {
        if let eventRoomState, eventRoomState.nodeId == nodeId {
            return eventRoomState
        }
        let context = EventContext(
            seed: runState.seed,
            floor: runState.floor,
            currentRow: runState.currentRow,
            nodeId: nodeId,
            playerMaxHP: runState.player.maxHP,
            playerCurrentHP: runState.player.currentHP,
            gold: runState.gold,
            deck: runState.deck,
            relicIds: runState.relicManager.all
        )
        let generated = EventRoomState(nodeId: nodeId, offer: EventGenerator.generate(context: context))
        self.eventRoomState = generated
        return generated
    }

    private func setShopMessage(_ message: String, in shopState: inout ShopRoomState) {
        shopMessageSequence &+= 1
        shopState.message = message
        shopState.messageSequence = shopMessageSequence
    }

    private func clearBattleState(preserveSnapshot: Bool) {
        battleEngine = nil
        if !preserveSnapshot {
            battleState = nil
            battleEvents = []
        }
        battleNodeId = nil
        battleRoomType = nil
        lastConsumedBattleEventIndex = 0
        playedCardContextsBySequence = [:]
        selectedEnemyIndex = nil
        battleTargetHint = nil
        battleSource = .mapNode
        eventBattleContext = nil
    }

    private func resolveEventEliteBattleVictory(nodeId: String) {
        let context = eventBattleContext
        clearBattleState(preserveSnapshot: false)

        guard var eventRoomState,
              let context,
              eventRoomState.nodeId == nodeId,
              context.nodeId == nodeId else {
            route = .room(nodeId: nodeId, roomType: .event)
            return
        }

        let enemyName = EnemyRegistry.require(context.enemyId).name.resolved(for: .zhHans)
        var resultLines = context.baseResultLines
        resultLines.append("你击败了：\(enemyName)")
        eventRoomState.phase = .resolved(optionIndex: context.optionIndex, resultLines: resultLines)
        eventRoomState.message = nil
        self.eventRoomState = eventRoomState
        route = .room(nodeId: nodeId, roomType: .event)
    }

    private func buildEventResultLines(option: EventOption, additional: [String]) -> [String] {
        if let preview = option.preview {
            let text = preview.resolved(for: .zhHans)
            if !text.isEmpty {
                return [text] + additional
            }
        }

        if option.effects.isEmpty {
            return additional.isEmpty ? ["没有发生任何事。"] : additional
        }

        let base = option.effects.map(describeRunEffect)
        return base + additional
    }

    private func describeRunEffect(_ effect: RunEffect) -> String {
        switch effect {
        case .gainGold(let amount):
            return "获得 \(amount) 金币"
        case .loseGold(let amount):
            return "失去 \(amount) 金币"
        case .heal(let amount):
            return "恢复 \(amount) HP"
        case .takeDamage(let amount):
            return "失去 \(amount) HP"
        case .addCard(let cardId):
            let name = CardRegistry.require(cardId).name.resolved(for: .zhHans)
            return "获得卡牌：\(name)"
        case .addRelic(let relicId):
            let def = RelicRegistry.require(relicId)
            return "获得遗物：\(def.icon) \(def.name.resolved(for: .zhHans))"
        case .applyStatus(let statusId, let stacks):
            let statusName = StatusRegistry.get(statusId)?.name.resolved(for: .zhHans) ?? statusId.rawValue
            let sign = stacks >= 0 ? "+" : ""
            return "\(statusName) \(sign)\(stacks)"
        case .setStatus(let statusId, let stacks):
            let statusName = StatusRegistry.get(statusId)?.name.resolved(for: .zhHans) ?? statusId.rawValue
            return "\(statusName) 设为 \(stacks)"
        case .upgradeCard:
            return "升级了一张卡牌"
        }
    }

    private func eventApplyFailureLine(for effect: RunEffect) -> String {
        switch effect {
        case .addCard(let cardId):
            if let def = CardRegistry.get(cardId), def.type == .consumable {
                return "消耗性卡牌槽位已满，未能获得 \(def.name.resolved(for: .zhHans))"
            }
            return "未能获得卡牌"
        default:
            return "有一项效果未能生效"
        }
    }
}
