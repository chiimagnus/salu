// MARK: - Damage / Block Calculators

/// 伤害计算器
/// 负责按 **ModifierPhase + priority** 的确定性顺序应用状态修正
public enum DamageCalculator {
    /// 计算最终伤害（应用输出/输入伤害修正）
    public static func calculate(baseDamage: Int, attacker: Entity, defender: Entity) -> Int {
        var damage = baseDamage
        
        // 应用攻击者的输出伤害修正（按 phase + priority 排序）
        let attackerModifiers = attacker.statuses.all
            .compactMap { (id, stacks) -> (phase: ModifierPhase, priority: Int, modify: (Int) -> Int)? in
                guard let def = StatusRegistry.get(id),
                      let phase = def.outgoingDamagePhase else { return nil }
                return (phase, def.priority, { def.modifyOutgoingDamage($0, stacks: stacks) })
            }
            .sorted { ($0.phase.rawValue, $0.priority) < ($1.phase.rawValue, $1.priority) }
        
        for modifier in attackerModifiers {
            damage = modifier.modify(damage)
        }
        
        // 应用防御者的输入伤害修正（按 phase + priority 排序）
        let defenderModifiers = defender.statuses.all
            .compactMap { (id, stacks) -> (phase: ModifierPhase, priority: Int, modify: (Int) -> Int)? in
                guard let def = StatusRegistry.get(id),
                      let phase = def.incomingDamagePhase else { return nil }
                return (phase, def.priority, { def.modifyIncomingDamage($0, stacks: stacks) })
            }
            .sorted { ($0.phase.rawValue, $0.priority) < ($1.phase.rawValue, $1.priority) }
        
        for modifier in defenderModifiers {
            damage = modifier.modify(damage)
        }
        
        return max(0, damage)
    }
}

/// 格挡计算器
/// 负责按 **ModifierPhase + priority** 的确定性顺序应用状态修正
public enum BlockCalculator {
    /// 计算最终格挡（应用格挡修正）
    public static func calculate(baseBlock: Int, entity: Entity) -> Int {
        var block = baseBlock
        
        let modifiers = entity.statuses.all
            .compactMap { (id, stacks) -> (phase: ModifierPhase, priority: Int, modify: (Int) -> Int)? in
                guard let def = StatusRegistry.get(id),
                      let phase = def.blockPhase else { return nil }
                return (phase, def.priority, { def.modifyBlock($0, stacks: stacks) })
            }
            .sorted { ($0.phase.rawValue, $0.priority) < ($1.phase.rawValue, $1.priority) }
        
        for modifier in modifiers {
            block = modifier.modify(block)
        }
        
        return max(0, block)
    }
}


