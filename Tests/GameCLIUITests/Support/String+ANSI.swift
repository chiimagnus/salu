import Foundation

extension String {
    /// 移除 ANSI 控制码（用于稳定断言，避免颜色/清屏等控制码干扰）。
    func strippingANSICodes() -> String {
        // ESC [ ... command
        replacingOccurrences(
            of: "\u{001B}\\[[0-9;?]*[ -/]*[@-~]",
            with: "",
            options: .regularExpression
        )
    }
}


