import GameCore

/// 战斗房间处理器
struct BattleRoomHandler: RoomHandling {
    var roomType: RoomType { .battle }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let won = handleBattle(node: node, runState: &runState, context: context)
        
        if won {
            return .completedNode
        } else {
            return .runEnded(won: false)
        }
    }
    
    private func handleBattle(node: MapNode, runState: inout RunState, context: RoomContext) -> Bool {
        // 使用当前 RNG 状态创建新的种子
        let battleSeed = runState.seed &+ UInt64(runState.currentRow) &* 1000
        
        // 选择敌人（普通战斗：弱敌人池）
        var rng = SeededRNG(seed: battleSeed)
        let enemyId = Act1EnemyPool.randomWeak(rng: &rng)
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
            context.logLine("\(Terminal.green)战斗胜利：击败 \(engine.state.enemy.name)\(Terminal.reset)")
            // P1：战斗奖励（卡牌 3 选 1）
            let rewardContext = RewardContext(
                seed: runState.seed,
                floor: runState.floor,
                currentRow: runState.currentRow,
                nodeId: node.id,
                roomType: node.roomType
            )
            
            // P2：战斗胜利获得金币（可复现）
            let goldEarned = GoldRewardStrategy.generateGoldReward(context: rewardContext)
            runState.gold += goldEarned
            context.logLine("\(Terminal.yellow)获得金币：+\(goldEarned)\(Terminal.reset)")
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
