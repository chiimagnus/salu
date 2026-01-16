import GameCore

/// 休息房间处理器（据点化：可与艾拉对话）
struct RestRoomHandler: RoomHandling {
    var roomType: RoomType { .rest }
    
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult {
        var message: String? = nil
        var hasSpokenToAira = false  // 记录是否已与艾拉对话
        
        while true {
            Screens.showRestOptions(runState: runState, message: message)
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                break
            }
            
            message = nil
            
            if input == "1" {
                // 执行休息
                let healed = runState.restAtNode()
                context.logLine("\(Terminal.green)\(L10n.text("休息", "Rest"))：\(L10n.text("恢复", "Recover")) \(healed) HP\(Terminal.reset)")
                
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
                    message = "\(Terminal.red)\(L10n.text("当前没有可升级的卡牌", "No upgradable cards available"))\(Terminal.reset)"
                    continue
                }
                
                let completed = handleUpgradeSelection(runState: &runState, upgradeableIndices: upgradeableIndices, context: context)
                if completed {
                    break
                }
                
                continue
            }
            
            if input == "3" {
                // 与艾拉对话（可多次对话，但内容相同）
                let dialogue = RestPointDialogues.getAiraDialogue(floor: runState.floor)
                Screens.showAiraDialogue(
                    title: L10n.resolve(dialogue.title),
                    content: L10n.resolve(dialogue.content),
                    effect: dialogue.effect.map(L10n.resolve)
                )
                _ = readLine()
                
                if !hasSpokenToAira {
                    context.logLine("\(Terminal.magenta)\(L10n.text("与艾拉进行了一次对话", "Chatted with Aira"))\(Terminal.reset)")
                    hasSpokenToAira = true
                }
                
                // 对话后返回选项界面，玩家可以继续选择休息或升级
                continue
            }
            
            message = "\(Terminal.red)⚠️ \(L10n.text("请输入有效的选项（1、2 或 3）", "Please enter a valid option (1, 2, or 3)"))\(Terminal.reset)"
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
                message = "\(Terminal.red)⚠️ \(L10n.text("请选择有效的卡牌编号", "Please choose a valid card number"))\(Terminal.reset)"
                continue
            }
            
            let deckIndex = upgradeableIndices[choice - 1]
            let card = runState.deck[deckIndex]
            
            guard let def = CardRegistry.get(card.cardId),
                  let upgradedId = def.upgradedId else {
                message = "\(Terminal.red)⚠️ \(L10n.text("该卡牌无法升级", "This card cannot be upgraded"))\(Terminal.reset)"
                continue
            }
            
            let upgradedDef = CardRegistry.require(upgradedId)
            _ = runState.upgradeCard(at: deckIndex)
            context.logLine("\(Terminal.cyan)\(L10n.text("升级", "Upgraded"))：\(L10n.resolve(def.name)) → \(L10n.resolve(upgradedDef.name))\(Terminal.reset)")
            
            Screens.showRestUpgradeResult(originalName: L10n.resolve(def.name), upgradedName: L10n.resolve(upgradedDef.name))
            _ = readLine()
            return true
        }
    }
}
