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
}
