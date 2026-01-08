import Foundation
import GameCore

/// 统计数据界面
enum StatisticsScreen {
    
    static func show(historyService: HistoryService) {
        Terminal.clear()
        
        let stats = historyService.getStatistics()
        
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
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[0]\(Terminal.reset) 返回")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.green)>>>\(Terminal.reset) ", terminator: "")
        Terminal.flush()
        
        // 等待用户输入返回
        _ = readLine()
    }
}

