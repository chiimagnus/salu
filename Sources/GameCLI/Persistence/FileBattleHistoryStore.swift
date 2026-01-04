import Foundation
import GameCore

/// 基于文件的战斗历史存储实现
/// 使用 JSON 格式保存到本地文件系统
final class FileBattleHistoryStore: BattleHistoryStore, @unchecked Sendable {
    
    private let fileName = "battle_history.json"
    private let dataDirEnvKey = "SALU_DATA_DIR"
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
        // 允许通过环境变量覆盖存储目录（用于测试/调试）
        if let overridePath = ProcessInfo.processInfo.environment[dataDirEnvKey],
           !overridePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let dir = URL(fileURLWithPath: overridePath, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent(fileName)
        }
        
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
}
