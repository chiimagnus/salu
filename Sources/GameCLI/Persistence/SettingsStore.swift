import Foundation

/// 游戏设置存储
/// 使用 JSON 格式保存用户设置到本地文件
final class SettingsStore {
    private static let dataDirEnvKey = "SALU_DATA_DIR"
    private static let fileName = "settings.json"
    
    private let fileURL: URL
    
    /// 设置数据模型
    struct Settings: Codable {
        var showLog: Bool = false
    }
    
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
        
        return candidates
    }
    
    @discardableResult
    private static func ensureDirectory(_ url: URL) -> Bool {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) { return true }
        do {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Public API
    
    /// 加载设置
    func load() -> Settings {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return Settings()
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(Settings.self, from: data)
        } catch {
            return Settings()
        }
    }
    
    /// 保存设置
    func save(_ settings: Settings) {
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: fileURL)
        } catch {
            // 静默失败，设置保存不是关键功能
        }
    }
}

