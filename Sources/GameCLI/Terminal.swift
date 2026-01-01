@preconcurrency import Foundation

/// 终端控制工具
/// 提供 ANSI 颜色代码和屏幕控制功能
enum Terminal {
    
    // MARK: - ANSI 颜色代码
    
    static let reset = "\u{001B}[0m"
    static let red = "\u{001B}[31m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let magenta = "\u{001B}[35m"
    static let cyan = "\u{001B}[36m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    
    // MARK: - 屏幕控制码
    
    static let clearScreen = "\u{001B}[2J"      // 清屏
    static let cursorHome = "\u{001B}[H"        // 光标移到左上角
    static let hideCursor = "\u{001B}[?25l"     // 隐藏光标
    static let showCursor = "\u{001B}[?25h"     // 显示光标
    
    // MARK: - 便捷方法
    
    /// 清屏并将光标移到左上角
    static func clear() {
        print(clearScreen + cursorHome, terminator: "")
    }
    
    /// 刷新输出缓冲区
    static func flush() {
        fflush(stdout)
    }
    
    /// 生成血量条
    /// - Parameters:
    ///   - percent: 血量百分比 (0.0 - 1.0)
    ///   - width: 血量条宽度
    /// - Returns: 血量条字符串
    static func healthBar(percent: Double, width: Int = 20) -> String {
        let clamped = max(0, min(1, percent))
        let filledWidth = Int(Double(width) * clamped)
        let emptyWidth = width - filledWidth
        return "[" + String(repeating: "█", count: filledWidth) + String(repeating: "░", count: emptyWidth) + "]"
    }
    
    /// 根据百分比返回对应颜色
    static func colorForPercent(_ percent: Double) -> String {
        if percent > 0.5 {
            return green
        } else if percent > 0.25 {
            return yellow
        } else {
            return red
        }
    }
}

