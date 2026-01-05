import Foundation

/// Run 日志服务：负责把“用户可见日志”落盘为纯文本（调试用途）
final class RunLogService: @unchecked Sendable {
    private let store: RunLogStore
    private let formatter: ISO8601DateFormatter
    
    init(store: RunLogStore) {
        self.store = store
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.formatter = f
    }
    
    func append(uiLine: String) {
        // 去掉 ANSI，并避免换行污染日志
        let plain = uiLine
            .strippingANSICodes()
            .replacingOccurrences(of: "\n", with: " ")
        
        let ts = formatter.string(from: Date())
        store.appendLine("[\(ts)] \(plain)\n")
    }
    
    func appendSystem(_ text: String) {
        let ts = formatter.string(from: Date())
        store.appendLine("\n[\(ts)] === \(text) ===\n")
    }
    
    func clear() {
        store.clear()
    }
}


