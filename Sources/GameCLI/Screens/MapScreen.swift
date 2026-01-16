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
        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
    
    // MARK: - 组件构建
    
    private static func buildHeader(runState: RunState) -> [String] {
        return [
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)  🗺️ \(L10n.text("第", "Floor")) \(runState.floor) \(L10n.text("层地图", "Map"))   \(Terminal.dim)🎲 \(L10n.text("种子", "Seed")): \(runState.seed)\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)"
        ]
    }
    
    private static func buildPlayerStatus(runState: RunState) -> [String] {
        let player = runState.player
        let hpPercent = Double(player.currentHP) / Double(player.maxHP)
        let hpBar = Terminal.healthBar(percent: hpPercent, width: 15)
        let hpColor = Terminal.colorForPercent(hpPercent)
        
        var lines: [String] = [
            "  \(Terminal.bold)\(Terminal.blue)🧑 \(L10n.resolve(player.name))\(Terminal.reset)  \(hpColor)\(hpBar)\(Terminal.reset) \(player.currentHP)/\(player.maxHP) HP  \(Terminal.dim)📚 \(runState.deck.count)\(L10n.text("张牌", " cards"))  \(Terminal.yellow)💰 \(runState.gold)\(L10n.text("金币", " gold"))\(Terminal.reset)"
        ]
        
        let relicIds = runState.relicManager.all
        if relicIds.isEmpty {
            lines.append("  \(Terminal.dim)🏺 \(L10n.text("遗物", "Relics"))：\(L10n.text("暂无", "None"))\(Terminal.reset)")
        } else {
            let relicText = relicIds.compactMap { relicId -> String? in
                guard let def = RelicRegistry.get(relicId) else { return nil }
                return "\(def.icon)\(L10n.resolve(def.name))"
            }.joined(separator: "  ")
            lines.append("  \(Terminal.dim)🏺 \(L10n.text("遗物", "Relics"))：\(Terminal.reset)\(relicText)")
        }
        
        return lines
    }
    
    private static func buildMapDisplay(runState: RunState) -> [String] {
        var lines: [String] = []
        
        lines.append("\(Terminal.bold)─────────────────── \(L10n.text("地图", "Map")) ───────────────────\(Terminal.reset)")
        lines.append("")

        let mapNodes = runState.map
        let maxRow = mapNodes.maxRow
        let mapSpacing = 6
        let mapNodeWidth = 3
        let mapPrefixWidth = 8
        let maxNodesPerRow = (0...maxRow).map { mapNodes.nodes(atRow: $0).count }.max() ?? 1
        let mapWidth = max(1, (maxNodesPerRow - 1) * mapSpacing + mapNodeWidth)
        let mapHeight = maxRow * 2 + 1
        var canvas = Array(repeating: Array(repeating: Character(" "), count: mapWidth), count: mapHeight)
        var nodePositions: [String: (x: Int, y: Int)] = [:]
        var rowNodesByPosition: [Int: [Int: MapNode]] = [:]
        var rowNodesByRow: [Int: [MapNode]] = [:]

        for row in 0...maxRow {
            let rowNodes = mapNodes.nodes(atRow: row).sorted { $0.column < $1.column }
            rowNodesByRow[row] = rowNodes
            guard !rowNodes.isEmpty else { continue }
            let rowWidth = (rowNodes.count - 1) * mapSpacing + mapNodeWidth
            let offset = max(0, (mapWidth - rowWidth) / 2)
            let rowY = (maxRow - row) * 2
            for node in rowNodes {
                let nodeX = offset + node.column * mapSpacing
                nodePositions[node.id] = (nodeX, rowY)
                rowNodesByPosition[row, default: [:]][nodeX] = node
            }
        }

        func drawLine(from: (x: Int, y: Int), to: (x: Int, y: Int)) {
            var x0 = from.x
            var y0 = from.y
            let x1 = to.x
            let y1 = to.y
            let dx = abs(x1 - x0)
            let sx = x0 < x1 ? 1 : -1
            let dy = -abs(y1 - y0)
            let sy = y0 < y1 ? 1 : -1
            var err = dx + dy

            while !(x0 == x1 && y0 == y1) {
                let prevX = x0
                let prevY = y0
                let e2 = 2 * err
                if e2 >= dy {
                    err += dy
                    x0 += sx
                }
                if e2 <= dx {
                    err += dx
                    y0 += sy
                }
                if x0 == x1 && y0 == y1 { break }
                guard y0 >= 0, y0 < mapHeight, x0 >= 0, x0 < mapWidth else { continue }
                let stepX = x0 - prevX
                let stepY = y0 - prevY
                let lineChar: Character
                if stepX == 0 {
                    lineChar = "│"
                } else if stepY == 0 {
                    lineChar = "─"
                } else if (stepX > 0 && stepY > 0) || (stepX < 0 && stepY < 0) {
                    lineChar = "╲"
                } else {
                    lineChar = "╱"
                }
                if canvas[y0][x0] == " " {
                    canvas[y0][x0] = lineChar
                }
            }
        }

        for node in mapNodes {
            guard let fromPosition = nodePositions[node.id] else { continue }
            for targetId in node.connections {
                guard let toPosition = nodePositions[targetId] else { continue }
                drawLine(from: fromPosition, to: toPosition)
            }
        }

        func rowPrefix(row: Int, hasAccessibleNode: Bool) -> String {
            if hasAccessibleNode {
                return "\(Terminal.yellow)  \(L10n.text("当前", "Now"))→\(Terminal.reset) "
            }
            if row == maxRow {
                return "\(Terminal.dim)  \(L10n.text("Boss", "Boss"))→\(Terminal.reset) "
            }
            if row == 0 {
                return "\(Terminal.dim)  \(L10n.text("起点", "Start"))→\(Terminal.reset) "
            }
            return String(repeating: " ", count: mapPrefixWidth)
        }

        for y in 0..<mapHeight {
            let isNodeRow = y % 2 == 0
            if isNodeRow {
                let row = maxRow - y / 2
                let rowNodes = rowNodesByRow[row] ?? []
                let nodesByPosition = rowNodesByPosition[row] ?? [:]
                var line = ""
                var index = 0
                while index < mapWidth {
                    if let node = nodesByPosition[index] {
                        line += formatNode(node)
                        index += mapNodeWidth
                    } else {
                        line.append(canvas[y][index])
                        index += 1
                    }
                }
                let prefix = rowPrefix(row: row, hasAccessibleNode: rowNodes.contains { $0.isAccessible })
                lines.append(prefix + line)
            } else {
                let prefix = String(repeating: " ", count: mapPrefixWidth)
                let line = String(canvas[y])
                lines.append(prefix + "\(Terminal.dim)\(line)\(Terminal.reset)")
            }
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
            lines.append("\(Terminal.bold)\(Terminal.green)🎉 \(L10n.text("恭喜通关！", "Congratulations!"))\(Terminal.reset)")
        } else {
            lines.append("\(Terminal.bold)\(Terminal.red)💀 \(L10n.text("冒险结束", "Adventure ended"))\(Terminal.reset)")
        }
        lines.append("")
        lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        lines.append("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("返回主菜单", "Back to Menu"))")
        lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
    } else {
        lines.append("\(Terminal.dim)\(L10n.text("没有可选择的节点", "No selectable nodes"))\(Terminal.reset)")
    }
} else {
    lines.append("\(Terminal.bold)\(L10n.text("选择下一个节点", "Choose the next node"))：\(Terminal.reset)")
    lines.append("")
    
    for (index, node) in accessibleNodes.enumerated() {
        let icon = node.roomType.icon
        let name = node.roomType.displayName(language: L10n.language)
        lines.append("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(icon) \(name)")
    }
            
            lines.append("")
            lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
    lines.append("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(accessibleNodes.count)]\(Terminal.reset) \(L10n.text("选择节点", "Select node"))  \(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("返回", "Back"))  \(Terminal.red)[abandon]\(Terminal.reset) \(L10n.text("放弃冒险", "Abandon run"))")
            lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        }
        
        return lines
    }

    private static func buildRunLog(_ logs: [String], maxLines: Int = 6) -> [String] {
        var lines: [String] = []
        lines.append("\(Terminal.bold)───────────── \(L10n.text("日志", "Log")) ─────────────\(Terminal.reset)")
        
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
    
    /// 显示休息选项界面（据点化：新增与艾拉对话选项）
    static func showRestOptions(runState: RunState, message: String? = nil) {
        Terminal.clear()
        
        let player = runState.player
        let healAmount = player.maxHP * 30 / 100
        let newHP = min(player.maxHP, player.currentHP + healAmount)
        let upgradeableCount = runState.upgradeableCardIndices.count
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🏠 \(L10n.text("灰烬营地", "Ash Camp"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(Terminal.dim)\(L10n.text("艾拉在营地中等待着你的归来。", "Aira waits for your return at the camp."))\(Terminal.reset)
          
          \(L10n.text("当前 HP", "Current HP")): \(Terminal.yellow)\(player.currentHP)/\(player.maxHP)\(Terminal.reset)
          
          \(Terminal.green)[1] \(L10n.text("休息", "Rest"))\(Terminal.reset) - \(L10n.text("恢复", "Recover")) \(healAmount) HP (→ \(newHP) HP)
          \(upgradeableCount > 0 ? "\(Terminal.blue)[2] \(L10n.text("升级卡牌", "Upgrade Card"))\(Terminal.reset) - \(L10n.text("可升级", "Upgradable")) \(upgradeableCount) \(L10n.text("张", "cards"))" : "\(Terminal.dim)[2] \(L10n.text("升级卡牌", "Upgrade Card")) - \(L10n.text("当前无可升级卡牌", "No upgradable cards"))\(Terminal.reset)")
          \(Terminal.magenta)[3] \(L10n.text("与艾拉对话", "Talk to Aira"))\(Terminal.reset) - \(L10n.text("听听她想说的话", "Hear what she has to say"))
          
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1]\(Terminal.reset) \(L10n.text("休息", "Rest"))  \(Terminal.cyan)[2]\(Terminal.reset) \(L10n.text("升级", "Upgrade"))  \(Terminal.cyan)[3]\(Terminal.reset) \(L10n.text("对话", "Talk"))
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        if let message {
            print(message)
            print("")
        }
        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
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
        \(Terminal.bold)\(Terminal.cyan)  🔧 \(L10n.text("升级卡牌", "Upgrade Card"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(Terminal.bold)\(L10n.text("选择一张卡牌进行升级", "Choose a card to upgrade"))：\(Terminal.reset)
        """)
        
        for (index, deckIndex) in upgradeableIndices.enumerated() {
            let card = runState.deck[deckIndex]
            let def = CardRegistry.require(card.cardId)
            guard let upgradedId = def.upgradedId else { continue }
            let upgradedDef = CardRegistry.require(upgradedId)
            print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(Terminal.bold)\(L10n.resolve(def.name))\(Terminal.reset) → \(Terminal.green)\(L10n.resolve(upgradedDef.name))\(Terminal.reset)")
        }
        
        print("")
        
        if let message {
            print(message)
            print("")
        }
        
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(max(1, upgradeableIndices.count))]\(Terminal.reset) \(L10n.text("选择卡牌", "Select card"))  \(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("返回", "Back"))")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }

    /// 显示升级结果
    static func showRestUpgradeResult(originalName: String, upgradedName: String) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🔧 \(L10n.text("升级完成", "Upgrade Complete"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(Terminal.green)\(L10n.text("已升级", "Upgraded"))：\(Terminal.reset)\(Terminal.bold)\(originalName)\(Terminal.reset) → \(Terminal.bold)\(upgradedName)\(Terminal.reset)
          
        """)
        NavigationBar.render(items: [.continueNext])
    }

    /// 显示休息结果
    static func showRestResult(healedAmount: Int, newHP: Int, maxHP: Int) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  💤 \(L10n.text("休息完成", "Rest Complete"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(Terminal.green)\(L10n.text("恢复了", "Recovered")) \(healedAmount) HP\(Terminal.reset)
          
          \(L10n.text("当前 HP", "Current HP")): \(Terminal.yellow)\(newHP)/\(maxHP)\(Terminal.reset)
          
        """)
        NavigationBar.render(items: [.continueNext])
    }

    /// 显示与艾拉对话界面
    static func showAiraDialogue(title: String, content: String, effect: String?) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.magenta)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.magenta)  💜 \(title)\(Terminal.reset)
        \(Terminal.bold)\(Terminal.magenta)═══════════════════════════════════════════════\(Terminal.reset)
        
        """)
        
        // 打印对话内容，每行缩进
        for line in content.split(separator: "\n", omittingEmptySubsequences: false) {
            print("  \(Terminal.dim)\(line)\(Terminal.reset)")
        }
        
        print("")
        
        if let effect {
            print("  \(Terminal.green)\(effect)\(Terminal.reset)")
            print("")
        }
        
        NavigationBar.render(items: [.continueNext])
    }
    
    // MARK: - 放弃冒险确认
    
    /// 显示放弃冒险确认界面
    /// - Returns: true 表示确认放弃，false 表示取消
    static func showAbandonConfirmation() -> Bool {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.red)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.red)  ⚠️ \(L10n.text("放弃冒险确认", "Confirm Abandon"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.red)═══════════════════════════════════════════════\(Terminal.reset)
        
          \(Terminal.yellow)\(L10n.text("你确定要放弃当前冒险吗？", "Are you sure you want to abandon this run?"))\(Terminal.reset)
          
          \(Terminal.dim)\(L10n.text("放弃后存档将被清除，无法恢复。", "The save will be cleared and cannot be restored."))\(Terminal.reset)
          
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.red)[y]\(Terminal.reset) \(L10n.text("确认放弃", "Confirm"))  \(Terminal.cyan)[n]\(Terminal.reset) \(L10n.text("取消", "Cancel"))
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
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
            print("\(Terminal.red)\(L10n.text("请输入 y 或 n", "Please enter y or n"))\(Terminal.reset)")
            print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
            Terminal.flush()
        }
    }
}
}
