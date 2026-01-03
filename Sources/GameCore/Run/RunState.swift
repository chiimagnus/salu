/// 冒险状态
/// 管理整个冒险过程中的玩家状态、地图进度等
public struct RunState: Sendable {
    
    // MARK: - 属性
    
    /// 玩家实体（HP 在战斗间保持）
    public var player: Entity
    
    /// 当前牌组
    public var deck: [Card]
    
    /// 地图节点
    public var map: [MapNode]
    
    /// 当前所在节点 ID
    public var currentNodeId: String?
    
    /// 随机种子
    public let seed: UInt64
    
    /// 当前楼层（Act）
    public let floor: Int
    
    /// 冒险是否结束
    public var isOver: Bool
    
    /// 是否通关（击败 Boss）
    public var won: Bool
    
    // MARK: - 初始化
    
    public init(
        player: Entity,
        deck: [Card],
        map: [MapNode],
        seed: UInt64,
        floor: Int = 1
    ) {
        self.player = player
        self.deck = deck
        self.map = map
        self.currentNodeId = nil
        self.seed = seed
        self.floor = floor
        self.isOver = false
        self.won = false
    }
    
    /// 使用默认配置创建新冒险
    public static func newRun(seed: UInt64) -> RunState {
        let player = createDefaultPlayer()
        let deck = createStarterDeck()
        let map = MapGenerator.generateBranching(seed: seed)
        
        return RunState(
            player: player,
            deck: deck,
            map: map,
            seed: seed
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
        
        // 标记当前节点为已完成
        map[nodeIndex].isCompleted = true
        map[nodeIndex].isAccessible = false
        
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
            isOver = true
            won = true
        }
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
    
    /// 从牌组移除卡牌
    public mutating func removeCardFromDeck(at index: Int) {
        guard index >= 0 && index < deck.count else { return }
        deck.remove(at: index)
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

