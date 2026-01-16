import GameCore

/// 商店界面（P4 扩展：支持遗物和消耗性卡牌）
enum ShopScreen {
    static func show(inventory: ShopInventory, runState: RunState, message: String? = nil) {
        Terminal.clear()
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🏪 \(L10n.text("商店", "Shop"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(L10n.text("当前金币", "Gold")): \(Terminal.yellow)\(runState.gold)\(Terminal.reset)
        """)
        
        // 卡牌区域
        print("")
        print("  \(Terminal.bold)🃏 \(L10n.text("卡牌", "Cards"))：\(Terminal.reset)")
        if inventory.cardOffers.isEmpty {
            print("  \(Terminal.dim)（\(L10n.text("暂无卡牌上架", "No cards in stock"))）\(Terminal.reset)")
        } else {
            for (index, offer) in inventory.cardOffers.enumerated() {
                let def = CardRegistry.require(offer.cardId)
                let typeText = "\(def.type.displayName(language: L10n.language))·\(def.rarity.displayName(language: L10n.language))"
                let affordable = runState.gold >= offer.price
                let priceColor = affordable ? Terminal.yellow : Terminal.dim
                print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(L10n.resolve(def.name)) \(Terminal.dim)(\(typeText))\(Terminal.reset) - \(priceColor)\(offer.price) \(L10n.text("金币", "gold"))\(Terminal.reset)")
            }
        }
        
        // 遗物区域
        print("")
        print("  \(Terminal.bold)💎 \(L10n.text("遗物", "Relics"))：\(Terminal.reset)")
        if inventory.relicOffers.isEmpty {
            print("  \(Terminal.dim)（\(L10n.text("暂无遗物上架", "No relics in stock"))）\(Terminal.reset)")
        } else {
            for (index, offer) in inventory.relicOffers.enumerated() {
                let def = RelicRegistry.require(offer.relicId)
                let affordable = runState.gold >= offer.price
                let priceColor = affordable ? Terminal.yellow : Terminal.dim
                print("  \(Terminal.cyan)[R\(index + 1)]\(Terminal.reset) \(def.icon) \(L10n.resolve(def.name)) - \(priceColor)\(offer.price) \(L10n.text("金币", "gold"))\(Terminal.reset)")
                print("      \(Terminal.dim)\(L10n.resolve(def.description))\(Terminal.reset)")
            }
        }
        
        // 消耗性卡牌区域
        print("")
        print("  \(Terminal.bold)🧪 \(L10n.text("消耗性卡牌", "Consumables"))：\(Terminal.reset)")
        if inventory.consumableOffers.isEmpty {
            print("  \(Terminal.dim)（\(L10n.text("暂无消耗性卡牌上架", "No consumables in stock"))）\(Terminal.reset)")
        } else {
            for (index, offer) in inventory.consumableOffers.enumerated() {
                let def = CardRegistry.require(offer.cardId)
                let affordable = runState.gold >= offer.price
                let priceColor = affordable ? Terminal.yellow : Terminal.dim
                print("  \(Terminal.cyan)[C\(index + 1)]\(Terminal.reset) 🧪 \(L10n.resolve(def.name)) - \(priceColor)\(offer.price) \(L10n.text("金币", "gold"))\(Terminal.reset)")
                print("      \(Terminal.dim)\(L10n.resolve(def.rulesText))\(Terminal.reset)")
            }
        }
        
        // 删牌服务
        print("")
        let removeAffordable = runState.gold >= inventory.removeCardPrice
        let removePriceColor = removeAffordable ? Terminal.yellow : Terminal.dim
        print("  \(Terminal.magenta)[D]\(Terminal.reset) \(L10n.text("删牌服务", "Remove a card")) - \(removePriceColor)\(inventory.removeCardPrice) \(L10n.text("金币", "gold"))\(Terminal.reset)")
        
        if let message {
            print("")
            print(message)
        }
        
        // 输入提示
        var hints: [String] = []
        if !inventory.cardOffers.isEmpty {
            hints.append("\(Terminal.cyan)[1-\(inventory.cardOffers.count)]\(Terminal.reset) \(L10n.text("买卡", "Buy cards"))")
        }
        if !inventory.relicOffers.isEmpty {
            hints.append("\(Terminal.cyan)[R1-R\(inventory.relicOffers.count)]\(Terminal.reset) \(L10n.text("买遗物", "Buy relics"))")
        }
        if !inventory.consumableOffers.isEmpty {
            hints.append("\(Terminal.cyan)[C1-C\(inventory.consumableOffers.count)]\(Terminal.reset) \(L10n.text("买消耗性卡牌", "Buy consumables"))")
        }
        hints.append("\(Terminal.cyan)[D]\(Terminal.reset) \(L10n.text("删牌", "Remove"))")
        hints.append("\(Terminal.cyan)[0]\(Terminal.reset) \(L10n.text("离开", "Leave"))")
        
        print("""
        
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(hints.joined(separator: "  "))
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
    
    static func showRemoveCardOptions(runState: RunState, price: Int, message: String? = nil) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🗑️ \(L10n.text("删牌服务", "Remove a card"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(L10n.text("当前金币", "Gold")): \(Terminal.yellow)\(runState.gold)\(Terminal.reset)  |  \(L10n.text("删牌费用", "Remove cost")): \(Terminal.yellow)\(price)\(Terminal.reset)
          
        \(Terminal.bold)\(L10n.text("选择要移除的卡牌", "Choose a card to remove"))：\(Terminal.reset)
        """)
        
        if runState.deck.isEmpty {
            print("  \(Terminal.dim)（\(L10n.text("牌组为空", "Deck is empty"))）\(Terminal.reset)")
        } else {
            for (index, card) in runState.deck.enumerated() {
                let def = CardRegistry.require(card.cardId)
                print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(L10n.resolve(def.name)) \(Terminal.dim)(\(def.type.displayName(language: L10n.language)))\(Terminal.reset)")
            }
        }
        
        if let message {
            print("")
            print(message)
        }
        
        let removeHint: String
        if runState.deck.isEmpty {
            removeHint = "\(Terminal.cyan)[\(L10n.text("无", "None"))]\(Terminal.reset) \(L10n.text("无卡牌可移除", "No cards to remove"))"
        } else {
            removeHint = "\(Terminal.cyan)[1-\(runState.deck.count)]\(Terminal.reset) \(L10n.text("选择卡牌", "Select card"))"
        }
        
        print("""
        
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(removeHint)  \(Terminal.cyan)[0]\(Terminal.reset) \(L10n.text("返回", "Back"))
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
}
