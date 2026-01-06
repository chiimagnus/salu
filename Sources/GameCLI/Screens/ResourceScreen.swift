import GameCore

/// 资源管理页面（开发者工具）
///
/// 用途：
/// - 查看当前注册的卡牌/敌人/遗物
/// - 查看关键“池子”内容（如 Act1 遭遇池）
/// - 提供基础统计洞察（数量、分组、双敌人占比等）
enum ResourceScreen {
    static func show() {
        Terminal.clear()
        
        var lines: [String] = []
        
        lines.append("\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.cyan)  📦 资源管理（内容与池子一览）\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("")
        
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
        
        // MARK: - Enemies & Encounters
        lines.append("")
        lines.append("\(Terminal.bold)👹 敌人（Act1 池子）\(Terminal.reset)")
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
        
        // Print
        for line in lines {
            print(line)
        }
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


