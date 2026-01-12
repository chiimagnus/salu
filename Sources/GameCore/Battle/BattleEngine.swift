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
    
    // P3: 占卜家遗物追踪
    /// 本回合是否已使用预知（用于破碎怀表遗物）
    private var foresightUsedThisTurn: Bool = false
    /// 本场战斗是否已使用改写（用于预言者手札遗物）
    private var rewriteUsedThisBattle: Bool = false
    /// 是否应该跳过下一次疯狂添加（用于预言者手札遗物）
    private var shouldSkipNextMadnessFromRewrite: Bool = false

    // P6: 赛弗 Boss 特殊机制（仅影响玩家下一回合）
    /// 下回合预知数量惩罚（回合开始时转入 thisTurn 后清零）
    private var foresightPenaltyNextTurn: Int = 0
    /// 本回合预知数量惩罚（对本回合所有预知生效）
    private var foresightPenaltyThisTurn: Int = 0
    /// 下回合第一张牌费用增加（回合开始时转入 thisTurn 后清零）
    private var firstCardCostIncreaseNextTurn: Int = 0
    /// 本回合第一张牌费用增加（仅首张出牌生效一次）
    private var firstCardCostIncreaseThisTurn: Int = 0
    /// 本回合是否已应用“首张牌费用增加”
    private var didApplyFirstCardCostIncreaseThisTurn: Bool = false
    /// 下回合回合开始后随机弃置手牌数量（用于赛弗“命运剥夺”等）
    private var discardRandomHandCountNextTurn: Int = 0

    // P7: 本回合预知次数（用于“预言回响”）
    private var foresightCountThisTurn: Int = 0
    
    /// 当前战斗携带的遗物（用于 UI 展示）
    public var relicIds: [RelicID] {
        relicManager.all
    }
    
    // MARK: - Initialization
    
    /// 初始化战斗引擎
    /// - Parameters:
    ///   - player: 玩家实体
    ///   - enemies: 敌人实体列表（顺序即战斗中的“槽位顺序”）
    ///   - deck: 初始牌组
    ///   - relicManager: 遗物管理器（P4 新增）
    ///   - seed: 随机数种子（用于可复现性）
    public init(
        player: Entity,
        enemies: [Entity],
        deck: [Card],
        relicManager: RelicManager = RelicManager(),
        seed: UInt64
    ) {
        self.rng = SeededRNG(seed: seed)
        self.state = BattleState(player: player, enemies: enemies)
        self.relicManager = relicManager
        
        // 初始化抽牌堆并洗牌
        self.state.drawPile = rng.shuffled(deck)
    }
    
    /// 使用默认配置初始化（随机选择敌人）
    public convenience init(seed: UInt64) {
        var tempRng = SeededRNG(seed: seed)
        let enemyId = Act1EnemyPool.randomWeak(rng: &tempRng)
        let enemy = createEnemy(enemyId: enemyId, instanceIndex: 0, rng: &tempRng)
        
        self.init(
            player: createDefaultPlayer(),
            enemies: [enemy],
            deck: createStarterDeck(),
            seed: seed
        )
    }
    
    // MARK: - Public Methods
    
    /// 开始战斗
    public func startBattle() {
        events.removeAll()
        emit(.battleStarted)

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
        case .playCard(let handIndex, let targetEnemyIndex):
            return playCard(at: handIndex, targetEnemyIndex: targetEnemyIndex)
            
        case .endTurn:
            endPlayerTurn()
            return true
        }
    }
    
    /// 获取当前可打出的手牌索引
    public var playableCardIndices: [Int] {
        state.hand.enumerated().compactMap { index, card in
            _ = card
            return costToPlay(cardAtHandIndex: index) <= state.energy ? index : nil
        }
    }

    /// 获取手牌中某张牌当前的实际费用（会包含“首张牌费用增加”等临时机制）
    public func costToPlay(cardAtHandIndex index: Int) -> Int {
        guard index >= 0, index < state.hand.count else { return 0 }
        let def = CardRegistry.require(state.hand[index].cardId)
        return effectiveCost(baseCost: def.cost)
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
    
    /// 计算最终伤害（通过 DamageCalculator 按 phase+priority 应用状态修正）
    ///
    /// P3 遗物支持：
    /// - 疯狂面具（madness_mask）：当玩家疯狂 ≥6 时，玩家攻击伤害 +50%
    private func calculateDamage(baseDamage: Int, attacker: Entity, defender: Entity, attackerIsPlayer: Bool = false) -> Int {
        var damage = DamageCalculator.calculate(baseDamage: baseDamage, attacker: attacker, defender: defender)
        
        // P3: 疯狂面具遗物 - 玩家攻击且疯狂 ≥6 时，攻击伤害 +50%
        if attackerIsPlayer && relicManager.has(MadnessMaskRelic.id) {
            let madnessStacks = state.player.statuses.stacks(of: Madness.id)
            if madnessStacks >= MadnessMaskRelic.madnessThreshold {
                damage = Int(Double(damage) * MadnessMaskRelic.damageMultiplier)
            }
        }
        
        return damage
    }

    // MARK: Target Resolution (P6)

    /// 将 EffectTarget 解析为当前战斗中的实体快照（用于计算/修正）
    ///
    private func resolveEntity(for target: EffectTarget) -> Entity {
        switch target {
        case .player:
            return state.player
        case .enemy(index: let index):
            // P2：多敌人结构
            if index >= 0, index < state.enemies.count {
                return state.enemies[index]
            }
            // 兜底：避免越界导致崩溃（后续 P3/P4 会在输入层保证合法索引）
            return state.enemies.first ?? state.player
        }
    }

    /// 将 EffectTarget 解析为用于事件/日志的展示名
    ///
    private func resolveDisplayName(for target: EffectTarget) -> String {
        switch target {
        case .player:
            return state.player.name
        case .enemy(index: let index):
            if index >= 0, index < state.enemies.count {
                return state.enemies[index].name
            }
            return state.enemies.first?.name ?? "敌人"
        }
    }

    // MARK: Turn Management
    
    private func startNewTurn() {
        state.turn += 1
        state.isPlayerTurn = true
        
        // P3: 重置本回合预知追踪（用于破碎怀表遗物）
        foresightUsedThisTurn = false
        // P7: 重置本回合预知计数（用于预言回响等）
        foresightCountThisTurn = 0

        // P6: 激活“下回合”机制，并重置一次性标记
        foresightPenaltyThisTurn = foresightPenaltyNextTurn
        foresightPenaltyNextTurn = 0
        firstCardCostIncreaseThisTurn = firstCardCostIncreaseNextTurn
        firstCardCostIncreaseNextTurn = 0
        didApplyFirstCardCostIncreaseThisTurn = false
        
        emit(.turnStarted(turn: state.turn))

        // 重置能量
        state.energy = state.maxEnergy
        emit(.energyReset(amount: state.energy))

        // P4: 触发战斗开始的遗物效果（仅第 1 回合）
        if state.turn == 1 {
            triggerRelics(.battleStart)
        }
        
        // P4: 触发回合开始的遗物效果（在能量重置之后，避免被覆盖）
        triggerRelics(.turnStart(turn: state.turn))
        
        // 清除玩家格挡
        if state.player.block > 0 {
            let clearedBlock = state.player.block
            state.player.clearBlock()
            emit(.blockCleared(target: state.player.name, amount: clearedBlock))
        }
        
        // P2: 状态递减现在由 processStatusesAtTurnEnd 处理（在回合结束时）
        
        // P0 占卜家序列：疯狂阈值检查（在抽牌前，因为阈值 1 会弃牌）
        checkMadnessThresholds()
        
        // 抽牌
        drawCards(cardsPerTurn)

        // P6: 赛弗“命运剥夺”等会在敌方回合设置“下回合随机弃牌”，需要在抽牌后执行
        applyScheduledRandomHandDiscardsIfNeeded()
        
        // AI 决定敌人意图
        decideEnemyIntents()
    }
    
    /// 让所有敌人 AI 决定下一个意图
    private func decideEnemyIntents() {
        for index in state.enemies.indices {
            guard state.enemies[index].isAlive else { continue }
            
            // P3: 使用 EnemyRegistry 获取定义并选择行动
            guard let enemyId = state.enemies[index].enemyId else {
                // 如果没有 enemyId（不应该发生），使用默认行动
                state.enemies[index].plannedMove = EnemyMove(
                    intent: EnemyIntentDisplay(icon: "❓", text: "未知"),
                    effects: []
                )
                emit(.enemyIntent(enemyId: state.enemies[index].id, action: "未知", damage: 0))
                continue
            }
            
            let def = EnemyRegistry.require(enemyId)
            let snapshot = BattleSnapshot(
                turn: state.turn,
                player: state.player,
                enemies: state.enemies,
                energy: state.energy
            )
            let move = def.chooseMove(selfIndex: index, snapshot: snapshot, rng: &rng)
            state.enemies[index].plannedMove = move
            
            // 发出敌人意图事件
            let intentDamage = move.intent.previewDamage ?? 0
            let actionName = move.intent.text
            emit(.enemyIntent(enemyId: state.enemies[index].id, action: actionName, damage: intentDamage))
        }
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
        
        // P0 占卜家序列：疯狂消减（回合结束时 -1）
        reduceMadness()

        // P4: 触发回合结束遗物效果（仅玩家回合结束）
        triggerRelics(.turnEnd(turn: state.turn))
        
        emit(.turnEnded(turn: state.turn))
        
        state.isPlayerTurn = false
        
        // 敌人行动
        executeEnemyTurn()
        
        // 如果战斗未结束，开始新回合
        if !state.isOver {
            // 清除敌人格挡（在敌人回合结束后、玩家回合开始前）
            for index in state.enemies.indices {
                if state.enemies[index].block > 0 {
                    let clearedBlock = state.enemies[index].block
                    state.enemies[index].clearBlock()
                    emit(.blockCleared(target: state.enemies[index].name, amount: clearedBlock))
                }
            }
            startNewTurn()
        }
    }
    
    private func executeEnemyTurn() {
        for index in state.enemies.indices {
            guard !state.isOver else { return }
            guard state.enemies[index].isAlive else { continue }
            
            // 执行敌人的计划行动（通过 BattleEffect）
            guard let move = state.enemies[index].plannedMove else {
                // 没有计划行动（不应该发生）
                emit(.enemyAction(enemyId: state.enemies[index].id, action: "跳过"))
                processStatusesAtTurnEnd(for: .enemy(index: index))
                checkBattleEnd()
                continue
            }
            
            emit(.enemyAction(enemyId: state.enemies[index].id, action: move.intent.text))
            
            // 执行所有效果
            for effect in move.effects {
                apply(effect)
                if state.isOver { break }
            }
            
            // 处理敌人回合结束的状态效果（触发 + 递减）
            processStatusesAtTurnEnd(for: .enemy(index: index))
            
            // 检查玩家是否死亡 / 是否全灭
            checkBattleEnd()
        }
    }
    
    // MARK: Card Playing
    
    private func playCard(at handIndex: Int, targetEnemyIndex: Int?) -> Bool {
        // 验证索引
        guard handIndex >= 0, handIndex < state.hand.count else {
            emit(.invalidAction(reason: "无效的卡牌索引"))
            return false
        }
        
        let card = state.hand[handIndex]
        let def = CardRegistry.require(card.cardId)
        let baseCost = def.cost
        let cost = effectiveCost(baseCost: baseCost)
        
        // 验证能量
        guard state.energy >= cost else {
            emit(.notEnoughEnergy(required: cost, available: state.energy))
            return false
        }

        // 解析目标（P6：多敌人 + 目标选择）
        let resolvedTargetEnemyIndex: Int?
        switch def.targeting {
        case .none:
            resolvedTargetEnemyIndex = nil
        case .singleEnemy:
            if let targetEnemyIndex {
                guard targetEnemyIndex >= 0, targetEnemyIndex < state.enemies.count else {
                    emit(.invalidAction(reason: "无效的敌人目标"))
                    return false
                }
                guard state.enemies[targetEnemyIndex].isAlive else {
                    emit(.invalidAction(reason: "目标已死亡"))
                    return false
                }
                resolvedTargetEnemyIndex = targetEnemyIndex
            } else {
                let aliveIndices = state.enemies.indices.filter { state.enemies[$0].isAlive }
                if aliveIndices.count == 1 {
                    resolvedTargetEnemyIndex = aliveIndices[0]
                } else if aliveIndices.isEmpty {
                    emit(.invalidAction(reason: "没有可选目标"))
                    return false
                } else {
                    emit(.invalidAction(reason: "该牌需要选择目标"))
                    return false
                }
            }
        }
        
        // P6: “下回合第一张牌费用 +N”只在本回合首次成功出牌时生效一次
        if cost != baseCost && !didApplyFirstCardCostIncreaseThisTurn {
            didApplyFirstCardCostIncreaseThisTurn = true
        }

        // 消耗能量
        state.energy -= cost
        
        // 从手牌移除
        state.hand.remove(at: handIndex)
        
        emit(.played(cardId: card.cardId, cost: cost))

        // P4: 触发打出卡牌的遗物效果
        triggerRelics(.cardPlayed(cardId: card.cardId))
        
        // 执行卡牌效果（新架构：通过 BattleEffect）
        executeCardEffect(card, targetEnemyIndex: resolvedTargetEnemyIndex)
        
        // 卡牌进入弃牌堆
        state.discardPile.append(card)
        
        // 检查战斗是否结束
        checkBattleEnd()
        
        return true
    }
    
    private func executeCardEffect(_ card: Card, targetEnemyIndex: Int?) {
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
            enemies: state.enemies,
            energy: state.energy
        )
        
        // 获取卡牌效果
        let effects = def.play(snapshot: snapshot, targetEnemyIndex: targetEnemyIndex)
        
        // 执行所有效果
        for effect in effects {
            apply(effect)
        }
    }
    
    /// 应用单个战斗效果（统一执行入口）
    private func apply(_ effect: BattleEffect) {
        switch effect {
        case .dealDamage(let source, let target, let base):
            applyDamage(source: source, target: target, base: base)
            
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
            
        // MARK: - 占卜家序列效果 (P1)
            
        case .foresight(let count):
            applyForesight(count: count)
            
        case .rewind(let count):
            applyRewind(count: count)
            
        case .clearMadness(let amount):
            applyClearMadness(amount: amount)
            
        case .rewriteIntent(let enemyIndex, let newIntent):
            applyRewriteIntent(enemyIndex: enemyIndex, newIntent: newIntent)

        // MARK: - 赛弗 Boss 特殊机制 (P6)

        case .applyForesightPenaltyNextTurn(let amount):
            applyForesightPenaltyNextTurn(amount: amount)

        case .applyFirstCardCostIncreaseNextTurn(let amount):
            applyFirstCardCostIncreaseNextTurn(amount: amount)

        case .discardRandomHand(let count):
            applyDiscardRandomHand(count: count)

        case .enemyHeal(let enemyIndex, let amount):
            applyHeal(target: .enemy(index: enemyIndex), amount: amount)

        // MARK: - 占卜家卡牌扩展 (P7)

        case .dealDamageBasedOnForesightCount(let source, let target, let basePerForesight):
            applyDamageBasedOnForesightCount(source: source, target: target, basePerForesight: basePerForesight)
        }
    }
    
    /// 应用伤害效果
    private func applyDamage(source: EffectTarget, target: EffectTarget, base: Int) {
        let attacker: Entity = resolveEntity(for: source)
        let defenderBefore: Entity = resolveEntity(for: target)
        
        // P3: 疯狂面具遗物需要知道攻击者是否为玩家
        let attackerIsPlayer = (source == .player)
        let finalDamage = calculateDamage(baseDamage: base, attacker: attacker, defender: defenderBefore, attackerIsPlayer: attackerIsPlayer)
        
        let damageResult: (dealt: Int, blocked: Int)
        switch target {
        case .player:
            damageResult = state.player.takeDamage(finalDamage)
            battleStats.totalDamageTaken += damageResult.dealt
        case .enemy(index: let enemyIndex):
            guard enemyIndex >= 0, enemyIndex < state.enemies.count else {
                emit(.invalidAction(reason: "无效的敌人索引"))
                return
            }
            
            let wasAlive = state.enemies[enemyIndex].isAlive
            damageResult = state.enemies[enemyIndex].takeDamage(finalDamage)
            battleStats.totalDamageDealt += damageResult.dealt
            
            // 敌人被击杀（P2：多敌人时应在击杀瞬间发出死亡事件）
            if wasAlive && !state.enemies[enemyIndex].isAlive {
                emit(.entityDied(entityId: state.enemies[enemyIndex].id, name: state.enemies[enemyIndex].name))
                triggerRelics(.enemyKilled)
            }
        }
        
        emit(.damageDealt(
            source: resolveDisplayName(for: source),
            target: resolveDisplayName(for: target),
            amount: damageResult.dealt,
            blocked: damageResult.blocked
        ))

        // P4: 触发伤害相关遗物效果（以玩家视角：造成伤害/受到伤害）
        switch target {
        case .enemy(index: _):
            triggerRelics(.damageDealt(amount: damageResult.dealt))
        case .player:
            triggerRelics(.damageTaken(amount: damageResult.dealt))
        }
    }
    
    /// 应用格挡效果
    private func applyBlock(target: EffectTarget, base: Int) {
        // 应用格挡修正（通过 BlockCalculator 按 phase+priority 排序）
        let entity = resolveEntity(for: target)
        let block = BlockCalculator.calculate(baseBlock: base, entity: entity)
        
        switch target {
        case .player:
            state.player.gainBlock(block)
            battleStats.totalBlockGained += block
            emit(.blockGained(target: state.player.name, amount: block))
            // P4: 触发获得格挡遗物效果（仅玩家）
            triggerRelics(.blockGained(amount: block))
        case .enemy(index: let enemyIndex):
            guard enemyIndex >= 0, enemyIndex < state.enemies.count else {
                emit(.invalidAction(reason: "无效的敌人索引"))
                return
            }
            state.enemies[enemyIndex].gainBlock(block)
            emit(.blockGained(target: state.enemies[enemyIndex].name, amount: block))
        }
    }
    
    /// 应用状态效果
    ///
    /// P3 遗物支持：
    /// - 预言者手札（prophet_notes）：首次改写时跳过疯狂添加
    private func applyStatusEffect(target: EffectTarget, statusId: StatusID, stacks: Int) {
        // P2: Now using StatusRegistry!
        guard let def = StatusRegistry.get(statusId) else {
            // Unknown status - skip silently
            return
        }
        
        // P3: 预言者手札遗物 - 首次改写后跳过疯狂添加
        if statusId == Madness.id && target == .player && stacks > 0 && shouldSkipNextMadnessFromRewrite {
            shouldSkipNextMadnessFromRewrite = false
            emit(.statusApplied(target: state.player.name, effect: "（预言者手札抵消疯狂）", stacks: 0))
            return
        }
        
        switch target {
        case .player:
            state.player.statuses.apply(statusId, stacks: stacks)
            emit(.statusApplied(target: state.player.name, effect: def.name, stacks: stacks))
        case .enemy(index: let enemyIndex):
            guard enemyIndex >= 0, enemyIndex < state.enemies.count else {
                emit(.invalidAction(reason: "无效的敌人索引"))
                return
            }
            state.enemies[enemyIndex].statuses.apply(statusId, stacks: stacks)
            emit(.statusApplied(target: state.enemies[enemyIndex].name, effect: def.name, stacks: stacks))
        }
    }
    
    /// 应用治疗效果
    private func applyHeal(target: EffectTarget, amount: Int) {
        switch target {
        case .player:
            state.player.currentHP = min(state.player.currentHP + amount, state.player.maxHP)
            // 治疗事件（目前没有对应的 BattleEvent，暂不 emit）
        case .enemy(index: let enemyIndex):
            guard enemyIndex >= 0, enemyIndex < state.enemies.count else {
                emit(.invalidAction(reason: "无效的敌人索引"))
                return
            }
            state.enemies[enemyIndex].currentHP = min(state.enemies[enemyIndex].currentHP + amount, state.enemies[enemyIndex].maxHP)
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

        // P4: 触发抽到卡牌的遗物效果
        triggerRelics(.cardDrawn(cardId: card.cardId))
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
        let entity = resolveEntity(for: target)

        let snapshot = BattleSnapshot(
            turn: state.turn,
            player: state.player,
            enemies: state.enemies,
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
                case .enemy(index: let enemyIndex):
                    guard enemyIndex >= 0, enemyIndex < state.enemies.count else {
                        emit(.invalidAction(reason: "无效的敌人索引"))
                        return
                    }
                    state.enemies[enemyIndex].statuses.set(statusId, stacks: newStacks)
                }
                
                if newStacks <= 0 {
                    expired.append(statusId)
                }
            }
        }
        
        // 3) 发出状态过期事件
        for statusId in expired {
            guard let def = StatusRegistry.get(statusId) else { continue }
            let entityName = resolveDisplayName(for: target)
            emit(.statusExpired(target: entityName, effect: def.name))
        }
    }
    
    // MARK: Battle End Check
    
    private func checkBattleEnd() {
        guard !state.isOver else { return }
        
        if state.enemies.allSatisfy({ !$0.isAlive }) {
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
    
    // MARK: - Madness System (P0 占卜家序列)
    
    /// 检查玩家疯狂阈值并触发效果（在回合开始、抽牌前调用）
    ///
    /// 时机说明：
    /// - 阈值 1（弃牌）在抽牌前检查，如果手牌为空则跳过（与杀戮尖塔"时钟"遗物行为一致）
    /// - 阈值 2（虚弱）立即生效
    /// - 阈值 3（增伤）由 Madness.modifyIncomingDamage 被动生效
    ///
    /// P3 遗物支持：
    /// - 理智之锚（sanity_anchor）：所有阈值 +3
    private func checkMadnessThresholds() {
        let madnessStacks = state.player.statuses.stacks(of: Madness.id)
        guard madnessStacks > 0 else { return }
        
        // P3: 理智之锚遗物使所有阈值 +3
        let thresholdOffset = relicManager.has(SanityAnchorRelic.id) ? SanityAnchorRelic.thresholdOffset : 0
        let effectiveThreshold1 = Madness.threshold1 + thresholdOffset
        let effectiveThreshold2 = Madness.threshold2 + thresholdOffset
        let effectiveThreshold3 = Madness.threshold3 + thresholdOffset
        
        // 阈值 1（≥3 层，或理智之锚时 ≥6 层）：随机弃 1 张手牌（如果有的话）
        // 注意：当前版本没有"保留手牌"效果，所以回合开始时手牌通常为空
        // 如果后续加入保留手牌效果，这里会生效
        if madnessStacks >= effectiveThreshold1 && !state.hand.isEmpty {
            let discardIndex = rng.nextInt(upperBound: state.hand.count)
            let discardedCard = state.hand.remove(at: discardIndex)
            state.discardPile.append(discardedCard)
            emit(.madnessDiscard(cardId: discardedCard.cardId))
            emit(.madnessThreshold(level: 1, effect: "随机弃 1 张牌"))
        }
        
        // 阈值 2（≥6 层，或理智之锚时 ≥9 层）：获得虚弱 1
        if madnessStacks >= effectiveThreshold2 {
            applyStatusEffect(target: .player, statusId: Weak.id, stacks: 1)
            emit(.madnessThreshold(level: 2, effect: "获得虚弱 1"))
        }
        
        // 阈值 3（≥10 层，或理智之锚时 ≥13 层）的"受到伤害 +50%"由 Madness.modifyIncomingDamage 处理
        // 这里只发出提示事件
        if madnessStacks >= effectiveThreshold3 {
            emit(.madnessThreshold(level: 3, effect: "受到伤害 +50%"))
        }
    }
    
    /// 回合结束时疯狂 -1
    private func reduceMadness() {
        let currentMadness = state.player.statuses.stacks(of: Madness.id)
        if currentMadness > 0 {
            state.player.statuses.apply(Madness.id, stacks: -1)
            let newMadness = state.player.statuses.stacks(of: Madness.id)
            emit(.madnessReduced(from: currentMadness, to: newMadness))
        }
    }
    
    // MARK: - Seer Sequence Mechanics (P1 占卜家序列机制)
    
    /// 应用预知效果（简化版：自动选择第一张攻击牌）
    ///
    /// 预知 N = 查看抽牌堆顶 N 张牌，选 1 张入手，其余按原顺序放回
    /// 简化逻辑：自动选择第一张攻击牌；如果没有攻击牌则选择第一张
    ///
    /// P3 遗物支持：
    /// - 破碎怀表（broken_watch）：每回合首次预知时，额外预知 1 张
    private func applyForesight(count: Int) {
        guard count > 0, !state.drawPile.isEmpty else { return }
        
        // P3: 破碎怀表遗物 - 每回合首次预知时，额外预知 1 张
        var effectiveCount = count
        if !foresightUsedThisTurn && relicManager.has(BrokenWatchRelic.id) {
            effectiveCount += 1
        }
        foresightUsedThisTurn = true

        // P6: 赛弗“预知反制”会在本回合对所有预知施加数量惩罚
        if foresightPenaltyThisTurn > 0 {
            effectiveCount = max(0, effectiveCount - foresightPenaltyThisTurn)
        }
        guard effectiveCount > 0 else { return }

        // P7: 记录本回合预知次数（用于“预言回响”等）
        foresightCountThisTurn += 1
        
        // 取出顶部 count 张（drawPile 是 LIFO，末尾是顶部）
        let actualCount = min(effectiveCount, state.drawPile.count)
        // 反转使第一张（顶部）在数组开头
        let topCards = Array(state.drawPile.suffix(actualCount).reversed())
        state.drawPile.removeLast(actualCount)
        
        // 选择第一张攻击牌（简化逻辑）
        var chosenIndex = 0
        for (index, card) in topCards.enumerated() {
            let def = CardRegistry.require(card.cardId)
            if def.type == .attack {
                chosenIndex = index
                break
            }
        }
        
        // 选中的牌入手
        let chosenCard = topCards[chosenIndex]
        state.hand.append(chosenCard)
        emit(.foresightChosen(cardId: chosenCard.cardId, fromCount: actualCount))
        
        // 其余牌按原顺序放回（顶部放在 drawPile 末尾）
        // 需要反向遍历以保持原顺序：原来的第一张应该回到顶部
        for index in (0..<topCards.count).reversed() {
            if index != chosenIndex {
                state.drawPile.append(topCards[index])
            }
        }

        // P7：序列共鸣（能力）——本场战斗中，每次预知后获得格挡
        let resonanceBlock = state.player.statuses.stacks(of: SequenceResonance.id)
        if resonanceBlock > 0 {
            applyBlock(target: .player, base: resonanceBlock)
        }
    }
    
    /// 应用回溯效果
    ///
    /// 回溯 N = 从弃牌堆选取最近 N 张牌返回手牌
    private func applyRewind(count: Int) {
        guard count > 0, !state.discardPile.isEmpty else { return }
        
        let actualCount = min(count, state.discardPile.count)
        for _ in 0..<actualCount {
            let card = state.discardPile.removeLast()
            state.hand.append(card)
            emit(.rewindCard(cardId: card.cardId))
        }
    }
    
    /// 应用清除疯狂效果
    ///
    /// - Parameter amount: 清除数量，0 表示清除所有
    private func applyClearMadness(amount: Int) {
        let currentMadness = state.player.statuses.stacks(of: Madness.id)
        guard currentMadness > 0 else { return }
        
        if amount == 0 {
            // 清除所有疯狂
            state.player.statuses.set(Madness.id, stacks: 0)
            emit(.madnessCleared(amount: currentMadness))
        } else {
            // 清除指定数量
            let actualClear = min(amount, currentMadness)
            state.player.statuses.apply(Madness.id, stacks: -actualClear)
            emit(.madnessCleared(amount: actualClear))
        }
    }
    
    /// 应用改写敌人意图效果
    ///
    /// - Parameters:
    ///   - enemyIndex: 目标敌人索引
    ///   - newIntent: 新的意图类型
    ///
    /// P3 遗物支持：
    /// - 预言者手札（prophet_notes）：每场战斗首次使用改写时，不获得疯狂
    private func applyRewriteIntent(enemyIndex: Int, newIntent: RewrittenIntent) {
        // 校验敌人索引有效性
        guard enemyIndex >= 0, enemyIndex < state.enemies.count else { return }
        guard state.enemies[enemyIndex].isAlive else { return }
        guard let oldMove = state.enemies[enemyIndex].plannedMove else { return }
        
        // P3: 预言者手札遗物 - 首次改写时不获得疯狂
        if !rewriteUsedThisBattle && relicManager.has(ProphetNotesRelic.id) {
            shouldSkipNextMadnessFromRewrite = true
        }
        rewriteUsedThisBattle = true
        
        // 构建新的 EnemyMove
        let newMove: EnemyMove
        switch newIntent {
        case .defend(let block):
            newMove = EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: "防御（被改写）"),
                effects: [.gainBlock(target: .enemy(index: enemyIndex), base: block)]
            )
        case .skip:
            newMove = EnemyMove(
                intent: EnemyIntentDisplay(icon: "💫", text: "眩晕（被改写）"),
                effects: []
            )
        }
        
        // 替换意图
        state.enemies[enemyIndex].plannedMove = newMove
        emit(.intentRewritten(
            enemyName: state.enemies[enemyIndex].name,
            oldIntent: oldMove.intent.text,
            newIntent: newMove.intent.text
        ))
    }

    // MARK: - Cipher Boss Mechanics (P6 赛弗 Boss 特殊机制)

    /// 赛弗：下回合预知数量惩罚
    private func applyForesightPenaltyNextTurn(amount: Int) {
        guard amount > 0 else { return }
        foresightPenaltyNextTurn = max(0, foresightPenaltyNextTurn + amount)
    }

    /// 赛弗：下回合第一张牌费用增加
    private func applyFirstCardCostIncreaseNextTurn(amount: Int) {
        guard amount > 0 else { return }
        firstCardCostIncreaseNextTurn = max(0, firstCardCostIncreaseNextTurn + amount)
    }

    /// 赛弗：随机弃置手牌
    ///
    /// 注意：
    /// - 当前战斗循环中，玩家回合结束会弃置所有手牌，因此敌方回合执行“弃置手牌”通常会在手牌为空时无效果。
    /// - 为了让 Boss 机制可感知：当该效果在敌方回合触发时，会被延迟到下回合抽牌后执行。
    private func applyDiscardRandomHand(count: Int) {
        guard count > 0 else { return }

        if state.isPlayerTurn {
            discardRandomFromHandNow(count: count)
        } else {
            discardRandomHandCountNextTurn += count
        }
    }

    /// 回合开始（抽牌后）处理延迟弃牌
    private func applyScheduledRandomHandDiscardsIfNeeded() {
        guard discardRandomHandCountNextTurn > 0 else { return }
        let count = discardRandomHandCountNextTurn
        discardRandomHandCountNextTurn = 0
        discardRandomFromHandNow(count: count)
    }

    private func discardRandomFromHandNow(count: Int) {
        guard count > 0, !state.hand.isEmpty else { return }

        let actualCount = min(count, state.hand.count)
        for _ in 0..<actualCount {
            let idx = rng.nextInt(upperBound: state.hand.count)
            let card = state.hand.remove(at: idx)
            state.discardPile.append(card)
        }
        emit(.handDiscarded(count: actualCount))
    }

    /// 计算当前出牌的实际费用（应用“首张牌费用增加”等临时机制）
    private func effectiveCost(baseCost: Int) -> Int {
        guard baseCost >= 0 else { return 0 }
        if firstCardCostIncreaseThisTurn > 0 && !didApplyFirstCardCostIncreaseThisTurn {
            return max(0, baseCost + firstCardCostIncreaseThisTurn)
        }
        return baseCost
    }

    // MARK: - Seer Advanced Cards (P7 占卜家扩展卡牌)

    private func applyDamageBasedOnForesightCount(
        source: EffectTarget,
        target: EffectTarget,
        basePerForesight: Int
    ) {
        guard basePerForesight > 0 else { return }
        let times = max(0, foresightCountThisTurn)
        let base = basePerForesight * times
        applyDamage(source: source, target: target, base: base)
    }
    
    // MARK: Relic System (P4)
    
    /// 触发遗物效果
    private func triggerRelics(_ trigger: BattleTrigger) {
        let snapshot = BattleSnapshot(
            turn: state.turn,
            player: state.player,
            enemies: state.enemies,
            energy: state.energy
        )
        
        let effects = relicManager.onBattleTrigger(trigger, snapshot: snapshot)
        for effect in effects {
            apply(effect)
        }
    }
}
