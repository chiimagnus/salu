// MARK: - Act 3 Boss Definitions

// ============================================================
// Sequence Progenitor (序列始祖) - Act 3 Boss (Final Boss)
// ============================================================

/// 序列始祖（Act3 最终 Boss）
///
/// 设计目标：
/// - 循环的根源，由无数扭曲的面孔和触手组成
/// - 4 回合循环，逐步升级压力
/// - 每轮都会提升自身力量，战斗越久越危险
public struct SequenceProgenitor: EnemyDefinition {
    public static let id: EnemyID = "sequence_progenitor"
    public static let name = LocalizedText("序列始祖", "Sequence Progenitor")
    public static let hpRange: ClosedRange<Int> = 150...170
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let cycle = (snapshot.turn - 1) % 4
        
        switch cycle {
        case 0:
            // 回合 1：命运宣告 - 全面削弱 + 力量成长
            return EnemyMove(
                intent: EnemyIntentDisplay(
                    icon: "👁️",
                    text: LocalizedText("命运宣告：易伤 2 + 虚弱 2 + 力量 +1", "Fate Decree: Vulnerable 2 + Weak 2 + Strength +1")
                ),
                effects: [
                    .applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 1),
                    .applyStatus(target: .player, statusId: "vulnerable", stacks: 2),
                    .applyStatus(target: .player, statusId: "weak", stacks: 2),
                ]
            )
            
        case 1:
            // 回合 2：触手乱舞 - 多段攻击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🦑", text: LocalizedText("触手乱舞 10×3", "Tentacle Frenzy 10×3"), previewDamage: 30),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10),
                ]
            )
            
        case 2:
            // 回合 3：虚无凝视 - 重击 + 中毒
            return EnemyMove(
                intent: EnemyIntentDisplay(
                    icon: "💀",
                    text: LocalizedText("虚无凝视 25 + 中毒 3", "Void Gaze 25 + Poison 3"),
                    previewDamage: 25
                ),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 25),
                    .applyStatus(target: .player, statusId: "poison", stacks: 3),
                ]
            )
            
        default:
            // 回合 4：循环终结 - 超强单击 + 自我回复
            return EnemyMove(
                intent: EnemyIntentDisplay(
                    icon: "🌀",
                    text: LocalizedText("循环终结 35 + 回复 10", "Cycle's End 35 + Heal 10"),
                    previewDamage: 35
                ),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 35),
                    .heal(target: .enemy(index: selfIndex), amount: 10),
                ]
            )
        }
    }
}
