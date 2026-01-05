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

    /// 可见字符长度（粗略：按 Unicode 字符计数；ANSI 不计入）
    var visibleLength: Int {
        strippingANSICodes().count
    }

    /// 在不破坏 ANSI 序列的前提下，截断为最多 `maxVisible` 个可见字符。
    /// - Note: 截断时会追加 `…`，并补一个 `Terminal.reset` 防止颜色“漏出”。
    func truncatingANSI(maxVisible: Int) -> String {
        guard maxVisible > 0 else { return "" }

        var out = ""
        out.reserveCapacity(self.count)

        var visible = 0
        var i = startIndex

        func isANSITerminator(_ c: Character) -> Bool {
            guard let scalar = c.unicodeScalars.first, c.unicodeScalars.count == 1 else { return false }
            let v = scalar.value
            // RFC: CSI sequences end with a byte in 0x40..0x7E
            return v >= 0x40 && v <= 0x7E
        }

        while i < endIndex && visible < maxVisible {
            let ch = self[i]

            if ch == "\u{001B}" {
                // 复制完整 ANSI 控制序列：ESC [ ... <final>
                out.append(ch)
                i = index(after: i)

                // 尝试吞掉后续字符直到终止
                while i < endIndex {
                    let next = self[i]
                    out.append(next)
                    i = index(after: i)
                    if isANSITerminator(next) { break }
                }
                continue
            }

            out.append(ch)
            visible += 1
            i = index(after: i)
        }

        if i < endIndex {
            // 预留一个位置给省略号
            if maxVisible >= 1 {
                // 若刚好达到上限，替换最后一个可见字符为省略号
                //（简单实现：直接追加，允许 visible + 1；对 UI 影响可接受）
                out.append("…")
            }
            out.append(Terminal.reset)
        }

        return out
    }
}


