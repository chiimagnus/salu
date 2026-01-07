/// 顶部 Tabs 渲染（轻量组件）
/// - Note: 仅负责生成单行字符串，不做布局系统。
enum TabBar {
    static func render(
        tabs: [String],
        selectedIndex: Int,
        hint: String? = nil
    ) -> String {
        let clamped = tabs.isEmpty ? 0 : max(0, min(selectedIndex, tabs.count - 1))

        var parts: [String] = []
        for (i, tab) in tabs.enumerated() {
            if i == clamped {
                parts.append("\(Terminal.inverse)\(Terminal.bold) \(tab) \(Terminal.reset)")
            } else {
                parts.append("\(Terminal.bold) \(tab) \(Terminal.reset)")
            }
        }

        var line = parts.joined(separator: " ")
        if let hint, !hint.isEmpty {
            line += " \(Terminal.dim)\(hint)\(Terminal.reset)"
        }
        return line
    }
}
