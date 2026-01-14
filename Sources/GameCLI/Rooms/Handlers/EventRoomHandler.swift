import GameCore

/// 事件房间处理器（P5）
struct EventRoomHandler: RoomHandling {
    var roomType: RoomType { .event }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let eventContext = EventContext(
            seed: runState.seed,
            floor: runState.floor,
            currentRow: runState.currentRow,
            nodeId: node.id,
            playerMaxHP: runState.player.maxHP,
            playerCurrentHP: runState.player.currentHP,
            gold: runState.gold,
            deck: runState.deck,
            relicIds: runState.relicManager.all
        )
        
        let offer = EventGenerator.generate(context: eventContext)
        context.logLine("\(Terminal.magenta)事件：\(offer.icon)\(offer.name)\(Terminal.reset)")
        guard let choiceIndex = EventScreen.chooseOption(offer: offer) else {
            // 默认视为离开（不产生效果）
            context.logLine("\(Terminal.dim)事件：离开\(Terminal.reset)")
            runState.completeCurrentNode()
            return .completedNode
        }
        
        guard choiceIndex >= 0, choiceIndex < offer.options.count else {
            runState.completeCurrentNode()
            return .completedNode
        }
        
        let picked = offer.options[choiceIndex]
        context.logLine("\(Terminal.cyan)事件选择：\(picked.title)\(Terminal.reset)")
        
        // 应用效果
        var applyFailureLines: [String] = []
        for effect in picked.effects {
            let ok = runState.apply(effect)
            if !ok {
                switch effect {
                case .addConsumable:
                    applyFailureLines.append("消耗品槽位已满，未能获得消耗品")
                default:
                    applyFailureLines.append("有一项效果未能生效")
                }
            }
        }

        // 二次选择（如：选择要升级的卡牌）
        var followUpLines: [String] = []
        if let followUp = picked.followUp {
            switch followUp {
            case .chooseUpgradeableCard(let indices):
                if let deckIndex = EventScreen.chooseUpgradeableCard(runState: runState, upgradeableIndices: indices) {
                    let before = runState.deck[deckIndex]
                    let beforeDef = CardRegistry.require(before.cardId)
                    if let upgradedId = beforeDef.upgradedId {
                        let upgradedDef = CardRegistry.require(upgradedId)
                        _ = runState.apply(.upgradeCard(deckIndex: deckIndex))
                        followUpLines.append("升级：\(beforeDef.name) → \(upgradedDef.name)")
                        context.logLine("\(Terminal.cyan)升级：\(beforeDef.name) → \(upgradedDef.name)\(Terminal.reset)")
                    }
                }
            case .startEliteBattle(let enemyId):
                let battleResult = runEliteBattleAgainst(enemyId: enemyId, node: node, runState: &runState, context: context)
                switch battleResult {
                case .won:
                    let name = EnemyRegistry.require(enemyId).name
                    followUpLines.append("你击败了：\(name)")
                case .lost:
                    return .runEnded(won: false)
                case .aborted:
                    return .aborted
                }
            }
        }
        
        // 结算展示（简单：逐条展示 preview 或效果摘要）
        let resultLines = buildResultLines(option: picked, additional: followUpLines + applyFailureLines)
        EventScreen.showResult(title: "你选择了：\(picked.title)", lines: resultLines)
        _ = readLine()
        
        // 完成节点
        runState.completeCurrentNode()
        return .completedNode
    }
    
    /// 事件触发的“精英战斗”分支（复用 EliteRoomHandler 的核心逻辑，但固定敌人）
    private func runEliteBattleAgainst(
        enemyId: EnemyID,
        node: MapNode,
        runState: inout RunState,
        context: RoomContext
    ) -> BattleHandleResult {
        // 使用当前 RNG 状态创建新的种子（与精英房间一致，保证可复现）
        let battleSeed = runState.seed &+ UInt64(runState.floor) &* 1_000_000 &+ UInt64(runState.currentRow) &* 1000
        
        // 固定敌人：疯狂预言者（或未来其他事件战）
        var rng = SeededRNG(seed: battleSeed)
        let enemy = context.createEnemy(enemyId, 0, &rng)
        
        let engine = BattleEngine(
            player: runState.player,
            enemies: [enemy],
            deck: TestMode.battleDeck(from: runState.deck),
            relicManager: runState.relicManager,
            seed: battleSeed
        )
        engine.startBattle()
        
        context.logBattleEvents(engine.events)
        engine.clearEvents()
        
        let loopResult = context.battleLoop(engine, battleSeed, &runState)
        if loopResult == .aborted {
            return .aborted
        }
        
        // 保存战斗记录（仅在战斗正常结束时）
        let record = BattleRecordBuilder.build(from: engine, seed: battleSeed)
        context.historyService.addRecord(record)
        
        // 更新玩家状态
        runState.updateFromBattle(playerHP: engine.state.player.currentHP)
        
        // 胜利：按“精英战斗”链路结算（金币 + 遗物掉落 + 卡牌奖励）
        if engine.state.playerWon == true {
            let enemyName = engine.state.enemies.first?.name ?? "敌人"
            context.logLine("\(Terminal.green)精英胜利：击败 \(enemyName)\(Terminal.reset)")
            
            let rewardContext = RewardContext(
                seed: runState.seed,
                floor: runState.floor,
                currentRow: runState.currentRow,
                nodeId: node.id,
                roomType: .elite
            )
            
            let goldEarned = GoldRewardStrategy.generateGoldReward(context: rewardContext)
            runState.gold += goldEarned
            context.logLine("\(Terminal.yellow)获得金币：+\(goldEarned)\(Terminal.reset)")
            
            if let relicId = RelicDropStrategy.generateRelicDrop(
                context: rewardContext,
                source: .elite,
                ownedRelics: runState.relicManager.all
            ) {
                let relicDef = RelicRegistry.require(relicId)
                if RelicRewardScreen.chooseRelic(relicId: relicId) {
                    runState.relicManager.add(relicId)
                    context.logLine("\(Terminal.magenta)获得遗物：\(relicDef.icon)\(relicDef.name)\(Terminal.reset)")
                } else {
                    context.logLine("\(Terminal.dim)遗物奖励：跳过（\(relicDef.icon)\(relicDef.name)）\(Terminal.reset)")
                }
            }
            
            let offer = RewardGenerator.generateCardReward(context: rewardContext)
            if let chosen = RewardScreen.chooseCard(offer: offer, goldEarned: goldEarned) {
                runState.addCardToDeck(cardId: chosen)
                context.logLine("\(Terminal.cyan)卡牌奖励：获得「\(CardRegistry.require(chosen).name)」\(Terminal.reset)")
            } else {
                context.logLine("\(Terminal.dim)卡牌奖励：跳过\(Terminal.reset)")
            }
            
            return .won
        }
        
        return .lost
    }
    
    private func buildResultLines(option: EventOption, additional: [String]) -> [String] {
        if let preview = option.preview, !preview.isEmpty {
            return [preview] + additional
        }
        
        if option.effects.isEmpty {
            if additional.isEmpty {
                return ["没有发生任何事。"]
            }
            return additional
        }
        
        let base = option.effects.map { effect in
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
                let name = CardRegistry.require(cardId).name
                return "获得卡牌：\(name)"
            case .addRelic(let relicId):
                let def = RelicRegistry.require(relicId)
                return "获得遗物：\(def.icon)\(def.name)"
            case .applyStatus(let statusId, let stacks):
                let name = StatusRegistry.get(statusId)?.name ?? statusId.rawValue
                let sign = stacks >= 0 ? "+" : ""
                return "\(name) \(sign)\(stacks)"
            case .setStatus(let statusId, let stacks):
                let name = StatusRegistry.get(statusId)?.name ?? statusId.rawValue
                return "\(name) 设为 \(stacks)"
            case .addConsumable(let consumableId):
                let def = ConsumableRegistry.require(consumableId)
                return "获得消耗品：\(def.icon)\(def.name)"
            case .upgradeCard:
                return "升级了一张卡牌"
            }
        }
        return base + additional
    }
}


