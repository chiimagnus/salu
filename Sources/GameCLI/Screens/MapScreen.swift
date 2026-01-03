import GameCore
import Foundation

/// 地图屏幕
/// 显示当前冒险的地图状态
enum MapScreen {
    
    /// 显示简单的地图视图
    static func show(nodes: [MapNode], paths: [MapPath]) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ═══════════════════════════════════════════
                       地图 - 第一章
        ═══════════════════════════════════════════
        \(Terminal.reset)
        """)
        
        // 从上到下显示节点（最高楼层在上）
        for node in nodes.sorted(by: { $0.floor > $1.floor }) {
            let icon = node.roomType.rawValue
            
            // 确定节点状态的样式
            let style: String
            let marker: String
            if node.isCurrentPosition {
                style = Terminal.bold + Terminal.yellow
                marker = "➤ "
            } else if node.isVisited {
                style = Terminal.dim
                marker = "✓ "
            } else if node.isAccessible {
                style = Terminal.green
                marker = "  "
            } else {
                style = Terminal.dim
                marker = "  "
            }
            
            print("\(marker)\(style)楼层 \(String(format: "%2d", node.floor)): \(icon) \(node.roomType.displayName)\(Terminal.reset)")
        }
        
        print("\n\(Terminal.dim)按 Enter 继续...\(Terminal.reset)")
    }
    
    /// 显示地图并让玩家选择下一个房间
    /// - Returns: 玩家选择的节点ID，如果取消则返回 nil
    static func showWithChoices(
        nodes: [MapNode],
        paths: [MapPath],
        nextNodes: [MapNode]
    ) -> Int? {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ═══════════════════════════════════════════
                       地图 - 第一章
        ═══════════════════════════════════════════
        \(Terminal.reset)
        """)
        
        // 按楼层分组显示
        let maxFloor = nodes.map { $0.floor }.max() ?? 0
        
        for floor in (0...maxFloor).reversed() {
            let floorNodes = nodes.filter { $0.floor == floor }
                .sorted { $0.column < $1.column }
            
            if floorNodes.isEmpty { continue }
            
            print("\n楼层 \(String(format: "%2d", floor)): ", terminator: "")
            
            for node in floorNodes {
                let icon = node.roomType.rawValue
                
                let style: String
                if node.isCurrentPosition {
                    style = Terminal.bold + Terminal.yellow
                } else if node.isVisited {
                    style = Terminal.dim
                } else if nextNodes.contains(where: { $0.id == node.id }) {
                    style = Terminal.green
                } else {
                    style = Terminal.dim
                }
                
                print("\(style)\(icon)\(Terminal.reset) ", terminator: "")
            }
        }
        
        print("\n")
        print("\(Terminal.bold)选择下一个房间：\(Terminal.reset)\n")
        
        for (index, node) in nextNodes.enumerated() {
            let icon = node.roomType.rawValue
            print("  \(index + 1). \(icon) \(node.roomType.displayName)")
        }
        
        print("\n\(Terminal.yellow)输入选择 (1-\(nextNodes.count)): \(Terminal.reset)", terminator: "")
        
        guard let input = readLine()?.trimmingCharacters(in: .whitespaces),
              let choice = Int(input),
              choice >= 1, choice <= nextNodes.count else {
            return nil
        }
        
        return nextNodes[choice - 1].id
    }
}
