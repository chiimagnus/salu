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
        let battleSeed = runState.seed &+ UInt64(runState.currentRow) &* 1000
        
        // 选择敌人（精英战斗：中等敌人池）
        var rng = SeededRNG(seed: battleSeed)
        let enemyId = Act1EnemyPool.randomMedium(rng: &rng)
        let enemy = context.createEnemy(enemyId, &rng)
        
        // 创建战斗引擎（使用冒险中的玩家状态和遗物）
        let engine = BattleEngine(
            player: runState.player,
            enemy: enemy,
            deck: TestMode.battleDeck(from: runState.deck),
            relicManager: runState.relicManager,
            seed: battleSeed
        )
        engine.startBattle()
        
        // 清空事件
        context.clearEvents()
        context.appendEvents(engine.events)
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
            let rewardContext = RewardContext(
                seed: runState.seed,
                floor: runState.floor,
                currentRow: runState.currentRow,
                nodeId: node.id,
                roomType: node.roomType
            )
            
            // 精英战斗：遗物掉落
            if let relicId = RelicDropStrategy.generateRelicDrop(
                context: rewardContext,
                source: .elite,
                ownedRelics: runState.relicManager.all
            ) {
                if RelicRewardScreen.chooseRelic(relicId: relicId) {
                    runState.relicManager.add(relicId)
                }
            }
            
            // 卡牌奖励（3 选 1）
            let offer = RewardGenerator.generateCardReward(context: rewardContext)
            if let chosen = RewardScreen.chooseCard(offer: offer) {
                runState.addCardToDeck(cardId: chosen)
            }
            
            runState.completeCurrentNode()
            return true
        }
        
        return false
    }
}
