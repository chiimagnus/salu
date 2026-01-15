import Foundation

/// 基于文件的 Run 日志存储（调试用途）
///
/// - 路径规则与 save/history 一致：优先使用 `SALU_DATA_DIR` 覆盖目录。
final class FileRunLogStore: RunLogStore, @unchecked Sendable {
    private let fileName = "run_log.txt"
    
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
        let (dir, _) = DataDirectory.resolved()
        return dir.appendingPathComponent(fileName)
    }
}


