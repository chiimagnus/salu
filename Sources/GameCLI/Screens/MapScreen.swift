import GameCore

/// 地图界面
/// 显示分支地图和当前位置，让玩家选择下一个节点
enum MapScreen {
    
    // MARK: - 主界面
    
    /// 显示地图界面
    /// - Parameters:
    ///   - runState: 冒险状态
    ///   - logs: 冒险日志（跨房间）
    ///   - showLog: 是否显示冒险日志面板
    ///   - message: 可选消息
    static func show(runState: RunState, logs: [String], showLog: Bool, message: String? = nil) {
        var lines: [String] = []
        
        // 标题栏
        lines.append(contentsOf: buildHeader(runState: runState))
        lines.append("")
        
        // 玩家状态栏
        lines.append(contentsOf: buildPlayerStatus(runState: runState))
        lines.append("")
        
        // 地图显示
        lines.append(contentsOf: buildMapDisplay(runState: runState))
        lines.append("")

        // 冒险日志（可折叠）
        if showLog {
            lines.append(contentsOf: buildRunLog(logs))
            lines.append("")
        }
        
        // 消息区域
        if let msg = message {
            lines.append(msg)
            lines.append("")
        }
        
        // 可选节点提示
        lines.append(contentsOf: buildNodeSelection(runState: runState, showLog: showLog))
        
        // 清屏并打印
        Terminal.clear()
        for line in lines {
            print(line)
        }
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
    
    // MARK: - 组件构建
    
    private static func buildHeader(runState: RunState) -> [String] {
        return [
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)  🗺️ 第 \(runState.floor) 层地图   \(Terminal.dim)🎲 种子: \(runState.seed)\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)"
        ]
    }
    
    private static func buildPlayerStatus(runState: RunState) -> [String] {
        let player = runState.player
        let hpPercent = Double(player.currentHP) / Double(player.maxHP)
        let hpBar = Terminal.healthBar(percent: hpPercent, width: 15)
        let hpColor = Terminal.colorForPercent(hpPercent)
        
        var lines: [String] = [
            "  \(Terminal.bold)\(Terminal.blue)🧑 \(player.name)\(Terminal.reset)  \(hpColor)\(hpBar)\(Terminal.reset) \(player.currentHP)/\(player.maxHP) HP  \(Terminal.dim)📚 \(runState.deck.count)张牌  \(Terminal.yellow)💰 \(runState.gold)金币\(Terminal.reset)"
        ]
        
        let relicIds = runState.relicManager.all
        if relicIds.isEmpty {
            lines.append("  \(Terminal.dim)🏺 遗物：暂无\(Terminal.reset)")
        } else {
            let relicText = relicIds.compactMap { relicId -> String? in
                guard let def = RelicRegistry.get(relicId) else { return nil }
                return "\(def.icon)\(def.name)"
            }.joined(separator: "  ")
            lines.append("  \(Terminal.dim)🏺 遗物：\(Terminal.reset)\(relicText)")
        }
        
        return lines
    }
    
    private static func buildMapDisplay(runState: RunState) -> [String] {
        var lines: [String] = []
        
        lines.append("\(Terminal.bold)─────────────────── 地图 ───────────────────\(Terminal.reset)")
        lines.append("")
        
        // 按层从高到低显示（Boss 在顶部）
        let maxRow = runState.map.maxRow
        
        for row in stride(from: maxRow, through: 0, by: -1) {
            let rowNodes = runState.map.nodes(atRow: row)
            var rowLine = "  "
            
            // 检查这一层是否有可选择的节点
            let hasAccessibleNode = rowNodes.contains { $0.isAccessible }
            
            // 添加层数标记（统一8个字符宽度）
            if hasAccessibleNode {
                // 当前可选择的层 - 黄色
                rowLine += "\(Terminal.yellow)  当前→\(Terminal.reset) "
            } else if row == maxRow {
                rowLine += "\(Terminal.dim)  Boss→\(Terminal.reset) "
            } else if row == 0 {
                rowLine += "\(Terminal.dim)  起点→\(Terminal.reset) "
            } else {
                rowLine += "        "
            }
            
            // 显示该层的所有节点
            var nodeStrings: [String] = []
            for node in rowNodes {
                let nodeStr = formatNode(node)
                nodeStrings.append(nodeStr)
            }
            
            rowLine += nodeStrings.joined(separator: "  ")
            lines.append(rowLine)
        }
        
        lines.append("")
        lines.append("\(Terminal.bold)─────────────────────────────────────────────\(Terminal.reset)")
        
        return lines
    }
    
    private static func formatNode(_ node: MapNode) -> String {
        let icon = node.roomType.icon
        
        if node.isCompleted {
            // 已完成 - 绿色勾号
            return "\(Terminal.green)[✓]\(Terminal.reset)"
        } else if node.isAccessible {
            // 可选择 - 黄色高亮（当前可进入的节点）
            return "\(Terminal.bold)\(Terminal.yellow)[\(icon)]\(Terminal.reset)"
        } else {
            // 未解锁 - 灰色
            return "\(Terminal.dim)[\(icon)]\(Terminal.reset)"
        }
    }
    
    private static func buildNodeSelection(runState: RunState, showLog: Bool) -> [String] {
        var lines: [String] = []
        
        let accessibleNodes = runState.accessibleNodes
        
        if accessibleNodes.isEmpty {
            if runState.isOver {
                if runState.won {
                    lines.append("\(Terminal.bold)\(Terminal.green)🎉 恭喜通关！\(Terminal.reset)")
                } else {
                    lines.append("\(Terminal.bold)\(Terminal.red)💀 冒险结束\(Terminal.reset)")
                }
                lines.append("")
                lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
                lines.append("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[q]\(Terminal.reset) 返回主菜单")
                lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
            } else {
                lines.append("\(Terminal.dim)没有可选择的节点\(Terminal.reset)")
            }
        } else {
            lines.append("\(Terminal.bold)选择下一个节点：\(Terminal.reset)")
            lines.append("")
            
            for (index, node) in accessibleNodes.enumerated() {
                let icon = node.roomType.icon
                let name = node.roomType.displayName
                lines.append("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(icon) \(name)")
            }
            
            lines.append("")
            lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
            lines.append("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(accessibleNodes.count)]\(Terminal.reset) 选择节点  \(Terminal.cyan)[q]\(Terminal.reset) 返回  \(Terminal.red)[abandon]\(Terminal.reset) 放弃冒险")
            lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        }
        
        return lines
    }

    private static func buildRunLog(_ logs: [String], maxLines: Int = 6) -> [String] {
        var lines: [String] = []
        lines.append("\(Terminal.bold)───────────── 日志 ─────────────\(Terminal.reset)")
        
        let display = logs.suffix(maxLines)
        for line in display {
            lines.append("  \(line)")
        }
        
        let padding = maxLines - display.count
        if padding > 0 {
            for _ in 0..<padding {
                lines.append("")
            }
        }
        
        lines.append("\(Terminal.bold)────────────────────────────────────\(Terminal.reset)")
        return lines
    }
    
    // MARK: - 休息界面
    
    /// 显示休息选项界面
    static func showRestOptions(runState: RunState, message: String? = nil) {
        Terminal.clear()
        
        let player = runState.player
        let healAmount = player.maxHP * 30 / 100
        let newHP = min(player.maxHP, player.currentHP + healAmount)
        let upgradeableCount = runState.upgradeableCardIndices.count
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  💤 休息点\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          当前 HP: \(Terminal.yellow)\(player.currentHP)/\(player.maxHP)\(Terminal.reset)
          
          \(Terminal.green)[1] 休息\(Terminal.reset) - 恢复 \(healAmount) HP (→ \(newHP) HP)
          \(upgradeableCount > 0 ? "\(Terminal.blue)[2] 升级卡牌\(Terminal.reset) - 可升级 \(upgradeableCount) 张" : "\(Terminal.dim)[2] 升级卡牌 - 当前无可升级卡牌\(Terminal.reset)")
          
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1]\(Terminal.reset) 休息  \(Terminal.cyan)[2]\(Terminal.reset) 升级卡牌
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        if let message {
            print(message)
            print("")
        }
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
    
    /// 显示升级卡牌选择
    static func showRestUpgradeOptions(
        runState: RunState,
        upgradeableIndices: [Int],
        message: String? = nil
    ) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🔧 升级卡牌\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(Terminal.bold)选择一张卡牌进行升级：\(Terminal.reset)
        """)
        
        for (index, deckIndex) in upgradeableIndices.enumerated() {
            let card = runState.deck[deckIndex]
            let def = CardRegistry.require(card.cardId)
            guard let upgradedId = def.upgradedId else { continue }
            let upgradedDef = CardRegistry.require(upgradedId)
            print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(Terminal.bold)\(def.name)\(Terminal.reset) → \(Terminal.green)\(upgradedDef.name)\(Terminal.reset)")
        }
        
        print("")
        
        if let message {
            print(message)
            print("")
        }
        
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(max(1, upgradeableIndices.count))]\(Terminal.reset) 选择卡牌  \(Terminal.cyan)[q]\(Terminal.reset) 返回")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }

    /// 显示升级结果
    static func showRestUpgradeResult(originalName: String, upgradedName: String) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🔧 升级完成\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(Terminal.green)已升级：\(Terminal.reset)\(Terminal.bold)\(originalName)\(Terminal.reset) → \(Terminal.bold)\(upgradedName)\(Terminal.reset)
          
        """)
        NavigationBar.render(items: [.continueNext])
    }

    /// 显示休息结果
    static func showRestResult(healedAmount: Int, newHP: Int, maxHP: Int) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  💤 休息完成\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(Terminal.green)恢复了 \(healedAmount) HP\(Terminal.reset)
          
          当前 HP: \(Terminal.yellow)\(newHP)/\(maxHP)\(Terminal.reset)
          
        """)
        NavigationBar.render(items: [.continueNext])
    }
    
    // MARK: - 放弃冒险确认
    
    /// 显示放弃冒险确认界面
    /// - Returns: true 表示确认放弃，false 表示取消
    static func showAbandonConfirmation() -> Bool {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.red)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.red)  ⚠️ 放弃冒险确认\(Terminal.reset)
        \(Terminal.bold)\(Terminal.red)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(Terminal.yellow)你确定要放弃当前冒险吗？\(Terminal.reset)
          
          \(Terminal.dim)放弃后存档将被清除，无法恢复。\(Terminal.reset)
          
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.red)[y]\(Terminal.reset) 确认放弃  \(Terminal.cyan)[n]\(Terminal.reset) 取消
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
        Terminal.flush()
        
        while true {
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                return false
            }
            
            switch input {
            case "y", "yes":
                return true
            case "n", "no", "q":
                return false
            default:
                print("\(Terminal.red)请输入 y 或 n\(Terminal.reset)")
                print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
                Terminal.flush()
            }
        }
    }
}
