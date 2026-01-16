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
            "\(Terminal.bold)\(Terminal.cyan)  📦 \(L10n.text("资源管理（内容与池子一览）", "Resources (Registries & Pools)"))\(Terminal.reset)",
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

        lines.append("\(Terminal.bold)🃏 \(L10n.text("卡牌（Registry）", "Cards (Registry)"))\(Terminal.reset)")
        lines.append("  \(L10n.text("总数", "Total"))：\(Terminal.yellow)\(cardIds.count)\(Terminal.reset)  |  \(L10n.text("攻击", "Attack"))：\(Terminal.yellow)\(attacks.count)\(Terminal.reset)  \(L10n.text("技能", "Skill"))：\(Terminal.yellow)\(skills.count)\(Terminal.reset)  \(L10n.text("能力", "Power"))：\(Terminal.yellow)\(powers.count)\(Terminal.reset)")
        lines.append("")

        lines.append(contentsOf: formatCardGroup(title: "⚔️ \(L10n.text("攻击牌", "Attack Cards"))", cards: attacks))
        lines.append(contentsOf: formatCardGroup(title: "🛡️ \(L10n.text("技能牌", "Skill Cards"))", cards: skills))
        lines.append(contentsOf: formatCardGroup(title: "✨ \(L10n.text("能力牌", "Power Cards"))", cards: powers))

        return lines
    }

    private static func buildEnemiesAndEncountersSectionLines() -> [String] {
        var lines: [String] = []

        // MARK: - Enemies & Encounters
        lines.append("")
        lines.append("\(Terminal.bold)👹 \(L10n.text("敌人池/遭遇池（Act1/Act2/Act3）", "Enemy/Encounter Pools (Act1/Act2/Act3)"))\(Terminal.reset)")
        lines.append("")

        lines.append("\(Terminal.bold)Act1 \(L10n.text("敌人池", "Enemy Pool"))\(Terminal.reset)")
        lines.append("  \(L10n.text("普通敌人（weak）数量", "Weak enemies"))：\(Terminal.yellow)\(Act1EnemyPool.weak.count)\(Terminal.reset)")
        lines.append("  \(L10n.text("精英敌人（medium）数量", "Medium enemies"))：\(Terminal.yellow)\(Act1EnemyPool.medium.count)\(Terminal.reset)")
        lines.append("")

        lines.append("  \(Terminal.bold)\(L10n.text("普通敌人（weak）", "Weak enemies"))\(Terminal.reset)")
        for id in Act1EnemyPool.weak.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }
        lines.append("")

        lines.append("  \(Terminal.bold)\(L10n.text("精英敌人（medium）", "Medium enemies"))\(Terminal.reset)")
        for id in Act1EnemyPool.medium.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        lines.append("")
        lines.append("\(Terminal.bold)🧩 \(L10n.text("遭遇池", "Encounter Pool"))（Act1EncounterPool.weak）\(Terminal.reset)")
        let encounters = Act1EncounterPool.weak
        let multiCount = encounters.filter { $0.enemyIds.count > 1 }.count
        let totalCount = max(1, encounters.count)
        let multiPercent = (multiCount * 100) / totalCount
        lines.append("  \(L10n.text("总遭遇数", "Total encounters"))：\(Terminal.yellow)\(encounters.count)\(Terminal.reset)  |  \(L10n.text("双敌人遭遇", "Multi-enemy"))：\(Terminal.yellow)\(multiCount)\(Terminal.reset)（\(L10n.text("约", "~")) \(multiPercent)%）")
        lines.append("")

        for (i, enc) in encounters.enumerated() {
            let names = enc.enemyIds.map { id in L10n.resolve(EnemyRegistry.require(id).name) }.joined(separator: " + ")
            lines.append("    [\(i + 1)] \(names)")
        }

        // Act2
        lines.append("")
        lines.append("\(Terminal.bold)Act2 \(L10n.text("敌人池", "Enemy Pool"))\(Terminal.reset)")
        lines.append("  \(L10n.text("普通敌人（weak）数量", "Weak enemies"))：\(Terminal.yellow)\(Act2EnemyPool.weak.count)\(Terminal.reset)")
        lines.append("  \(L10n.text("精英敌人（medium）数量", "Medium enemies"))：\(Terminal.yellow)\(Act2EnemyPool.medium.count)\(Terminal.reset)")
        lines.append("")

        lines.append("  \(Terminal.bold)\(L10n.text("普通敌人（weak）", "Weak enemies"))\(Terminal.reset)")
        for id in Act2EnemyPool.weak.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }
        lines.append("")

        lines.append("  \(Terminal.bold)\(L10n.text("精英敌人（medium）", "Medium enemies"))\(Terminal.reset)")
        for id in Act2EnemyPool.medium.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        // Act2 Boss（用于 P2 核对：Act2 Boss 是否为赛弗）
        lines.append("")
        lines.append("  \(Terminal.bold)\(L10n.text("Boss（Act2）", "Boss (Act2)"))\(Terminal.reset)")
        do {
            let id = Act2EnemyPool.boss
            let def = EnemyRegistry.require(id)
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        lines.append("")
        lines.append("\(Terminal.bold)🧩 \(L10n.text("遭遇池", "Encounter Pool"))（Act2EncounterPool.weak）\(Terminal.reset)")
        let act2Encounters = Act2EncounterPool.weak
        let act2MultiCount = act2Encounters.filter { $0.enemyIds.count > 1 }.count
        let act2TotalCount = max(1, act2Encounters.count)
        let act2MultiPercent = (act2MultiCount * 100) / act2TotalCount
        lines.append("  \(L10n.text("总遭遇数", "Total encounters"))：\(Terminal.yellow)\(act2Encounters.count)\(Terminal.reset)  |  \(L10n.text("双敌人遭遇", "Multi-enemy"))：\(Terminal.yellow)\(act2MultiCount)\(Terminal.reset)（\(L10n.text("约", "~")) \(act2MultiPercent)%）")
        lines.append("")

        for (i, enc) in act2Encounters.enumerated() {
            let names = enc.enemyIds.map { id in L10n.resolve(EnemyRegistry.require(id).name) }.joined(separator: " + ")
            lines.append("    [\(i + 1)] \(names)")
        }

        // Act3
        lines.append("")
        lines.append("\(Terminal.bold)Act3 \(L10n.text("敌人池", "Enemy Pool"))\(Terminal.reset)")
        lines.append("  \(L10n.text("普通敌人（weak）数量", "Weak enemies"))：\(Terminal.yellow)\(Act3EnemyPool.weak.count)\(Terminal.reset)")
        lines.append("  \(L10n.text("精英敌人（medium）数量", "Medium enemies"))：\(Terminal.yellow)\(Act3EnemyPool.medium.count)\(Terminal.reset)")
        lines.append("")

        lines.append("  \(Terminal.bold)\(L10n.text("普通敌人（weak）", "Weak enemies"))\(Terminal.reset)")
        for id in Act3EnemyPool.weak.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }
        lines.append("")

        lines.append("  \(Terminal.bold)\(L10n.text("精英敌人（medium）", "Medium enemies"))\(Terminal.reset)")
        for id in Act3EnemyPool.medium.sorted(by: { $0.rawValue < $1.rawValue }) {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        lines.append("")
        lines.append("\(Terminal.bold)🧩 \(L10n.text("遭遇池", "Encounter Pool"))（Act3EncounterPool.weak）\(Terminal.reset)")
        let act3Encounters = Act3EncounterPool.weak
        let act3MultiCount = act3Encounters.filter { $0.enemyIds.count > 1 }.count
        let act3TotalCount = max(1, act3Encounters.count)
        let act3MultiPercent = (act3MultiCount * 100) / act3TotalCount
        lines.append("  \(L10n.text("总遭遇数", "Total encounters"))：\(Terminal.yellow)\(act3Encounters.count)\(Terminal.reset)  |  \(L10n.text("双敌人遭遇", "Multi-enemy"))：\(Terminal.yellow)\(act3MultiCount)\(Terminal.reset)（\(L10n.text("约", "~")) \(act3MultiPercent)%）")
        lines.append("")

        for (i, enc) in act3Encounters.enumerated() {
            let names = enc.enemyIds.map { id in L10n.resolve(EnemyRegistry.require(id).name) }.joined(separator: " + ")
            lines.append("    [\(i + 1)] \(names)")
        }

        // Enemy Registry
        lines.append("")
        lines.append("\(Terminal.bold)📚 \(L10n.text("EnemyRegistry（全部已注册敌人）", "EnemyRegistry (All enemies)"))\(Terminal.reset)")
        lines.append("  \(L10n.text("总数", "Total"))：\(Terminal.yellow)\(EnemyRegistry.allEnemyIds.count)\(Terminal.reset)")
        lines.append("")
        for id in EnemyRegistry.allEnemyIds {
            let def = EnemyRegistry.require(id)
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        return lines
    }

    private static func buildStatusesSectionLines() -> [String] {
        var lines: [String] = []
        lines.append("")
        lines.append("\(Terminal.bold)🧬 \(L10n.text("状态（StatusRegistry）", "Statuses (StatusRegistry)"))\(Terminal.reset)")

        let ids = StatusRegistry.allStatusIds
        lines.append("  \(L10n.text("总数", "Total"))：\(Terminal.yellow)\(ids.count)\(Terminal.reset)")
        lines.append("")

        for id in ids {
            let def = StatusRegistry.require(id)
            let polarity = def.isPositive ? "\(Terminal.green)\(L10n.text("正面", "Positive"))\(Terminal.reset)" : "\(Terminal.red)\(L10n.text("负面", "Negative"))\(Terminal.reset)"

            let decayText: String
            switch def.decay {
            case .none:
                decayText = L10n.text("不递减", "No decay")
            case .turnEnd(let decreaseBy):
                decayText = "\(L10n.text("回合结束", "Turn end")) -\(decreaseBy)"
            }

            let phaseSummary = [
                "出伤:\(formatPhase(def.outgoingDamagePhase))",
                "入伤:\(formatPhase(def.incomingDamagePhase))",
                "格挡:\(formatPhase(def.blockPhase))",
                "prio:\(def.priority)",
            ].joined(separator: "  ")

            lines.append("  - \(def.icon)\(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)  \(polarity)  \(Terminal.dim)\(decayText)  \(phaseSummary)\(Terminal.reset)")
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
        lines.append("\(Terminal.bold)🧪 \(L10n.text("消耗性卡牌（CardRegistry）", "Consumables (CardRegistry)"))\(Terminal.reset)")

        let ids = CardRegistry.allCardIds.filter { CardRegistry.require($0).type == .consumable }
        lines.append("  \(L10n.text("已注册", "Registered"))：\(Terminal.yellow)\(ids.count)\(Terminal.reset)  |  \(L10n.text("商店池", "Shop pool"))：\(Terminal.yellow)\(ids.count)\(Terminal.reset)  |  \(L10n.text("槽位上限", "Slots"))：\(Terminal.yellow)\(RunState.maxConsumableCardSlots)\(Terminal.reset)")
        lines.append("")

        for id in ids {
            let def = CardRegistry.require(id)
            lines.append("  - 🧪\(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)  \(Terminal.dim)\(def.rarity.displayName(language: L10n.language))\(Terminal.reset)  \(Terminal.dim)\(L10n.text("费用", "Cost")) \(def.cost)\(Terminal.reset)")
            lines.append("    \(Terminal.dim)\(L10n.resolve(def.rulesText))\(Terminal.reset)")
        }

        lines.append("")
        return lines
    }

    private static func buildEventsSectionLines() -> [String] {
        var lines: [String] = []
        lines.append("")
        lines.append("\(Terminal.bold)🧭 \(L10n.text("事件（EventRegistry）", "Events (EventRegistry)"))\(Terminal.reset)")

        let ids = EventRegistry.allEventIds
        lines.append("  \(L10n.text("总数", "Total"))：\(Terminal.yellow)\(ids.count)\(Terminal.reset)")
        lines.append("")

        for id in ids {
            let def = EventRegistry.require(id)
            lines.append("  - \(def.icon)\(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)")
        }

        lines.append("")
        return lines
    }

    private static func buildRelicsSectionLines() -> [String] {
        var lines: [String] = []

        // MARK: - Relics
        lines.append("")
        lines.append("\(Terminal.bold)🏺 \(L10n.text("遗物（Registry）", "Relics (Registry)"))\(Terminal.reset)")

        let droppable = RelicPool.availableRelicIds(excluding: [])
        let allRelicIds = RelicRegistry.allRelicIds

        lines.append("  \(L10n.text("已注册", "Registered"))：\(Terminal.yellow)\(allRelicIds.count)\(Terminal.reset)  |  \(L10n.text("可掉落（排除起始）", "Droppable (excl. starter)"))：\(Terminal.yellow)\(droppable.count)\(Terminal.reset)")
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
            lines.append("  \(Terminal.bold)\(rarity.displayName(language: L10n.language))（\(ids.count)）\(Terminal.reset)")
            for id in ids.sorted(by: { $0.rawValue < $1.rawValue }) {
                let def = RelicRegistry.require(id)
                lines.append("    - \(def.icon)\(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)  \(Terminal.dim)\(L10n.resolve(def.description))\(Terminal.reset)")
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
            lines.append("    - \(L10n.resolve(def.name))  \(Terminal.dim)(\(id.rawValue))\(Terminal.reset)  ◆\(def.cost)  \(Terminal.dim)\(def.rarity.displayName(language: L10n.language))\(Terminal.reset)")
        }
        
        lines.append("")
        return lines
    }
}
