/// 地图生成策略协议
/// 为不同的 Act 或难度级别提供扩展点
public protocol MapGenerating: Sendable {
    /// 生成地图
    /// - Parameters:
    ///   - seed: 随机种子（保证可复现）
    ///   - rows: 地图层数
    /// - Returns: 地图节点数组
    func generate(seed: UInt64, rows: Int) -> [MapNode]
}

/// 默认的分支地图生成器
public struct BranchingMapGenerator: MapGenerating {
    public init() {}
    
    public func generate(seed: UInt64, rows: Int) -> [MapNode] {
        // 委托给现有的 MapGenerator.generateBranching
        return MapGenerator.generateBranching(seed: seed, rows: rows)
    }
}
