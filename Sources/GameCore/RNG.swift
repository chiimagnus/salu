/// 可复现的随机数生成器
/// 使用线性同余生成器 (LCG) 算法，确保相同 seed 产生相同序列
public final class SeededRNG: @unchecked Sendable {
    // LCG 参数（与 Java 的 Random 相同）
    private static let multiplier: UInt64 = 0x5DEECE66D
    private static let addend: UInt64 = 0xB
    private static let mask: UInt64 = (1 << 48) - 1
    
    private var state: UInt64
    
    /// 使用指定的种子初始化
    public init(seed: UInt64) {
        self.state = (seed ^ Self.multiplier) & Self.mask
    }
    
    /// 生成下一个随机数
    private func nextBits(_ bits: Int) -> UInt64 {
        state = (state &* Self.multiplier &+ Self.addend) & Self.mask
        return state >> (48 - bits)
    }
    
    /// 生成 [0, upperBound) 范围内的随机整数
    public func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        
        // 简化实现：直接使用模运算
        let r = nextBits(31)
        return Int(r % UInt64(upperBound))
    }
    
    /// Fisher-Yates 洗牌算法
    public func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = nextInt(upperBound: i + 1)
            array.swapAt(i, j)
        }
    }
    
    /// 返回洗牌后的新数组（不修改原数组）
    public func shuffled<T>(_ array: [T]) -> [T] {
        var result = array
        shuffle(&result)
        return result
    }
}

