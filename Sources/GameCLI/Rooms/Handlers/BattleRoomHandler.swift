import GameCore

/// 战斗房间处理器
struct BattleRoomHandler: RoomHandling {
    var roomType: RoomType { .battle }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let isElite = (node.roomType == .elite)
        let won = handleBattle(runState: &runState, isElite: isElite, context: context)
        
        if won {
            return .completedNode
        } else {
            return .runEnded(won: false)
        }
    }
    
    private func handleBattle(runState: inout RunState, isElite: Bool, context: RoomContext) -> Bool {
        // 使用当前 RNG 状态创建新的种子
        let battleSeed = runState.seed &+ UInt64(runState.currentRow) &* 1000
        
        // 选择敌人
        var rng = SeededRNG(seed: battleSeed)
        let enemyId: EnemyID
        if isElite {
            // 精英战斗：使用 medium 池
            enemyId = Act1EnemyPool.randomAny(rng: &rng)
        } else {
            // 普通战斗
            enemyId = Act1EnemyPool.randomWeak(rng: &rng)
        }
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
