import Foundation
import GameCore

/// 游戏设置存储
/// 使用 JSON 格式保存用户设置到本地文件
final class SettingsStore {
    private static let fileName = "settings.json"
    
    private let fileURL: URL
    
    /// 设置数据模型
    struct Settings: Codable {
        var showLog: Bool = false
        var language: GameLanguage = .zhHans
    }
    
    init() {
        let (dir, _) = DataDirectory.resolved()
        self.fileURL = dir.appendingPathComponent(Self.fileName)
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
