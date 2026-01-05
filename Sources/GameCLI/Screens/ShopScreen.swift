import GameCore

/// 商店界面
enum ShopScreen {
    static func show(inventory: ShopInventory, runState: RunState, message: String? = nil) {
        Terminal.clear()
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🏪 商店\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          当前金币: \(Terminal.yellow)\(runState.gold)\(Terminal.reset)
          
        \(Terminal.bold)可购买的卡牌：\(Terminal.reset)
        """)
        
        if inventory.cardOffers.isEmpty {
            print("  \(Terminal.dim)（暂无卡牌上架）\(Terminal.reset)")
        } else {
            for (index, offer) in inventory.cardOffers.enumerated() {
                let def = CardRegistry.require(offer.cardId)
                let typeText = "\(def.type.rawValue)·\(def.rarity.rawValue)"
                print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(def.name) \(Terminal.dim)(\(typeText))\(Terminal.reset) - \(Terminal.yellow)\(offer.price)金币\(Terminal.reset)")
            }
        }
        
        print("")
        print("  \(Terminal.magenta)[D]\(Terminal.reset) 删牌 - \(Terminal.yellow)\(inventory.removeCardPrice)金币\(Terminal.reset)")
        
        if let message {
            print("")
            print(message)
        }
        
        let buyHint: String
        if inventory.cardOffers.isEmpty {
            buyHint = "\(Terminal.cyan)[无]\(Terminal.reset) 无卡牌可买"
        } else {
            buyHint = "\(Terminal.cyan)[1-\(inventory.cardOffers.count)]\(Terminal.reset) 购买卡牌"
        }
        
        print("""
        
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(buyHint)  \(Terminal.cyan)[D]\(Terminal.reset) 删牌  \(Terminal.cyan)[0]\(Terminal.reset) 离开
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        print("\(Terminal.green)>>>\(Terminal.reset) ", terminator: "")
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
        print("\(Terminal.green)>>>\(Terminal.reset) ", terminator: "")
        Terminal.flush()
    }
}
