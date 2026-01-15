import GameCore

/// 商店界面（P4 扩展：支持遗物和消耗性卡牌）
enum ShopScreen {
    static func show(inventory: ShopInventory, runState: RunState, message: String? = nil) {
        Terminal.clear()
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🏪 商店\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          当前金币: \(Terminal.yellow)\(runState.gold)\(Terminal.reset)
        """)
        
        // 卡牌区域
        print("")
        print("  \(Terminal.bold)🃏 卡牌：\(Terminal.reset)")
        if inventory.cardOffers.isEmpty {
            print("  \(Terminal.dim)（暂无卡牌上架）\(Terminal.reset)")
        } else {
            for (index, offer) in inventory.cardOffers.enumerated() {
                let def = CardRegistry.require(offer.cardId)
                let typeText = "\(def.type.rawValue)·\(def.rarity.rawValue)"
                let affordable = runState.gold >= offer.price
                let priceColor = affordable ? Terminal.yellow : Terminal.dim
                print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(def.name) \(Terminal.dim)(\(typeText))\(Terminal.reset) - \(priceColor)\(offer.price)金币\(Terminal.reset)")
            }
        }
        
        // 遗物区域
        print("")
        print("  \(Terminal.bold)💎 遗物：\(Terminal.reset)")
        if inventory.relicOffers.isEmpty {
            print("  \(Terminal.dim)（暂无遗物上架）\(Terminal.reset)")
        } else {
            for (index, offer) in inventory.relicOffers.enumerated() {
                let def = RelicRegistry.require(offer.relicId)
                let affordable = runState.gold >= offer.price
                let priceColor = affordable ? Terminal.yellow : Terminal.dim
                print("  \(Terminal.cyan)[R\(index + 1)]\(Terminal.reset) \(def.icon) \(def.name) - \(priceColor)\(offer.price)金币\(Terminal.reset)")
                print("      \(Terminal.dim)\(def.description)\(Terminal.reset)")
            }
        }
        
        // 消耗性卡牌区域
        print("")
        print("  \(Terminal.bold)🧪 消耗性卡牌：\(Terminal.reset)")
        if inventory.consumableOffers.isEmpty {
            print("  \(Terminal.dim)（暂无消耗性卡牌上架）\(Terminal.reset)")
        } else {
            for (index, offer) in inventory.consumableOffers.enumerated() {
                let def = CardRegistry.require(offer.cardId)
                let affordable = runState.gold >= offer.price
                let priceColor = affordable ? Terminal.yellow : Terminal.dim
                print("  \(Terminal.cyan)[C\(index + 1)]\(Terminal.reset) 🧪 \(def.name) - \(priceColor)\(offer.price)金币\(Terminal.reset)")
                print("      \(Terminal.dim)\(def.rulesText)\(Terminal.reset)")
            }
        }
        
        // 删牌服务
        print("")
        let removeAffordable = runState.gold >= inventory.removeCardPrice
        let removePriceColor = removeAffordable ? Terminal.yellow : Terminal.dim
        print("  \(Terminal.magenta)[D]\(Terminal.reset) 删牌服务 - \(removePriceColor)\(inventory.removeCardPrice)金币\(Terminal.reset)")
        
        if let message {
            print("")
            print(message)
        }
        
        // 输入提示
        var hints: [String] = []
        if !inventory.cardOffers.isEmpty {
            hints.append("\(Terminal.cyan)[1-\(inventory.cardOffers.count)]\(Terminal.reset) 买卡")
        }
        if !inventory.relicOffers.isEmpty {
            hints.append("\(Terminal.cyan)[R1-R\(inventory.relicOffers.count)]\(Terminal.reset) 买遗物")
        }
        if !inventory.consumableOffers.isEmpty {
            hints.append("\(Terminal.cyan)[C1-C\(inventory.consumableOffers.count)]\(Terminal.reset) 买消耗性卡牌")
        }
        hints.append("\(Terminal.cyan)[D]\(Terminal.reset) 删牌")
        hints.append("\(Terminal.cyan)[0]\(Terminal.reset) 离开")
        
        print("""
        
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(hints.joined(separator: "  "))
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
    
    static func showRemoveCardOptions(runState: RunState, price: Int, message: String? = nil) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🗑️ 删牌服务\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          当前金币: \(Terminal.yellow)\(runState.gold)\(Terminal.reset)  |  删牌费用: \(Terminal.yellow)\(price)\(Terminal.reset)
          
        \(Terminal.bold)选择要移除的卡牌：\(Terminal.reset)
        """)
        
        if runState.deck.isEmpty {
            print("  \(Terminal.dim)（牌组为空）\(Terminal.reset)")
        } else {
            for (index, card) in runState.deck.enumerated() {
                let def = CardRegistry.require(card.cardId)
                print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(def.name) \(Terminal.dim)(\(def.type.rawValue))\(Terminal.reset)")
            }
        }
        
        if let message {
            print("")
            print(message)
        }
        
        let removeHint: String
        if runState.deck.isEmpty {
            removeHint = "\(Terminal.cyan)[无]\(Terminal.reset) 无卡牌可移除"
        } else {
            removeHint = "\(Terminal.cyan)[1-\(runState.deck.count)]\(Terminal.reset) 选择卡牌"
        }
        
        print("""
        
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(removeHint)  \(Terminal.cyan)[0]\(Terminal.reset) 返回
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
}
