import Foundation

extension String {
    /// 移除 ANSI 控制码（用于落盘日志/稳定对比）
    func strippingANSICodes() -> String {
        replacingOccurrences(
            of: "\u{001B}\\[[0-9;?]*[ -/]*[@-~]",
            with: "",
            options: .regularExpression
        )
    }
}


