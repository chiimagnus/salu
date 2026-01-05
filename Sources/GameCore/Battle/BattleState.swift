/// 战斗状态
/// 包含玩家、敌人、能量、回合数、牌堆等信息
public struct BattleState: Sendable {
    public var player: Entity
    public var enemies: [Entity]
    
    public var energy: Int
    public let maxEnergy: Int
    
    public var turn: Int
    public var isPlayerTurn: Bool
    
    public var drawPile: [Card]
    public var hand: [Card]
    public var discardPile: [Card]
    
    public var isOver: Bool
    public var playerWon: Bool?
    
    public init(
        player: Entity,
        enemies: [Entity],
        maxEnergy: Int = 3
    ) {
        self.player = player
        self.enemies = enemies
        self.energy = maxEnergy
        self.maxEnergy = maxEnergy
        self.turn = 0
        self.isPlayerTurn = true
        self.drawPile = []
        self.hand = []
        self.discardPile = []
        self.isOver = false
        self.playerWon = nil
    }
}

