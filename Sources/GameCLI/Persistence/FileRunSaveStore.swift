import Foundation
import GameCore

/// Run 存档文件存储实现
/// 使用 JSON 格式保存冒险进度到本地文件
final class FileRunSaveStore: RunSaveStore {
    private let fileURL: URL
    
    init() {
        // 使用与历史记录相同的目录
        let fileManager = FileManager.default
        let directory: URL
        
        #if os(Linux)
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            directory = URL(fileURLWithPath: home).appendingPathComponent(".salu")
        } else {
            directory = fileManager.temporaryDirectory.appendingPathComponent("salu")
        }
        #else
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            directory = appSupport.appendingPathComponent("Salu")
        } else {
            directory = fileManager.temporaryDirectory.appendingPathComponent("salu")
        }
        #endif
        
        // 确保目录存在
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        
        self.fileURL = directory.appendingPathComponent("run_save.json")
    }
    
    func load() throws -> RunSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: fileURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        return snapshot
    }
    
    func save(_ snapshot: RunSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }
    
    func clear() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    /// 检查是否存在存档
    func hasSave() -> Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
}
