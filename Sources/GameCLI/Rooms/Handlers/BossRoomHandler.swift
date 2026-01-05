import GameCore

/// Boss 房间处理器
struct BossRoomHandler: RoomHandling {
    var roomType: RoomType { .boss }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let won = handleBossFight(node: node, runState: &runState, context: context)
        return .runEnded(won: won)
    }
    
    private func handleBossFight(node: MapNode, runState: inout RunState, context: RoomContext) -> Bool {
        // Boss 战斗使用特殊种子
        let bossSeed = runState.seed &+ 99999
        
        // 创建 Boss 敌人（目前使用 slimeMediumAcid 作为临时 Boss）
        var rng = SeededRNG(seed: bossSeed)
        let enemy = context.createEnemy("slime_medium_acid", &rng)
        
        // 创建战斗引擎（使用冒险中的玩家状态和遗物）
        let engine = BattleEngine(
            player: runState.player,
            enemy: enemy,
            deck: TestMode.battleDeck(from: runState.deck),
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
        
        // 胜利后掉落遗物
        if engine.state.playerWon == true {
            context.appendRunLog("\(Terminal.green)Boss 胜利：击败 \(engine.state.enemy.name)\(Terminal.reset)")
            let rewardContext = RewardContext(
                seed: runState.seed,
                floor: runState.floor,
                currentRow: runState.currentRow,
                nodeId: node.id,
                roomType: node.roomType
            )
            
            if let relicId = RelicDropStrategy.generateRelicDrop(
                context: rewardContext,
                source: .boss,
                ownedRelics: runState.relicManager.all
            ) {
                let relicDef = RelicRegistry.require(relicId)
                if RelicRewardScreen.chooseRelic(relicId: relicId) {
                    runState.relicManager.add(relicId)
                    context.appendRunLog("\(Terminal.magenta)获得遗物：\(relicDef.icon)\(relicDef.name)\(Terminal.reset)")
                } else {
                    context.appendRunLog("\(Terminal.dim)遗物奖励：跳过（\(relicDef.icon)\(relicDef.name)）\(Terminal.reset)")
                }
            }
        } else {
            context.appendRunLog("\(Terminal.red)Boss 失败：倒在 \(engine.state.enemy.name) 面前\(Terminal.reset)")
        }
        
        return engine.state.playerWon == true
    }
}
