import GameCore
import Foundation

/// 游戏 CLI 入口
@main
struct GameCLI {
    
    // MARK: - 状态
    
    /// 日志（统一：战斗事件 + 冒险事件）
    private nonisolated(unsafe) static var recentLogs: [String] = []
    private static let maxRecentLogs = 200
    
    /// 当前消息
    private nonisolated(unsafe) static var currentMessage: String? = nil
    
    /// 是否显示日志面板
    private nonisolated(unsafe) static var showLog: Bool = false
    
    /// 历史记录服务（依赖注入，替代单例）
    private nonisolated(unsafe) static var historyService: HistoryService!
    
    /// 存档服务（依赖注入）
    private nonisolated(unsafe) static var saveService: SaveService!

    /// Run 日志服务（调试用落盘）
    private nonisolated(unsafe) static var runLogService: RunLogService!
    
    /// 设置存储
    private nonisolated(unsafe) static var settingsStore: SettingsStore!
    
    // MARK: - Main Entry
    
    static func main() {
        // 初始化历史记录服务（依赖注入）
        let historyStore = FileBattleHistoryStore()
        historyService = HistoryService(store: historyStore)
        
        // 初始化存档服务（依赖注入）
        let saveStore = FileRunSaveStore()
        saveService = SaveService(store: saveStore)

        // 初始化 Run 日志服务（依赖注入）
        runLogService = RunLogService(store: FileRunLogStore())
        
        // 初始化设置存储并加载设置
        settingsStore = SettingsStore()
        let settings = settingsStore.load()
        showLog = settings.showLog
        
        // 检查命令行快捷参数
        if CommandLine.arguments.contains("--history") || CommandLine.arguments.contains("-H") {
            Screens.showHistory(historyService: historyService)
            return
        }
        
        if CommandLine.arguments.contains("--stats") || CommandLine.arguments.contains("-S") {
            Screens.showStatistics(historyService: historyService)
            return
        }
        
        // 显示主菜单
        mainMenuLoop()
        
        // 显示光标
        print(Terminal.showCursor, terminator: "")
    }
    
    // MARK: - Main Menu
    
    static func mainMenuLoop() {
        while true {
            let hasSave = saveService.hasSave()
            Screens.showMainMenu(historyService: historyService, hasSave: hasSave)
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                // EOF 或输入关闭，退出主菜单
                return
            }

            // 使用 (hasSave, input) 明确分支，避免 switch pattern + where 造成歧义
            switch (hasSave, input) {
            case (_, "q"):
                Screens.showExit()
                return

            case (true, "1"):
                // 继续上次冒险
                continueRun()

            case (true, "2"):
                // 开始新冒险
                startNewRun()

            case (true, "3"):
                // 设置菜单
                settingsMenuLoop()

            case (true, "4"):
                Screens.showExit()
                return

            case (false, "1"):
                // 开始冒险
                startNewRun()

            case (false, "2"):
                // 设置菜单
                settingsMenuLoop()

            case (false, "3"):
                Screens.showExit()
                return

            default:
                // 无效输入，重新显示
                break
            }
        }
    }
    
    // MARK: - Settings Menu
    
    static func settingsMenuLoop() {
        while true {
            Screens.showSettingsMenu(historyService: historyService, showLog: showLog)
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                // EOF 或输入关闭，退出设置菜单
                return
            }
            
            switch input {
            case "1":
                // 查看历史记录
                Screens.showHistory(historyService: historyService)
                
            case "2":
                // 查看统计数据
                Screens.showStatistics(historyService: historyService)
                
            case "3":
                // 清除历史记录
                confirmClearHistory()
                
            case "4":
                // 资源管理（开发者工具）
                Screens.showResources()
                NavigationBar.waitForBack()
                Terminal.clearAll()  // 清除长列表的滚动缓冲区
                
            case "5":
                // 游戏帮助
                Screens.showHelp()
                NavigationBar.waitForBack()
                
            case "6":
                // 切换日志显示并保存设置
                showLog.toggle()
                var settings = settingsStore.load()
                settings.showLog = showLog
                settingsStore.save(settings)

            case "7":
                // 数据目录（开发者/排查工具）
                Screens.showDataDirectory()
                NavigationBar.waitForBack()

            case "8":
                // 事件种子工具（开发者/验收辅助）
                Screens.showEventSeedTool()
                NavigationBar.waitForBack()
                
            case "q":
                // 返回主菜单
                return
                
            default:
                break
            }
        }
    }
    
    static func confirmClearHistory() {
        Terminal.clear()
        print("""
        \(Terminal.bold)\(Terminal.red)
        ╔═══════════════════════════════════════════════════════╗
        ║              ⚠️  确认清除历史记录？                   ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  此操作不可恢复！                                     ║
        ║                                                       ║
        ║  当前共有 \(String(format: "%3d", historyService.recordCount)) 条记录                                ║
        ║                                                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║  输入 \(Terminal.reset)yes\(Terminal.bold)\(Terminal.red) 确认删除，其他任意键取消                     ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        print("\(Terminal.yellow)> \(Terminal.reset)", terminator: "")
        if let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased(), input == "yes" {
            historyService.clearHistory()
            Terminal.clear()
            print("\n        \(Terminal.green)✓ 历史记录已清除\(Terminal.reset)\n")
            NavigationBar.render(items: [.back])
            NavigationBar.waitForBack()
        }
    }
    
    // MARK: - Run (冒险模式)
    
    /// 当前冒险状态
    private nonisolated(unsafe) static var currentRunState: RunState? = nil
    
    static func startNewRun() {
        let seed = parseSeed(from: CommandLine.arguments)

        // 新冒险：清空内存日志，并在文件日志写入分隔线
        recentLogs.removeAll()
        runLogService.appendSystem("开始新冒险（seed=\(seed)）")
        
        // 创建新冒险
        if TestMode.useTestMap {
            currentRunState = TestMode.testRunState(seed: seed)
        } else {
            currentRunState = RunState.newRun(seed: seed)
        }
        
        // 进入冒险循环
        runLoop()
    }
    
    static func continueRun() {
        do {
            // 尝试加载存档
            guard let runState = try saveService.loadRun() else {
                print("\(Terminal.red)没有找到存档！\(Terminal.reset)")
                NavigationBar.render(items: [.back])
                NavigationBar.waitForBack()
                return
            }
            
            // 恢复冒险
            currentRunState = runState
            recentLogs.removeAll()
            runLogService.appendSystem("继续冒险（seed=\(runState.seed)）")
            print("\(Terminal.green)存档加载成功！\(Terminal.reset)")
            print("\(Terminal.dim)正在继续冒险...\(Terminal.reset)")
            Thread.sleep(forTimeInterval: 1.0)
            
            // 进入冒险循环
            runLoop()
            
        } catch SaveError.incompatibleVersion(let saved, let current) {
            print("\(Terminal.red)存档版本不兼容！\(Terminal.reset)")
            print("\(Terminal.dim)存档版本: \(saved), 当前版本: \(current)\(Terminal.reset)")
            print("\(Terminal.yellow)请开始新的冒险。\(Terminal.reset)")
            NavigationBar.render(items: [.back])
            NavigationBar.waitForBack()
        } catch {
            print("\(Terminal.red)加载存档失败: \(error)\(Terminal.reset)")
            NavigationBar.render(items: [.back])
            NavigationBar.waitForBack()
        }
    }
    
    static func runLoop() {
        guard var runState = currentRunState else { return }
        
        // 创建房间处理器注册表
        let registry = RoomHandlerRegistry.makeDefault()
        
        // 创建房间上下文
        let context = RoomContext(
            logBattleEvents: { events in
                appendBattleEvents(events)
            },
            logLine: { line in
                appendLogLine(line)
            },
            battleLoop: { engine, seed, runState in
                return battleLoop(engine: engine, seed: seed, runState: &runState)
            },
            createEnemy: { enemyId, instanceIndex, rng in
                TestMode.createEnemy(enemyId: enemyId, instanceIndex: instanceIndex, rng: &rng)
            },
            historyService: historyService
        )
        
        while !runState.isOver {
            // 显示地图
            Screens.showMap(runState: runState, logs: recentLogs, showLog: showLog)
            
            // 读取玩家输入
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                return
            }
            
            // 处理输入
            if input == "q" {
                // 返回主菜单（保留存档）
                saveService.saveRun(runState)
                currentRunState = runState
                return
            }
            
            if input == "abandon" {
                // 放弃冒险（需要确认）
                if MapScreen.showAbandonConfirmation() {
                    // 确认放弃：标记为失败并结束
                    runState.isOver = true
                    runState.won = false
                    break
                } else {
                    // 取消放弃：继续显示地图
                    continue
                }
            }
            
            // 获取可选节点
            let accessibleNodes = runState.accessibleNodes
            
            if accessibleNodes.isEmpty {
                // 没有可选节点（冒险应该已结束）
                break
            }
            
            // 解析节点选择
            guard let choice = Int(input), choice >= 1, choice <= accessibleNodes.count else {
                // 无效输入，重新显示
                continue
            }
            
            let selectedNode = accessibleNodes[choice - 1]
            
            // 进入节点
            guard runState.enterNode(selectedNode.id) else {
                continue
            }

            // 记录进入房间（统一日志）
            context.logLine("\(Terminal.dim)进入：\(selectedNode.roomType.icon) \(selectedNode.roomType.displayName)\(Terminal.reset)")
            
            // 使用 handler 处理房间（消除 switch 分支）
            guard let handler = registry.handler(for: selectedNode.roomType) else {
                // 未注册的房间类型，跳过
                continue
            }
            
            let result = handler.run(node: selectedNode, runState: &runState, context: context)
            
            // 根据结果更新冒险状态
            switch result {
            case .completedNode:
                // 节点完成，继续冒险
                // 自动保存进度
                saveService.saveRun(runState)
                
            case .runEnded(let won):
                // 冒险结束（胜利或失败）
                runState.isOver = true
                runState.won = won
                
            case .aborted:
                // 用户中途退出（返回主菜单，保留存档）
                // 保存当前进度（玩家可能在战斗中退出，需要保留之前的状态）
                saveService.saveRun(runState)
                currentRunState = runState
                return
            }
            
            // 更新全局状态
            currentRunState = runState
        }
        
        // 冒险结束，清除存档
        saveService.clearSave()
        
        // 冒险结束
        showRunResult(runState: runState)
        currentRunState = nil
    }
    
    /// 显示冒险结果
    private static func showRunResult(runState: RunState) {
        Terminal.clear()
        
        if runState.won {
            print("""
            \(Terminal.bold)\(Terminal.green)
            ╔═══════════════════════════════════════════════════════╗
            ║                                                       ║
            ║               🎉 恭喜通关！🎉                          ║
            ║                                                       ║
            ╠═══════════════════════════════════════════════════════╣
            ║                                                       ║
            ║   你成功击败了所有敌人，完成了冒险！                   ║
            ║                                                       ║
            ║   最终 HP: \(runState.player.currentHP)/\(runState.player.maxHP)                                    ║
            ║                                                       ║
            ╚═══════════════════════════════════════════════════════╝
            \(Terminal.reset)
            """)
        } else {
            print("""
            \(Terminal.bold)\(Terminal.red)
            ╔═══════════════════════════════════════════════════════╗
            ║                                                       ║
            ║               💀 冒险失败 💀                           ║
            ║                                                       ║
            ╠═══════════════════════════════════════════════════════╣
            ║                                                       ║
            ║   你倒在了冒险途中...                                  ║
            ║                                                       ║
            ║   进度: 第 \(runState.currentRow) 层                                        ║
            ║                                                       ║
            ╚═══════════════════════════════════════════════════════╝
            \(Terminal.reset)
            """)
        }
        
        print("")
        NavigationBar.render(items: [.backToMenu])
        NavigationBar.waitForBack()
    }
    
    // MARK: - Battle (快速战斗模式)
    
    static func startNewBattle() {
        let seed = parseSeed(from: CommandLine.arguments)
        
        // 初始化战斗引擎
        let engine = BattleEngine(seed: seed)
        engine.startBattle()
        
        // 清空之前的日志
        recentLogs.removeAll()
        currentMessage = nil
        
        // 收集初始事件
        appendBattleEvents(engine.events)
        engine.clearEvents()
        
        // 直接进入游戏主循环
        // - Note: 快速战斗不依赖 RunState（消耗品/地图/存档），这里注入一个最小 RunState 仅用于复用 battleLoop。
        var tempRunState = RunState(
            player: engine.state.player,
            deck: [],
            gold: 0,
            relicManager: RelicManager(),
            consumables: [],
            map: [],
            seed: seed,
            floor: 1,
            maxFloor: 1
        )
        battleLoop(engine: engine, seed: seed, runState: &tempRunState)
        
        // 战斗结束 - 保存战绩
        let record = BattleRecordBuilder.build(from: engine, seed: seed)
        historyService.addRecord(record)
        
        Screens.showFinal(state: engine.state, record: record)
        
        print("")
        NavigationBar.render(items: [.backToMenu])
        NavigationBar.waitForBack()
    }
    
    // MARK: - Battle Loop
    
    /// 战斗主循环（用于冒险模式和快速战斗模式）
    /// 返回战斗循环结果，区分正常结束和用户中途退出
    @discardableResult
    static func battleLoop(engine: BattleEngine, seed: UInt64, runState: inout RunState) -> BattleLoopResult {
        while !engine.state.isOver {
            // P1：若战斗引擎需要额外输入（如“预知选牌”），优先处理该输入
            if let pending = engine.pendingInput {
                switch pending {
                case .foresight(let options, let fromCount):
                    ForesightSelectionScreen.render(options: options, fromCount: fromCount, message: currentMessage)

                    guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                        // EOF：为了避免黑盒测试卡死，默认选择第 1 张
                        currentMessage = nil
                        _ = engine.submitForesightChoice(index: 0)
                        appendBattleEvents(engine.events)
                        engine.clearEvents()
                        continue
                    }

                    currentMessage = nil

                    if input.lowercased() == "q" {
                        return .aborted
                    }

                    guard let n = Int(input), n >= 1, n <= options.count else {
                        currentMessage = "\(Terminal.red)⚠️ 无效选择：1-\(options.count)\(Terminal.reset)"
                        continue
                    }

                    _ = engine.submitForesightChoice(index: n - 1)
                    appendBattleEvents(engine.events)
                    engine.clearEvents()
                    continue
                }
            }

            // 刷新整个屏幕
            BattleScreen.renderBattleScreen(
                engine: engine,
                seed: seed,
                logs: recentLogs,
                message: currentMessage,
                showLog: showLog,
                consumables: runState.consumables
            )
            
            // 读取玩家输入
            // 注意：当管道输入用完时，readLine() 返回 nil，需要退出循环
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                // EOF 或输入关闭，视为用户退出
                return .aborted
            }
            
            // 清除之前的消息
            currentMessage = nil
            
            // 处理输入
            switch input.lowercased() {
            case "q":
                // 返回主菜单（用户中途退出，保留存档）
                return .aborted

            default:
                break
            }

            // P4：消耗品（战斗内使用/丢弃）
            if let cmd = parseConsumableCommand(input) {
                let idx = cmd.index
                guard idx >= 0, idx < runState.consumables.count else {
                    currentMessage = "\(Terminal.red)⚠️ 无效消耗品序号：1-\(runState.consumables.count)\(Terminal.reset)"
                    continue
                }

                let consumableId = runState.consumables[idx]
                let def = ConsumableRegistry.require(consumableId)

                switch cmd.action {
                case .use:
                    guard def.usableInBattle else {
                        currentMessage = "\(Terminal.red)⚠️ 该消耗品不可在战斗中使用\(Terminal.reset)"
                        continue
                    }

                    let snapshot = BattleSnapshot(
                        turn: engine.state.turn,
                        player: engine.state.player,
                        enemies: engine.state.enemies,
                        energy: engine.state.energy
                    )
                    let effects = def.useInBattle(snapshot: snapshot)
                    let didApply = engine.applyExternalEffects(effects)
                    if didApply {
                        runState.removeConsumable(at: idx)
                        currentMessage = "\(Terminal.green)✅ 已使用：\(def.icon)\(def.name)\(Terminal.reset)"
                    } else {
                        currentMessage = "\(Terminal.red)⚠️ 当前无法使用消耗品（请先完成当前选择）\(Terminal.reset)"
                    }
                    appendBattleEvents(engine.events)
                    engine.clearEvents()
                    continue

                case .discard:
                    runState.removeConsumable(at: idx)
                    currentMessage = "\(Terminal.dim)🗑️ 已丢弃：\(def.icon)\(def.name)\(Terminal.reset)"
                    continue
                }
            }
                
            let parts = input.split { $0 == " " || $0 == "\t" }
            guard !parts.isEmpty else {
                currentMessage = "\(Terminal.red)⚠️ 请输入有效指令\(Terminal.reset)"
                continue
            }
            
            // 0：结束回合
            if parts.count == 1, let number = Int(parts[0]), number == 0 {
                engine.handleAction(.endTurn)
                // 收集新事件
                appendBattleEvents(engine.events)
                engine.clearEvents()
                continue
            }
            
            // 出牌：支持 `卡牌序号` 或 `卡牌序号 目标序号`
            guard let cardNumber = Int(parts[0]),
                  cardNumber >= 1,
                  cardNumber <= engine.state.hand.count
            else {
                currentMessage = "\(Terminal.red)⚠️ 无效选择: 1-\(engine.state.hand.count) / 0\(Terminal.reset)"
                continue
            }
            
            let handIndex = cardNumber - 1
            let cardDef = CardRegistry.require(engine.state.hand[handIndex].cardId)
            
            let targetEnemyIndex: Int?
            if parts.count >= 2, let targetNumber = Int(parts[1]) {
                let idx = targetNumber - 1
                guard idx >= 0, idx < engine.state.enemies.count else {
                    currentMessage = "\(Terminal.red)⚠️ 无效目标：1-\(engine.state.enemies.count)\(Terminal.reset)"
                    continue
                }
                guard engine.state.enemies[idx].isAlive else {
                    currentMessage = "\(Terminal.red)⚠️ 目标已死亡，请选择存活敌人\(Terminal.reset)"
                    continue
                }
                targetEnemyIndex = idx
            } else {
                switch cardDef.targeting {
                case .none:
                    targetEnemyIndex = nil
                case .singleEnemy:
                    let alive = engine.state.enemies.enumerated().compactMap { $0.element.isAlive ? $0.offset : nil }
                    if alive.count <= 1 {
                        targetEnemyIndex = alive.first
                    } else {
                        currentMessage = "\(Terminal.red)⚠️ 该牌需要选择目标，请输入：卡牌序号 目标序号（例如：1 2）\(Terminal.reset)"
                        continue
                    }
                }
            }
            
            engine.handleAction(.playCard(handIndex: handIndex, targetEnemyIndex: targetEnemyIndex))
            
            // 收集新事件
            appendBattleEvents(engine.events)
            engine.clearEvents()
        }
        
        // 战斗正常结束（胜利或失败）
        return .finished
    }

    // MARK: - Consumables (Battle Input)

    private enum ConsumableCommandAction: Sendable {
        case use
        case discard
    }

    private struct ConsumableCommand: Sendable {
        let action: ConsumableCommandAction
        let index: Int
    }

    /// 解析消耗品指令：`C1..Cn`（使用）/ `X1..Xn`（丢弃）
    private static func parseConsumableCommand(_ raw: String) -> ConsumableCommand? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }

        let lower = trimmed.lowercased()
        guard let first = lower.first else { return nil }

        let action: ConsumableCommandAction
        switch first {
        case "c":
            action = .use
        case "x":
            action = .discard
        default:
            return nil
        }

        let numString = String(lower.dropFirst())
        guard let n = Int(numString), n >= 1 else { return nil }

        return ConsumableCommand(action: action, index: n - 1)
    }
    
    // MARK: - Log (Unified)
    
    static func appendBattleEvents(_ events: [BattleEvent]) {
        for event in events {
            let formatted = EventFormatter.format(event)
            if !formatted.isEmpty {
                appendLogLine(formatted)
            }
        }
    }
    
    static func appendLogLine(_ line: String) {
        recentLogs.append(line)
        while recentLogs.count > maxRecentLogs {
            recentLogs.removeFirst()
        }
        
        runLogService.append(uiLine: line)
    }
    
    // MARK: - Argument Parsing
    
    static func parseSeed(from arguments: [String]) -> UInt64 {
        for (index, arg) in arguments.enumerated() {
            if arg == "--seed", index + 1 < arguments.count {
                if let seedValue = UInt64(arguments[index + 1]) {
                    return seedValue
                }
            }
            if arg.hasPrefix("--seed=") {
                let valueString = String(arg.dropFirst("--seed=".count))
                if let seedValue = UInt64(valueString) {
                    return seedValue
                }
            }
        }
        return UInt64(Date().timeIntervalSince1970 * 1000)
    }
}
