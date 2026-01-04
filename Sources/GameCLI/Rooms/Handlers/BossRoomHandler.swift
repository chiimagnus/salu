import GameCore

/// Boss 房间处理器
struct BossRoomHandler: RoomHandling {
    var roomType: RoomType { .boss }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let won = handleBossFight(runState: &runState, context: context)
        return .runEnded(won: won)
    }
    
    private func handleBossFight(runState: inout RunState, context: RoomContext) -> Bool {
        // Boss 战斗使用特殊种子
        let bossSeed = runState.seed &+ 99999
        
        // 创建 Boss 敌人（目前使用 slimeMediumAcid 作为临时 Boss）
        var rng = SeededRNG(seed: bossSeed)
        let enemy = context.createEnemy("slime_medium_acid", &rng)
        
        // 创建战斗引擎（使用冒险中的玩家状态和遗物）
        let engine = BattleEngine(
            player: runState.player,
            enemy: enemy,
            deck: runState.deck,
            relicManager: runState.relicManager,
            seed: bossSeed
        )
        engine.startBattle()
        
        // 清空事件
        context.clearEvents()
        context.appendEvents(engine.events)
        engine.clearEvents()
        
        // 战斗循环
        context.battleLoop(engine, bossSeed)
        
        // 保存战斗记录
        let record = BattleRecordBuilder.build(from: engine, seed: bossSeed)
        context.historyService.addRecord(record)
        
        // 更新玩家状态
        runState.updateFromBattle(playerHP: engine.state.player.currentHP)
        
        // 返回是否胜利
        return engine.state.playerWon == true
    }
}
