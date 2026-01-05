import GameCore

/// 休息房间处理器
struct RestRoomHandler: RoomHandling {
    var roomType: RoomType { .rest }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        var message: String? = nil
        while true {
            Screens.showRestOptions(runState: runState, message: message)
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                break
            }
            
            message = nil
            
            if input == "1" {
                // 执行休息
                let healed = runState.restAtNode()
                context.logLine("\(Terminal.green)休息：恢复 \(healed) HP\(Terminal.reset)")
                
                // 显示结果
                Screens.showRestResult(
                    healedAmount: healed,
                    newHP: runState.player.currentHP,
                    maxHP: runState.player.maxHP
                )
                
                _ = readLine()
                break
            }
            
            if input == "2" {
                let upgradeableIndices = runState.upgradeableCardIndices
                if upgradeableIndices.isEmpty {
                    message = "\(Terminal.red)当前没有可升级的卡牌\(Terminal.reset)"
                    continue
                }
                
                let completed = handleUpgradeSelection(runState: &runState, upgradeableIndices: upgradeableIndices, context: context)
                if completed {
                    break
                }
                
                continue
            }
            
            message = "\(Terminal.red)⚠️ 请输入有效的选项（1 或 2）\(Terminal.reset)"
        }
        
        // 完成节点
        runState.completeCurrentNode()
        return .completedNode
    }
    
    private func handleUpgradeSelection(runState: inout RunState, upgradeableIndices: [Int], context: RoomContext) -> Bool {
        var message: String? = nil
        while true {
            Screens.showRestUpgradeOptions(
                runState: runState,
                upgradeableIndices: upgradeableIndices,
                message: message
            )
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                return false
            }
            
            message = nil
            
            if input == "q" {
                return false
            }
            
            guard let choice = Int(input), choice >= 1, choice <= upgradeableIndices.count else {
                message = "\(Terminal.red)⚠️ 请选择有效的卡牌编号\(Terminal.reset)"
                continue
            }
            
            let deckIndex = upgradeableIndices[choice - 1]
            let card = runState.deck[deckIndex]
            
            guard let def = CardRegistry.get(card.cardId),
                  let upgradedId = def.upgradedId else {
                message = "\(Terminal.red)⚠️ 该卡牌无法升级\(Terminal.reset)"
                continue
            }
            
            let upgradedDef = CardRegistry.require(upgradedId)
            _ = runState.upgradeCard(at: deckIndex)
            context.logLine("\(Terminal.cyan)升级：\(def.name) → \(upgradedDef.name)\(Terminal.reset)")
            
            Screens.showRestUpgradeResult(originalName: def.name, upgradedName: upgradedDef.name)
            _ = readLine()
            return true
        }
    }
}
