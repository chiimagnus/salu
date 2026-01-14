import GameCore

/// 商店房间处理器（P4 扩展：支持遗物和消耗品）
struct ShopRoomHandler: RoomHandling {
    var roomType: RoomType { .shop }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        run(node: node, runState: &runState, context: context, inputProvider: { readLine() })
    }
    
    func run(
        node: MapNode,
        runState: inout RunState,
        context: RoomContext,
        inputProvider: () -> String?
    ) -> RoomRunResult {
        let shopContext = ShopContext(
            seed: runState.seed,
            floor: runState.floor,
            currentRow: runState.currentRow,
            nodeId: node.id,
            ownedRelicIds: runState.relicManager.all  // P4: 传入已拥有的遗物
        )
        var inventory = ShopInventory.generate(context: shopContext)
        var message: String? = nil
        
        while true {
            Screens.showShop(inventory: inventory, runState: runState, message: message)
            
            guard let input = inputProvider()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                break
            }
            
            message = nil
            
            if input == "0" {
                break
            }
            
            // 删牌服务
            if input == "d" {
                handleRemoveCard(
                    runState: &runState,
                    inventory: inventory,
                    context: context,
                    message: &message,
                    inputProvider: inputProvider
                )
                continue
            }
            
            // P4: 购买遗物 (R1, R2, R3...)
            if input.hasPrefix("r"), let indexStr = input.dropFirst().first, let index = Int(String(indexStr)) {
                inventory = handleBuyRelic(
                    index: index,
                    runState: &runState,
                    inventory: inventory,
                    context: context,
                    message: &message
                )
                continue
            }
            
            // P4: 购买消耗品 (C1, C2, C3...)
            if input.hasPrefix("c"), let indexStr = input.dropFirst().first, let index = Int(String(indexStr)) {
                inventory = handleBuyConsumable(
                    index: index,
                    runState: &runState,
                    inventory: inventory,
                    context: context,
                    message: &message
                )
                continue
            }
            
            // 购买卡牌 (1, 2, 3...)
            guard let choice = Int(input), choice >= 1, choice <= inventory.cardOffers.count else {
                message = "\(Terminal.red)⚠️ 无效选择，请输入对应编号\(Terminal.reset)"
                continue
            }
            
            inventory = handleBuyCard(
                choice: choice,
                runState: &runState,
                inventory: inventory,
                context: context,
                message: &message
            )
        }
        
        runState.completeCurrentNode()
        return .completedNode
    }
    
    // MARK: - Buy Card
    
    private func handleBuyCard(
        choice: Int,
        runState: inout RunState,
        inventory: ShopInventory,
        context: RoomContext,
        message: inout String?
    ) -> ShopInventory {
        let offer = inventory.cardOffers[choice - 1]
        if runState.gold < offer.price {
            message = "\(Terminal.red)金币不足，无法购买该卡牌\(Terminal.reset)"
            return inventory
        }
        
        runState.gold -= offer.price
        runState.addCardToDeck(cardId: offer.cardId)
        let boughtName = CardRegistry.require(offer.cardId).name
        context.logLine("\(Terminal.yellow)商店购买：\(boughtName)（-\(offer.price) 金币）\(Terminal.reset)")
        
        // 从库存移除已购买的卡牌
        let newCardOffers = inventory.cardOffers.enumerated().compactMap { index, cardOffer in
            index == choice - 1 ? nil : cardOffer
        }
        message = "\(Terminal.green)购买成功，已加入牌组\(Terminal.reset)"
        
        return ShopInventory(
            cardOffers: newCardOffers,
            relicOffers: inventory.relicOffers,
            consumableOffers: inventory.consumableOffers,
            removeCardPrice: inventory.removeCardPrice
        )
    }
    
    // MARK: - Buy Relic (P4)
    
    private func handleBuyRelic(
        index: Int,
        runState: inout RunState,
        inventory: ShopInventory,
        context: RoomContext,
        message: inout String?
    ) -> ShopInventory {
        guard index >= 1, index <= inventory.relicOffers.count else {
            message = "\(Terminal.red)⚠️ 无效的遗物编号\(Terminal.reset)"
            return inventory
        }
        
        let offer = inventory.relicOffers[index - 1]
        if runState.gold < offer.price {
            message = "\(Terminal.red)金币不足，无法购买该遗物\(Terminal.reset)"
            return inventory
        }
        
        runState.gold -= offer.price
        runState.relicManager.add(offer.relicId)
        let def = RelicRegistry.require(offer.relicId)
        context.logLine("\(Terminal.yellow)商店购买：\(def.icon) \(def.name)（-\(offer.price) 金币）\(Terminal.reset)")
        
        // 从库存移除已购买的遗物
        let newRelicOffers = inventory.relicOffers.enumerated().compactMap { idx, relicOffer in
            idx == index - 1 ? nil : relicOffer
        }
        message = "\(Terminal.green)购买成功，获得遗物【\(def.name)】\(Terminal.reset)"
        
        return ShopInventory(
            cardOffers: inventory.cardOffers,
            relicOffers: newRelicOffers,
            consumableOffers: inventory.consumableOffers,
            removeCardPrice: inventory.removeCardPrice
        )
    }
    
    // MARK: - Buy Consumable Card (P4R)
    
    private func handleBuyConsumable(
        index: Int,
        runState: inout RunState,
        inventory: ShopInventory,
        context: RoomContext,
        message: inout String?
    ) -> ShopInventory {
        guard index >= 1, index <= inventory.consumableOffers.count else {
            message = "\(Terminal.red)⚠️ 无效的消耗品编号\(Terminal.reset)"
            return inventory
        }
        
        let offer = inventory.consumableOffers[index - 1]
        if runState.gold < offer.price {
            message = "\(Terminal.red)金币不足，无法购买该消耗品\(Terminal.reset)"
            return inventory
        }
        
        guard runState.addConsumableCardToDeck(cardId: offer.cardId) else {
            message = "\(Terminal.red)消耗性卡牌槽位已满（最多 \(RunState.maxConsumableCardSlots) 个），无法购买\(Terminal.reset)"
            return inventory
        }
        
        runState.gold -= offer.price
        let def = CardRegistry.require(offer.cardId)
        context.logLine("\(Terminal.yellow)商店购买：🧪 \(def.name)（-\(offer.price) 金币）\(Terminal.reset)")
        
        // 消耗品可重复购买，不从库存移除
        message = "\(Terminal.green)购买成功，获得消耗性卡牌【\(def.name)】\(Terminal.reset)"
        
        return inventory
    }
    
    // MARK: - Remove Card
    
    private func handleRemoveCard(
        runState: inout RunState,
        inventory: ShopInventory,
        context: RoomContext,
        message: inout String?,
        inputProvider: () -> String?
    ) {
        if runState.gold < inventory.removeCardPrice {
            message = "\(Terminal.red)金币不足，无法删牌\(Terminal.reset)"
            return
        }
        
        var removeMessage: String? = nil
        while true {
            Screens.showShopRemoveCard(runState: runState, price: inventory.removeCardPrice, message: removeMessage)
            guard let input = inputProvider()?.trimmingCharacters(in: .whitespaces).lowercased() else {
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
            context.logLine("\(Terminal.yellow)商店删牌：\(removedName)（-\(inventory.removeCardPrice) 金币）\(Terminal.reset)")
            return
        }
    }
}
