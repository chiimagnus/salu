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
    public static let name = LocalizedText("赛弗", "Cipher")
    public static let hpRange: ClosedRange<Int> = 100...110
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        _ = rng
        // 计算当前血量百分比（使用 selfIndex 直接获取，避免多敌人场景下的问题）
        guard selfIndex >= 0, selfIndex < snapshot.enemies.count else {
            // 回退到默认行为
            return phase1Move(selfIndex: selfIndex, turn: snapshot.turn)
        }
        let enemy = snapshot.enemies[selfIndex]
        let hpPercent = Double(enemy.currentHP) / Double(enemy.maxHP)
        
        if hpPercent > 0.6 {
            // 阶段 1：试探
            return phase1Move(selfIndex: selfIndex, turn: snapshot.turn)
        } else if hpPercent > 0.3 {
            // 阶段 2：认真
            return phase2Move(selfIndex: selfIndex, turn: snapshot.turn)
        } else {
            // 阶段 3：觉醒
            return phase3Move(selfIndex: selfIndex, turn: snapshot.turn)
        }
    }
    
    // MARK: - 阶段 1：试探（HP > 60%）
    
    private static func phase1Move(selfIndex: Int, turn: Int) -> EnemyMove {
        let cycle = (turn - 1) % 3
        
        switch cycle {
        case 0:
            // 普通攻击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: LocalizedText("试探 10", "Probe 10"), previewDamage: 10),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10)
                ]
            )
        case 1:
            // 防御
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: LocalizedText("预判：格挡 12", "Anticipate: Block 12")),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 12)
                ]
            )
        default:
            // P6：预知反制（下回合预知 -1，可被“改写”取消）
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🔮", text: LocalizedText("预知反制：下回合预知 -1", "Foresee Counter: Foresee -1 next turn")),
                effects: [
                    .applyForesightPenaltyNextTurn(amount: 1)
                ]
            )
        }
    }
    
    // MARK: - 阶段 2：认真（60% ≥ HP > 30%）
    
    private static func phase2Move(selfIndex: Int, turn: Int) -> EnemyMove {
        let cycle = (turn - 1) % 3
        
        switch cycle {
        case 0:
            // 强攻
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️💥", text: LocalizedText("命运之刃 18", "Blade of Fate 18"), previewDamage: 18),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 18)
                ]
            )
        case 1:
            // P6：命运剥夺（随机弃置 2 张手牌 + 疯狂 +2，可被“改写”取消）
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "👁️", text: LocalizedText("命运剥夺：弃牌 2 + 疯狂 +2", "Fate Strip: Discard 2 + Madness +2")),
                effects: [
                    .discardRandomHand(count: 2),
                    .applyStatus(target: .player, statusId: Madness.id, stacks: 2),
                ]
            )
        default:
            // 精神冲击：伤害 + 疯狂
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "👁️⚡", text: LocalizedText("精神冲击 14", "Psychic Shock 14"), previewDamage: 14),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 14),
                    .applyStatus(target: .player, statusId: Madness.id, stacks: 2),
                ]
            )
        }
    }
    
    // MARK: - 阶段 3：觉醒（HP ≤ 30%）
    
    private static func phase3Move(selfIndex: Int, turn: Int) -> EnemyMove {
        let cycle = (turn - 1) % 4
        
        switch cycle {
        case 0:
            // 强攻
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️💥💥", text: LocalizedText("绝望之击 22", "Despair Strike 22"), previewDamage: 22),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 22)
                ]
            )
        case 1:
            // P6：命运改写（敌方版）：下回合第一张牌费用 +1（可被“改写”取消）
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "✍️", text: LocalizedText("命运改写：下回合首牌费用 +1", "Fate Rewrite: first card next turn costs +1")),
                effects: [
                    .applyFirstCardCostIncreaseNextTurn(amount: 1),
                ]
            )
        case 2:
            // P6：时间回溯：回复 15 HP（可被“改写”取消）
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⏪", text: LocalizedText("时间回溯：回复 15 HP", "Time Rewind: Heal 15 HP")),
                effects: [
                    .enemyHeal(enemyIndex: selfIndex, amount: 15),
                ]
            )
        default:
            // 多段攻击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️⚔️", text: LocalizedText("命运连击 8×3", "Fated Combo 8×3"), previewDamage: 24),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8)
                ]
            )
        }
    }
}
