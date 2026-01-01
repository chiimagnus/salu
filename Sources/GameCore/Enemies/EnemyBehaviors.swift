/// 下颚虫 AI
/// 行为模式：咬（攻击）、嚎叫（+力量）、猛扑（攻击+获得格挡）
public struct JawWormAI: EnemyAI {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        
        if turn == 1 {
            // 第一回合 50% 咬，50% 嚎叫
            return roll < 50 ? .attack(damage: 11) : .buff(buff: "力量", stacks: 3)
        }
        
        // 根据上次行动决定
        switch lastIntent {
        case .attack:
            // 上次攻击 → 30% 再攻击，30% 嚎叫，40% 猛扑
            if roll < 30 { return .attack(damage: 11) }
            if roll < 60 { return .buff(buff: "力量", stacks: 3) }
            return .attackDebuff(damage: 7, debuff: "格挡", stacks: 5)
            
        case .buff:
            // 上次增益 → 70% 攻击，30% 猛扑
            if roll < 70 { return .attack(damage: 11) }
            return .attackDebuff(damage: 7, debuff: "格挡", stacks: 5)
            
        case .attackDebuff:
            // 上次猛扑 → 30% 攻击，45% 嚎叫，25% 猛扑
            if roll < 30 { return .attack(damage: 11) }
            if roll < 75 { return .buff(buff: "力量", stacks: 3) }
            return .attackDebuff(damage: 7, debuff: "格挡", stacks: 5)
            
        default:
            return .attack(damage: 11)
        }
    }
    
    public func executeIntent(
        intent: EnemyIntent,
        enemy: inout Entity,
        player: inout Entity
    ) -> [BattleEvent] {
        var events: [BattleEvent] = []
        
        switch intent {
        case .attack(let baseDamage):
            let finalDamage = calculateDamage(baseDamage: baseDamage, attacker: enemy, defender: player)
            let (dealt, blocked) = player.takeDamage(finalDamage)
            events.append(.damageDealt(
                source: enemy.name,
                target: player.name,
                amount: dealt,
                blocked: blocked
            ))
            
        case .attackDebuff(let baseDamage, _, let blockStacks):
            // 猛扑：攻击并且敌人自己获得格挡
            let finalDamage = calculateDamage(baseDamage: baseDamage, attacker: enemy, defender: player)
            let (dealt, blocked) = player.takeDamage(finalDamage)
            events.append(.damageDealt(
                source: enemy.name,
                target: player.name,
                amount: dealt,
                blocked: blocked
            ))
            enemy.gainBlock(blockStacks)
            events.append(.blockGained(target: enemy.name, amount: blockStacks))
            
        case .buff(let buffName, let stacks):
            enemy.strength += stacks
            events.append(.statusApplied(target: enemy.name, effect: buffName, stacks: stacks))
            
        default:
            break
        }
        
        return events
    }
}

/// 信徒 AI
/// 行为模式：第一回合念咒（+力量），后续持续攻击
public struct CultistAI: EnemyAI {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        if turn == 1 {
            // 第一回合：念咒增加力量
            return .buff(buff: "念咒", stacks: 3)
        }
        
        // 后续回合：持续攻击
        return .attack(damage: 6)
    }
    
    public func executeIntent(
        intent: EnemyIntent,
        enemy: inout Entity,
        player: inout Entity
    ) -> [BattleEvent] {
        var events: [BattleEvent] = []
        
        switch intent {
        case .attack(let baseDamage):
            let finalDamage = calculateDamage(baseDamage: baseDamage, attacker: enemy, defender: player)
            let (dealt, blocked) = player.takeDamage(finalDamage)
            events.append(.damageDealt(
                source: enemy.name,
                target: player.name,
                amount: dealt,
                blocked: blocked
            ))
            
        case .buff(let buffName, let stacks):
            enemy.strength += stacks
            events.append(.statusApplied(target: enemy.name, effect: buffName, stacks: stacks))
            
        default:
            break
        }
        
        return events
    }
}

/// 虱子 AI（绿色和红色共用）
/// 行为模式：攻击或卷曲（+力量）
public struct LouseAI: EnemyAI {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        
        // 25% 卷曲，75% 攻击
        if roll < 25 {
            return .buff(buff: "卷曲", stacks: 3)
        }
        
        // 攻击伤害随机 5-7
        let damage = 5 + rng.nextInt(upperBound: 3)
        return .attack(damage: damage)
    }
    
    public func executeIntent(
        intent: EnemyIntent,
        enemy: inout Entity,
        player: inout Entity
    ) -> [BattleEvent] {
        var events: [BattleEvent] = []
        
        switch intent {
        case .attack(let baseDamage):
            let finalDamage = calculateDamage(baseDamage: baseDamage, attacker: enemy, defender: player)
            let (dealt, blocked) = player.takeDamage(finalDamage)
            events.append(.damageDealt(
                source: enemy.name,
                target: player.name,
                amount: dealt,
                blocked: blocked
            ))
            
        case .buff(let buffName, let stacks):
            enemy.strength += stacks
            events.append(.statusApplied(target: enemy.name, effect: buffName, stacks: stacks))
            
        default:
            break
        }
        
        return events
    }
}

/// 酸液史莱姆 AI
/// 行为模式：攻击或涂抹（施加虚弱）
public struct AcidSlimeAI: EnemyAI {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        
        // 根据上次行动决定
        if case .attackDebuff = lastIntent {
            // 上次涂抹 → 70% 攻击，30% 涂抹
            if roll < 70 {
                return .attack(damage: 10)
            }
        }
        
        // 30% 涂抹（施加虚弱），70% 攻击
        if roll < 30 {
            return .attackDebuff(damage: 7, debuff: "虚弱", stacks: 1)
        }
        
        return .attack(damage: 10)
    }
    
    public func executeIntent(
        intent: EnemyIntent,
        enemy: inout Entity,
        player: inout Entity
    ) -> [BattleEvent] {
        var events: [BattleEvent] = []
        
        switch intent {
        case .attack(let baseDamage):
            let finalDamage = calculateDamage(baseDamage: baseDamage, attacker: enemy, defender: player)
            let (dealt, blocked) = player.takeDamage(finalDamage)
            events.append(.damageDealt(
                source: enemy.name,
                target: player.name,
                amount: dealt,
                blocked: blocked
            ))
            
        case .attackDebuff(let baseDamage, let debuff, let stacks):
            // 涂抹：攻击并施加虚弱
            let finalDamage = calculateDamage(baseDamage: baseDamage, attacker: enemy, defender: player)
            let (dealt, blocked) = player.takeDamage(finalDamage)
            events.append(.damageDealt(
                source: enemy.name,
                target: player.name,
                amount: dealt,
                blocked: blocked
            ))
            player.weak += stacks
            events.append(.statusApplied(target: player.name, effect: debuff, stacks: stacks))
            
        default:
            break
        }
        
        return events
    }
}

// MARK: - Helper Functions
// Note: calculateDamage is now in BattleUtils.swift and imported globally

