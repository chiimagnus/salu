import Foundation
import GameCore

/// Run 存档文件存储实现
/// 使用 JSON 格式保存冒险进度到本地文件
final class FileRunSaveStore: RunSaveStore {
    private static let fileName = "run_save.json"
    
    private let fileURL: URL
    
    init() {
        let (dir, _) = DataDirectory.resolved()
        self.fileURL = dir.appendingPathComponent(Self.fileName)
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
