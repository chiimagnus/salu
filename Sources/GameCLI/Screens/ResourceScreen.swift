import GameCore

/// 资源管理页面（开发者工具）
///
/// 用途：
/// - 查看当前注册的卡牌/敌人/遗物
/// - 查看关键"池子"内容（如 Act1 遭遇池）
/// - 提供基础统计洞察（数量、分组、双敌人占比等）
enum ResourceScreen {
    static func show() {
        Terminal.clear()
        var lines: [String] = []
        lines.append(contentsOf: buildHeaderLines())
        lines.append(contentsOf: buildCardsSectionLines())
        lines.append(contentsOf: buildStatusesSectionLines())
        lines.append(contentsOf: buildConsumablesSectionLines())
        lines.append(contentsOf: buildEventsSectionLines())
        lines.append(contentsOf: buildEnemiesAndEncountersSectionLines())
        lines.append(contentsOf: buildRelicsSectionLines())
        for line in lines {
            print(line)
        }
        // 渲染导航栏
        NavigationBar.render(items: [.back])
    }

    private static func buildHeaderLines() -> [String] {
        [
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)  📦 资源管理（内容与池子一览）\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)",
            ""
        ]
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

        // Act3
        lines.append("")
        lines.append("\(Terminal.bold)Act3 敌人池\(Terminal.reset)")
        lines.append("  普通敌人（weak）数量：\(Terminal.yellow)\(Act3EnemyPool.weak.count)\(Terminal.reset)")
        lines.append("  精英敌人（medium）数量：\(Terminal.yellow)\(Act3EnemyPool.medium.count)\(Terminal.reset)")
        lines.append("")

        lines.append("  \(Terminal.bold)普通敌人（weak）\(Terminal.reset)")
        for id in Act3EnemyPool.weak.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }
        lines.append("")

        lines.append("  \(Terminal.bold)精英敌人（medium）\(Terminal.reset)")
        for id in Act3EnemyPool.medium.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        lines.append("")
        lines.append("\(Terminal.bold)🧩 遭遇池（Act3EncounterPool.weak）\(Terminal.reset)")
        let act3Encounters = Act3EncounterPool.weak
        let act3MultiCount = act3Encounters.filter { $0.enemyIds.count > 1 }.count
        let act3TotalCount = max(1, act3Encounters.count)
        let act3MultiPercent = (act3MultiCount * 100) / act3TotalCount
        lines.append("  总遭遇数：\(Terminal.yellow)\(act3Encounters.count)\(Terminal.reset)  |  双敌人遭遇：\(Terminal.yellow)\(act3MultiCount)\(Terminal.reset)（约 \(act3MultiPercent)%）")
        lines.append("")

        for (i, enc) in act3Encounters.enumerated() {
            let names = enc.enemyIds.map { id in EnemyRegistry.require(id).name }.joined(separator: " + ")
            lines.append("    [\(i + 1)] \(names)")
        }

        // Enemy Registry
        lines.append("")
        lines.append("\(Terminal.bold)📚 EnemyRegistry（全部已注册敌人）\(Terminal.reset)")
        lines.append("  总数：\(Terminal.yellow)\(EnemyRegistry.allEnemyIds.count)\(Terminal.reset)")
        lines.append("")
        for id in EnemyRegistry.allEnemyIds {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        return lines
    }

    private static func buildStatusesSectionLines() -> [String] {
        var lines: [String] = []
        lines.append("")
        lines.append("\(Terminal.bold)🧬 状态（StatusRegistry）\(Terminal.reset)")

        let ids = StatusRegistry.allStatusIds
        lines.append("  总数：\(Terminal.yellow)\(ids.count)\(Terminal.reset)")
        lines.append("")

        for id in ids {
            let def = StatusRegistry.require(id)
            let polarity = def.isPositive ? "\(Terminal.green)正面\(Terminal.reset)" : "\(Terminal.red)负面\(Terminal.reset)"

            let decayText: String
            switch def.decay {
            case .none:
                decayText = "不递减"
            case .turnEnd(let decreaseBy):
                decayText = "回合结束 -\(decreaseBy)"
            }

            let phaseSummary = [
                "出伤:\(formatPhase(def.outgoingDamagePhase))",
                "入伤:\(formatPhase(def.incomingDamagePhase))",
                "格挡:\(formatPhase(def.blockPhase))",
                "prio:\(def.priority)",
            ].joined(separator: "  ")

            lines.append("  - \(def.icon)\(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)  \(polarity)  \(Terminal.dim)\(decayText)  \(phaseSummary)\(Terminal.reset)")
        }

        lines.append("")
        return lines
    }

    private static func formatPhase(_ phase: ModifierPhase?) -> String {
        guard let phase else { return "-" }
        switch phase {
        case .add:
            return "add"
        case .multiply:
            return "mul"
        }
    }

    private static func buildConsumablesSectionLines() -> [String] {
        var lines: [String] = []
        lines.append("")
        lines.append("\(Terminal.bold)🧪 消耗品（ConsumableRegistry）\(Terminal.reset)")

        let ids = ConsumableRegistry.allConsumableIds
        lines.append("  已注册：\(Terminal.yellow)\(ids.count)\(Terminal.reset)  |  商店池：\(Terminal.yellow)\(ConsumableRegistry.shopConsumableIds.count)\(Terminal.reset)")
        lines.append("")

        for id in ids {
            let def = ConsumableRegistry.require(id)
            let battle = def.usableInBattle ? "\(Terminal.green)战斗内可用\(Terminal.reset)" : "\(Terminal.dim)战斗内不可用\(Terminal.reset)"
            let outside = def.usableOutsideBattle ? "\(Terminal.green)战斗外可用\(Terminal.reset)" : "\(Terminal.dim)战斗外不可用\(Terminal.reset)"
            lines.append("  - \(def.icon)\(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)  \(Terminal.dim)\(def.rarity.rawValue)\(Terminal.reset)  \(battle)  \(outside)")
            lines.append("    \(Terminal.dim)\(def.description)\(Terminal.reset)")
        }

        lines.append("")
        return lines
    }

    private static func buildEventsSectionLines() -> [String] {
        var lines: [String] = []
        lines.append("")
        lines.append("\(Terminal.bold)🧭 事件（EventRegistry）\(Terminal.reset)")

        let ids = EventRegistry.allEventIds
        lines.append("  总数：\(Terminal.yellow)\(ids.count)\(Terminal.reset)")
        lines.append("")

        for id in ids {
            let def = EventRegistry.require(id)
            lines.append("  - \(def.icon)\(def.name)  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        lines.append("")
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
