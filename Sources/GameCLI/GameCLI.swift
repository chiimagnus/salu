import GameCore
import Foundation

@main
struct GameCLI {
    
    // MARK: - ANSI 颜色代码
    
    private static let colorReset = "\u{001B}[0m"
    private static let colorRed = "\u{001B}[31m"
    private static let colorGreen = "\u{001B}[32m"
    private static let colorYellow = "\u{001B}[33m"
    private static let colorBlue = "\u{001B}[34m"
    private static let colorMagenta = "\u{001B}[35m"
    private static let colorCyan = "\u{001B}[36m"
    private static let colorBold = "\u{001B}[1m"
    private static let colorDim = "\u{001B}[2m"
    
    // MARK: - Main Entry
    
    static func main() {
        // 解析命令行参数
        let seed = parseSeed(from: CommandLine.arguments)
        
        // 清屏并显示标题
        clearScreen()
        printTitle()
        print("\(colorDim)🎲 随机种子：\(seed)\(colorReset)")
        print()
        pauseForEffect(seconds: 0.5)
        
        // 初始化战斗引擎
        let engine = BattleEngine(seed: seed)
        engine.startBattle()
        
        // 打印初始事件
        printEvents(engine.events, animated: true)
        engine.clearEvents()
        
        pauseForEffect(seconds: 0.3)
        
        // 游戏主循环
        gameLoop(engine: engine)
    }
    
    // MARK: - Game Loop
    
    static func gameLoop(engine: BattleEngine) {
        while !engine.state.isOver {
            // 打印当前状态
            printBattleState(engine.state)
            
            // 打印操作提示
            printInputPrompt(handCount: engine.state.hand.count)
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                continue
            }
            
            // 处理输入
            if input.lowercased() == "q" {
                printExitMessage()
                return
            }
            
            if input.lowercased() == "h" || input.lowercased() == "help" {
                printHelp()
                continue
            }
            
            guard let number = Int(input) else {
                printError("请输入有效数字，输入 h 查看帮助")
                continue
            }
            
            if number == 0 {
                // 结束回合
                print()
                engine.handleAction(.endTurn)
            } else if number >= 1, number <= engine.state.hand.count {
                // 打出卡牌（转换为 0-based 索引）
                print()
                engine.handleAction(.playCard(handIndex: number - 1))
            } else {
                printError("无效选择，请输入 1-\(engine.state.hand.count) 或 0")
                continue
            }
            
            // 打印事件
            printEvents(engine.events, animated: false)
            engine.clearEvents()
        }
        
        // 战斗结束
        printFinalResult(engine.state)
    }
    
    // MARK: - Display: Title & Messages
    
    static func printTitle() {
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
    }
    
    static func printInputPrompt(handCount: Int) {
        print()
        print("\(colorBold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(colorReset)")
        print("\(colorYellow)⌨️  操作：\(colorReset) \(colorCyan)[1-\(handCount)]\(colorReset) 出牌  \(colorCyan)[0]\(colorReset) 结束回合  \(colorCyan)[h]\(colorReset) 帮助  \(colorCyan)[q]\(colorReset) 退出")
        print("\(colorBold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(colorReset)")
        print("\(colorGreen)>>>\(colorReset) ", terminator: "")
    }
    
    static func printHelp() {
        print()
        print("\(colorBold)\(colorCyan)╭─────────────────────────────────────╮\(colorReset)")
        print("\(colorCyan)│\(colorReset)           \(colorBold)📖 游戏帮助\(colorReset)              \(colorCyan)│\(colorReset)")
        print("\(colorCyan)├─────────────────────────────────────┤\(colorReset)")
        print("\(colorCyan)│\(colorReset)  \(colorYellow)1-N\(colorReset)  打出第 N 张手牌          \(colorCyan)│\(colorReset)")
        print("\(colorCyan)│\(colorReset)  \(colorYellow)0\(colorReset)    结束当前回合            \(colorCyan)│\(colorReset)")
        print("\(colorCyan)│\(colorReset)  \(colorYellow)h\(colorReset)    显示此帮助信息          \(colorCyan)│\(colorReset)")
        print("\(colorCyan)│\(colorReset)  \(colorYellow)q\(colorReset)    退出游戏                \(colorCyan)│\(colorReset)")
        print("\(colorCyan)├─────────────────────────────────────┤\(colorReset)")
        print("\(colorCyan)│\(colorReset)  \(colorDim)提示：格挡在每回合开始时清零\(colorReset)    \(colorCyan)│\(colorReset)")
        print("\(colorCyan)│\(colorReset)  \(colorDim)提示：伤害会先被格挡吸收\(colorReset)        \(colorCyan)│\(colorReset)")
        print("\(colorCyan)╰─────────────────────────────────────╯\(colorReset)")
        print()
    }
    
    static func printError(_ message: String) {
        print("\(colorRed)⚠️  \(message)\(colorReset)")
    }
    
    static func printExitMessage() {
        print()
        print("\(colorMagenta)╭─────────────────────────────────────╮\(colorReset)")
        print("\(colorMagenta)│\(colorReset)     👋 感谢游玩，下次再见！        \(colorMagenta)│\(colorReset)")
        print("\(colorMagenta)╰─────────────────────────────────────╯\(colorReset)")
        print()
    }
    
    // MARK: - Display: Battle State
    
    static func printBattleState(_ state: BattleState) {
        print()
        
        // 敌人区域
        printEnemyArea(state.enemy)
        
        // 分隔线
        print("\(colorDim)─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─\(colorReset)")
        
        // 玩家区域
        printPlayerArea(state)
        
        // 手牌区域
        printHandArea(state)
        
        // 牌堆信息
        printDeckInfo(state)
    }
    
    static func printEnemyArea(_ enemy: Entity) {
        let hpPercent = Double(enemy.currentHP) / Double(enemy.maxHP)
        let hpBar = generateHealthBar(percent: hpPercent, width: 20)
        let hpColor = hpPercent > 0.5 ? colorGreen : (hpPercent > 0.25 ? colorYellow : colorRed)
        
        print("\(colorBold)\(colorRed)👹 \(enemy.name)\(colorReset)")
        print("   \(hpColor)\(hpBar)\(colorReset) \(enemy.currentHP)/\(enemy.maxHP) HP")
        
        if enemy.block > 0 {
            print("   \(colorCyan)🛡️ \(enemy.block) 格挡\(colorReset)")
        }
        
        print("   \(colorDim)📢 意图：攻击 7 伤害\(colorReset)")
    }
    
    static func printPlayerArea(_ state: BattleState) {
        let hpPercent = Double(state.player.currentHP) / Double(state.player.maxHP)
        let hpBar = generateHealthBar(percent: hpPercent, width: 20)
        let hpColor = hpPercent > 0.5 ? colorGreen : (hpPercent > 0.25 ? colorYellow : colorRed)
        
        print()
        print("\(colorBold)\(colorBlue)🧑 \(state.player.name)\(colorReset)")
        print("   \(hpColor)\(hpBar)\(colorReset) \(state.player.currentHP)/\(state.player.maxHP) HP")
        
        if state.player.block > 0 {
            print("   \(colorCyan)🛡️ \(state.player.block) 格挡\(colorReset)")
        }
        
        // 能量显示
        let energyDisplay = String(repeating: "◆", count: state.energy) + 
                           String(repeating: "◇", count: state.maxEnergy - state.energy)
        print("   \(colorYellow)⚡ \(energyDisplay) \(state.energy)/\(state.maxEnergy)\(colorReset)")
    }
    
    static func printHandArea(_ state: BattleState) {
        print()
        print("\(colorBold)🃏 手牌 (\(state.hand.count)张)\(colorReset)")
        print()
        
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
            
            print("   \(statusIcon) \(cardColor)[\(index + 1)] \(card.displayName)\(colorReset)  \(colorYellow)◆\(card.cost)\(colorReset)  \(effectIcon) \(effect)")
        }
    }
    
    static func printDeckInfo(_ state: BattleState) {
        print()
        print("\(colorDim)╭───────────────────────────────────────╮\(colorReset)")
        print("\(colorDim)│  📚 抽牌堆: \(String(format: "%2d", state.drawPile.count))张    🗑️  弃牌堆: \(String(format: "%2d", state.discardPile.count))张  │\(colorReset)")
        print("\(colorDim)╰───────────────────────────────────────╯\(colorReset)")
    }
    
    static func generateHealthBar(percent: Double, width: Int) -> String {
        let filledWidth = Int(Double(width) * max(0, min(1, percent)))
        let emptyWidth = width - filledWidth
        return "[" + String(repeating: "█", count: filledWidth) + String(repeating: "░", count: emptyWidth) + "]"
    }
    
    // MARK: - Display: Events
    
    static func printEvents(_ events: [BattleEvent], animated: Bool) {
        for event in events {
            let description = formatEvent(event)
            print(description)
            
            if animated {
                pauseForEffect(seconds: 0.1)
            }
        }
    }
    
    static func formatEvent(_ event: BattleEvent) -> String {
        switch event {
        case .battleStarted:
            return "\(colorBold)\(colorMagenta)⚔️  战斗开始！\(colorReset)"
            
        case .turnStarted(let turn):
            return "\n\(colorBold)\(colorCyan)══════════════ 第 \(turn) 回合 ══════════════\(colorReset)"
            
        case .energyReset(let amount):
            return "\(colorYellow)⚡ 能量恢复至 \(amount)\(colorReset)"
            
        case .blockCleared(let target, let amount):
            return "\(colorDim)🛡️ \(target) 的 \(amount) 点格挡已清除\(colorReset)"
            
        case .drew(_, let cardName):
            return "\(colorGreen)🃏 抽到 \(cardName)\(colorReset)"
            
        case .shuffled(let count):
            return "\(colorMagenta)🔀 洗牌：\(count) 张牌从弃牌堆洗入抽牌堆\(colorReset)"
            
        case .played(_, let cardName, let cost):
            return "\(colorBold)▶️  打出 \(cardName)（消耗 \(cost) 能量）\(colorReset)"
            
        case .damageDealt(let source, let target, let amount, let blocked):
            if blocked > 0 {
                return "\(colorRed)💥 \(source) 对 \(target) 造成 \(amount) 伤害\(colorReset)\(colorCyan)（\(blocked) 被格挡）\(colorReset)"
            } else if amount > 0 {
                return "\(colorRed)💥 \(source) 对 \(target) 造成 \(amount) 伤害\(colorReset)"
            } else {
                return "\(colorCyan)🛡️ \(source) 的攻击被 \(target) 完全格挡！\(colorReset)"
            }
            
        case .blockGained(let target, let amount):
            return "\(colorCyan)🛡️ \(target) 获得 \(amount) 格挡\(colorReset)"
            
        case .handDiscarded(let count):
            return "\(colorDim)🗑️ 弃置 \(count) 张手牌\(colorReset)"
            
        case .enemyIntent(_, let action, let damage):
            return "\(colorDim)👁️ 敌人意图：\(action)（\(damage) 伤害）\(colorReset)"
            
        case .enemyAction(let enemyId, let action):
            return "\(colorRed)\(colorBold)👹 \(enemyId) 发动 \(action)！\(colorReset)"
            
        case .turnEnded(let turn):
            return "\(colorDim)───────────── 第 \(turn) 回合结束 ─────────────\(colorReset)"
            
        case .entityDied(_, let name):
            return "\(colorRed)\(colorBold)💀 \(name) 已被击败！\(colorReset)"
            
        case .battleWon:
            return "\(colorGreen)\(colorBold)🎉 战斗胜利！\(colorReset)"
            
        case .battleLost:
            return "\(colorRed)\(colorBold)💔 战斗失败...\(colorReset)"
            
        case .notEnoughEnergy(let required, let available):
            return "\(colorRed)⚠️ 能量不足：需要 \(required)，当前 \(available)\(colorReset)"
            
        case .invalidAction(let reason):
            return "\(colorRed)❌ 无效操作：\(reason)\(colorReset)"
        }
    }
    
    // MARK: - Display: Final Result
    
    static func printFinalResult(_ state: BattleState) {
        print()
        
        if state.playerWon == true {
            print("""
            \(colorGreen)\(colorBold)
            ╔═══════════════════════════════════════════════════════╗
            ║                                                       ║
            ║        🏆  V I C T O R Y  🏆                          ║
            ║                                                       ║
            ║              战 斗 胜 利 ！                           ║
            ║                                                       ║
            ╠═══════════════════════════════════════════════════════╣
            ║                                                       ║
            ║    剩余 HP：\(String(format: "%3d", state.player.currentHP))/\(state.player.maxHP)                               ║
            ║    战斗回合：\(String(format: "%3d", state.turn))                                 ║
            ║                                                       ║
            ╚═══════════════════════════════════════════════════════╝
            \(colorReset)
            """)
        } else {
            print("""
            \(colorRed)\(colorBold)
            ╔═══════════════════════════════════════════════════════╗
            ║                                                       ║
            ║        💀  D E F E A T  💀                            ║
            ║                                                       ║
            ║              战 斗 失 败 ...                          ║
            ║                                                       ║
            ╠═══════════════════════════════════════════════════════╣
            ║                                                       ║
            ║    坚持回合：\(String(format: "%3d", state.turn))                                 ║
            ║                                                       ║
            ║    再接再厉！                                         ║
            ║                                                       ║
            ╚═══════════════════════════════════════════════════════╝
            \(colorReset)
            """)
        }
    }
    
    // MARK: - Utilities
    
    static func clearScreen() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
    }
    
    static func pauseForEffect(seconds: Double) {
        Thread.sleep(forTimeInterval: seconds)
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
