import GameCore

/// 遗物奖励界面
enum RelicRewardScreen {
    /// 显示遗物奖励并读取选择
    /// - Returns: 是否选择获得遗物
    static func chooseRelic(relicId: RelicID) -> Bool {
        Terminal.clear()
        
        let def = RelicRegistry.require(relicId)
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🏺 遗物奖励\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(Terminal.bold)获得一件遗物：\(Terminal.reset)
        
          \(def.icon) \(Terminal.bold)\(def.name)\(Terminal.reset)  \(Terminal.dim)(\(def.rarity.rawValue))\(Terminal.reset)
          \(Terminal.dim)\(def.description)\(Terminal.reset)
        
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1]\(Terminal.reset) 获得  \(Terminal.cyan)[0]\(Terminal.reset) 跳过
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        
        while true {
            print("\(Terminal.green)>>>\(Terminal.reset) ", terminator: "")
            Terminal.flush()
            
            // EOF（管道输入结束）默认跳过，避免测试/脚本卡死
            guard let raw = readLine() else {
                return false
            }
            
            let input = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if input.isEmpty {
                continue
            }
            
            if input == "1" {
                return true
            }
            
            if input == "0" {
                return false
            }
        }
    }
}
