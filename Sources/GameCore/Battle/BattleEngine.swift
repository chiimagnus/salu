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

    // MARK: - Effect Execution (P1)

    private enum EffectActor {
        case player
        case enemy
    }

    private func apply(_ effect: BattleEffect, actor: EffectActor) {
        switch effect {
        case .dealDamage(let target, let base):
            let attacker: Entity = (actor == .player) ? state.player : state.enemy
            let finalTargetIsPlayer = (target == .player)
            let defender: Entity = finalTargetIsPlayer ? state.player : state.enemy

            let finalDamage = calculateDamage(baseDamage: base, attacker: attacker, defender: defender)

            if finalTargetIsPlayer {
                let (dealt, blocked) = state.player.takeDamage(finalDamage)
                battleStats.totalDamageTaken += dealt
                emit(.damageDealt(source: attacker.name, target: state.player.name, amount: dealt, blocked: blocked))
            } else {
                let (dealt, blocked) = state.enemy.takeDamage(finalDamage)
                battleStats.totalDamageDealt += dealt
                emit(.damageDealt(source: attacker.name, target: state.enemy.name, amount: dealt, blocked: blocked))
            }

        case .gainBlock(let target, let amount):
            if target == .player {
                state.player.gainBlock(amount)
                battleStats.totalBlockGained += amount
                emit(.blockGained(target: state.player.name, amount: amount))
            } else {
                state.enemy.gainBlock(amount)
                emit(.blockGained(target: state.enemy.name, amount: amount))
            }

        case .drawCards(let count):
            drawCards(count)

        case .gainEnergy(let amount):
            guard amount != 0 else { return }
            state.energy += amount
            emit(.energyGained(amount: amount, current: state.energy))

        case .applyStatus(let target, let statusId, let stacks):
            if target == .player {
                applyStatusById(to: &state.player, statusId: statusId, stacks: stacks)
            } else {
                applyStatusById(to: &state.enemy, statusId: statusId, stacks: stacks)
            }

        case .heal(let target, let amount):
            if target == .player {
                let old = state.player.currentHP
                state.player.currentHP = min(state.player.maxHP, state.player.currentHP + amount)
                let healed = state.player.currentHP - old
                if healed > 0 {
                    emit(.healed(target: state.player.name, amount: healed))
                }
            } else {
                let old = state.enemy.currentHP
                state.enemy.currentHP = min(state.enemy.maxHP, state.enemy.currentHP + amount)
                let healed = state.enemy.currentHP - old
                if healed > 0 {
                    emit(.healed(target: state.enemy.name, amount: healed))
                }
            }
        }
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

    /// 根据 StatusID 施加状态（P1 版本：映射到 Entity 硬编码字段）
    private func applyStatusById(to target: inout Entity, statusId: StatusID, stacks: Int) {
        switch statusId.rawValue {
        case "vulnerable":
            target.vulnerable += stacks
            emit(.statusApplied(target: target.name, effect: "易伤", stacks: stacks))
        case "weak":
            target.weak += stacks
            emit(.statusApplied(target: target.name, effect: "虚弱", stacks: stacks))
        case "strength":
            target.strength += stacks
            emit(.statusApplied(target: target.name, effect: "力量", stacks: stacks))
        default:
            emit(.statusApplied(target: target.name, effect: statusId.rawValue, stacks: stacks))
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
        
        // 验证能量
        guard state.energy >= card.cost else {
            emit(.notEnoughEnergy(required: card.cost, available: state.energy))
            return false
        }
        
        // 消耗能量
        state.energy -= card.cost
        
        // 从手牌移除
        state.hand.remove(at: handIndex)
        
        emit(.played(cardId: card.cardId, cost: card.cost))
        
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

        let def = card.definition
        switch def.type {
        case .attack:
            battleStats.strikesPlayed += 1
        case .skill:
            battleStats.defendsPlayed += 1
        case .power:
            battleStats.skillsPlayed += 1
        }

        let snapshot = BattleSnapshot(
            turn: state.turn,
            player: state.player,
            enemy: state.enemy,
            energy: state.energy
        )

        let effects = def.play(snapshot: snapshot)
        for effect in effects {
            apply(effect, actor: .player)
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

