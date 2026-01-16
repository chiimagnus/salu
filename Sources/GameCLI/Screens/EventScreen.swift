import GameCore

/// 事件界面（P5）
enum EventScreen {
    /// 展示事件并读取选择
    /// - Returns: 选择的选项索引（0-based）；nil 表示离开/跳过（由上层决定）
    static func chooseOption(offer: EventOffer) -> Int? {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  \(offer.icon) \(L10n.text("事件", "Event"))：\(L10n.resolve(offer.name))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(L10n.resolve(offer.description))
        
        \(Terminal.bold)\(L10n.text("请选择一个选项", "Choose an option"))：\(Terminal.reset)
        """)
        
        for (index, option) in offer.options.enumerated() {
            let preview = option.preview.map { " \(Terminal.dim)(\(L10n.resolve($0)))\(Terminal.reset)" } ?? ""
            print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(L10n.resolve(option.title))\(preview)")
        }
        print("  \(Terminal.cyan)[0]\(Terminal.reset) \(L10n.text("离开", "Leave"))")
        
        print("")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(max(offer.options.count, 1))]\(Terminal.reset) \(L10n.text("选择", "Select"))  \(Terminal.cyan)[0]\(Terminal.reset) \(L10n.text("离开", "Leave"))")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        
        while true {
            print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
            Terminal.flush()
            
            // EOF：默认不选择，避免测试/脚本卡死
            guard let raw = readLine() else {
                return nil
            }
            
            let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if input.isEmpty {
                continue
            }
            
            if input == "0" {
                return nil
            }
            
            if let n = Int(input), n >= 1, n <= offer.options.count {
                return n - 1
            }
        }
    }
    
    static func showResult(title: String, lines: [String]) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  ✅ \(L10n.text("事件结算", "Event Result"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(Terminal.bold)\(title)\(Terminal.reset)
        """)
        
        for line in lines {
            print("  \(line)")
        }
        
        print("")
        NavigationBar.render(items: [.continueNext])
    }

    /// 事件二次选择：选择要升级的卡牌（返回牌组索引）
    static func chooseUpgradeableCard(runState: RunState, upgradeableIndices: [Int]) -> Int? {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  ？ \(L10n.text("选择要升级的卡牌", "Choose a card to upgrade"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(Terminal.bold)\(L10n.text("从可升级卡中选择 1 张", "Choose 1 upgradable card"))：\(Terminal.reset)
        """)
        
        for (index, deckIndex) in upgradeableIndices.enumerated() {
            let card = runState.deck[deckIndex]
            let def = CardRegistry.require(card.cardId)
            guard let upgradedId = def.upgradedId else { continue }
            let upgradedDef = CardRegistry.require(upgradedId)
            print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(Terminal.bold)\(L10n.resolve(def.name))\(Terminal.reset) → \(Terminal.green)\(L10n.resolve(upgradedDef.name))\(Terminal.reset)")
        }
        
        print("")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(max(1, upgradeableIndices.count))]\(Terminal.reset) \(L10n.text("选择", "Select"))  \(Terminal.cyan)[0]\(Terminal.reset) \(L10n.text("取消", "Cancel"))")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        
        while true {
            print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
            Terminal.flush()
            
            guard let raw = readLine() else {
                return nil
            }
            
            let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if input.isEmpty {
                continue
            }
            
            if input == "0" {
                return nil
            }
            
            if let n = Int(input), n >= 1, n <= upgradeableIndices.count {
                return upgradeableIndices[n - 1]
            }
        }
    }
}

