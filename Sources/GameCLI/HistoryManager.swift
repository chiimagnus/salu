import Foundation
import GameCore

/// 战绩历史管理器
/// 负责持久化存储和读取战斗记录
final class HistoryManager: @unchecked Sendable {
    
    static let shared = HistoryManager()
    
    private let fileName = "battle_history.json"
    private var records: [BattleRecord] = []
    
    private init() {
        loadRecords()
    }
    
    // MARK: - Public API
    
    /// 添加新的战斗记录
    func addRecord(_ record: BattleRecord) {
        records.append(record)
        saveRecords()
    }
    
    /// 获取所有记录
    func getAllRecords() -> [BattleRecord] {
        records
    }
    
    /// 获取最近 N 条记录
    func getRecentRecords(_ count: Int) -> [BattleRecord] {
        Array(records.suffix(count))
    }
    
    /// 获取统计数据
    func getStatistics() -> BattleStatistics {
        BattleStatistics(records: records)
    }
    
    /// 清空历史记录
    func clearHistory() {
        records.removeAll()
        saveRecords()
    }
    
    /// 记录数量
    var recordCount: Int {
        records.count
    }
    
    // MARK: - File Management
    
    /// 获取存储路径
    private func getStoragePath() -> URL? {
        #if os(Windows)
        // Windows: 使用 LOCALAPPDATA 环境变量
        if let localAppData = ProcessInfo.processInfo.environment["LOCALAPPDATA"] {
            let saluDir = URL(fileURLWithPath: localAppData).appendingPathComponent("Salu")
            try? FileManager.default.createDirectory(at: saluDir, withIntermediateDirectories: true)
            return saluDir.appendingPathComponent(fileName)
        }
        // 备用: 当前目录
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(fileName)
        #else
        // macOS/Linux: 使用 Application Support 或 ~/.salu
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let saluDir = appSupport.appendingPathComponent("Salu")
            try? FileManager.default.createDirectory(at: saluDir, withIntermediateDirectories: true)
            return saluDir.appendingPathComponent(fileName)
        }
        // 备用: ~/.salu
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let saluDir = homeDir.appendingPathComponent(".salu")
        try? FileManager.default.createDirectory(at: saluDir, withIntermediateDirectories: true)
        return saluDir.appendingPathComponent(fileName)
        #endif
    }
    
    // MARK: - Persistence
    
    private func loadRecords() {
        guard let path = getStoragePath() else { return }
        
        guard FileManager.default.fileExists(atPath: path.path) else {
            records = []
            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([BattleRecord].self, from: data)
        } catch {
            // 解析失败，从空记录开始
            records = []
        }
    }
    
    private func saveRecords() {
        guard let path = getStoragePath() else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)
            try data.write(to: path)
        } catch {
            // 保存失败，静默处理
        }
    }
}

