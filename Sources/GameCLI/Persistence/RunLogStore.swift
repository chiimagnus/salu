import Foundation

/// Run 维度日志存储（GameCLI 专用，调试用途）
protocol RunLogStore: Sendable {
    func appendLine(_ line: String)
    func clear()
}


