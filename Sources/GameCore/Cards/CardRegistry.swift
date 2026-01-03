// MARK: - Card Registry

/// 卡牌注册表
/// 新增卡牌的唯一扩展点
public enum CardRegistry {
    /// 注册的卡牌定义
    private static let defs: [CardID: any CardDefinition.Type] = [
        // Basic Cards
        Strike.id: Strike.self,
        StrikePlus.id: StrikePlus.self,
        Defend.id: Defend.self,
        DefendPlus.id: DefendPlus.self,
        Bash.id: Bash.self,
        BashPlus.id: BashPlus.self,
        
        // Common Cards
        PommelStrike.id: PommelStrike.self,
        ShrugItOff.id: ShrugItOff.self,
        Inflame.id: Inflame.self,
        Clothesline.id: Clothesline.self,
    ]
    
    /// 获取卡牌定义
    public static func get(_ id: CardID) -> (any CardDefinition.Type)? {
        return defs[id]
    }
    
    /// 强制获取卡牌定义（找不到会崩溃，用于必须存在的卡牌）
    public static func require(_ id: CardID) -> any CardDefinition.Type {
        guard let def = defs[id] else {
            fatalError("CardRegistry: 未找到卡牌定义 '\(id.rawValue)'")
        }
        return def
    }
}
