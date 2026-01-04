import GameCore

/// 精英战斗房间处理器
struct EliteRoomHandler: RoomHandling {
    var roomType: RoomType { .elite }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let won = handleEliteBattle(runState: &runState, context: context)
        
        if won {
            return .completedNode
        } else {
            return .runEnded(won: false)
        }
    }
    
    private func handleEliteBattle(runState: inout RunState, context: RoomContext) -> Bool {
        // 使用当前 RNG 状态创建新的种子
        let battleSeed = runState.seed &+ UInt64(runState.currentRow) &* 1000
        
        // 选择敌人（精英战斗：使用 medium 池）
        var rng = SeededRNG(seed: battleSeed)
        let enemyId = Act1EnemyPool.randomAny(rng: &rng)
        let enemy = context.createEnemy(enemyId, &rng)
        
        // 创建战斗引擎（使用冒险中的玩家状态和遗物）
        let engine = BattleEngine(
            player: runState.player,
            enemy: enemy,
            deck: runState.deck,
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
            runState.completeCurrentNode()
            return true
        }
        
        return false
    }
}
