import Foundation

/// 冒险管理器
/// 管理整个冒险的流程
public final class RunManager: @unchecked Sendable {
    public private(set) var runState: RunState
    private let seed: UInt64
    private var rng: SeededRNG
    
    public init(seed: UInt64) {
        self.seed = seed
        self.rng = SeededRNG(seed: seed)
        let player = createDefaultPlayer()
        let deck = createStarterDeck()
        self.runState = RunState(player: player, deck: deck, seed: seed)
    }
    
    /// 开始房间内容（战斗、休息等）
    public func enterCurrentRoom() -> RoomType {
        guard let node = runState.currentNode else {
            fatalError("No current node")
        }
        return node.roomType
    }
    
    /// 创建当前房间的战斗
    public func createBattleForCurrentRoom() -> BattleEngine {
        guard let node = runState.currentNode else {
            fatalError("No current node")
        }
        
        // 根据房间类型选择敌人
        let enemyKind: EnemyKind
        if node.roomType == .boss {
            enemyKind = Act1EnemyPool.randomBoss(rng: &rng)
        } else {
            enemyKind = Act1EnemyPool.randomWeak(rng: &rng)
        }
        
        let enemy = createEnemy(kind: enemyKind, rng: &rng)
        
        // 使用当前时间作为战斗种子
        let battleSeed = UInt64(Date().timeIntervalSince1970 * 1000) + UInt64(runState.currentFloor)
        
        return BattleEngine(
            player: runState.player,
            enemy: enemy,
            deck: runState.deck,
            seed: battleSeed
        )
    }
    
    /// 战斗结束后更新玩家状态
    public func updatePlayerAfterBattle(_ newState: BattleState) {
        runState.player.currentHP = newState.player.currentHP
        runState.player.block = newState.player.block
        // 注意：状态效果在战斗间不保留，这是杀戮尖塔的规则
    }
    
    /// 移动到下一个房间
    public func proceedToNextRoom() {
        runState.moveToNextNode()
    }
    
    /// 移动到指定节点
    public func moveToNode(_ nodeId: Int) {
        runState.moveToNode(nodeId)
    }
    
    /// 休息恢复生命值
    /// - Returns: 实际恢复的生命值
    public func rest() -> Int {
        let healAmount = min(30, runState.player.maxHP - runState.player.currentHP)
        runState.player.currentHP += healAmount
        return healAmount
    }
    
    /// 结束冒险（失败）
    public func endRunAsDefeat() {
        runState.isRunOver = true
        runState.won = false
    }
    
    /// 结束冒险（胜利）
    public func endRunAsVictory() {
        runState.isRunOver = true
        runState.won = true
    }
}
