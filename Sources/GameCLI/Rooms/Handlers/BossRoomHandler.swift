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

            // 测试模式：进入下一幕后继续使用小地图，避免退回 15 层分支大地图导致验收变慢。
            if TestMode.useTestMap && !runState.isOver {
                runState.map = TestMode.testMapNodes()
            }
            
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
        
        // 创建 Boss 敌人
        var rng = SeededRNG(seed: bossSeed)
        let bossId: EnemyID
        switch runState.floor {
        case 1:
            bossId = "toxic_colossus"  // 瘴气之主
        case 2:
            bossId = "cipher"  // 赛弗（P2 占卜家序列：替换窥视者）
        default:
            bossId = "sequence_progenitor"  // 序列始祖（最终 Boss）
        }
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
        let loopResult = context.battleLoop(engine, bossSeed, &runState)
        
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
            let enemyName = engine.state.enemies.first.map { L10n.resolve($0.name) } ?? L10n.text("敌人", "Enemy")
            context.logLine("\(Terminal.green)Boss \(L10n.text("胜利", "victory"))：\(L10n.text("击败", "Defeated")) \(enemyName)\(Terminal.reset)")
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
                    context.logLine("\(Terminal.magenta)\(L10n.text("获得遗物", "Relic gained"))：\(relicDef.icon)\(L10n.resolve(relicDef.name))\(Terminal.reset)")
                } else {
                    context.logLine("\(Terminal.dim)\(L10n.text("遗物奖励", "Relic reward"))：\(L10n.text("跳过", "Skipped"))（\(relicDef.icon)\(L10n.resolve(relicDef.name))）\(Terminal.reset)")
                }
            }
            
            // 显示章节收束/结局文本
            // 只有在真正的最终章（第 3 章及以上且已达到 maxFloor）才算通关
            let isVictory = runState.floor >= 3 && runState.floor >= runState.maxFloor
            ChapterEndScreen.show(floor: runState.floor, maxFloor: runState.maxFloor, isVictory: isVictory)
            
            // 若不是最终幕，提示进入下一幕
            if runState.floor < runState.maxFloor {
                context.logLine("\(Terminal.cyan)\(L10n.text("进入第", "Entering floor")) \(runState.floor + 1) \(L10n.text("层冒险…", "..."))\(Terminal.reset)")
            }
            
            return .won
        }
        
        // 战斗失败（玩家 HP 归零）
        let enemyName = engine.state.enemies.first.map { L10n.resolve($0.name) } ?? L10n.text("敌人", "Enemy")
        context.logLine("\(Terminal.red)Boss \(L10n.text("失败", "defeat"))：\(L10n.text("倒在", "Fell before")) \(enemyName)\(Terminal.reset)")
        return .lost
    }
}
