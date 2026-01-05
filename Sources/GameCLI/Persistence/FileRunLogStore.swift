import Foundation

/// 基于文件的 Run 日志存储（调试用途）
///
/// - 路径规则与 save/history 一致：优先使用 `SALU_DATA_DIR` 覆盖目录。
final class FileRunLogStore: RunLogStore, @unchecked Sendable {
    private let fileName = "run_log.txt"
    private let dataDirEnvKey = "SALU_DATA_DIR"
    
    init() {}
    
    func appendLine(_ line: String) {
        guard let path = getStoragePath() else { return }
        guard let data = line.data(using: .utf8) else { return }
        
        do {
            if FileManager.default.fileExists(atPath: path.path) {
                let handle = try FileHandle(forWritingTo: path)
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                try data.write(to: path)
            }
        } catch {
            // 调试日志写入失败不应影响游戏流程
        }
    }
    
    func clear() {
        guard let path = getStoragePath() else { return }
        do {
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
            }
        } catch {
            // ignore
        }
    }
    
    // MARK: - Private
    
    private func getStoragePath() -> URL? {
        // 允许通过环境变量覆盖存储目录（用于测试/调试）
        if let overridePath = ProcessInfo.processInfo.environment[dataDirEnvKey],
           !overridePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let dir = URL(fileURLWithPath: overridePath, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent(fileName)
        }
        
        #if os(Windows)
        if let localAppData = ProcessInfo.processInfo.environment["LOCALAPPDATA"] {
            let saluDir = URL(fileURLWithPath: localAppData).appendingPathComponent("Salu")
            try? FileManager.default.createDirectory(at: saluDir, withIntermediateDirectories: true)
            return saluDir.appendingPathComponent(fileName)
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(fileName)
        #else
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let saluDir = appSupport.appendingPathComponent("Salu")
            try? FileManager.default.createDirectory(at: saluDir, withIntermediateDirectories: true)
            return saluDir.appendingPathComponent(fileName)
        }
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let saluDir = homeDir.appendingPathComponent(".salu")
        try? FileManager.default.createDirectory(at: saluDir, withIntermediateDirectories: true)
        return saluDir.appendingPathComponent(fileName)
        #endif
    }
}


