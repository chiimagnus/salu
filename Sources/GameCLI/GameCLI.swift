import GameCore
import Foundation

/// 游戏 CLI 入口
@main
struct GameCLI {
    
    // MARK: - 状态
    
    /// 事件日志
    private static var recentEvents: [String] = []
    private static let maxRecentEvents = 12
    
    /// 当前消息
    private static var currentMessage: String? = nil
    
    /// 是否显示事件日志
    private static var showEventLog: Bool = false
    
    // MARK: - Main Entry
    
    static func main() {
        // 检查命令行快捷参数
        if CommandLine.arguments.contains("--history") || CommandLine.arguments.contains("-H") {
            Screens.showHistory()
            return
        }
        
        if CommandLine.arguments.contains("--stats") || CommandLine.arguments.contains("-S") {
            Screens.showStatistics()
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
            Screens.showMainMenu()
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                // EOF 或输入关闭，退出主菜单
                return
            }
            
            switch input {
            case "1":
                // 开始冒险
                startNewRun()
                
            case "2":
                // 设置菜单
                settingsMenuLoop()
                
            case "3", "q":
                // 退出游戏
                Screens.showExit()
                return
                
            default:
                break
            }
        }
    }
    
    // MARK: - Settings Menu
    
    static func settingsMenuLoop() {
        while true {
            Screens.showSettingsMenu()
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                // EOF 或输入关闭，退出设置菜单
                return
            }
            
            switch input {
            case "1":
                // 查看历史记录
                Screens.showHistory()
                print("\(Terminal.dim)按 Enter 返回...\(Terminal.reset)")
                _ = readLine()
                
            case "2":
                // 查看统计数据
                Screens.showStatistics()
                print("\(Terminal.dim)按 Enter 返回...\(Terminal.reset)")
                _ = readLine()
                
            case "3":
                // 清除历史记录
                confirmClearHistory()
                
            case "0", "q", "b":
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
        ║  当前共有 \(String(format: "%3d", HistoryManager.shared.recordCount)) 条记录                                ║
        ║                                                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║  输入 \(Terminal.reset)yes\(Terminal.bold)\(Terminal.red) 确认删除，其他任意键取消                     ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        print("\(Terminal.yellow)> \(Terminal.reset)", terminator: "")
        if let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased(), input == "yes" {
            HistoryManager.shared.clearHistory()
            Terminal.clear()
            print("\n        \(Terminal.green)✓ 历史记录已清除\(Terminal.reset)\n")
            print("\(Terminal.dim)按 Enter 返回...\(Terminal.reset)")
            _ = readLine()
        }
    }
    
    // MARK: - Run (冒险模式)
    
    /// 当前冒险状态
    private static var currentRunState: RunState? = nil
    
    static func startNewRun() {
        let seed = parseSeed(from: CommandLine.arguments)
        
        // 创建新冒险
        currentRunState = RunState.newRun(seed: seed)
        
        // 进入冒险循环
        runLoop()
    }
    
    static func runLoop() {
        guard var runState = currentRunState else { return }
        
        while !runState.isOver {
            // 显示地图
            Screens.showMap(runState: runState)
            
            // 读取玩家输入
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                return
            }
            
            // 处理输入
            if input == "q" {
                // 返回主菜单
                currentRunState = nil
                return
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
            
            // 根据房间类型处理
            switch selectedNode.roomType {
            case .start:
                // 起点，直接完成
                runState.completeCurrentNode()
                
            case .battle, .elite:
                // 战斗节点
                let won = handleBattleNode(runState: &runState, isElite: selectedNode.roomType == .elite)
                if !won {
                    // 战斗失败，冒险结束
                    runState.isOver = true
                    runState.won = false
                }
                
            case .rest:
                // 休息节点
                handleRestNode(runState: &runState)
                
            case .boss:
                // Boss 战斗
                let won = handleBossNode(runState: &runState)
                if won {
                    runState.isOver = true
                    runState.won = true
                } else {
                    runState.isOver = true
                    runState.won = false
                }
            }
            
            // 更新全局状态
            currentRunState = runState
        }
        
        // 冒险结束
        showRunResult(runState: runState)
        currentRunState = nil
    }
    
    /// 处理战斗节点
    private static func handleBattleNode(runState: inout RunState, isElite: Bool) -> Bool {
        // 使用当前 RNG 状态创建新的种子
        let battleSeed = runState.seed &+ UInt64(runState.currentRow) &* 1000
        
        // 选择敌人
        var rng = SeededRNG(seed: battleSeed)
        let enemyKind: EnemyKind
        if isElite {
            // 精英战斗：使用 medium 池
            enemyKind = Act1EnemyPool.randomAny(rng: &rng)
        } else {
            // 普通战斗
            enemyKind = Act1EnemyPool.randomWeak(rng: &rng)
        }
        let enemy = createEnemy(kind: enemyKind, rng: &rng)
        
        // 创建战斗引擎（使用冒险中的玩家状态）
        let engine = BattleEngine(
            player: runState.player,
            enemy: enemy,
            deck: runState.deck,
            seed: battleSeed
        )
        engine.startBattle()
        
        // 清空事件
        recentEvents.removeAll()
        currentMessage = nil
        appendEvents(engine.events)
        engine.clearEvents()
        
        // 战斗循环
        battleLoop(engine: engine, seed: battleSeed)
        
        // 更新玩家状态
        runState.updateFromBattle(playerHP: engine.state.player.currentHP)
        
        // 如果胜利，完成节点
        if engine.state.playerWon == true {
            runState.completeCurrentNode()
            return true
        }
        
        return false
    }
    
    /// 处理休息节点
    private static func handleRestNode(runState: inout RunState) {
        Screens.showRestOptions(runState: runState)
        
        // 等待输入
        _ = readLine()
        
        // 执行休息
        let healed = runState.restAtNode()
        
        // 显示结果
        Screens.showRestResult(
            healedAmount: healed,
            newHP: runState.player.currentHP,
            maxHP: runState.player.maxHP
        )
        
        _ = readLine()
        
        // 完成节点
        runState.completeCurrentNode()
    }
    
    /// 处理 Boss 节点
    private static func handleBossNode(runState: inout RunState) -> Bool {
        // Boss 战斗使用特殊种子
        let bossSeed = runState.seed &+ 99999
        
        // 创建 Boss 敌人（目前使用 slimeMediumAcid 作为临时 Boss）
        var rng = SeededRNG(seed: bossSeed)
        let enemy = createEnemy(kind: .slimeMediumAcid, rng: &rng)
        
        // 创建战斗引擎
        let engine = BattleEngine(
            player: runState.player,
            enemy: enemy,
            deck: runState.deck,
            seed: bossSeed
        )
        engine.startBattle()
        
        // 清空事件
        recentEvents.removeAll()
        currentMessage = nil
        appendEvents(engine.events)
        engine.clearEvents()
        
        // 战斗循环
        battleLoop(engine: engine, seed: bossSeed)
        
        // 更新玩家状态
        runState.updateFromBattle(playerHP: engine.state.player.currentHP)
        
        return engine.state.playerWon == true
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
        
        print("\n\(Terminal.dim)按 Enter 返回主菜单...\(Terminal.reset)")
        _ = readLine()
    }
    
    // MARK: - Battle (快速战斗模式)
    
    static func startNewBattle() {
        let seed = parseSeed(from: CommandLine.arguments)
        
        // 初始化战斗引擎
        let engine = BattleEngine(seed: seed)
        engine.startBattle()
        
        // 清空之前的事件
        recentEvents.removeAll()
        currentMessage = nil
        
        // 收集初始事件
        appendEvents(engine.events)
        engine.clearEvents()
        
        // 直接进入游戏主循环
        battleLoop(engine: engine, seed: seed)
        
        // 战斗结束 - 保存战绩
        let record = BattleRecordBuilder.build(from: engine, seed: seed)
        HistoryManager.shared.addRecord(record)
        
        Screens.showFinal(state: engine.state, record: record)
        
        print("\n\(Terminal.dim)按 Enter 返回主菜单...\(Terminal.reset)")
        _ = readLine()
    }
    
    // MARK: - Battle Loop
    
    /// 战斗主循环（用于冒险模式和快速战斗模式）
    static func battleLoop(engine: BattleEngine, seed: UInt64) {
        while !engine.state.isOver {
            // 刷新整个屏幕
            ScreenRenderer.renderBattleScreen(
                engine: engine,
                seed: seed,
                events: recentEvents,
                message: currentMessage,
                showEventLog: showEventLog
            )
            
            // 读取玩家输入
            // 注意：当管道输入用完时，readLine() 返回 nil，需要退出循环
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                // EOF 或输入关闭，退出游戏
                return
            }
            
            // 清除之前的消息
            currentMessage = nil
            
            // 处理输入
            switch input.lowercased() {
            case "q":
                // 返回主菜单而不是退出
                return
                
            case "h", "help":
                Screens.showHelp()
                _ = readLine()
                continue
                
            case "l", "log":
                // 切换事件日志显示
                showEventLog.toggle()
                continue
                
            default:
                break
            }
            
            guard let number = Int(input) else {
                currentMessage = "\(Terminal.red)⚠️ 请输入有效数字，输入 h 查看帮助\(Terminal.reset)"
                continue
            }
            
            if number == 0 {
                engine.handleAction(.endTurn)
            } else if number >= 1, number <= engine.state.hand.count {
                engine.handleAction(.playCard(handIndex: number - 1))
            } else {
                currentMessage = "\(Terminal.red)⚠️ 无效选择: 1-\(engine.state.hand.count) / 0\(Terminal.reset)"
                continue
            }
            
            // 收集新事件
            appendEvents(engine.events)
            engine.clearEvents()
        }
    }
    
    // MARK: - Event Management
    
    static func appendEvents(_ events: [BattleEvent]) {
        for event in events {
            let formatted = EventFormatter.format(event)
            if !formatted.isEmpty {
                recentEvents.append(formatted)
            }
        }
        // 保持事件数量限制
        while recentEvents.count > maxRecentEvents * 2 {
            recentEvents.removeFirst()
        }
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
