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
        ║                   📊 \(L10n.text("战绩统计", "Statistics"))                         ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        if stats.totalBattles == 0 {
            print("        \(Terminal.dim)\(L10n.text("暂无战斗数据", "No battle data yet"))\(Terminal.reset)")
        } else {
            // 胜负统计
            print("        \(Terminal.yellow)▸ \(L10n.text("战斗统计", "Battle Stats"))\(Terminal.reset)")
            print("          \(L10n.text("总场次", "Total battles")): \(stats.totalBattles)")
            print("          \(L10n.text("胜利", "Wins")): \(Terminal.green)\(stats.wins)\(Terminal.reset)  \(L10n.text("失败", "Losses")): \(Terminal.red)\(stats.losses)\(Terminal.reset)  \(L10n.text("胜率", "Win rate")): \(String(format: "%.1f", stats.winRate))%")
            print()
            
            // 回合统计
            print("        \(Terminal.yellow)▸ \(L10n.text("回合统计", "Turn Stats"))\(Terminal.reset)")
            print("          \(L10n.text("平均回合", "Average turns")): \(String(format: "%.1f", stats.averageTurns))")
            if let fastest = stats.fastestWin {
                print("          \(L10n.text("最快胜利", "Fastest win")): \(fastest) \(L10n.text("回合", "turns"))")
            }
            if let longest = stats.longestBattle {
                print("          \(L10n.text("最长战斗", "Longest battle")): \(longest) \(L10n.text("回合", "turns"))")
            }
            print()
            
            // 战斗数据
            print("        \(Terminal.yellow)▸ \(L10n.text("累计数据", "Totals"))\(Terminal.reset)")
            print("          \(L10n.text("使用卡牌", "Cards played")): \(stats.totalCardsPlayed)")
            print("          \(L10n.text("造成伤害", "Damage dealt")): \(stats.totalDamageDealt)")
            print("          \(L10n.text("受到伤害", "Damage taken")): \(stats.totalDamageTaken)")
            print("          \(L10n.text("获得格挡", "Block gained")): \(stats.totalBlockGained)")
        }
        
        print()
        NavigationBar.render(items: [.back])
        NavigationBar.waitForBack()
    }
}
