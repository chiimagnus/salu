/// 日志面板（横排紧凑版）
///
/// 目标：把日志显示控制在 3 行以内，同时尽量展示更多条目。
enum LogPanel {
    /// 构建日志面板的渲染行（最多 `maxLines` 行）
    static func build(
        logs: [String],
        maxLines: Int = 3,
        maxWidth: Int? = nil
    ) -> [String] {
        let width = maxWidth ?? Terminal.columns()
        let indent = "  "
        let availableWidth = max(20, width - indent.visibleLength)

        // 每条日志的最大可见长度（防止长句占满一整行）
        let entryMax = min(32, max(14, availableWidth / 3))
        let sep = "\(Terminal.dim)  │  \(Terminal.reset)"

        // 先把所有日志按“横向拼接 + 自动换行”聚合成多行
        var wrapped: [String] = [""]
        for raw in logs {
            let entry = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .truncatingANSI(maxVisible: entryMax)

            if entry.isEmpty { continue }

            let current = wrapped[wrapped.count - 1]
            let candidate = current.isEmpty ? entry : (current + sep + entry)

            if candidate.visibleLength <= availableWidth {
                wrapped[wrapped.count - 1] = candidate
            } else {
                wrapped.append(entry)
            }
        }

        // 只保留最后 maxLines 行，保证“日志面板 <= 3 行”
        var tail = Array(wrapped.suffix(maxLines))

        // 不足补空行，保证高度稳定（可选）
        if tail.count < maxLines {
            tail = Array(repeating: "", count: maxLines - tail.count) + tail
        }

        return tail.map { indent + $0 }
    }
}


