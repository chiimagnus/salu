/// 下颚虫 AI
/// 行为模式：咬（11伤害）、嚎叫（+3力量）、猛扑（7伤害+5格挡）
public struct JawWormAI: EnemyAI, Sendable {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        let strength = enemy.statuses.stacks(of: "strength")
        let baseDamage = 11 + strength
        
        if turn == 1 {
            // 第一回合 75% 咬
            return roll < 75 ? .attack(damage: baseDamage) : .buff(name: "力量", stacks: 3)
        }
        
        // 后续回合
        if roll < 45 {
            return .attack(damage: baseDamage)
        } else if roll < 75 {
            return .buff(name: "力量", stacks: 3)
        } else {
            // 猛扑：造成伤害 + 获得格挡（这里简化为攻击）
            return .attack(damage: 7 + strength)
        }
    }
}

/// 信徒 AI
/// 行为模式：第一回合念咒（+3力量），后续攻击
public struct CultistAI: EnemyAI, Sendable {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        if turn == 1 {
            // 第一回合必定念咒
            return .buff(name: "仪式", stacks: 3)
        }
        // 后续回合攻击（基础6 + 力量加成）
        let strength = enemy.statuses.stacks(of: "strength")
        return .attack(damage: 6 + strength)
    }
}

/// 虱子 AI
/// 行为模式：攻击为主，偶尔卷曲（+3力量）
public struct LouseAI: EnemyAI, Sendable {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        let strength = enemy.statuses.stacks(of: "strength")
        let baseDamage = 6 + strength
        
        if roll < 75 {
            return .attack(damage: baseDamage)
        } else {
            return .buff(name: "卷曲", stacks: 3)
        }
    }
}

/// 史莱姆 AI
/// 行为模式：攻击 + 涂抹（施加虚弱）
public struct SlimeAI: EnemyAI, Sendable {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        let strength = enemy.statuses.stacks(of: "strength")
        let baseDamage = 10 + strength
        
        if roll < 70 {
            return .attack(damage: baseDamage)
        } else {
            // 涂抹：攻击 + 施加虚弱
            return .attackDebuff(damage: 7 + strength, debuff: "虚弱", stacks: 1)
        }
    }
}

