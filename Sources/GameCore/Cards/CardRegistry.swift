/// 卡牌注册表
/// 唯一扩展点：新增卡牌只需新增 Definition 类型并在这里注册。

public enum CardRegistry {
    private static let defs: [CardID: any CardDefinition.Type] = [
        // Basic
        StrikeCard.id: StrikeCard.self,
        StrikePlusCard.id: StrikePlusCard.self,
        DefendCard.id: DefendCard.self,
        DefendPlusCard.id: DefendPlusCard.self,
        BashCard.id: BashCard.self,
        BashPlusCard.id: BashPlusCard.self,
        
        // Common
        PommelStrikeCard.id: PommelStrikeCard.self,
        ShrugItOffCard.id: ShrugItOffCard.self,
        InflameCard.id: InflameCard.self,
        ClotheslineCard.id: ClotheslineCard.self
    ]
    
    public static func get(_ id: CardID) -> (any CardDefinition.Type)? {
        defs[id]
    }
    
    public static func require(_ id: CardID) -> any CardDefinition.Type {
        // 破坏性策略：找不到就直接失败，避免静默 fallback
        guard let def = defs[id] else {
            fatalError("CardRegistry: unknown card id '\(id.rawValue)'")
        }
        return def
    }
}


