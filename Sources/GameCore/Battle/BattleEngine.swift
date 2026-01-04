/// 战斗引擎
/// 负责管理战斗状态、处理玩家动作、执行敌人行动
public final class BattleEngine: @unchecked Sendable {
    
    // MARK: - Properties
    
    public private(set) var state: BattleState
    public private(set) var events: [BattleEvent] = []
    
    /// 战斗统计（累积，不会被清除）
    public private(set) var battleStats: BattleStats = BattleStats()
    
    private var rng: SeededRNG
    private let cardsPerTurn: Int = 5
    
    // P4: 遗物管理器（从 RunState 传入）
    private let relicManager: RelicManager
    
    // MARK: - Initialization
    
    /// 初始化战斗引擎
    /// - Parameters:
    ///   - player: 玩家实体
    ///   - enemy: 敌人实体
    ///   - deck: 初始牌组
    ///   - relicManager: 遗物管理器（P4 新增）
    ///   - seed: 随机数种子（用于可复现性）
    public init(
        player: Entity,
        enemy: Entity,
        deck: [Card],
        relicManager: RelicManager = RelicManager(),
        seed: UInt64
    ) {
        self.rng = SeededRNG(seed: seed)
        self.state = BattleState(player: player, enemy: enemy)
        self.relicManager = relicManager
        
        // 初始化抽牌堆并洗牌
        self.state.drawPile = rng.shuffled(deck)
    }
    
    /// 使用默认配置初始化（随机选择敌人）
    public convenience init(seed: UInt64) {
        var tempRng = SeededRNG(seed: seed)
        let enemyId = Act1EnemyPool.randomWeak(rng: &tempRng)
        let enemy = createEnemy(enemyId: enemyId, rng: &tempRng)
        
        self.init(
            player: createDefaultPlayer(),
            enemy: enemy,
            deck: createStarterDeck(),
            seed: seed
        )
    }
    
    // MARK: - Public Methods
    
    /// 开始战斗
    public func startBattle() {
        events.removeAll()
        emit(.battleStarted)
        
        // P4: 触发战斗开始的遗物效果
        triggerRelics(.battleStart)
        
        startNewTurn()
    }
    
    /// 处理玩家动作
    /// - Returns: 动作是否成功执行
    @discardableResult
    public func handleAction(_ action: PlayerAction) -> Bool {
        guard !state.isOver else {
            emit(.invalidAction(reason: "战斗已结束"))
            return false
        }
        
        guard state.isPlayerTurn else {
            emit(.invalidAction(reason: "不是玩家回合"))
            return false
        }
        
        switch action {
        case .playCard(let handIndex):
            return playCard(at: handIndex)
            
        case .endTurn:
            endPlayerTurn()
            return true
        }
    }
    
    /// 获取当前可打出的手牌索引
    public var playableCardIndices: [Int] {
        state.hand.enumerated().compactMap { index, card in
            let def = CardRegistry.require(card.cardId)
            return def.cost <= state.energy ? index : nil
        }
    }
    
    /// 清除事件日志
    public func clearEvents() {
        events.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func emit(_ event: BattleEvent) {
        events.append(event)
    }
    
    // MARK: Damage Calculation
    
    /// 计算最终伤害（应用力量、虚弱、易伤修正）
    private func calculateDamage(baseDamage: Int, attacker: Entity, defender: Entity) -> Int {
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
    
    // MARK: Turn Management
    
    private func startNewTurn() {
        state.turn += 1
        state.isPlayerTurn = true
        
        emit(.turnStarted(turn: state.turn))
        
        // P4: 触发回合开始的遗物效果
        triggerRelics(.turnStart(turn: state.turn))
        
        // 重置能量
        state.energy = state.maxEnergy
        emit(.energyReset(amount: state.energy))
        
        // 清除玩家格挡
        if state.player.block > 0 {
            let clearedBlock = state.player.block
            state.player.clearBlock()
            emit(.blockCleared(target: state.player.name, amount: clearedBlock))
        }
        
        // P2: 状态递减现在由 processStatusesAtTurnEnd 处理（在回合结束时）
        
        // 抽牌
        drawCards(cardsPerTurn)
        
        // AI 决定敌人意图
        decideEnemyIntent()
    }
    
    /// 让敌人 AI 决定下一个意图
    private func decideEnemyIntent() {
        // P3: 使用 EnemyRegistry 获取定义并选择行动
        guard let enemyId = state.enemy.enemyId else {
            // 如果没有 enemyId（不应该发生），使用默认行动
            state.enemy.plannedMove = EnemyMove(
                intent: EnemyIntentDisplay(icon: "❓", text: "未知"),
                effects: []
            )
            emit(.enemyIntent(enemyId: state.enemy.id, action: "未知", damage: 0))
            return
        }
        
        let def = EnemyRegistry.require(enemyId)
        let snapshot = BattleSnapshot(
            turn: state.turn,
            player: state.player,
            enemy: state.enemy,
            energy: state.energy
        )
        let move = def.chooseMove(snapshot: snapshot, rng: &rng)
        state.enemy.plannedMove = move
        
        // 发出敌人意图事件
        let intentDamage = move.intent.previewDamage ?? 0
        let actionName = move.intent.text
        emit(.enemyIntent(enemyId: state.enemy.id, action: actionName, damage: intentDamage))
    }
    
    private func endPlayerTurn() {
        // 弃掉所有手牌
        let handCount = state.hand.count
        state.discardPile.append(contentsOf: state.hand)
        state.hand.removeAll()
        
        if handCount > 0 {
            emit(.handDiscarded(count: handCount))
        }
        
        // 处理玩家回合结束的状态效果（触发 + 递减）
        processStatusesAtTurnEnd(for: .player)
        
        emit(.turnEnded(turn: state.turn))
        
        state.isPlayerTurn = false
        
        // 敌人行动
        executeEnemyTurn()
        
        // 如果战斗未结束，开始新回合
        if !state.isOver {
            // 清除敌人格挡（在敌人回合结束后、玩家回合开始前）
            if state.enemy.block > 0 {
                let clearedBlock = state.enemy.block
                state.enemy.clearBlock()
                emit(.blockCleared(target: state.enemy.name, amount: clearedBlock))
            }
            startNewTurn()
        }
    }
    
    private func executeEnemyTurn() {
        // P3: 执行敌人的计划行动（通过 BattleEffect）
        guard let move = state.enemy.plannedMove else {
            // 没有计划行动（不应该发生）
            emit(.enemyAction(enemyId: state.enemy.id, action: "跳过"))
            processStatusesAtTurnEnd(for: .enemy)
            checkBattleEnd()
            return
        }
        
        emit(.enemyAction(enemyId: state.enemy.id, action: move.intent.text))
        
        // 执行所有效果
        for effect in move.effects {
            apply(effect)
        }
        
        // 处理敌人回合结束的状态效果（触发 + 递减）
        processStatusesAtTurnEnd(for: .enemy)
        
        // 检查玩家是否死亡
        checkBattleEnd()
    }
    
    // MARK: Card Playing
    
    private func playCard(at handIndex: Int) -> Bool {
        // 验证索引
        guard handIndex >= 0, handIndex < state.hand.count else {
            emit(.invalidAction(reason: "无效的卡牌索引"))
            return false
        }
        
        let card = state.hand[handIndex]
        let def = CardRegistry.require(card.cardId)
        
        // 验证能量
        guard state.energy >= def.cost else {
            emit(.notEnoughEnergy(required: def.cost, available: state.energy))
            return false
        }
        
        // 消耗能量
        state.energy -= def.cost
        
        // 从手牌移除
        state.hand.remove(at: handIndex)
        
        emit(.played(cardId: card.cardId, cost: def.cost))
        
        // 执行卡牌效果（新架构：通过 BattleEffect）
        executeCardEffect(card)
        
        // 卡牌进入弃牌堆
        state.discardPile.append(card)
        
        // 检查战斗是否结束
        checkBattleEnd()
        
        return true
    }
    
    private func executeCardEffect(_ card: Card) {
        let def = CardRegistry.require(card.cardId)
        
        // 统计卡牌使用（基于类型）
        battleStats.cardsPlayed += 1
        switch def.type {
        case .attack:
            battleStats.strikesPlayed += 1
        case .skill:
            battleStats.defendsPlayed += 1
        case .power:
            battleStats.skillsPlayed += 1
        }
        
        // 生成战斗快照
        let snapshot = BattleSnapshot(
            turn: state.turn,
            player: state.player,
            enemy: state.enemy,
            energy: state.energy
        )
        
        // 获取卡牌效果
        let effects = def.play(snapshot: snapshot)
        
        // 执行所有效果
        for effect in effects {
            apply(effect)
        }
    }
    
    /// 应用单个战斗效果（统一执行入口）
    private func apply(_ effect: BattleEffect) {
        switch effect {
        case .dealDamage(let target, let base):
            applyDamage(target: target, base: base)
            
        case .gainBlock(let target, let base):
            applyBlock(target: target, base: base)
            
        case .drawCards(let count):
            drawCards(count)
            
        case .gainEnergy(let amount):
            state.energy += amount
            emit(.energyReset(amount: state.energy))
            
        case .applyStatus(let target, let statusId, let stacks):
            applyStatusEffect(target: target, statusId: statusId, stacks: stacks)
            
        case .heal(let target, let amount):
            applyHeal(target: target, amount: amount)
        }
    }
    
    /// 应用伤害效果
    private func applyDamage(target: EffectTarget, base: Int) {
        let (attackerName, defenderName): (String, String)
        let (attacker, defender): (Entity, Entity)
        let finalDamage: Int
        let damageResult: (Int, Int)
        
        switch target {
        case .enemy:
            attacker = state.player
            defender = state.enemy
            finalDamage = calculateDamage(baseDamage: base, attacker: attacker, defender: defender)
            damageResult = state.enemy.takeDamage(finalDamage)
            battleStats.totalDamageDealt += damageResult.0
            attackerName = state.player.name
            defenderName = state.enemy.name
        case .player:
            attacker = state.enemy
            defender = state.player
            finalDamage = calculateDamage(baseDamage: base, attacker: attacker, defender: defender)
            damageResult = state.player.takeDamage(finalDamage)
            battleStats.totalDamageTaken += damageResult.0
            attackerName = state.enemy.name
            defenderName = state.player.name
        }
        
        emit(.damageDealt(
            source: attackerName,
            target: defenderName,
            amount: damageResult.0,
            blocked: damageResult.1
        ))
    }
    
    /// 应用格挡效果
    private func applyBlock(target: EffectTarget, base: Int) {
        var block = base
        
        // 应用格挡修正（按 phase + priority 排序）
        let entity = target == .player ? state.player : state.enemy
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
        
        switch target {
        case .player:
            state.player.gainBlock(block)
            battleStats.totalBlockGained += block
            emit(.blockGained(target: state.player.name, amount: block))
        case .enemy:
            state.enemy.gainBlock(block)
            emit(.blockGained(target: state.enemy.name, amount: block))
        }
    }
    
    /// 应用状态效果
    private func applyStatusEffect(target: EffectTarget, statusId: StatusID, stacks: Int) {
        // P2: Now using StatusRegistry!
        guard let def = StatusRegistry.get(statusId) else {
            // Unknown status - skip silently
            return
        }
        
        switch target {
        case .player:
            state.player.statuses.apply(statusId, stacks: stacks)
            emit(.statusApplied(target: state.player.name, effect: def.name, stacks: stacks))
        case .enemy:
            state.enemy.statuses.apply(statusId, stacks: stacks)
            emit(.statusApplied(target: state.enemy.name, effect: def.name, stacks: stacks))
        }
    }
    
    /// 应用治疗效果
    private func applyHeal(target: EffectTarget, amount: Int) {
        switch target {
        case .player:
            state.player.currentHP = min(state.player.currentHP + amount, state.player.maxHP)
            // 治疗事件（目前没有对应的 BattleEvent，暂不 emit）
        case .enemy:
            state.enemy.currentHP = min(state.enemy.currentHP + amount, state.enemy.maxHP)
            // 治疗事件（目前没有对应的 BattleEvent，暂不 emit）
        }
    }
    
    // MARK: Card Drawing
    
    private func drawCards(_ count: Int) {
        for _ in 0..<count {
            drawOneCard()
        }
    }
    
    private func drawOneCard() {
        // 如果抽牌堆空了，洗入弃牌堆
        if state.drawPile.isEmpty {
            shuffleDiscardIntoDraw()
        }
        
        // 如果还是空的（没有牌可抽），直接返回
        guard !state.drawPile.isEmpty else { return }
        
        // 抽一张牌
        let card = state.drawPile.removeLast()
        state.hand.append(card)
        emit(.drew(cardId: card.cardId))
    }
    
    private func shuffleDiscardIntoDraw() {
        guard !state.discardPile.isEmpty else { return }
        
        let count = state.discardPile.count
        state.drawPile = rng.shuffled(state.discardPile)
        state.discardPile.removeAll()
        
        emit(.shuffled(count: count))
    }
    
    // MARK: Status Processing
    
    /// 处理实体的回合结束状态效果（触发 + 递减）
    private func processStatusesAtTurnEnd(for target: EffectTarget) {
        let entity = target == .player ? state.player : state.enemy
        let snapshot = BattleSnapshot(
            turn: state.turn,
            player: state.player,
            enemy: state.enemy,
            energy: state.energy
        )
        
        // 1) 触发所有状态的 onTurnEnd 效果（如中毒造成伤害）
        for (statusId, stacks) in entity.statuses.all {
            guard let def = StatusRegistry.get(statusId) else { continue }
            let effects = def.onTurnEnd(owner: target, stacks: stacks, snapshot: snapshot)
            for effect in effects {
                apply(effect)
            }
        }
        
        // 2) 递减状态层数
        var expired: [StatusID] = []
        for (statusId, stacks) in entity.statuses.all {
            guard let def = StatusRegistry.get(statusId) else { continue }
            
            switch def.decay {
            case .none:
                // 不递减（如力量）
                break
            case .turnEnd(let decreaseBy):
                let newStacks = stacks - decreaseBy
                
                switch target {
                case .player:
                    state.player.statuses.set(statusId, stacks: newStacks)
                case .enemy:
                    state.enemy.statuses.set(statusId, stacks: newStacks)
                }
                
                if newStacks <= 0 {
                    expired.append(statusId)
                }
            }
        }
        
        // 3) 发出状态过期事件
        for statusId in expired {
            guard let def = StatusRegistry.get(statusId) else { continue }
            let entityName = target == .player ? state.player.name : state.enemy.name
            emit(.statusExpired(target: entityName, effect: def.name))
        }
    }
    
    // MARK: Battle End Check
    
    private func checkBattleEnd() {
        if !state.enemy.isAlive {
            emit(.entityDied(entityId: state.enemy.id, name: state.enemy.name))
            state.isOver = true
            state.playerWon = true
            emit(.battleWon)
            // P4: 触发战斗结束（胜利）- 包括燃烧之血恢复生命
            triggerRelics(.battleEnd(won: true))
        } else if !state.player.isAlive {
            emit(.entityDied(entityId: state.player.id, name: state.player.name))
            state.isOver = true
            state.playerWon = false
            emit(.battleLost)
            // P4: 触发战斗结束（失败）
            triggerRelics(.battleEnd(won: false))
        }
    }
    
    // MARK: Relic System (P4)
    
    /// 触发遗物效果
    private func triggerRelics(_ trigger: BattleTrigger) {
        let snapshot = BattleSnapshot(
            turn: state.turn,
            player: state.player,
            enemy: state.enemy,
            energy: state.energy
        )
        
        let effects = relicManager.onBattleTrigger(trigger, snapshot: snapshot)
        for effect in effects {
            apply(effect)
        }
    }
}

