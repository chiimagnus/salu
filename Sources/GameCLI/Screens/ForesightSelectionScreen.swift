import GameCore

/// 预知选牌界面（P1）
///
/// 展示抽牌堆顶 N 张牌，让玩家选择 1 张入手。
enum ForesightSelectionScreen {
    static func render(options: [Card], fromCount: Int, message: String? = nil) {
        Terminal.clear()
        var lines: [String] = []

        lines.append("\(Terminal.bold)\(Terminal.magenta)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.magenta)  👁️ \(L10n.text("预知", "Foresee"))（\(L10n.text("查看", "View")) \(fromCount) \(L10n.text("张", "cards"))，\(L10n.text("选择 1 张入手", "choose 1"))）\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.magenta)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("")

        if options.isEmpty {
            lines.append("\(Terminal.dim)（\(L10n.text("没有可选卡牌", "No cards available"))）\(Terminal.reset)")
        } else {
            for (idx, card) in options.enumerated() {
                let def = CardRegistry.require(card.cardId)
                let typeIcon: String
                let typeLabel: String
                switch def.type {
                case .attack:
                    typeIcon = "⚔️"
                    typeLabel = L10n.text("攻击", "Attack")
                case .skill:
                    typeIcon = "🛡️"
                    typeLabel = L10n.text("技能", "Skill")
                case .power:
                    typeIcon = "💪"
                    typeLabel = L10n.text("能力", "Power")
                case .consumable:
                    typeIcon = "🧪"
                    typeLabel = L10n.text("消耗性", "Consumable")
                }
                lines.append("  \(Terminal.cyan)[\(idx + 1)]\(Terminal.reset) \(Terminal.bold)\(L10n.resolve(def.name))\(Terminal.reset)  \(Terminal.yellow)◆\(def.cost)\(Terminal.reset)  \(typeIcon)\(Terminal.dim)【\(typeLabel)】\(Terminal.reset) \(Terminal.dim)\(L10n.resolve(def.rulesText))\(Terminal.reset)")
            }
        }

        lines.append("")
        if let message, !message.isEmpty {
            lines.append(message)
            lines.append("")
        }

        lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        lines.append("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(max(1, options.count))]\(Terminal.reset) \(L10n.text("选择", "Select"))  \(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("返回主菜单（保留存档）", "Back to Menu (keep save)"))")
        lines.append("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")

        for line in lines {
            print(line)
        }

        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
}
