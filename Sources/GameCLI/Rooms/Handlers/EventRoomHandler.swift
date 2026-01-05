import GameCore

/// 事件房间处理器（P5）
struct EventRoomHandler: RoomHandling {
    var roomType: RoomType { .event }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        let eventContext = EventContext(
            seed: runState.seed,
            floor: runState.floor,
            currentRow: runState.currentRow,
            nodeId: node.id,
            playerMaxHP: runState.player.maxHP,
            playerCurrentHP: runState.player.currentHP,
            gold: runState.gold,
            deck: runState.deck,
            relicIds: runState.relicManager.all
        )
        
        let offer = EventGenerator.generate(context: eventContext)
        guard let choiceIndex = EventScreen.chooseOption(offer: offer) else {
            // 默认视为离开（不产生效果）
            runState.completeCurrentNode()
            return .completedNode
        }
        
        guard choiceIndex >= 0, choiceIndex < offer.options.count else {
            runState.completeCurrentNode()
            return .completedNode
        }
        
        let picked = offer.options[choiceIndex]
        
        // 应用效果
        for effect in picked.effects {
            _ = runState.apply(effect)
        }

        // 二次选择（如：选择要升级的卡牌）
        var followUpLines: [String] = []
        if let followUp = picked.followUp {
            switch followUp {
            case .chooseUpgradeableCard(let indices):
                if let deckIndex = EventScreen.chooseUpgradeableCard(runState: runState, upgradeableIndices: indices) {
                    let before = runState.deck[deckIndex]
                    let beforeDef = CardRegistry.require(before.cardId)
                    if let upgradedId = beforeDef.upgradedId {
                        let upgradedDef = CardRegistry.require(upgradedId)
                        _ = runState.apply(.upgradeCard(deckIndex: deckIndex))
                        followUpLines.append("升级：\(beforeDef.name) → \(upgradedDef.name)")
                    }
                }
            }
        }
        
        // 结算展示（简单：逐条展示 preview 或效果摘要）
        let resultLines = buildResultLines(option: picked, additional: followUpLines)
        EventScreen.showResult(title: "你选择了：\(picked.title)", lines: resultLines)
        _ = readLine()
        
        // 完成节点
        runState.completeCurrentNode()
        return .completedNode
    }
    
    private func buildResultLines(option: EventOption, additional: [String]) -> [String] {
        if let preview = option.preview, !preview.isEmpty {
            return [preview] + additional
        }
        
        if option.effects.isEmpty {
            if additional.isEmpty {
                return ["没有发生任何事。"]
            }
            return additional
        }
        
        let base = option.effects.map { effect in
            switch effect {
            case .gainGold(let amount):
                return "获得 \(amount) 金币"
            case .loseGold(let amount):
                return "失去 \(amount) 金币"
            case .heal(let amount):
                return "恢复 \(amount) HP"
            case .takeDamage(let amount):
                return "失去 \(amount) HP"
            case .addCard(let cardId):
                let name = CardRegistry.require(cardId).name
                return "获得卡牌：\(name)"
            case .addRelic(let relicId):
                let def = RelicRegistry.require(relicId)
                return "获得遗物：\(def.icon)\(def.name)"
            case .upgradeCard:
                return "升级了一张卡牌"
            }
        }
        return base + additional
    }
}


