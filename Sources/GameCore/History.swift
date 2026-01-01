import Foundation

// MARK: - Battle Record

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
    
    // 敌人状态
    public let enemyName: String
    public let enemyMaxHP: Int
    public let enemyFinalHP: Int
    
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
        enemyName: String,
        enemyMaxHP: Int,
        enemyFinalHP: Int,
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
        self.enemyName = enemyName
        self.enemyMaxHP = enemyMaxHP
        self.enemyFinalHP = enemyFinalHP
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
    
    /// 从战斗引擎和事件日志构建记录
    public static func build(from engine: BattleEngine, seed: UInt64) -> BattleRecord {
        let state = engine.state
        let events = engine.events
        
        // 统计卡牌使用
        var strikesPlayed = 0
        var defendsPlayed = 0
        var totalDamageDealt = 0
        var totalDamageTaken = 0
        var totalBlockGained = 0
        
        for event in events {
            switch event {
            case .played(_, let cardName, _):
                if cardName == "Strike" {
                    strikesPlayed += 1
                } else if cardName == "Defend" {
                    defendsPlayed += 1
                }
                
            case .damageDealt(let source, _, let amount, _):
                if source == state.player.name {
                    totalDamageDealt += amount
                } else {
                    totalDamageTaken += amount
                }
                
            case .blockGained(let target, let amount):
                if target == state.player.name {
                    totalBlockGained += amount
                }
                
            default:
                break
            }
        }
        
        return BattleRecord(
            seed: seed,
            won: state.playerWon ?? false,
            turnsPlayed: state.turn,
            playerName: state.player.name,
            playerMaxHP: state.player.maxHP,
            playerFinalHP: state.player.currentHP,
            enemyName: state.enemy.name,
            enemyMaxHP: state.enemy.maxHP,
            enemyFinalHP: state.enemy.currentHP,
            cardsPlayed: strikesPlayed + defendsPlayed,
            strikesPlayed: strikesPlayed,
            defendsPlayed: defendsPlayed,
            totalDamageDealt: totalDamageDealt,
            totalDamageTaken: totalDamageTaken,
            totalBlockGained: totalBlockGained
        )
    }
}

