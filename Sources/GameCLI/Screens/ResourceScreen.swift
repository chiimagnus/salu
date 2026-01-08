import GameCore

/// 资源管理页面（开发者工具）
///
/// 用途：
/// - 查看当前注册的卡牌/敌人/遗物
/// - 查看关键“池子”内容（如 Act1 遭遇池）
/// - 提供基础统计洞察（数量、分组、双敌人占比等）
enum ResourceScreen {
    static func show() {
        if TerminalKeyReader.isInteractiveTTY() {
            showInteractive()
        } else {
            showNonInteractive()
        }
    }

    private static func showNonInteractive() {
        // 保持旧行为：一次性输出全量内容（用于测试/日志/管道场景）。
        Terminal.clear()
        for line in buildAllLines() {
            print(line)
        }
    }

    private static func showInteractive() {
        var selectedIndex = 0
        let tabs = ["卡牌", "敌人/遭遇", "遗物"]
        var offset = 0
        let pageSize = 24
        var shouldExit = false

        var keyReader = TerminalKeyReader()

        func contentLines(for index: Int) -> [String] {
            switch index {
            case 0:
                return buildCardsSectionLines()
            case 1:
                return buildEnemiesAndEncountersSectionLines()
            case 2:
                return buildRelicsSectionLines()
            default:
                return []
            }
        }

        func redraw() {
            Terminal.clear()

            var lines: [String] = []
            lines.append(contentsOf: buildHeaderLines())
            lines.append(TabBar.render(tabs: tabs, selectedIndex: selectedIndex, hint: "（Tab 切换）"))
            lines.append("")
            let allContent = contentLines(for: selectedIndex)
            let clampedOffset = max(0, min(offset, max(0, allContent.count - 1)))
            offset = clampedOffset
            let end = min(allContent.count, clampedOffset + pageSize)
            if clampedOffset < end {
                lines.append(contentsOf: allContent[clampedOffset..<end])
            }
            lines.append("")
            lines.append("\(Terminal.dim)↑↓ 滚动  Tab 切换分栏  输入 0 返回\(Terminal.reset)")
            lines.append("")
            lines.append("\(Terminal.green)>>>\(Terminal.reset) ")

            for line in lines {
                print(line, terminator: line == lines.last ? "" : "\n")
            }
            Terminal.flush()
        }

        // 初次绘制
        redraw()

        // 即时模式循环（Tab/方向键即时响应）
        TerminalKeyReader.withRawMode {
            print(Terminal.hideCursor, terminator: "")
            defer {
                print(Terminal.showCursor, terminator: "")
                Terminal.flush()
            }

            while !shouldExit {
                let key = keyReader.readKey()
                switch key {
                case .tab:
                    selectedIndex = (selectedIndex + 1) % max(1, tabs.count)
                    offset = 0
                    redraw()

                case .shiftTab:
                    let count = max(1, tabs.count)
                    selectedIndex = (selectedIndex - 1 + count) % count
                    offset = 0
                    redraw()

                case .arrowUp:
                    offset = max(0, offset - 1)
                    redraw()

                case .arrowDown:
                    offset += 1
                    redraw()

                case .printable(let c):
                    // 输入 0 或 q 退出，并回显字符
                    if c == "0" || c == "q" || c == "Q" {
                        // 回显输入的字符
                        print(c)
                        Terminal.flush()
                        shouldExit = true
                    }

                default:
                    break
                }
            }
        }
    }

    private static func buildHeaderLines() -> [String] {
        [
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)  📦 资源管理（内容与池子一览）\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)",
            ""
        ]
    }

    private static func buildAllLines() -> [String] {
        var lines: [String] = []
        lines.append(contentsOf: buildHeaderLines())
        lines.append(contentsOf: buildCardsSectionLines())
        lines.append(contentsOf: buildEnemiesAndEncountersSectionLines())
        lines.append(contentsOf: buildRelicsSectionLines())
        return lines
    }

    private static func buildCardsSectionLines() -> [String] {
        var lines: [String] = []

        // MARK: - Cards
        let cardIds = CardRegistry.allCardIds
        let cardDefs = cardIds.map { id in (id, CardRegistry.require(id)) }

        let attacks = cardDefs.filter { $0.1.type == .attack }
        let skills = cardDefs.filter { $0.1.type == .skill }
        let powers = cardDefs.filter { $0.1.type == .power }

        lines.append("\(Terminal.bold)🃏 卡牌（Registry）\(Terminal.reset)")
        lines.append("  总数：\(Terminal.yellow)\(cardIds.count)\(Terminal.reset)  |  攻击：\(Terminal.yellow)\(attacks.count)\(Terminal.reset)  技能：\(Terminal.yellow)\(skills.count)\(Terminal.reset)  能力：\(Terminal.yellow)\(powers.count)\(Terminal.reset)")
        lines.append("")

        lines.append(contentsOf: formatCardGroup(title: "⚔️ 攻击牌", cards: attacks))
        lines.append(contentsOf: formatCardGroup(title: "🛡️ 技能牌", cards: skills))
        lines.append(contentsOf: formatCardGroup(title: "✨ 能力牌", cards: powers))

        return lines
    }

    private static func buildEnemiesAndEncountersSectionLines() -> [String] {
        var lines: [String] = []

        // MARK: - Enemies & Encounters
        lines.append("")
        lines.append("\(Terminal.bold)👹 敌人池/遭遇池（Act1/Act2）\(Terminal.reset)")
        lines.append("")

        lines.append("\(Terminal.bold)Act1 敌人池\(Terminal.reset)")
        lines.append("  普通敌人（weak）数量：\(Terminal.yellow)\(Act1EnemyPool.weak.count)\(Terminal.reset)")
        lines.append("  精英敌人（medium）数量：\(Terminal.yellow)\(Act1EnemyPool.medium.count)\(Terminal.reset)")
        lines.append("")

        lines.append("  \(Terminal.bold)普通敌人（weak）\(Terminal.reset)")
        for id in Act1EnemyPool.weak.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }
        lines.append("")

        lines.append("  \(Terminal.bold)精英敌人（medium）\(Terminal.reset)")
        for id in Act1EnemyPool.medium.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        lines.append("")
        lines.append("\(Terminal.bold)🧩 遭遇池（Act1EncounterPool.weak）\(Terminal.reset)")
        let encounters = Act1EncounterPool.weak
        let multiCount = encounters.filter { $0.enemyIds.count > 1 }.count
        let totalCount = max(1, encounters.count)
        let multiPercent = (multiCount * 100) / totalCount
        lines.append("  总遭遇数：\(Terminal.yellow)\(encounters.count)\(Terminal.reset)  |  双敌人遭遇：\(Terminal.yellow)\(multiCount)\(Terminal.reset)（约 \(multiPercent)%）")
        lines.append("")

        for (i, enc) in encounters.enumerated() {
            let names = enc.enemyIds.map { id in EnemyRegistry.require(id).name }.joined(separator: " + ")
            lines.append("    [\(i + 1)] \(names)")
        }

        // Act2
        lines.append("")
        lines.append("\(Terminal.bold)Act2 敌人池\(Terminal.reset)")
        lines.append("  普通敌人（weak）数量：\(Terminal.yellow)\(Act2EnemyPool.weak.count)\(Terminal.reset)")
        lines.append("  精英敌人（medium）数量：\(Terminal.yellow)\(Act2EnemyPool.medium.count)\(Terminal.reset)")
        lines.append("")

        lines.append("  \(Terminal.bold)普通敌人（weak）\(Terminal.reset)")
        for id in Act2EnemyPool.weak.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }
        lines.append("")

        lines.append("  \(Terminal.bold)精英敌人（medium）\(Terminal.reset)")
        for id in Act2EnemyPool.medium.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        lines.append("")
        lines.append("\(Terminal.bold)🧩 遭遇池（Act2EncounterPool.weak）\(Terminal.reset)")
        let act2Encounters = Act2EncounterPool.weak
        let act2MultiCount = act2Encounters.filter { $0.enemyIds.count > 1 }.count
        let act2TotalCount = max(1, act2Encounters.count)
        let act2MultiPercent = (act2MultiCount * 100) / act2TotalCount
        lines.append("  总遭遇数：\(Terminal.yellow)\(act2Encounters.count)\(Terminal.reset)  |  双敌人遭遇：\(Terminal.yellow)\(act2MultiCount)\(Terminal.reset)（约 \(act2MultiPercent)%）")
        lines.append("")

        for (i, enc) in act2Encounters.enumerated() {
            let names = enc.enemyIds.map { id in EnemyRegistry.require(id).name }.joined(separator: " + ")
            lines.append("    [\(i + 1)] \(names)")
        }

        return lines
    }

    private static func buildRelicsSectionLines() -> [String] {
        var lines: [String] = []

        // MARK: - Relics
        lines.append("")
        lines.append("\(Terminal.bold)🏺 遗物（Registry）\(Terminal.reset)")

        let droppable = RelicPool.availableRelicIds(excluding: [])
        let allRelicIds = RelicRegistry.allRelicIds

        lines.append("  已注册：\(Terminal.yellow)\(allRelicIds.count)\(Terminal.reset)  |  可掉落（排除起始）：\(Terminal.yellow)\(droppable.count)\(Terminal.reset)")
        lines.append("")

        let groupedByRarity: [(RelicRarity, [RelicID])] = [
            (.starter, allRelicIds.filter { RelicRegistry.require($0).rarity == .starter }),
            (.common, allRelicIds.filter { RelicRegistry.require($0).rarity == .common }),
            (.uncommon, allRelicIds.filter { RelicRegistry.require($0).rarity == .uncommon }),
            (.rare, allRelicIds.filter { RelicRegistry.require($0).rarity == .rare }),
            (.boss, allRelicIds.filter { RelicRegistry.require($0).rarity == .boss }),
            (.event, allRelicIds.filter { RelicRegistry.require($0).rarity == .event }),
        ]

        for (rarity, ids) in groupedByRarity where !ids.isEmpty {
            lines.append("  \(Terminal.bold)\(rarity.rawValue)（\(ids.count)）\(Terminal.reset)")
            for id in ids.sorted(by: { $0.rawValue < $1.rawValue }) {
                let def = RelicRegistry.require(id)
                lines.append("    - \(def.icon)\(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)  \(Terminal.dim)\(def.description)\(Terminal.reset)")
            }
            lines.append("")
        }

        return lines
    }
    
    private static func formatCardGroup(
        title: String,
        cards: [(CardID, any CardDefinition.Type)]
    ) -> [String] {
        var lines: [String] = []
        lines.append("  \(Terminal.bold)\(title)（\(cards.count)）\(Terminal.reset)")
        
        for (id, def) in cards.sorted(by: { $0.0.rawValue < $1.0.rawValue }) {
            lines.append("    - \(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)  ◆\(def.cost)  \(Terminal.dim)\(def.rarity.rawValue)\(Terminal.reset)")
        }
        
        lines.append("")
        return lines
    }
}


