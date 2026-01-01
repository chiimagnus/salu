import Foundation

/// 配置管理器
/// 负责保存和加载用户配置（如语言偏好）
final class ConfigManager: @unchecked Sendable {
    
    // MARK: - 单例
    
    static let shared = ConfigManager()
    
    // MARK: - 配置文件路径
    
    private let configDirectory: URL
    private let configFilePath: URL
    
    // MARK: - 配置结构
    
    struct Config: Codable {
        var language: String  // "zh" 或 "en"
        
        static let `default` = Config(language: "zh")
    }
    
    // MARK: - 初始化
    
    private init() {
        // 获取用户主目录
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        
        // 创建配置目录路径 ~/.salu/
        configDirectory = homeDirectory.appendingPathComponent(".salu")
        configFilePath = configDirectory.appendingPathComponent("config.json")
        
        // 确保配置目录存在
        try? FileManager.default.createDirectory(
            at: configDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    // MARK: - 加载配置
    
    /// 加载配置
    /// - Returns: 用户配置，如果不存在则返回默认配置
    func loadConfig() -> Config {
        guard FileManager.default.fileExists(atPath: configFilePath.path) else {
            return Config.default
        }
        
        do {
            let data = try Data(contentsOf: configFilePath)
            let config = try JSONDecoder().decode(Config.self, from: data)
            return config
        } catch {
            print("⚠️ Failed to load config: \(error.localizedDescription)")
            return Config.default
        }
    }
    
    // MARK: - 保存配置
    
    /// 保存配置
    /// - Parameter config: 要保存的配置
    func saveConfig(_ config: Config) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFilePath, options: .atomic)
        } catch {
            print("⚠️ Failed to save config: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 便捷方法
    
    /// 保存语言偏好
    /// - Parameter language: 语言代码（"zh" 或 "en"）
    func saveLanguagePreference(_ language: Language) {
        var config = loadConfig()
        config.language = language.rawValue
        saveConfig(config)
    }
    
    /// 加载语言偏好
    /// - Returns: 保存的语言，如果不存在则返回中文
    func loadLanguagePreference() -> Language {
        let config = loadConfig()
        return Language(rawValue: config.language) ?? .chinese
    }
}
