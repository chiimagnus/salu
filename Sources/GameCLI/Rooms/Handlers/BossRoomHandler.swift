import GameCore

/// Boss 房间处理器
struct BossRoomHandler: RoomHandling {
    var roomType: RoomType { .boss }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let result = handleBossFight(node: node, runState: &runState, context: context)
        
        switch result {
        case .won:
            // Boss 胜利：完成节点（可能推进到下一幕，也可能直接通关）
            runState.completeCurrentNode()
            
            if runState.isOver {
                return .runEnded(won: true)
            }
            return .completedNode
            
        case .lost:
            return .runEnded(won: false)
            
        case .aborted:
            return .aborted
        }
    }
    
    private func handleBossFight(node: MapNode, runState: inout RunState, context: RoomContext) -> BattleHandleResult {
        // Boss 战斗使用特殊种子
        let bossSeed = runState.seed &+ UInt64(runState.floor) &* 1_000_000 &+ 99999
        
        // 创建 Boss 敌人（P7：Act1 真 Boss）
        var rng = SeededRNG(seed: bossSeed)
        let bossId: EnemyID = (runState.floor == 1) ? "toxic_colossus" : "chrono_watcher"
        let enemy = context.createEnemy(bossId, 0, &rng)
        
        // 创建战斗引擎（使用冒险中的玩家状态和遗物）
        let engine = BattleEngine(
            player: runState.player,
            enemies: [enemy],
            deck: TestMode.battleDeck(from: runState.deck),
            relicManager: runState.relicManager,
            seed: bossSeed
        )
        engine.startBattle()
        
        // 收集初始事件（统一日志）
        context.logBattleEvents(engine.events)
        engine.clearEvents()
        
        // 战斗循环
        let loopResult = context.battleLoop(engine, bossSeed)
        
        // 用户中途退出：不保存战斗记录，不更新玩家状态，直接返回
        if loopResult == .aborted {
            return .aborted
        }
        
        // 保存战斗记录（仅在战斗正常结束时）
        let record = BattleRecordBuilder.build(from: engine, seed: bossSeed)
        context.historyService.addRecord(record)
        
        // 更新玩家状态
        runState.updateFromBattle(playerHP: engine.state.player.currentHP)
        
        // 胜利后掉落遗物
        if engine.state.playerWon == true {
            let enemyName = engine.state.enemies.first?.name ?? "敌人"
            context.logLine("\(Terminal.green)Boss 胜利：击败 \(enemyName)\(Terminal.reset)")
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
                    context.logLine("\(Terminal.magenta)获得遗物：\(relicDef.icon)\(relicDef.name)\(Terminal.reset)")
                } else {
                    context.logLine("\(Terminal.dim)遗物奖励：跳过（\(relicDef.icon)\(relicDef.name)）\(Terminal.reset)")
                }
            }
            
            // 若不是最终幕，提示进入下一幕
            if runState.floor < runState.maxFloor {
                context.logLine("\(Terminal.cyan)进入第 \(runState.floor + 1) 层冒险…\(Terminal.reset)")
            }
            
            return .won
        }
        
        // 战斗失败（玩家 HP 归零）
        let enemyName = engine.state.enemies.first?.name ?? "敌人"
        context.logLine("\(Terminal.red)Boss 失败：倒在 \(enemyName) 面前\(Terminal.reset)")
        return .lost
    }
}
