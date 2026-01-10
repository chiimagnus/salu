// MARK: - Ironclad Power Cards

// ============================================================
// Inflame
// ============================================================

/// Inflame - 禁忌献祭
/// 能力牌，获得 2 点力量
public struct Inflame: CardDefinition {
    public static let id: CardID = "inflame"
    public static let name = "禁忌献祭"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "以理智换取力量。获得 2 点力量。"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .applyStatus(target: .player, statusId: "strength", stacks: 2)
        ]
    }
}

// ============================================================
// Agile Stance (敏捷姿态)
// ============================================================

/// 虚空步
/// 能力牌：获得 1 点敏捷
public struct AgileStance: CardDefinition {
    public static let id: CardID = "agile_stance"
    public static let name = "虚空步"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "踏入另一维度。获得 1 点敏捷。"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        [.applyStatus(target: .player, statusId: "dexterity", stacks: 1)]
    }
}


