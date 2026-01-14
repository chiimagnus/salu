import Foundation

/// 统一的数据目录解析（GameCLI）
///
/// 规则：
/// 1) 若设置了 `SALU_DATA_DIR`，优先使用该目录（用于测试/调试隔离数据）。
/// 2) 否则使用平台默认目录：
///    - macOS: ~/Library/Application Support/Salu
///    - Linux: ~/.salu
///    - Windows: %LOCALAPPDATA%/Salu
/// 3) 若以上目录不可写，则回退到系统临时目录下的 `salu/`。
enum DataDirectory {
    static let envKey = "SALU_DATA_DIR"
    static let appFolderName = "Salu"
    static let fallbackFolderName = "salu"
    
    enum Source: String {
        case envOverride = "SALU_DATA_DIR"
        case platformDefault = "platform-default"
        case temporaryFallback = "temporary-fallback"
    }
    
    static func resolved(fileManager: FileManager = .default) -> (directory: URL, source: Source) {
        // 1) env override
        if let overridePath = ProcessInfo.processInfo.environment[Self.envKey],
           !overridePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let dir = URL(fileURLWithPath: overridePath, isDirectory: true)
            if ensureDirectory(dir, fileManager: fileManager),
               fileManager.isWritableFile(atPath: dir.path) {
                return (dir, .envOverride)
            }
        }
        
        // 2) platform default
        #if os(Windows)
        if let localAppData = ProcessInfo.processInfo.environment["LOCALAPPDATA"],
           !localAppData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let dir = URL(fileURLWithPath: localAppData, isDirectory: true)
                .appendingPathComponent(Self.appFolderName)
            if ensureDirectory(dir, fileManager: fileManager),
               fileManager.isWritableFile(atPath: dir.path) {
                return (dir, .platformDefault)
            }
        }
        #elseif os(Linux)
        if let home = ProcessInfo.processInfo.environment["HOME"],
           !home.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let dir = URL(fileURLWithPath: home, isDirectory: true)
                .appendingPathComponent(".salu")
            if ensureDirectory(dir, fileManager: fileManager),
               fileManager.isWritableFile(atPath: dir.path) {
                return (dir, .platformDefault)
            }
        }
        #else
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent(Self.appFolderName)
            if ensureDirectory(dir, fileManager: fileManager),
               fileManager.isWritableFile(atPath: dir.path) {
                return (dir, .platformDefault)
            }
        }
        #endif
        
        // 3) fallback to temporary directory
        let tmpDir = fileManager.temporaryDirectory.appendingPathComponent(Self.fallbackFolderName)
        _ = ensureDirectory(tmpDir, fileManager: fileManager)
        return (tmpDir, .temporaryFallback)
    }
    
    @discardableResult
    private static func ensureDirectory(_ directory: URL, fileManager: FileManager) -> Bool {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            return true
        } catch {
            return false
        }
    }
}

