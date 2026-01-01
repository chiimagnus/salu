import GameCore
import Foundation

/// 游戏 CLI 入口
@main
struct GameCLI {
    
    // MARK: - 状态
    
    /// 事件日志
    private nonisolated(unsafe) static var recentEvents: [String] = []
    private static let maxRecentEvents = 6
    
    /// 当前消息
    private nonisolated(unsafe) static var currentMessage: String? = nil
    
    // MARK: - Main Entry
    
    static func main() {
        // 检查是否查看历史记录
        if CommandLine.arguments.contains("--history") || CommandLine.arguments.contains("-H") {
            Screens.showHistory()
            return
        }
        
        // 检查是否查看统计数据
        if CommandLine.arguments.contains("--stats") || CommandLine.arguments.contains("-S") {
            Screens.showStatistics()
            return
        }
        
        let seed = parseSeed(from: CommandLine.arguments)
        
        // 初始化战斗引擎
        let engine = BattleEngine(seed: seed)
        engine.startBattle()
        
        // 收集初始事件
        appendEvents(engine.events)
        engine.clearEvents()
        
        // 显示标题屏幕
        Screens.showTitle(seed: seed)
        
        // 等待用户按键开始
        print("\(Terminal.cyan)按 Enter 开始战斗...\(Terminal.reset)", terminator: "")
        _ = readLine()
        
        // 游戏主循环
        gameLoop(engine: engine, seed: seed)
        
        // 显示光标
        print(Terminal.showCursor, terminator: "")
    }
    
    // MARK: - Game Loop
    
    static func gameLoop(engine: BattleEngine, seed: UInt64) {
        while !engine.state.isOver {
            // 刷新整个屏幕
            ScreenRenderer.renderBattleScreen(
                engine: engine,
                seed: seed,
                events: recentEvents,
                message: currentMessage
            )
            
            // 读取玩家输入
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                continue
            }
            
            // 清除之前的消息
            currentMessage = nil
            
            // 处理输入
            switch input.lowercased() {
            case "q":
                Screens.showExit()
                return
                
            case "h", "help":
                Screens.showHelp()
                _ = readLine()
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
