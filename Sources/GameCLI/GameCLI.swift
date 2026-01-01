import GameCore
import Foundation

@main
struct GameCLI {
    
    // MARK: - ANSI 控制码
    
    private static let colorReset = "\u{001B}[0m"
    private static let colorRed = "\u{001B}[31m"
    private static let colorGreen = "\u{001B}[32m"
    private static let colorYellow = "\u{001B}[33m"
    private static let colorBlue = "\u{001B}[34m"
    private static let colorMagenta = "\u{001B}[35m"
    private static let colorCyan = "\u{001B}[36m"
    private static let colorBold = "\u{001B}[1m"
    private static let colorDim = "\u{001B}[2m"
    
    // 屏幕控制
    private static let clearScreen = "\u{001B}[2J"      // 清屏
    private static let cursorHome = "\u{001B}[H"        // 光标移到左上角
    private static let hideCursor = "\u{001B}[?25l"     // 隐藏光标
    private static let showCursor = "\u{001B}[?25h"     // 显示光标
    
    // 事件日志（保留最近的事件用于显示）
    private nonisolated(unsafe) static var recentEvents: [String] = []
    private static let maxRecentEvents = 6
    
    // 当前消息（用于显示错误或提示）
    private nonisolated(unsafe) static var currentMessage: String? = nil
    
    // MARK: - Main Entry
    
    static func main() {
        let seed = parseSeed(from: CommandLine.arguments)
        
        // 初始化战斗引擎
        let engine = BattleEngine(seed: seed)
        engine.startBattle()
        
        // 收集初始事件
        appendEvents(engine.events)
        engine.clearEvents()
        
        // 显示标题屏幕
        showTitleScreen(seed: seed)
        
        // 等待用户按键开始
        print("\(colorCyan)按 Enter 开始战斗...\(colorReset)", terminator: "")
        _ = readLine()
        
        // 游戏主循环
        gameLoop(engine: engine, seed: seed)
        
        // 显示光标
        print(showCursor, terminator: "")
    }
    
    // MARK: - Title Screen
    
    static func showTitleScreen(seed: UInt64) {
        print(clearScreen + cursorHome, terminator: "")
        print("""
        \(colorBold)\(colorCyan)
        ╔═══════════════════════════════════════════════════════╗
        ║                                                       ║
        ║      ███████╗ █████╗ ██╗     ██╗   ██╗                ║
        ║      ██╔════╝██╔══██╗██║     ██║   ██║                ║
        ║      ███████╗███████║██║     ██║   ██║                ║
        ║      ╚════██║██╔══██║██║     ██║   ██║                ║
        ║      ███████║██║  ██║███████╗╚██████╔╝                ║
        ║      ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝                 ║
        ║                                                       ║
        ║              ⚔️  杀戮尖塔 CLI 版  ⚔️                   ║
        ║                                                       ║
        ╚═══════════════════════════════════════════════════════╝
        \(colorReset)
        """)
        print("\(colorDim)        🎲 随机种子：\(seed)\(colorReset)")
        print()
    }
    
    // MARK: - Game Loop
    
    static func gameLoop(engine: BattleEngine, seed: UInt64) {
        while !engine.state.isOver {
            // 刷新整个屏幕
            refreshScreen(engine: engine, seed: seed)
            
            // 读取玩家输入
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                continue
            }
            
            // 清除之前的消息
            currentMessage = nil
            
            // 处理输入
            if input.lowercased() == "q" {
                showExitScreen()
                return
            }
            
            if input.lowercased() == "h" || input.lowercased() == "help" {
                showHelpScreen()
                _ = readLine()
                continue
            }
            
            guard let number = Int(input) else {
                currentMessage = "\(colorRed)⚠️ 请输入有效数字，输入 h 查看帮助\(colorReset)"
                continue
            }
            
            if number == 0 {
                engine.handleAction(.endTurn)
            } else if number >= 1, number <= engine.state.hand.count {
                engine.handleAction(.playCard(handIndex: number - 1))
            } else {
                currentMessage = "\(colorRed)⚠️ 无效选择，请输入 1-\(engine.state.hand.count) 或 0\(colorReset)"
                continue
            }
            
            // 收集新事件
            appendEvents(engine.events)
            engine.clearEvents()
        }
        
        // 战斗结束
        showFinalScreen(engine.state)
    }
    
    // MARK: - Screen Refresh
    
    static func refreshScreen(engine: BattleEngine, seed: UInt64) {
        var lines: [String] = []
        
        // 顶部标题栏
        lines.append("\(colorBold)\(colorCyan)═══════════════════════════════════════════════\(colorReset)")
        lines.append("\(colorBold)\(colorCyan)  ⚔️ SALU - 杀戮尖塔 CLI   \(colorDim)第 \(engine.state.turn) 回合  🎲 \(seed)\(colorReset)")
        lines.append("\(colorBold)\(colorCyan)═══════════════════════════════════════════════\(colorReset)")
        lines.append("")
        
        // 敌人区域
        lines.append(contentsOf: buildEnemyArea(engine.state.enemy))
        lines.append("")
        
        // 分隔线
        lines.append("\(colorDim)─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─\(colorReset)")
        lines.append("")
        
        // 玩家区域
        lines.append(contentsOf: buildPlayerArea(engine.state))
        lines.append("")
        
        // 手牌区域
        lines.append(contentsOf: buildHandArea(engine.state))
        lines.append("")
        
        // 牌堆信息
        lines.append("\(colorDim)  📚 抽牌堆: \(engine.state.drawPile.count)张    🗑️ 弃牌堆: \(engine.state.discardPile.count)张\(colorReset)")
        lines.append("")
        
        // 事件日志区域
        lines.append("\(colorBold)───────────── 事件日志 ─────────────\(colorReset)")
        for event in recentEvents.suffix(maxRecentEvents) {
            lines.append("  \(event)")
        }
        // 填充空行保持高度一致
        let eventPadding = maxRecentEvents - min(recentEvents.count, maxRecentEvents)
        for _ in 0..<eventPadding {
            lines.append("")
        }
        lines.append("\(colorBold)─────────────────────────────────────\(colorReset)")
        lines.append("")
        
        // 消息区域
        if let message = currentMessage {
            lines.append(message)
        } else {
            lines.append("")
        }
        lines.append("")
        
        // 操作提示
        lines.append("\(colorBold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(colorReset)")
        lines.append("\(colorYellow)⌨️ 操作:\(colorReset) \(colorCyan)[1-\(engine.state.hand.count)]\(colorReset) 出牌  \(colorCyan)[0]\(colorReset) 结束回合  \(colorCyan)[h]\(colorReset) 帮助  \(colorCyan)[q]\(colorReset) 退出")
        lines.append("\(colorBold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(colorReset)")
        
        // 清屏并打印所有内容
        print(clearScreen + cursorHome, terminator: "")
        for line in lines {
            print(line)
        }
        print("\(colorGreen)>>>\(colorReset) ", terminator: "")
        fflush(stdout)
    }
    
    // MARK: - Build Screen Components
    
    static func buildEnemyArea(_ enemy: Entity) -> [String] {
        var lines: [String] = []
        
        let hpPercent = Double(enemy.currentHP) / Double(enemy.maxHP)
        let hpBar = generateHealthBar(percent: hpPercent, width: 20)
        let hpColor = hpPercent > 0.5 ? colorGreen : (hpPercent > 0.25 ? colorYellow : colorRed)
        
        lines.append("  \(colorBold)\(colorRed)👹 \(enemy.name)\(colorReset)")
        lines.append("     \(hpColor)\(hpBar)\(colorReset) \(enemy.currentHP)/\(enemy.maxHP) HP")
        
        if enemy.block > 0 {
            lines.append("     \(colorCyan)🛡️ \(enemy.block) 格挡\(colorReset)")
        }
        
        lines.append("     \(colorYellow)📢 意图：攻击 7 伤害\(colorReset)")
        
        return lines
    }
    
    static func buildPlayerArea(_ state: BattleState) -> [String] {
        var lines: [String] = []
        
        let hpPercent = Double(state.player.currentHP) / Double(state.player.maxHP)
        let hpBar = generateHealthBar(percent: hpPercent, width: 20)
        let hpColor = hpPercent > 0.5 ? colorGreen : (hpPercent > 0.25 ? colorYellow : colorRed)
        
        lines.append("  \(colorBold)\(colorBlue)🧑 \(state.player.name)\(colorReset)")
        lines.append("     \(hpColor)\(hpBar)\(colorReset) \(state.player.currentHP)/\(state.player.maxHP) HP")
        
        if state.player.block > 0 {
            lines.append("     \(colorCyan)🛡️ \(state.player.block) 格挡\(colorReset)")
        }
        
        let energyDisplay = String(repeating: "◆", count: state.energy) + 
                           String(repeating: "◇", count: state.maxEnergy - state.energy)
        lines.append("     \(colorYellow)⚡ \(energyDisplay) \(state.energy)/\(state.maxEnergy)\(colorReset)")
        
        return lines
    }
    
    static func buildHandArea(_ state: BattleState) -> [String] {
        var lines: [String] = []
        
        lines.append("  \(colorBold)🃏 手牌 (\(state.hand.count)张)\(colorReset)")
        
        for (index, card) in state.hand.enumerated() {
            let canPlay = card.cost <= state.energy
            let statusIcon = canPlay ? "\(colorGreen)●\(colorReset)" : "\(colorRed)○\(colorReset)"
            let cardColor = canPlay ? colorBold : colorDim
            
            let effect: String
            let effectIcon: String
            switch card.kind {
            case .strike:
                effect = "造成 \(card.damage) 伤害"
                effectIcon = "⚔️"
            case .defend:
                effect = "获得 \(card.block) 格挡"
                effectIcon = "🛡️"
            }
            
            lines.append("     \(statusIcon) \(cardColor)[\(index + 1)] \(card.displayName)\(colorReset)  \(colorYellow)◆\(card.cost)\(colorReset)  \(effectIcon) \(effect)")
        }
        
        return lines
    }
    
    static func generateHealthBar(percent: Double, width: Int) -> String {
        let filledWidth = Int(Double(width) * max(0, min(1, percent)))
        let emptyWidth = width - filledWidth
        return "[" + String(repeating: "█", count: filledWidth) + String(repeating: "░", count: emptyWidth) + "]"
    }
    
    // MARK: - Event Management
    
    static func appendEvents(_ events: [BattleEvent]) {
        for event in events {
            let formatted = formatEvent(event)
            recentEvents.append(formatted)
        }
        // 保持事件数量限制
        while recentEvents.count > maxRecentEvents * 2 {
            recentEvents.removeFirst()
        }
    }
    
    static func formatEvent(_ event: BattleEvent) -> String {
        switch event {
        case .battleStarted:
            return "\(colorBold)\(colorMagenta)⚔️ 战斗开始！\(colorReset)"
            
        case .turnStarted(let turn):
            return "\(colorCyan)══ 第 \(turn) 回合开始 ══\(colorReset)"
            
        case .energyReset(let amount):
            return "\(colorYellow)⚡ 能量恢复至 \(amount)\(colorReset)"
            
        case .blockCleared(let target, let amount):
            return "\(colorDim)🛡️ \(target) 的 \(amount) 格挡清除\(colorReset)"
            
        case .drew(_, let cardName):
            return "\(colorGreen)🃏 抽到 \(cardName)\(colorReset)"
            
        case .shuffled(let count):
            return "\(colorMagenta)🔀 洗牌：\(count) 张\(colorReset)"
            
        case .played(_, let cardName, let cost):
            return "\(colorBold)▶️ 打出 \(cardName) (◆\(cost))\(colorReset)"
            
        case .damageDealt(let source, let target, let amount, let blocked):
            if blocked > 0 && amount == 0 {
                return "\(colorCyan)🛡️ \(target) 完全格挡了攻击！\(colorReset)"
            } else if blocked > 0 {
                return "\(colorRed)💥 \(source)→\(target) \(amount)伤害\(colorReset)\(colorCyan)(\(blocked)格挡)\(colorReset)"
            } else {
                return "\(colorRed)💥 \(source)→\(target) \(amount)伤害\(colorReset)"
            }
            
        case .blockGained(let target, let amount):
            return "\(colorCyan)🛡️ \(target) +\(amount)格挡\(colorReset)"
            
        case .handDiscarded(let count):
            return "\(colorDim)🗑️ 弃置 \(count) 张手牌\(colorReset)"
            
        case .enemyIntent(_, _, _):
            return ""  // 不显示，已经在界面上显示了
            
        case .enemyAction(let enemyId, let action):
            return "\(colorRed)\(colorBold)👹 \(enemyId) \(action)！\(colorReset)"
            
        case .turnEnded(let turn):
            return "\(colorDim)── 第 \(turn) 回合结束 ──\(colorReset)"
            
        case .entityDied(_, let name):
            return "\(colorRed)\(colorBold)💀 \(name) 被击败！\(colorReset)"
            
        case .battleWon:
            return "\(colorGreen)\(colorBold)🎉 战斗胜利！\(colorReset)"
            
        case .battleLost:
            return "\(colorRed)\(colorBold)💔 战斗失败...\(colorReset)"
            
        case .notEnoughEnergy(let required, let available):
            return "\(colorRed)⚠️ 能量不足：需 \(required)，有 \(available)\(colorReset)"
            
        case .invalidAction(let reason):
            return "\(colorRed)❌ \(reason)\(colorReset)"
        }
    }
    
    // MARK: - Special Screens
    
    static func showHelpScreen() {
        print(clearScreen + cursorHome, terminator: "")
        print("""
        \(colorBold)\(colorCyan)
        ╔═══════════════════════════════════════════════════════╗
        ║                     📖 游戏帮助                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(colorYellow)操作说明\(colorCyan)                                          ║
        ║  ────────                                             ║
        ║  \(colorReset)1-N\(colorCyan)    打出第 N 张手牌                            ║
        ║  \(colorReset)0\(colorCyan)      结束当前回合                              ║
        ║  \(colorReset)h\(colorCyan)      显示此帮助信息                            ║
        ║  \(colorReset)q\(colorCyan)      退出游戏                                  ║
        ║                                                       ║
        ║  \(colorYellow)游戏规则\(colorCyan)                                          ║
        ║  ────────                                             ║
        ║  \(colorReset)• 每回合开始时获得 3 点能量\(colorCyan)                       ║
        ║  \(colorReset)• 每回合抽 5 张牌\(colorCyan)                                 ║
        ║  \(colorReset)• 格挡在每回合开始时清零\(colorCyan)                          ║
        ║  \(colorReset)• 伤害会先被格挡吸收\(colorCyan)                              ║
        ║  \(colorReset)• 将敌人 HP 降为 0 即可获胜\(colorCyan)                       ║
        ║                                                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║           按 Enter 返回游戏...                        ║
        ╚═══════════════════════════════════════════════════════╝
        \(colorReset)
        """)
    }
    
    static func showExitScreen() {
        print(clearScreen + cursorHome, terminator: "")
        print("""
        \(colorMagenta)
        ╔═══════════════════════════════════════════════════════╗
        ║                                                       ║
        ║           👋 感谢游玩 SALU！                          ║
        ║                                                       ║
        ║              期待下次再见！                           ║
        ║                                                       ║
        ╚═══════════════════════════════════════════════════════╝
        \(colorReset)
        """)
    }
    
    static func showFinalScreen(_ state: BattleState) {
        print(clearScreen + cursorHome, terminator: "")
        
        if state.playerWon == true {
            print("""
            \(colorGreen)\(colorBold)
            
            
            ╔═══════════════════════════════════════════════════════╗
            ║                                                       ║
            ║     ██╗   ██╗██╗ ██████╗████████╗ ██████╗ ██████╗ ██╗ ║
            ║     ██║   ██║██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██║ ║
            ║     ██║   ██║██║██║        ██║   ██║   ██║██████╔╝╚═╝ ║
            ║     ╚██╗ ██╔╝██║██║        ██║   ██║   ██║██╔══██╗    ║
            ║      ╚████╔╝ ██║╚██████╗   ██║   ╚██████╔╝██║  ██║██╗ ║
            ║       ╚═══╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝ ║
            ║                                                       ║
            ║                  🏆 战 斗 胜 利 🏆                    ║
            ║                                                       ║
            ╠═══════════════════════════════════════════════════════╣
            ║                                                       ║
            ║         剩余 HP：\(String(format: "%3d", state.player.currentHP))/\(state.player.maxHP)                            ║
            ║         战斗回合：\(String(format: "%3d", state.turn))                              ║
            ║                                                       ║
            ╚═══════════════════════════════════════════════════════╝
            \(colorReset)
            """)
        } else {
            print("""
            \(colorRed)\(colorBold)
            
            
            ╔═══════════════════════════════════════════════════════╗
            ║                                                       ║
            ║      ██████╗ ███████╗███████╗███████╗ █████╗ ████████╗║
            ║      ██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗╚══██╔══╝║
            ║      ██║  ██║█████╗  █████╗  █████╗  ███████║   ██║   ║
            ║      ██║  ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██║   ██║   ║
            ║      ██████╔╝███████╗██║     ███████╗██║  ██║   ██║   ║
            ║      ╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ║
            ║                                                       ║
            ║                  💀 战 斗 失 败 💀                    ║
            ║                                                       ║
            ╠═══════════════════════════════════════════════════════╣
            ║                                                       ║
            ║         坚持回合：\(String(format: "%3d", state.turn))                              ║
            ║                                                       ║
            ║              再接再厉！下次一定！                     ║
            ║                                                       ║
            ╚═══════════════════════════════════════════════════════╝
            \(colorReset)
            """)
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
