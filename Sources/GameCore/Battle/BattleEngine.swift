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
    private let enemyAI: any EnemyAI
    private var lastEnemyIntent: EnemyIntent? = nil
    
    // MARK: - Initialization
    
    /// 初始化战斗引擎
    /// - Parameters:
    ///   - player: 玩家实体
    ///   - enemy: 敌人实体
    ///   - enemyAI: 敌人 AI
    ///   - deck: 初始牌组
    ///   - seed: 随机数种子（用于可复现性）
    public init(
        player: Entity,
        enemy: Entity,
        enemyAI: any EnemyAI,
        deck: [Card],
        seed: UInt64
    ) {
        self.rng = SeededRNG(seed: seed)
        self.enemyAI = enemyAI
        self.state = BattleState(player: player, enemy: enemy)
        
        // 初始化抽牌堆并洗牌
        self.state.drawPile = rng.shuffled(deck)
    }
    
    /// 使用默认配置初始化
    public convenience init(seed: UInt64) {
        // 使用 RNG 随机选择敌人
        var tempRNG = SeededRNG(seed: seed)
        let enemyKinds: [EnemyKind] = [.jawWorm, .cultist, .louseGreen, .louseRed, .slimeMediumAcid]
        let selectedKind = enemyKinds[tempRNG.nextInt(upperBound: enemyKinds.count)]
        
        self.init(
            player: createDefaultPlayer(),
            enemy: createEnemy(kind: selectedKind, rng: &tempRNG),
            enemyAI: getEnemyAI(kind: selectedKind),
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
            card.cost <= state.energy ? index : nil
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
        
        // 决定敌人意图
        state.enemy.intent = enemyAI.decideIntent(
            enemy: state.enemy,
            player: state.player,
            turn: state.turn,
            lastIntent: lastEnemyIntent,
            rng: &rng
        )
        
        // 发送意图事件（用于日志）
        emit(.enemyIntent(
            enemyId: state.enemy.id,
            action: state.enemy.intent.displayText,
            damage: 0  // 伤害已包含在 displayText 中
        ))
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
        emit(.enemyAction(enemyId: state.enemy.id, action: state.enemy.intent.displayText))
        
        // 使用 AI 执行意图
        let aiEvents = enemyAI.executeIntent(
            intent: state.enemy.intent,
            enemy: &state.enemy,
            player: &state.player
        )
        
        // 发送 AI 生成的事件
        for event in aiEvents {
            emit(event)
            
            // 统计伤害
            if case .damageDealt(_, _, let dealt, _) = event {
                battleStats.totalDamageTaken += dealt
            }
        }
        
        // 保存当前意图供下次使用
        lastEnemyIntent = state.enemy.intent
        
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
        
        // 验证能量
        guard state.energy >= card.cost else {
            emit(.notEnoughEnergy(required: card.cost, available: state.energy))
            return false
        }
        
        // 消耗能量
        state.energy -= card.cost
        
        // 从手牌移除
        state.hand.remove(at: handIndex)
        
        emit(.played(cardId: card.id, cardName: card.displayName, cost: card.cost))
        
        // 执行卡牌效果
        executeCardEffect(card)
        
        // 卡牌进入弃牌堆
        state.discardPile.append(card)
        
        // 检查战斗是否结束
        checkBattleEnd()
        
        return true
    }
    
    private func executeCardEffect(_ card: Card) {
        // 统计卡牌使用
        battleStats.cardsPlayed += 1
        switch card.kind {
        case .strike, .pommelStrike, .bash, .clothesline:
            battleStats.strikesPlayed += 1
        case .defend, .shrugItOff:
            battleStats.defendsPlayed += 1
        case .inflame:
            battleStats.skillsPlayed += 1
        }
        
        switch card.kind {
        case .strike:
            // 对敌人造成伤害（应用伤害修正）
            let finalDamage = calculateDamage(baseDamage: card.damage, attacker: state.player, defender: state.enemy)
            let (dealt, blocked) = state.enemy.takeDamage(finalDamage)
            battleStats.totalDamageDealt += dealt
            emit(.damageDealt(
                source: state.player.name,
                target: state.enemy.name,
                amount: dealt,
                blocked: blocked
            ))
            
        case .pommelStrike:
            // 造成伤害
            let finalDamage = calculateDamage(baseDamage: card.damage, attacker: state.player, defender: state.enemy)
            let (dealt, blocked) = state.enemy.takeDamage(finalDamage)
            battleStats.totalDamageDealt += dealt
            emit(.damageDealt(
                source: state.player.name,
                target: state.enemy.name,
                amount: dealt,
                blocked: blocked
            ))
            // 抽牌
            drawCards(card.drawCount)
            
        case .defend:
            // 获得格挡
            state.player.gainBlock(card.block)
            battleStats.totalBlockGained += card.block
            emit(.blockGained(target: state.player.name, amount: card.block))
            
        case .shrugItOff:
            // 获得格挡
            state.player.gainBlock(card.block)
            battleStats.totalBlockGained += card.block
            emit(.blockGained(target: state.player.name, amount: card.block))
            // 抽牌
            drawCards(card.drawCount)
            
        case .bash:
            // 造成伤害
            let finalDamage = calculateDamage(baseDamage: card.damage, attacker: state.player, defender: state.enemy)
            let (dealt, blocked) = state.enemy.takeDamage(finalDamage)
            battleStats.totalDamageDealt += dealt
            emit(.damageDealt(
                source: state.player.name,
                target: state.enemy.name,
                amount: dealt,
                blocked: blocked
            ))
            // 施加易伤
            if card.vulnerableApply > 0 {
                state.enemy.vulnerable += card.vulnerableApply
                emit(.statusApplied(target: state.enemy.name, effect: "易伤", stacks: card.vulnerableApply))
            }
            
        case .inflame:
            // 获得力量
            if card.strengthGain > 0 {
                state.player.strength += card.strengthGain
                emit(.statusApplied(target: state.player.name, effect: "力量", stacks: card.strengthGain))
            }
            
        case .clothesline:
            // 造成伤害
            let finalDamage = calculateDamage(baseDamage: card.damage, attacker: state.player, defender: state.enemy)
            let (dealt, blocked) = state.enemy.takeDamage(finalDamage)
            battleStats.totalDamageDealt += dealt
            emit(.damageDealt(
                source: state.player.name,
                target: state.enemy.name,
                amount: dealt,
                blocked: blocked
            ))
            // 施加虚弱
            if card.weakApply > 0 {
                state.enemy.weak += card.weakApply
                emit(.statusApplied(target: state.enemy.name, effect: "虚弱", stacks: card.weakApply))
            }
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
        emit(.drew(cardId: card.id, cardName: card.displayName))
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

