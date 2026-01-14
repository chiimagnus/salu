import GameCore

/// 奖励界面（P1：战斗后卡牌奖励）
enum RewardScreen {
    /// 显示卡牌奖励并读取选择
    /// - Returns: 选中的 CardID；nil 表示跳过
    static func chooseCard(offer: CardRewardOffer, goldEarned: Int? = nil) -> CardID? {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🎁 战斗奖励\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(goldEarned.map { "  \(Terminal.yellow)💰 获得 \($0) 金币\(Terminal.reset)\n" } ?? "")
        \(Terminal.bold)选择一张卡牌加入牌组（或跳过）：\(Terminal.reset)
        """)
        
        if offer.choices.isEmpty {
            print("\(Terminal.dim)  （当前没有可用的奖励卡牌）\(Terminal.reset)\n")
        } else {
            for (index, cardId) in offer.choices.enumerated() {
                let def = CardRegistry.require(cardId)
                let typeIcon: String
                switch def.type {
                case .attack: typeIcon = "⚔️"
                case .skill: typeIcon = "🛡️"
                case .power: typeIcon = "💪"
                case .consumable: typeIcon = "🧪"
                }
                
                print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(Terminal.bold)\(def.name)\(Terminal.reset)  \(Terminal.yellow)◆\(def.cost)\(Terminal.reset)  \(typeIcon) \(def.rulesText)")
            }
            print("")
        }
        
        if offer.canSkip {
            print("  \(Terminal.dim)\(Terminal.cyan)[0]\(Terminal.reset)\(Terminal.dim) 跳过\(Terminal.reset)")
            print("")
        }
        
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(max(offer.choices.count, 1))]\(Terminal.reset) 选择  \(Terminal.cyan)[0]\(Terminal.reset) 跳过")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        
        while true {
            print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
            Terminal.flush()
            
            // EOF（管道输入结束）默认跳过，避免测试/脚本卡死
            guard let raw = readLine() else {
                return nil
            }
            
            let input = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if input.isEmpty {
                continue
            }
            
            if offer.canSkip, input == "0" {
                return nil
            }
            
            if let number = Int(input) {
                let idx = number - 1
                if idx >= 0, idx < offer.choices.count {
                    return offer.choices[idx]
                }
            }
            
            // // 无效输入：提示并继续读
            // print("\(Terminal.red)⚠️ 无效输入：请输入 1-\(offer.choices.count) 或 0 跳过\(Terminal.reset)")
        }
    }
}

