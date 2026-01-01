/// 卡牌种类枚举
/// 定义所有卡牌类型及其基础属性
public enum CardKind: String, Sendable {
    case strike         // 攻击牌：1能量，造成6伤害
    case defend         // 防御牌：1能量，获得5格挡
    case pommelStrike   // 柄击：1能量，造成9伤害，抽1张牌
    case shrugItOff     // 耸肩：1能量，获得8格挡，抽1张牌
    case bash           // 重击：2能量，造成8伤害，给予易伤2
    case inflame        // 燃烧：1能量，获得2力量
    case clothesline    // 晾衣绳：2能量，造成12伤害，给予虚弱2
}

