import GameCore

/// 预知选牌界面（P1）
///
/// 展示抽牌堆顶 N 张牌，让玩家选择 1 张入手。
enum ForesightSelectionScreen {
    static func render(options: [Card], fromCount: Int, message: String? = nil) {
        Terminal.clear()
        var lines: [String] = []

        lines.append("\(Terminal.bold)\(Terminal.magenta)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.magenta)  👁️ 预知（查看 \(fromCount) 张，选择 1 张入手）\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.magenta)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("")

        if options.isEmpty {
            lines.append("\(Terminal.dim)（没有可选卡牌）\(Terminal.reset)")
        } else {
            for (idx, card) in options.enumerated() {
                let def = CardRegistry.require(card.cardId)
                let typeIcon: String
                let typeLabel: String
                switch def.type {
                case .attack:
                    typeIcon = "⚔️"
                    typeLabel = "攻击"
                case .skill:
                    typeIcon = "🛡️"
                    typeLabel = "技能"
                case .power:
                    typeIcon = "💪"
                    typeLabel = "能力"
                case .consumable:
                    typeIcon = "🧪"
                    typeLabel = "消耗性"
                }
                lines.append("  \(Terminal.cyan)[\(idx + 1)]\(Terminal.reset) \(Terminal.bold)\(def.name)\(Terminal.reset)  \(Terminal.yellow)◆\(def.cost)\(Terminal.reset)  \(typeIcon)\(Terminal.dim)【\(typeLabel)】\(Terminal.reset) \(Terminal.dim)\(def.rulesText)\(Terminal.reset)")
            }
        }

        lines.append("")
        if let message, !message.isEmpty {
            lines.append(message)
            lines.append("")
        }

        lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        lines.append("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(max(1, options.count))]\(Terminal.reset) 选择  \(Terminal.cyan)[q]\(Terminal.reset) 返回主菜单（保留存档）")
        lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")

        for line in lines {
            print(line)
        }

        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
}
