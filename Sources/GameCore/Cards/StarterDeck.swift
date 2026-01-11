/// 创建初始牌组
/// 安德的起始牌组配置
public func createStarterDeck() -> [Card] {
    var cards: [Card] = []
    
    // 4 张 Strike
    for i in 1...4 {
        cards.append(Card(id: "strike_\(i)", cardId: "strike"))
    }
    
    // 4 张 Defend
    for i in 1...4 {
        cards.append(Card(id: "defend_\(i)", cardId: "defend"))
    }
    
    // 1 张 Bash（起始牌）
    cards.append(Card(id: "bash_1", cardId: "bash"))
    
    // P1: 起始牌组调整（+1 灵视，-1 触须鞭笞）
    cards.append(Card(id: "spirit_sight_1", cardId: "spirit_sight"))
    
    // 1 张 Shrug It Off
    cards.append(Card(id: "shrug_it_off_1", cardId: "shrug_it_off"))
    
    // 1 张 Inflame
    cards.append(Card(id: "inflame_1", cardId: "inflame"))
    
    // 1 张 Clothesline
    cards.append(Card(id: "clothesline_1", cardId: "clothesline"))
    
    return cards  // 总计 13 张
}

