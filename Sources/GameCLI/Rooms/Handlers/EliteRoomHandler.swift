import GameCore

/// 精英战斗房间处理器
struct EliteRoomHandler: RoomHandling {
    var roomType: RoomType { .elite }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let won = handleEliteBattle(node: node, runState: &runState, context: context)
        
        if won {
            return .completedNode
        } else {
            return .runEnded(won: false)
        }
    }
    
    private func handleEliteBattle(node: MapNode, runState: inout RunState, context: RoomContext) -> Bool {
        // 使用当前 RNG 状态创建新的种子
        let battleSeed = runState.seed &+ UInt64(runState.floor) &* 1_000_000 &+ UInt64(runState.currentRow) &* 1000
        
        // 选择敌人（精英战斗：中等敌人池）
        var rng = SeededRNG(seed: battleSeed)
        let enemyId = (runState.floor == 1) ? Act1EnemyPool.randomMedium(rng: &rng) : Act2EnemyPool.randomMedium(rng: &rng)
        let enemy = context.createEnemy(enemyId, 0, &rng)
        
        // 创建战斗引擎（使用冒险中的玩家状态和遗物）
        let engine = BattleEngine(
            player: runState.player,
            enemies: [enemy],
            deck: TestMode.battleDeck(from: runState.deck),
            relicManager: runState.relicManager,
            seed: battleSeed
        )
        engine.startBattle()
        
        // 收集初始事件（统一日志）
        context.logBattleEvents(engine.events)
        engine.clearEvents()
        
        // 战斗循环
        context.battleLoop(engine, battleSeed)
        
        // 保存战斗记录
        let record = BattleRecordBuilder.build(from: engine, seed: battleSeed)
        context.historyService.addRecord(record)
        
        // 更新玩家状态
        runState.updateFromBattle(playerHP: engine.state.player.currentHP)
        
        // 如果胜利，完成节点
        if engine.state.playerWon == true {
            let enemyName = engine.state.enemies.first?.name ?? "敌人"
            context.logLine("\(Terminal.green)精英胜利：击败 \(enemyName)\(Terminal.reset)")
            let rewardContext = RewardContext(
                seed: runState.seed,
                floor: runState.floor,
                currentRow: runState.currentRow,
                nodeId: node.id,
                roomType: node.roomType
            )

            // P2：精英胜利获得金币（可复现）
            let goldEarned = GoldRewardStrategy.generateGoldReward(context: rewardContext)
            runState.gold += goldEarned
            context.logLine("\(Terminal.yellow)获得金币：+\(goldEarned)\(Terminal.reset)")
            
            // 精英战斗：遗物掉落
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
            
            // 卡牌奖励（3 选 1）
            let offer = RewardGenerator.generateCardReward(context: rewardContext)
            if let chosen = RewardScreen.chooseCard(offer: offer, goldEarned: goldEarned) {
                runState.addCardToDeck(cardId: chosen)
                context.logLine("\(Terminal.cyan)卡牌奖励：获得「\(CardRegistry.require(chosen).name)」\(Terminal.reset)")
            } else {
                context.logLine("\(Terminal.dim)卡牌奖励：跳过\(Terminal.reset)")
            }
            
            runState.completeCurrentNode()
            return true
        }
        
        return false
    }
}
