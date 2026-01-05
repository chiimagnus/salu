import GameCore

/// 商店房间处理器
struct ShopRoomHandler: RoomHandling {
    var roomType: RoomType { .shop }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let shopContext = ShopContext(
            seed: runState.seed,
            floor: runState.floor,
            currentRow: runState.currentRow,
            nodeId: node.id
        )
        var inventory = ShopInventory.generate(context: shopContext)
        var message: String? = nil
        
        while true {
            Screens.showShop(inventory: inventory, runState: runState, message: message)
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                break
            }
            
            message = nil
            
            if input == "0" {
                break
            }
            
            if input == "d" {
                handleRemoveCard(runState: &runState, inventory: inventory, context: context, message: &message)
                continue
            }
            
            guard let choice = Int(input), choice >= 1, choice <= inventory.cardOffers.count else {
                message = "\(Terminal.red)⚠️ 无效选择，请输入对应编号\(Terminal.reset)"
                continue
            }
            
            let offer = inventory.cardOffers[choice - 1]
            if runState.gold < offer.price {
                message = "\(Terminal.red)金币不足，无法购买该卡牌\(Terminal.reset)"
                continue
            }
            
            runState.gold -= offer.price
            runState.addCardToDeck(cardId: offer.cardId)
            let boughtName = CardRegistry.require(offer.cardId).name
            context.appendRunLog("\(Terminal.yellow)商店购买：\(boughtName)（-\(offer.price) 金币）\(Terminal.reset)")
            inventory = ShopInventory(
                cardOffers: inventory.cardOffers.enumerated().compactMap { index, cardOffer in
                    index == choice - 1 ? nil : cardOffer
                },
                removeCardPrice: inventory.removeCardPrice
            )
            message = "\(Terminal.green)购买成功，已加入牌组\(Terminal.reset)"
        }
        
        runState.completeCurrentNode()
        return .completedNode
    }
    
    private func handleRemoveCard(runState: inout RunState, inventory: ShopInventory, context: RoomContext, message: inout String?) {
        if runState.gold < inventory.removeCardPrice {
            message = "\(Terminal.red)金币不足，无法删牌\(Terminal.reset)"
            return
        }
        
        var removeMessage: String? = nil
        while true {
            Screens.showShopRemoveCard(runState: runState, price: inventory.removeCardPrice, message: removeMessage)
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                break
            }
            
            removeMessage = nil
            
            if input == "0" {
                break
            }
            
            guard let choice = Int(input), choice >= 1, choice <= runState.deck.count else {
                removeMessage = "\(Terminal.red)⚠️ 请选择有效的卡牌编号\(Terminal.reset)"
                continue
            }
            
            let removed = runState.deck[choice - 1]
            let removedName = CardRegistry.require(removed.cardId).name
            runState.removeCardFromDeck(at: choice - 1)
            runState.gold -= inventory.removeCardPrice
            message = "\(Terminal.green)删牌成功\(Terminal.reset)"
            context.appendRunLog("\(Terminal.yellow)商店删牌：\(removedName)（-\(inventory.removeCardPrice) 金币）\(Terminal.reset)")
            return
        }
    }
}
