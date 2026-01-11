// MARK: - Act 2 Boss Definitions

// ============================================================
// Cipher (赛弗) - Act 2 Boss (P2 占卜家序列替换)
// ============================================================

/// 赛弗（Act2 Boss）
///
/// **剧情背景**：
/// 第 46 号终结者，与安德有着惊人相似的面孔。
/// 他觉醒了真相，选择了另一条道路——打破循环。
/// 战斗中会展现完整的占卜师力量。
///
/// **设计目标**：
/// - 3 阶段 Boss，展现占卜师镜像对决
/// - 阶段 1（HP > 60%）：试探
/// - 阶段 2（60% ≥ HP > 30%）：认真
/// - 阶段 3（HP ≤ 30%）：觉醒
///
/// **战略价值**：
/// 强化"改写"卡牌的重要性——没有改写几乎无法舒适地打这场 Boss
public struct Cipher: EnemyDefinition {
    public static let id: EnemyID = "cipher"
    public static let name = "赛弗"
    public static let hpRange: ClosedRange<Int> = 100...110
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        // 计算当前血量百分比
        guard let enemy = snapshot.enemies.first(where: { $0.name == name }) else {
            // 回退到默认行为
            return phase1Move(selfIndex: selfIndex, turn: snapshot.turn, rng: &rng)
        }
        
        let hpPercent = Double(enemy.currentHP) / Double(enemy.maxHP)
        
        if hpPercent > 0.6 {
            // 阶段 1：试探
            return phase1Move(selfIndex: selfIndex, turn: snapshot.turn, rng: &rng)
        } else if hpPercent > 0.3 {
            // 阶段 2：认真
            return phase2Move(selfIndex: selfIndex, turn: snapshot.turn, rng: &rng)
        } else {
            // 阶段 3：觉醒
            return phase3Move(selfIndex: selfIndex, turn: snapshot.turn, rng: &rng)
        }
    }
    
    // MARK: - 阶段 1：试探（HP > 60%）
    
    private static func phase1Move(selfIndex: Int, turn: Int, rng: inout SeededRNG) -> EnemyMove {
        let cycle = (turn - 1) % 3
        
        switch cycle {
        case 0:
            // 普通攻击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "试探 10", previewDamage: 10),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10)
                ]
            )
        case 1:
            // 防御
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: "预判：格挡 12"),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 12)
                ]
            )
        default:
            // 预知反制：给予玩家疯狂 + 力量成长
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🔮", text: "预知反制：疯狂 +2"),
                effects: [
                    .applyStatus(target: .player, statusId: Madness.id, stacks: 2),
                    .applyStatus(target: .enemy(index: selfIndex), statusId: Strength.id, stacks: 1)
                ]
            )
        }
    }
    
    // MARK: - 阶段 2：认真（60% ≥ HP > 30%）
    
    private static func phase2Move(selfIndex: Int, turn: Int, rng: inout SeededRNG) -> EnemyMove {
        let cycle = (turn - 1) % 3
        
        switch cycle {
        case 0:
            // 强攻
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️💥", text: "命运之刃 18", previewDamage: 18),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 18)
                ]
            )
        case 1:
            // 命运剥夺：精神冲击 + 大量疯狂
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "👁️", text: "命运剥夺 12", previewDamage: 12),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 12),
                    .applyStatus(target: .player, statusId: Madness.id, stacks: 3)
                ]
            )
        default:
            // 精神冲击 + 力量成长
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "👁️⚡", text: "精神冲击 14", previewDamage: 14),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 14),
                    .applyStatus(target: .player, statusId: Madness.id, stacks: 2),
                    .applyStatus(target: .enemy(index: selfIndex), statusId: Strength.id, stacks: 1)
                ]
            )
        }
    }
    
    // MARK: - 阶段 3：觉醒（HP ≤ 30%）
    
    private static func phase3Move(selfIndex: Int, turn: Int, rng: inout SeededRNG) -> EnemyMove {
        let cycle = (turn - 1) % 4
        
        switch cycle {
        case 0:
            // 强攻
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️💥💥", text: "绝望之击 22", previewDamage: 22),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 22)
                ]
            )
        case 1:
            // 命运改写（敌方版）：大量精神伤害
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "✍️", text: "命运改写 16", previewDamage: 16),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 16),
                    .applyStatus(target: .player, statusId: Madness.id, stacks: 4)
                ]
            )
        case 2:
            // 时间回溯：回复 HP + 力量成长
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⏪", text: "时间回溯：回复 15 HP"),
                effects: [
                    .heal(target: .enemy(index: selfIndex), amount: 15),
                    .applyStatus(target: .enemy(index: selfIndex), statusId: Strength.id, stacks: 2)
                ]
            )
        default:
            // 多段攻击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️⚔️", text: "命运连击 8×3", previewDamage: 24),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8)
                ]
            )
        }
    }
}
