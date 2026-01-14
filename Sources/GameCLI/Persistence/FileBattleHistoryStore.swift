import Foundation
import GameCore

/// 基于文件的战斗历史存储实现
/// 使用 JSON 格式保存到本地文件系统
final class FileBattleHistoryStore: BattleHistoryStore, @unchecked Sendable {
    
    private let fileName = "battle_history.json"
    private var cachedRecords: [BattleRecord] = []
    private var isLoaded = false
    
    init() {}
    
    // MARK: - BattleHistoryStore Protocol
    
    func load() throws -> [BattleRecord] {
        guard !isLoaded else { return cachedRecords }
        
        guard let path = getStoragePath() else {
            cachedRecords = []
            isLoaded = true
            return []
        }
        
        guard FileManager.default.fileExists(atPath: path.path) else {
            cachedRecords = []
            isLoaded = true
            return []
        }
        
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        cachedRecords = try decoder.decode([BattleRecord].self, from: data)
        isLoaded = true
        return cachedRecords
    }
    
    func append(_ record: BattleRecord) throws {
        // 确保已加载
        if !isLoaded {
            _ = try load()
        }
        
        cachedRecords.append(record)
        try save()
    }
    
    func clear() throws {
        cachedRecords.removeAll()
        isLoaded = true
        try save()
    }
    
    // MARK: - Private Methods
    
    private func save() throws {
        guard let path = getStoragePath() else {
            return
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(cachedRecords)
        try data.write(to: path)
    }
    
    /// 获取存储路径
    private func getStoragePath() -> URL? {
        let (dir, _) = DataDirectory.resolved()
        return dir.appendingPathComponent(fileName)
    }
}
