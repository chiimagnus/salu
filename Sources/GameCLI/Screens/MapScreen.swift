import GameCore

/// 地图界面
/// 显示分支地图和当前位置，让玩家选择下一个节点
enum MapScreen {
    
    // MARK: - 主界面
    
    /// 显示地图界面
    /// - Parameters:
    ///   - runState: 冒险状态
    ///   - message: 可选消息
    static func show(runState: RunState, message: String? = nil) {
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
        
        // 消息区域
        if let msg = message {
            lines.append(msg)
            lines.append("")
        }
        
        // 可选节点提示
        lines.append(contentsOf: buildNodeSelection(runState: runState))
        
        // 清屏并打印
        Terminal.clear()
        for line in lines {
            print(line)
        }
        print("\(Terminal.green)>>>\(Terminal.reset) ", terminator: "")
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
        
        return [
            "  \(Terminal.bold)\(Terminal.blue)🧑 \(player.name)\(Terminal.reset)  \(hpColor)\(hpBar)\(Terminal.reset) \(player.currentHP)/\(player.maxHP) HP  \(Terminal.dim)📚 \(runState.deck.count)张牌\(Terminal.reset)"
        ]
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
            // 已完成 - 绿色
            return "\(Terminal.green)[\(icon)]\(Terminal.reset)"
        } else if node.isAccessible {
            // 可选择 - 绿色加粗（当前可进入的节点）
            return "\(Terminal.bold)\(Terminal.green)[\(icon)]\(Terminal.reset)"
        } else {
            // 未解锁 - 灰色
            return "\(Terminal.dim)[\(icon)]\(Terminal.reset)"
        }
    }
    
    private static func buildNodeSelection(runState: RunState) -> [String] {
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
                lines.append("\(Terminal.dim)按 Enter 返回主菜单...\(Terminal.reset)")
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
            lines.append("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(accessibleNodes.count)]\(Terminal.reset) 选择节点  \(Terminal.cyan)[q]\(Terminal.reset) 返回主菜单")
            lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        }
        
        return lines
    }
    
    // MARK: - 休息界面
    
    /// 显示休息选项界面
    static func showRestOptions(runState: RunState) {
        Terminal.clear()
        
        let player = runState.player
        let healAmount = player.maxHP * 30 / 100
        let newHP = min(player.maxHP, player.currentHP + healAmount)
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  💤 休息点\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
          当前 HP: \(Terminal.yellow)\(player.currentHP)/\(player.maxHP)\(Terminal.reset)
          
          \(Terminal.green)[1] 休息\(Terminal.reset) - 恢复 \(healAmount) HP (→ \(newHP) HP)
          
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        \(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1]\(Terminal.reset) 休息
        \(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)
        """)
        print("\(Terminal.green)>>>\(Terminal.reset) ", terminator: "")
        Terminal.flush()
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
          
        \(Terminal.dim)按 Enter 继续...\(Terminal.reset)
        """)
        Terminal.flush()
    }
}

