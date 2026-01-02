import GameCore
import Foundation

/// 游戏 CLI 入口
@main
struct GameCLI {
    
    // MARK: - 状态
    
    /// 事件日志
    private nonisolated(unsafe) static var recentEvents: [String] = []
    private static let maxRecentEvents = 12
    
    /// 当前消息
    private nonisolated(unsafe) static var currentMessage: String? = nil
    
    /// 是否显示事件日志
    private nonisolated(unsafe) static var showEventLog: Bool = false
    
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
                // 开始新战斗
                startNewBattle()
                
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
    
    // MARK: - Battle
    
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
        gameLoop(engine: engine, seed: seed)
    }
    
    // MARK: - Game Loop
    
    static func gameLoop(engine: BattleEngine, seed: UInt64) {
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
        
        // 战斗结束 - 保存战绩
        let record = BattleRecordBuilder.build(from: engine, seed: seed)
        HistoryManager.shared.addRecord(record)
        
        Screens.showFinal(state: engine.state, record: record)
        
        print("\n\(Terminal.dim)按 Enter 返回主菜单...\(Terminal.reset)")
        _ = readLine()
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
