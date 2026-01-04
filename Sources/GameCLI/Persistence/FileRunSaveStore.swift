import Foundation
import GameCore

/// Run 存档文件存储实现
/// 使用 JSON 格式保存冒险进度到本地文件
final class FileRunSaveStore: RunSaveStore {
    private static let dataDirEnvKey = "SALU_DATA_DIR"
    private static let fileName = "run_save.json"
    
    private let fileURL: URL
    
    init() {
        let fileManager = FileManager.default
        
        // 允许通过环境变量覆盖存储目录（用于测试/调试）
        if let overridePath = ProcessInfo.processInfo.environment[Self.dataDirEnvKey],
           !overridePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let overrideDir = URL(fileURLWithPath: overridePath, isDirectory: true)
            if Self.ensureDirectory(overrideDir) {
                self.fileURL = overrideDir.appendingPathComponent(Self.fileName)
                return
            }
        }
        
        let candidates = Self.defaultDirectoryCandidates(fileManager: fileManager)
        let directory = candidates.first(where: { dir in
            Self.ensureDirectory(dir) && fileManager.isWritableFile(atPath: dir.path)
        }) ?? fileManager.temporaryDirectory.appendingPathComponent("salu")
        
        _ = Self.ensureDirectory(directory)
        self.fileURL = directory.appendingPathComponent(Self.fileName)
    }
    
    private static func defaultDirectoryCandidates(fileManager: FileManager) -> [URL] {
        var candidates: [URL] = []
        
        #if os(Windows)
        if let localAppData = ProcessInfo.processInfo.environment["LOCALAPPDATA"] {
            candidates.append(URL(fileURLWithPath: localAppData).appendingPathComponent("Salu"))
        }
        #elseif os(Linux)
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            candidates.append(URL(fileURLWithPath: home).appendingPathComponent(".salu"))
        }
        #else
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            candidates.append(appSupport.appendingPathComponent("Salu"))
        }
        #endif
        
        candidates.append(fileManager.temporaryDirectory.appendingPathComponent("salu"))
        return candidates
    }
    
    @discardableResult
    private static func ensureDirectory(_ directory: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return true
        } catch {
            return false
        }
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
