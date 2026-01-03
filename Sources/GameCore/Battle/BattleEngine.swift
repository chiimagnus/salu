/// 战斗引擎
/// 负责管理战斗状态、处理玩家动作、执行敌人AI
public final class BattleEngine: @unchecked Sendable {
    
    // MARK: - Properties
    
    public private(set) var state: BattleState
    public private(set) var events: [BattleEvent] = []
    
    /// 战斗统计（累积，不会被清除）
    public private(set) var battleStats: BattleStats = BattleStats()
    
    private var rng: SeededRNG
    private let cardsPerTurn: Int = 5
    
    /// 敌人 AI 决策器
    private let enemyAI: any EnemyAI
    
    // MARK: - Initialization
    
    /// 初始化战斗引擎
    /// - Parameters:
    ///   - player: 玩家实体
    ///   - enemy: 敌人实体
    ///   - deck: 初始牌组
    ///   - seed: 随机数种子（用于可复现性）
    public init(
        player: Entity,
        enemy: Entity,
        deck: [Card],
        seed: UInt64
    ) {
        self.rng = SeededRNG(seed: seed)
        self.state = BattleState(player: player, enemy: enemy)
        
        // 初始化敌人 AI
        let kind = enemy.kind ?? .jawWorm
        self.enemyAI = EnemyAIFactory.create(for: kind)
        
        // 初始化抽牌堆并洗牌
        self.state.drawPile = rng.shuffled(deck)
    }
    
    /// 使用默认配置初始化（随机选择敌人）
    public convenience init(seed: UInt64) {
        var tempRng = SeededRNG(seed: seed)
        let enemyKind = Act1EnemyPool.randomWeak(rng: &tempRng)
        let enemy = createEnemy(kind: enemyKind, rng: &tempRng)
        
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
        
        // 力量加成
        damage += attacker.strength
        
        // 虚弱减伤（-25%，向下取整）
        if attacker.weak > 0 {
            damage = Int(Double(damage) * 0.75)
        }
        
        // 易伤增伤（+50%，向下取整）
        if defender.vulnerable > 0 {
            damage = Int(Double(damage) * 1.5)
        }
        
        return max(0, damage)
    }
    
    // MARK: Turn Management
    
    private func startNewTurn() {
        state.turn += 1
        state.isPlayerTurn = true
        
        emit(.turnStarted(turn: state.turn))
        
        // 重置能量
        state.energy = state.maxEnergy
        emit(.energyReset(amount: state.energy))
        
        // 清除玩家格挡
        if state.player.block > 0 {
            let clearedBlock = state.player.block
            state.player.clearBlock()
            emit(.blockCleared(target: state.player.name, amount: clearedBlock))
        }
        
        // 递减玩家状态效果
        let playerExpired = state.player.tickStatusEffects()
        for effect in playerExpired {
            emit(.statusExpired(target: state.player.name, effect: effect))
        }
        
        // 递减敌人状态效果
        let enemyExpired = state.enemy.tickStatusEffects()
        for effect in enemyExpired {
            emit(.statusExpired(target: state.enemy.name, effect: effect))
        }
        
        // 抽牌
        drawCards(cardsPerTurn)
        
        // AI 决定敌人意图
        decideEnemyIntent()
    }
    
    /// 让敌人 AI 决定下一个意图
    private func decideEnemyIntent() {
        let intent = enemyAI.decideIntent(
            enemy: state.enemy,
            player: state.player,
            turn: state.turn,
            rng: &rng
        )
        state.enemy.intent = intent
        
        // 发出敌人意图事件
        let intentDamage = intent.damageValue ?? 0
        let actionName = intent.displayText
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
        let intent = state.enemy.intent
        emit(.enemyAction(enemyId: state.enemy.id, action: intent.displayText))
        
        switch intent {
        case .attack(let baseDamage):
            // 纯攻击
            let finalDamage = calculateDamage(baseDamage: baseDamage, attacker: state.enemy, defender: state.player)
            let (dealt, blocked) = state.player.takeDamage(finalDamage)
            battleStats.totalDamageTaken += dealt
            emit(.damageDealt(
                source: state.enemy.name,
                target: state.player.name,
                amount: dealt,
                blocked: blocked
            ))
            
        case .attackDebuff(let baseDamage, let debuff, let stacks):
            // 攻击 + Debuff
            let finalDamage = calculateDamage(baseDamage: baseDamage, attacker: state.enemy, defender: state.player)
            let (dealt, blocked) = state.player.takeDamage(finalDamage)
            battleStats.totalDamageTaken += dealt
            emit(.damageDealt(
                source: state.enemy.name,
                target: state.player.name,
                amount: dealt,
                blocked: blocked
            ))
            
            // 施加 Debuff
            applyDebuff(to: &state.player, debuff: debuff, stacks: stacks)
            
        case .defend(let block):
            // 防御
            state.enemy.gainBlock(block)
            emit(.blockGained(target: state.enemy.name, amount: block))
            
        case .buff(let name, let stacks):
            // 增益（目前只支持力量）
            if name == "力量" || name == "仪式" || name == "卷曲" {
                state.enemy.strength += stacks
                emit(.statusApplied(target: state.enemy.name, effect: name, stacks: stacks))
            }
            
        case .unknown:
            // 未知意图，默认攻击
            let data = EnemyData.get(state.enemy.kind ?? .jawWorm)
            let finalDamage = calculateDamage(baseDamage: data.baseAttackDamage, attacker: state.enemy, defender: state.player)
            let (dealt, blocked) = state.player.takeDamage(finalDamage)
            battleStats.totalDamageTaken += dealt
            emit(.damageDealt(
                source: state.enemy.name,
                target: state.player.name,
                amount: dealt,
                blocked: blocked
            ))
        }
        
        // 检查玩家是否死亡
        checkBattleEnd()
    }
    
    /// 对目标施加 Debuff
    private func applyDebuff(to target: inout Entity, debuff: String, stacks: Int) {
        switch debuff {
        case "虚弱":
            target.weak += stacks
            emit(.statusApplied(target: target.name, effect: "虚弱", stacks: stacks))
        case "易伤":
            target.vulnerable += stacks
            emit(.statusApplied(target: target.name, effect: "易伤", stacks: stacks))
        default:
            break
        }
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
        switch target {
        case .player:
            state.player.gainBlock(base)
            battleStats.totalBlockGained += base
            emit(.blockGained(target: state.player.name, amount: base))
        case .enemy:
            state.enemy.gainBlock(base)
            emit(.blockGained(target: state.enemy.name, amount: base))
        }
    }
    
    /// 应用状态效果
    private func applyStatusEffect(target: EffectTarget, statusId: StatusID, stacks: Int) {
        let entityName: String
        
        // TODO(P2): This hardcoded status handling will be replaced with StatusRegistry
        // in Phase 2 (Status Effect System Protocol-Driven)
        // Currently using hardcoded string matching as a temporary solution
        
        switch target {
        case .player:
            entityName = state.player.name
            // 根据 statusId 应用状态（目前硬编码，P2 会重构）
            switch statusId.rawValue {
            case "vulnerable":
                state.player.vulnerable += stacks
                emit(.statusApplied(target: entityName, effect: "易伤", stacks: stacks))
            case "weak":
                state.player.weak += stacks
                emit(.statusApplied(target: entityName, effect: "虚弱", stacks: stacks))
            case "strength":
                state.player.strength += stacks
                emit(.statusApplied(target: entityName, effect: "力量", stacks: stacks))
            default:
                // Silently ignore unknown status effects for now
                // P2 will add proper error handling via StatusRegistry
                break
            }
        case .enemy:
            entityName = state.enemy.name
            // 根据 statusId 应用状态（目前硬编码，P2 会重构）
            switch statusId.rawValue {
            case "vulnerable":
                state.enemy.vulnerable += stacks
                emit(.statusApplied(target: entityName, effect: "易伤", stacks: stacks))
            case "weak":
                state.enemy.weak += stacks
                emit(.statusApplied(target: entityName, effect: "虚弱", stacks: stacks))
            case "strength":
                state.enemy.strength += stacks
                emit(.statusApplied(target: entityName, effect: "力量", stacks: stacks))
            default:
                // Silently ignore unknown status effects for now
                // P2 will add proper error handling via StatusRegistry
                break
            }
        }
    }
    
    /// 应用治疗效果
    private func applyHeal(target: EffectTarget, amount: Int) {
        switch target {
        case .player:
            let oldHP = state.player.currentHP
            state.player.currentHP = min(state.player.currentHP + amount, state.player.maxHP)
            // 治疗事件（目前没有对应的 BattleEvent，暂不 emit）
        case .enemy:
            let oldHP = state.enemy.currentHP
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
    
    // MARK: Battle End Check
    
    private func checkBattleEnd() {
        if !state.enemy.isAlive {
            emit(.entityDied(entityId: state.enemy.id, name: state.enemy.name))
            state.isOver = true
            state.playerWon = true
            emit(.battleWon)
        } else if !state.player.isAlive {
            emit(.entityDied(entityId: state.player.id, name: state.player.name))
            state.isOver = true
            state.playerWon = false
            emit(.battleLost)
        }
    }
}

