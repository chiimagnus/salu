import GameCore

@main
struct GameCLI {
    static func main() {
        // 解析命令行参数
        let seed = parseSeed(from: CommandLine.arguments)
        
        print("""
        ╔══════════════════════════════════════╗
        ║         Salu - 杀戮尖塔 CLI          ║
        ╚══════════════════════════════════════╝
        """)
        print("🎲 随机种子：\(seed)")
        print()
        
        // 初始化战斗引擎
        let engine = BattleEngine(seed: seed)
        engine.startBattle()
        
        // 打印初始事件
        printEvents(engine.events)
        engine.clearEvents()
        
        // 游戏主循环
        gameLoop(engine: engine)
    }
    
    // MARK: - Game Loop
    
    static func gameLoop(engine: BattleEngine) {
        while !engine.state.isOver {
            // 打印当前状态
            printBattleState(engine.state)
            
            // 读取玩家输入
            print("\n请输入操作（1-\(engine.state.hand.count) 出牌 | 0 结束回合 | q 退出）：", terminator: " ")
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                continue
            }
            
            // 处理输入
            if input.lowercased() == "q" {
                print("\n👋 再见！")
                return
            }
            
            guard let number = Int(input) else {
                print("⚠️ 请输入有效数字")
                continue
            }
            
            if number == 0 {
                // 结束回合
                engine.handleAction(.endTurn)
            } else if number >= 1, number <= engine.state.hand.count {
                // 打出卡牌（转换为 0-based 索引）
                engine.handleAction(.playCard(handIndex: number - 1))
            } else {
                print("⚠️ 无效选择，请输入 1-\(engine.state.hand.count) 或 0")
                continue
            }
            
            // 打印事件
            print()
            printEvents(engine.events)
            engine.clearEvents()
        }
        
        // 战斗结束
        printFinalResult(engine.state)
    }
    
    // MARK: - Display Helpers
    
    static func printBattleState(_ state: BattleState) {
        print()
        print("┌─────────────────────────────────────┐")
        
        // 敌人状态
        let enemyHP = "❤️ \(state.enemy.currentHP)/\(state.enemy.maxHP)"
        let enemyBlock = state.enemy.block > 0 ? " 🛡️ \(state.enemy.block)" : ""
        print("│ 👹 \(state.enemy.name): \(enemyHP)\(enemyBlock)")
        
        print("├─────────────────────────────────────┤")
        
        // 玩家状态
        let playerHP = "❤️ \(state.player.currentHP)/\(state.player.maxHP)"
        let playerBlock = state.player.block > 0 ? " 🛡️ \(state.player.block)" : ""
        let energy = "⚡ \(state.energy)/\(state.maxEnergy)"
        print("│ 🧑 \(state.player.name): \(playerHP)\(playerBlock)")
        print("│ 能量：\(energy)")
        
        print("├─────────────────────────────────────┤")
        
        // 手牌
        print("│ 🃏 手牌：")
        for (index, card) in state.hand.enumerated() {
            let canPlay = card.cost <= state.energy ? "✓" : "✗"
            let cardInfo = "[\(index + 1)] \(card.displayName) (\(card.cost)能量)"
            let effect: String
            switch card.kind {
            case .strike:
                effect = "造成\(card.damage)伤害"
            case .defend:
                effect = "获得\(card.block)格挡"
            }
            print("│     \(canPlay) \(cardInfo) - \(effect)")
        }
        
        print("├─────────────────────────────────────┤")
        
        // 牌堆信息
        print("│ 📚 抽牌堆：\(state.drawPile.count) | 🗑️ 弃牌堆：\(state.discardPile.count)")
        
        print("└─────────────────────────────────────┘")
    }
    
    static func printEvents(_ events: [BattleEvent]) {
        for event in events {
            print(event.description)
        }
    }
    
    static func printFinalResult(_ state: BattleState) {
        print()
        print("╔══════════════════════════════════════╗")
        if state.playerWon == true {
            print("║           🎉 战斗胜利！🎉             ║")
        } else {
            print("║           💀 战斗失败...              ║")
        }
        print("╠══════════════════════════════════════╣")
        print("║ 玩家剩余 HP：\(String(format: "%3d", state.player.currentHP))/\(state.player.maxHP)              ║")
        print("║ 战斗回合数：\(String(format: "%3d", state.turn))                      ║")
        print("╚══════════════════════════════════════╝")
    }
    
    // MARK: - Argument Parsing
    
    static func parseSeed(from arguments: [String]) -> UInt64 {
        // 查找 --seed 参数
        for (index, arg) in arguments.enumerated() {
            if arg == "--seed", index + 1 < arguments.count {
                if let seedValue = UInt64(arguments[index + 1]) {
                    return seedValue
                }
            }
            // 也支持 --seed=123 格式
            if arg.hasPrefix("--seed=") {
                let valueString = String(arg.dropFirst("--seed=".count))
                if let seedValue = UInt64(valueString) {
                    return seedValue
                }
            }
        }
        
        // 默认使用当前时间作为种子
        return UInt64(Date().timeIntervalSince1970 * 1000)
    }
}

// MARK: - Date Extension (for seed generation)

import Foundation
