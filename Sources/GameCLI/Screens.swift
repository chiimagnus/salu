import Foundation
import GameCore

/// 特殊屏幕
/// 包含标题、帮助、结束等全屏界面
enum Screens {
    
    // MARK: - 主菜单
    
    static func showMainMenu() {
        Terminal.clear()
        
        // 获取统计信息显示
        let stats = HistoryManager.shared.getStatistics()
        let statsLine: String
        if stats.totalBattles > 0 {
            statsLine = "📈 \(stats.wins)胜 \(stats.losses)负 (胜率 \(String(format: "%.1f", stats.winRate))%)"
        } else {
            statsLine = "📈 暂无战绩"
        }
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)
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
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(Terminal.reset)\(Terminal.green)[1]\(Terminal.cyan) ⚔️  开始战斗                                ║
        ║  \(Terminal.reset)\(Terminal.yellow)[2]\(Terminal.cyan) ⚙️  设置 / 战绩                              ║
        ║  \(Terminal.reset)\(Terminal.red)[3]\(Terminal.cyan) 🚪 退出游戏                                ║
        ║                                                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║  \(Terminal.reset)\(Terminal.dim)\(statsLine)\(Terminal.bold)\(Terminal.cyan)\(String(repeating: " ", count: max(0, 40 - statsLine.count)))║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
    }
    
    // MARK: - 设置菜单
    
    static func showSettingsMenu() {
        Terminal.clear()
        
        let recordCount = HistoryManager.shared.recordCount
        
        print("""
        \(Terminal.bold)\(Terminal.yellow)
        ╔═══════════════════════════════════════════════════════╗
        ║                    ⚙️  设置菜单                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(Terminal.reset)\(Terminal.cyan)[1]\(Terminal.bold)\(Terminal.yellow) 📜 查看历史记录                            ║
        ║  \(Terminal.reset)\(Terminal.cyan)[2]\(Terminal.bold)\(Terminal.yellow) 📊 查看战绩统计                            ║
        ║  \(Terminal.reset)\(Terminal.red)[3]\(Terminal.bold)\(Terminal.yellow) 🗑️  清除历史记录 \(Terminal.dim)(\(recordCount) 条)\(Terminal.bold)\(Terminal.yellow)                   ║
        ║                                                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║  \(Terminal.reset)\(Terminal.dim)[0/B] 返回主菜单\(Terminal.bold)\(Terminal.yellow)                               ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
    }
    
    // MARK: - 帮助屏幕
    
    static func showHelp() {
        Terminal.clear()
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ╔═══════════════════════════════════════════════════════╗
        ║                     📖 游戏帮助                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(Terminal.yellow)操作说明\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)1-N\(Terminal.cyan)    打出第 N 张手牌                            ║
        ║  \(Terminal.reset)0\(Terminal.cyan)      结束当前回合                              ║
        ║  \(Terminal.reset)h\(Terminal.cyan)      显示此帮助信息                            ║
        ║  \(Terminal.reset)q\(Terminal.cyan)      返回主菜单                                ║
        ║                                                       ║
        ║  \(Terminal.yellow)游戏规则\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)• 每回合开始时获得 3 点能量\(Terminal.cyan)                       ║
        ║  \(Terminal.reset)• 每回合抽 5 张牌\(Terminal.cyan)                                 ║
        ║  \(Terminal.reset)• 格挡在每回合开始时清零\(Terminal.cyan)                          ║
        ║  \(Terminal.reset)• 伤害会先被格挡吸收\(Terminal.cyan)                              ║
        ║  \(Terminal.reset)• 将敌人 HP 降为 0 即可获胜\(Terminal.cyan)                       ║
        ║                                                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║           按 Enter 返回游戏...                        ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
    }
    
    // MARK: - 退出屏幕
    
    static func showExit() {
        Terminal.clear()
        print("""
        \(Terminal.magenta)
        ╔═══════════════════════════════════════════════════════╗
        ║                                                       ║
        ║           👋 感谢游玩 SALU！                          ║
        ║                                                       ║
        ║              期待下次再见！                           ║
        ║                                                       ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
    }
    
    // MARK: - 战斗结果屏幕
    
    static func showVictory(state: BattleState) {
        Terminal.clear()
        print("""
        \(Terminal.green)\(Terminal.bold)
        
        
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
        \(Terminal.reset)
        """)
    }
    
    static func showDefeat(state: BattleState) {
        Terminal.clear()
        print("""
        \(Terminal.red)\(Terminal.bold)
        
        
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
        \(Terminal.reset)
        """)
    }
    
    static func showFinal(state: BattleState, record: BattleRecord? = nil) {
        if state.playerWon == true {
            showVictory(state: state)
        } else {
            showDefeat(state: state)
        }
        
        // 显示战绩统计
        if let record = record {
            print()
            print("        \(Terminal.dim)╭──────────────────────────────────────╮\(Terminal.reset)")
            print("        \(Terminal.dim)│ 📊 本局统计                          │\(Terminal.reset)")
            print("        \(Terminal.dim)├──────────────────────────────────────┤\(Terminal.reset)")
            print("        \(Terminal.dim)│ 打出卡牌: \(String(format: "%-3d", record.cardsPlayed))                          │\(Terminal.reset)")
            print("        \(Terminal.dim)│ 造成伤害: \(String(format: "%-3d", record.totalDamageDealt))  获得格挡: \(String(format: "%-3d", record.totalBlockGained))        │\(Terminal.reset)")
            print("        \(Terminal.dim)│ 受到伤害: \(String(format: "%-3d", record.totalDamageTaken))                          │\(Terminal.reset)")
            print("        \(Terminal.dim)╰──────────────────────────────────────╯\(Terminal.reset)")
        }
        
        // 显示累计胜率
        let stats = HistoryManager.shared.getStatistics()
        if stats.totalBattles > 0 {
            print()
            print("        \(Terminal.cyan)📈 累计战绩: \(stats.wins)胜 \(stats.losses)负 (胜率 \(String(format: "%.1f", stats.winRate))%)\(Terminal.reset)")
        }
        
        print()
        print("        \(Terminal.dim)使用 --history 查看历史记录\(Terminal.reset)")
        print("        \(Terminal.dim)使用 --stats 查看详细统计\(Terminal.reset)")
    }
    
    // MARK: - 历史记录屏幕
    
    static func showHistory() {
        Terminal.clear()
        
        let records = HistoryManager.shared.getRecentRecords(10)
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ╔═══════════════════════════════════════════════════════╗
        ║                  📜 战斗历史记录                      ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        if records.isEmpty {
            print("        \(Terminal.dim)暂无战斗记录\(Terminal.reset)")
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd HH:mm"
            
            print("        \(Terminal.dim)序号  时间         结果   回合  剩余HP  伤害输出\(Terminal.reset)")
            print("        \(Terminal.dim)────────────────────────────────────────────────\(Terminal.reset)")
            
            for (index, record) in records.reversed().enumerated() {
                let resultIcon = record.won ? "\(Terminal.green)✓ 胜利\(Terminal.reset)" : "\(Terminal.red)✗ 失败\(Terminal.reset)"
                let dateStr = dateFormatter.string(from: record.timestamp)
                let hpStr = "\(record.playerFinalHP)/\(record.playerMaxHP)".padding(toLength: 7, withPad: " ", startingAt: 0)
                let indexStr = String(format: "%2d", index + 1)
                let turnStr = String(format: "%3d", record.turnsPlayed)
                
                print("        \(indexStr)    \(dateStr)  \(resultIcon)  \(turnStr)   \(hpStr)  \(record.totalDamageDealt)")
            }
            
            print()
            print("        \(Terminal.dim)显示最近 \(records.count) 场战斗 (共 \(HistoryManager.shared.recordCount) 场)\(Terminal.reset)")
        }
        
        print()
    }
    
    // MARK: - 统计屏幕
    
    static func showStatistics() {
        Terminal.clear()
        
        let stats = HistoryManager.shared.getStatistics()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ╔═══════════════════════════════════════════════════════╗
        ║                   📊 战绩统计                         ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        if stats.totalBattles == 0 {
            print("        \(Terminal.dim)暂无战斗数据\(Terminal.reset)")
        } else {
            // 胜负统计
            print("        \(Terminal.yellow)▸ 战斗统计\(Terminal.reset)")
            print("          总场次: \(stats.totalBattles)")
            print("          胜利: \(Terminal.green)\(stats.wins)\(Terminal.reset)  失败: \(Terminal.red)\(stats.losses)\(Terminal.reset)  胜率: \(String(format: "%.1f", stats.winRate))%")
            print()
            
            // 回合统计
            print("        \(Terminal.yellow)▸ 回合统计\(Terminal.reset)")
            print("          平均回合: \(String(format: "%.1f", stats.averageTurns))")
            if let fastest = stats.fastestWin {
                print("          最快胜利: \(fastest) 回合")
            }
            if let longest = stats.longestBattle {
                print("          最长战斗: \(longest) 回合")
            }
            print()
            
            // 战斗数据
            print("        \(Terminal.yellow)▸ 累计数据\(Terminal.reset)")
            print("          使用卡牌: \(stats.totalCardsPlayed)")
            print("          造成伤害: \(stats.totalDamageDealt)")
            print("          受到伤害: \(stats.totalDamageTaken)")
            print("          获得格挡: \(stats.totalBlockGained)")
        }
        
        print()
    }
}

