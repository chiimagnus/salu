import Foundation

// MARK: - Battle Record

/// 单个敌人的战斗记录快照（用于战绩落盘）
public struct EnemyBattleRecord: Codable, Sendable, Equatable {
    /// 实体实例 ID（用于同类敌人同场区分）
    public let entityId: String
    
    /// 敌人类型 ID（EnemyRegistry 的 key；可能为空，例如某些测试构造的“木桩”）
    public let enemyId: String?
    
    public let name: String
    public let maxHP: Int
    public let finalHP: Int
    
    public init(entityId: String, enemyId: String?, name: String, maxHP: Int, finalHP: Int) {
        self.entityId = entityId
        self.enemyId = enemyId
        self.name = name
        self.maxHP = maxHP
        self.finalHP = finalHP
    }
}

/// 单场战斗记录
public struct BattleRecord: Codable, Sendable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let seed: UInt64
    
    // 战斗结果
    public let won: Bool
    public let turnsPlayed: Int
    
    // 玩家状态
    public let playerName: String
    public let playerMaxHP: Int
    public let playerFinalHP: Int
    
    // 敌人状态（P6：支持多敌人）
    public let enemies: [EnemyBattleRecord]
    
    // 卡牌统计
    public let cardsPlayed: Int
    public let strikesPlayed: Int
    public let defendsPlayed: Int
    
    // 伤害统计
    public let totalDamageDealt: Int
    public let totalDamageTaken: Int
    public let totalBlockGained: Int
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        seed: UInt64,
        won: Bool,
        turnsPlayed: Int,
        playerName: String,
        playerMaxHP: Int,
        playerFinalHP: Int,
        enemies: [EnemyBattleRecord],
        cardsPlayed: Int,
        strikesPlayed: Int,
        defendsPlayed: Int,
        totalDamageDealt: Int,
        totalDamageTaken: Int,
        totalBlockGained: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.seed = seed
        self.won = won
        self.turnsPlayed = turnsPlayed
        self.playerName = playerName
        self.playerMaxHP = playerMaxHP
        self.playerFinalHP = playerFinalHP
        self.enemies = enemies
        self.cardsPlayed = cardsPlayed
        self.strikesPlayed = strikesPlayed
        self.defendsPlayed = defendsPlayed
        self.totalDamageDealt = totalDamageDealt
        self.totalDamageTaken = totalDamageTaken
        self.totalBlockGained = totalBlockGained
    }
}

// MARK: - Statistics

/// 战绩统计汇总
public struct BattleStatistics: Sendable {
    public let totalBattles: Int
    public let wins: Int
    public let losses: Int
    
    public var winRate: Double {
        guard totalBattles > 0 else { return 0 }
        return Double(wins) / Double(totalBattles) * 100
    }
    
    public let averageTurns: Double
    public let fastestWin: Int?       // 最少回合胜利
    public let longestBattle: Int?    // 最长战斗回合
    
    public let totalCardsPlayed: Int
    public let totalDamageDealt: Int
    public let totalDamageTaken: Int
    public let totalBlockGained: Int
    
    public init(records: [BattleRecord]) {
        self.totalBattles = records.count
        self.wins = records.filter { $0.won }.count
        self.losses = records.filter { !$0.won }.count
        
        if records.isEmpty {
            self.averageTurns = 0
            self.fastestWin = nil
            self.longestBattle = nil
        } else {
            self.averageTurns = Double(records.map { $0.turnsPlayed }.reduce(0, +)) / Double(records.count)
            self.fastestWin = records.filter { $0.won }.map { $0.turnsPlayed }.min()
            self.longestBattle = records.map { $0.turnsPlayed }.max()
        }
        
        self.totalCardsPlayed = records.map { $0.cardsPlayed }.reduce(0, +)
        self.totalDamageDealt = records.map { $0.totalDamageDealt }.reduce(0, +)
        self.totalDamageTaken = records.map { $0.totalDamageTaken }.reduce(0, +)
        self.totalBlockGained = records.map { $0.totalBlockGained }.reduce(0, +)
    }
}

// MARK: - Record Builder

/// 从战斗引擎构建战斗记录
public struct BattleRecordBuilder {
    
    /// 从战斗引擎构建记录（使用 battleStats 累积数据）
    public static func build(from engine: BattleEngine, seed: UInt64) -> BattleRecord {
        let state = engine.state
        let stats = engine.battleStats
        
        let enemies: [EnemyBattleRecord] = state.enemies.map { enemy in
            EnemyBattleRecord(
                entityId: enemy.id,
                enemyId: enemy.enemyId?.rawValue,
                name: enemy.name.zhHans,
                maxHP: enemy.maxHP,
                finalHP: enemy.currentHP
            )
        }
        
        return BattleRecord(
            seed: seed,
            won: state.playerWon ?? false,
            turnsPlayed: state.turn,
            playerName: state.player.name.zhHans,
            playerMaxHP: state.player.maxHP,
            playerFinalHP: state.player.currentHP,
            enemies: enemies,
            cardsPlayed: stats.cardsPlayed,
            strikesPlayed: stats.strikesPlayed,
            defendsPlayed: stats.defendsPlayed,
            totalDamageDealt: stats.totalDamageDealt,
            totalDamageTaken: stats.totalDamageTaken,
            totalBlockGained: stats.totalBlockGained
        )
    }
}
