/// 冒险状态
/// 管理整个冒险过程中的玩家状态、地图进度等
public struct RunState: Sendable {
    
    // MARK: - 属性
    
    /// 玩家实体（HP 在战斗间保持）
    public var player: Entity
    
    /// 当前牌组
    public var deck: [Card]
    
    /// 当前金币
    public var gold: Int
    
    /// 遗物管理器（P4 新增）
    public var relicManager: RelicManager

    /// 消耗品列表（P4 新增）
    /// - Note: 1.0 版本默认最多 3 个槽位
    public private(set) var consumables: [ConsumableID]
    
    /// 地图节点
    public var map: [MapNode]
    
    /// 当前所在节点 ID
    public var currentNodeId: String?
    
    /// 随机种子
    public let seed: UInt64
    
    /// 当前楼层（Act）
    public var floor: Int
    
    /// 最大楼层（Act 数）
    /// - Note: 用于支持多幕（例如 Act1→Act2）。
    public let maxFloor: Int
    
    /// 冒险是否结束
    public var isOver: Bool
    
    /// 是否通关（击败 Boss）
    public var won: Bool
    
    // MARK: - 初始化
    
    public init(
        player: Entity,
        deck: [Card],
        gold: Int = RunState.startingGold,
        relicManager: RelicManager = RelicManager(),
        consumables: [ConsumableID] = [],
        map: [MapNode],
        seed: UInt64,
        floor: Int = 1,
        maxFloor: Int = 3
    ) {
        self.player = player
        self.deck = deck
        self.gold = gold
        self.relicManager = relicManager
        self.consumables = Array(consumables.prefix(RunState.maxConsumableSlots))
        self.map = map
        self.currentNodeId = nil
        self.seed = seed
        self.floor = floor
        self.maxFloor = maxFloor
        self.isOver = false
        self.won = false
    }
    
    /// 使用默认配置创建新冒险
    public static func newRun(seed: UInt64) -> RunState {
        let player = createDefaultPlayer()
        let deck = createStarterDeck()
        let map = MapGenerator.generateBranching(seed: seed)
        
        // 添加起始遗物（燃烧之血）
        var relicManager = RelicManager()
        relicManager.add("burning_blood")
        
        return RunState(
            player: player,
            deck: deck,
            gold: RunState.startingGold,
            relicManager: relicManager,
            consumables: [],
            map: map,
            seed: seed,
            floor: 1,
            maxFloor: 3
        )
    }
    
    // MARK: - 节点操作
    
    /// 获取当前可选择的节点
    public var accessibleNodes: [MapNode] {
        map.accessibleNodes
    }
    
    /// 获取当前节点
    public var currentNode: MapNode? {
        guard let id = currentNodeId else { return nil }
        return map.node(withId: id)
    }
    
    /// 进入指定节点
    /// - Parameter nodeId: 目标节点 ID
    /// - Returns: 是否成功进入
    public mutating func enterNode(_ nodeId: String) -> Bool {
        guard let nodeIndex = map.nodeIndex(withId: nodeId) else {
            return false
        }
        
        // 检查节点是否可进入
        guard map[nodeIndex].isAccessible else {
            return false
        }
        
        currentNodeId = nodeId
        return true
    }
    
    /// 完成当前节点，解锁下一层节点
    public mutating func completeCurrentNode() {
        guard let nodeId = currentNodeId,
              let nodeIndex = map.nodeIndex(withId: nodeId) else {
            return
        }
        
        // 获取当前节点的层数
        let currentRow = map[nodeIndex].row
        
        // 标记当前节点为已完成
        map[nodeIndex].isCompleted = true
        map[nodeIndex].isAccessible = false
        
        // 将同一层的其他可访问节点设为不可访问（不能回头选择）
        for i in 0..<map.count {
            if map[i].row == currentRow && map[i].id != nodeId {
                map[i].isAccessible = false
            }
        }
        
        // 获取当前节点的连接
        let connections = map[nodeIndex].connections
        
        // 解锁连接的下一层节点
        for nextId in connections {
            if let nextIndex = map.nodeIndex(withId: nextId) {
                map[nextIndex].isAccessible = true
            }
        }
        
        // 清除当前节点
        currentNodeId = nil
        
        // 检查是否通关（当前节点是 Boss 且已完成）
        if map[nodeIndex].roomType == .boss {
            if floor >= maxFloor {
                isOver = true
                won = true
            } else {
                // 进入下一幕：提升 floor，并生成新地图（保持可复现）
                floor += 1
                map = MapGenerator.generateBranching(seed: seedForFloor(floor))
            }
        }
    }

    // MARK: - Multi-Act Helpers
    
    private func seedForFloor(_ floor: Int) -> UInt64 {
        // 使用 floor 派生新地图种子，避免 Act1 与 Act2 地图完全一致
        seed &+ UInt64(floor) &* 1_000_000_000
    }
    
    // MARK: - 玩家状态操作
    
    /// 从战斗结果更新玩家状态
    /// - Parameter finalHP: 战斗结束时的 HP
    public mutating func updateFromBattle(playerHP: Int) {
        player.currentHP = playerHP
        
        // 检查玩家是否死亡
        if !player.isAlive {
            isOver = true
            won = false
        }
    }
    
    /// 在休息点恢复生命
    /// - Returns: 恢复的生命值
    @discardableResult
    public mutating func restAtNode() -> Int {
        let healAmount = player.maxHP * 30 / 100
        let oldHP = player.currentHP
        player.currentHP = min(player.maxHP, player.currentHP + healAmount)
        return player.currentHP - oldHP
    }
    
    /// 添加卡牌到牌组
    public mutating func addCardToDeck(_ card: Card) {
        deck.append(card)
    }

    /// 添加卡牌到牌组（自动生成实例 ID）
    /// - Note: 实例 ID 规则：`<cardId.rawValue>_<n>`（n 为同 cardId 的序号）
    public mutating func addCardToDeck(cardId: CardID) {
        let instanceId = makeNextCardInstanceId(for: cardId)
        deck.append(Card(id: instanceId, cardId: cardId))
    }
    
    /// 从牌组移除卡牌
    public mutating func removeCardFromDeck(at index: Int) {
        guard index >= 0 && index < deck.count else { return }
        deck.remove(at: index)
    }

    // MARK: - Consumables (P4)

    /// 消耗品槽位上限
    public static let maxConsumableSlots = 3

    /// 添加一个消耗品（若槽位已满则失败）
    @discardableResult
    public mutating func addConsumable(_ id: ConsumableID) -> Bool {
        guard consumables.count < RunState.maxConsumableSlots else { return false }
        consumables.append(id)
        return true
    }

    /// 移除指定索引的消耗品
    public mutating func removeConsumable(at index: Int) {
        guard index >= 0 && index < consumables.count else { return }
        consumables.remove(at: index)
    }

    // MARK: - RunEffect（P5：事件系统）
    
    /// 应用一个 RunEffect 到当前冒险状态
    @discardableResult
    public mutating func apply(_ effect: RunEffect) -> Bool {
        switch effect {
        case .gainGold(let amount):
            guard amount != 0 else { return true }
            gold = max(0, gold + amount)
            return true
            
        case .loseGold(let amount):
            guard amount > 0 else { return true }
            gold = max(0, gold - amount)
            return true
            
        case .heal(let amount):
            guard amount > 0 else { return true }
            player.currentHP = min(player.maxHP, player.currentHP + amount)
            return true
            
        case .takeDamage(let amount):
            guard amount > 0 else { return true }
            player.currentHP = max(0, player.currentHP - amount)
            if !player.isAlive {
                isOver = true
                won = false
            }
            return true
            
        case .addCard(let cardId):
            addCardToDeck(cardId: cardId)
            return true
            
        case .addRelic(let relicId):
            relicManager.add(relicId)
            return true
            
        case .upgradeCard(let deckIndex):
            return upgradeCard(at: deckIndex)
        }
    }

    // MARK: - 卡牌升级

    /// 获取可升级卡牌在牌组中的索引（按牌组顺序）
    public var upgradeableCardIndices: [Int] {
        RunState.upgradeableCardIndices(in: deck)
    }

    /// 获取可升级卡牌在牌组中的索引（按牌组顺序）
    public static func upgradeableCardIndices(in deck: [Card]) -> [Int] {
        deck.enumerated().compactMap { index, card in
            guard let def = CardRegistry.get(card.cardId), def.upgradedId != nil else {
                return nil
            }
            return index
        }
    }

    /// 生成升级后的卡牌实例（保持实例 ID 不变）
    public static func upgradedCard(from card: Card) -> Card? {
        guard let def = CardRegistry.get(card.cardId),
              let upgradedId = def.upgradedId else {
            return nil
        }
        return Card(id: card.id, cardId: upgradedId)
    }

    /// 生成升级后的牌组（纯函数）
    public static func upgradedDeck(from deck: [Card], at index: Int) -> [Card]? {
        guard index >= 0 && index < deck.count else { return nil }
        guard let upgradedCard = upgradedCard(from: deck[index]) else { return nil }
        
        var updated = deck
        updated[index] = upgradedCard
        return updated
    }

    /// 升级指定索引的卡牌
    @discardableResult
    public mutating func upgradeCard(at index: Int) -> Bool {
        guard let updated = RunState.upgradedDeck(from: deck, at: index) else {
            return false
        }
        deck = updated
        return true
    }

    private func makeNextCardInstanceId(for cardId: CardID) -> String {
        let prefix = "\(cardId.rawValue)_"
        var maxIndex = 0
        
        for card in deck where card.id.hasPrefix(prefix) {
            let suffix = card.id.dropFirst(prefix.count)
            if let n = Int(suffix), n > maxIndex {
                maxIndex = n
            }
        }
        
        return "\(prefix)\(maxIndex + 1)"
    }
    
    // MARK: - 地图查询
    
    /// 获取地图进度百分比
    public var progressPercent: Double {
        let completedCount = map.filter { $0.isCompleted }.count
        let totalCount = max(1, map.count)
        return Double(completedCount) / Double(totalCount) * 100
    }
    
    /// 获取当前层数（已完成的最高层）
    public var currentRow: Int {
        if let nodeId = currentNodeId, let node = map.node(withId: nodeId) {
            return node.row
        }
        return map.filter { $0.isCompleted }.map { $0.row }.max() ?? 0
    }
}

// MARK: - Gold

extension RunState {
    /// 起始金币
    public static let startingGold = 99
}
