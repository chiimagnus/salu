import Foundation

/// 测试用临时目录（自动创建，手动清理）
struct TemporaryDirectory {
    let url: URL
    
    init(prefix: String = "salu-tests-") throws {
        let base = FileManager.default.temporaryDirectory
        self.url = base.appendingPathComponent("\(prefix)\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    func cleanup() {
        try? FileManager.default.removeItem(at: url)
    }
}


