/// Run 存档版本管理
/// 用于存档格式版本控制，确保不同版本间的兼容性处理
public enum RunSaveVersion {
    /// 当前存档格式版本号
    public static let current: Int = 4
    
    /// 检查版本是否兼容
    /// - Parameter version: 存档中的版本号
    /// - Returns: 是否可以加载此版本的存档
    public static func isCompatible(_ version: Int) -> Bool {
        return version == current
    }
}
