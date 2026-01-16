// MARK: - Act 2 Elite Enemy Definitions

// ============================================================
// Mad Prophet (疯狂预言者) - P2 占卜家序列新增
// ============================================================

/// 疯狂预言者（Act2 精英）
///
/// 设计目标：
/// - 符合占卜家序列主题，强化"疯狂"机制的存在感
/// - 每回合被动给予玩家 +1 疯狂
/// - 主要使用精神冲击（伤害 + 疯狂）
///
/// 特点：
/// - 开局使用"预言"增益自身（力量 +2）
/// - 循环：精神冲击 / 防御 / 精神冲击
public struct MadProphet: EnemyDefinition {
    public static let id: EnemyID = "mad_prophet"
    public static let name = LocalizedText("疯狂预言者", "Mad Prophet")
    public static let hpRange: ClosedRange<Int> = 50...60
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        // 被动：每回合给予玩家 +1 疯狂（通过额外效果）
        let passiveMadness: [BattleEffect] = [
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1)
        ]
        
        if snapshot.turn == 1 {
            // 开局：预言（力量 +2）+ 被动疯狂
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🔮", text: LocalizedText("预言：力量 +2", "Prophecy: Strength +2")),
                effects: [
                    .applyStatus(target: .enemy(index: selfIndex), statusId: Strength.id, stacks: 2)
                ] + passiveMadness
            )
        }
        
        // 2 回合循环：精神冲击 / 防御
        let cycle = (snapshot.turn - 2) % 3
        switch cycle {
        case 0:
            // 精神冲击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "👁️", text: LocalizedText("精神冲击 10", "Psychic Shock 10"), previewDamage: 10),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10),
                    .applyStatus(target: .player, statusId: Madness.id, stacks: 2)
                ] + passiveMadness
            )
        case 1:
            // 防御
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: LocalizedText("冥想：格挡 15", "Meditation: Block 15")),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 15)
                ] + passiveMadness
            )
        default:
            // 强精神冲击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "👁️💥", text: LocalizedText("深渊低语 14", "Abyss Whisper 14"), previewDamage: 14),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 14),
                    .applyStatus(target: .player, statusId: Madness.id, stacks: 3)
                ] + passiveMadness
            )
        }
    }
}

// ============================================================
// Time Guardian (时间守卫) - P2 占卜家序列新增
// ============================================================

/// 时间守卫（Act2 精英）
///
/// 设计目标：
/// - 符合时间/预知主题
/// - 首次被攻击时获得 10 格挡（被动）
///
/// 特点：
/// - 开局使用"时间凝滞"（给予脆弱）
/// - 循环：攻击 / 时间加速（力量+1）/ 强攻
public struct TimeGuardian: EnemyDefinition {
    public static let id: EnemyID = "time_guardian"
    public static let name = LocalizedText("时间守卫", "Time Guardian")
    public static let hpRange: ClosedRange<Int> = 65...75
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        if snapshot.turn == 1 {
            // 开局：时间凝滞（脆弱 2）
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⏳", text: LocalizedText("时间凝滞：脆弱 2", "Time Stasis: Frail 2")),
                effects: [
                    .applyStatus(target: .player, statusId: Frail.id, stacks: 2)
                ]
            )
        }
        
        let cycle = (snapshot.turn - 2) % 3
        switch cycle {
        case 0:
            // 普通攻击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: LocalizedText("时间切割 12", "Time Slash 12"), previewDamage: 12),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 12)
                ]
            )
        case 1:
            // 时间加速（力量 +1 + 格挡 10）
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⏰", text: LocalizedText("时间加速：力量 +1 + 格挡 10", "Time Acceleration: Strength +1 + Block 10")),
                effects: [
                    .applyStatus(target: .enemy(index: selfIndex), statusId: Strength.id, stacks: 1),
                    .gainBlock(target: .enemy(index: selfIndex), base: 10)
                ]
            )
        default:
            // 强攻
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️💥", text: LocalizedText("时间崩坏 18", "Time Collapse 18"), previewDamage: 18),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 18)
                ]
            )
        }
    }
}

// ============================================================
// Rune Guardian (符文守卫)
// ============================================================

/// 符文执行者（Act2 精英）
///
/// 特点：
/// - 开局制造易伤，放大后续伤害压力
/// - 轮换：重击 / 叠甲 / 多段
public struct RuneGuardian: EnemyDefinition {
    public static let id: EnemyID = "rune_guardian"
    public static let name = LocalizedText("符文执行者", "Rune Guardian")
    public static let hpRange: ClosedRange<Int> = 70...76
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        if snapshot.turn == 1 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💥", text: LocalizedText("破甲：易伤 2", "Sunder: Vulnerable 2")),
                effects: [
                    .applyStatus(target: .player, statusId: "vulnerable", stacks: 2)
                ]
            )
        }
        
        let cycle = (snapshot.turn - 2) % 3
        switch cycle {
        case 0:
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: LocalizedText("符文重击 18", "Rune Smash 18"), previewDamage: 18),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 18)
                ]
            )
        case 1:
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: LocalizedText("符文护盾：格挡 20", "Rune Shield: Block 20")),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 20)
                ]
            )
        default:
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️", text: LocalizedText("符文连斩 9×2", "Rune Flurry 9×2"), previewDamage: 18),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 9),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 9),
                ]
            )
        }
    }
}
