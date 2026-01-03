import GameCore
import Foundation

/// 休息屏幕
/// 显示休息界面，玩家可以恢复生命值
enum RestScreen {
    
    /// 显示休息界面
    static func show(player: Entity, healAmount: Int) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.green)
        ═══════════════════════════════════════════
                       🔥 休息
        ═══════════════════════════════════════════
        \(Terminal.reset)
        
        你在篝火旁休息片刻...
        
        \(Terminal.green)生命值：\(player.currentHP) → \(min(player.currentHP + healAmount, player.maxHP)) / \(player.maxHP)\(Terminal.reset)
        \(Terminal.dim)（恢复 \(healAmount) 点生命）\(Terminal.reset)
        
        \(Terminal.dim)按 Enter 继续...\(Terminal.reset)
        """)
    }
}
