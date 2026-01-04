import Foundation

struct CLIRunResult: Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

enum CLIRunnerError: Error, CustomStringConvertible {
    case gameCLIBinaryNotFound(expected: [URL])
    case nonUTF8Output
    case timedOut(timeout: TimeInterval, partialStdout: String, partialStderr: String)
    
    var description: String {
        switch self {
        case .gameCLIBinaryNotFound(let expected):
            let list = expected.map(\.path).joined(separator: "\n- ")
            return """
            未找到 GameCLI 可执行文件。请先在项目根目录执行：
              swift build
            或（推荐 CI）：
              swift build -c release
            
            期望路径：
            - \(list)
            """
        case .nonUTF8Output:
            return "进程输出不是 UTF-8，无法做稳定断言。"
        case .timedOut(let timeout, let out, let err):
            return """
            运行 GameCLI 超时（\(timeout)s）。
            
            stdout(截断)：
            \(out)
            
            stderr(截断)：
            \(err)
            """
        }
    }
}

/// 使用 `Process` 启动 GameCLI，并通过 stdin 驱动 CLI 流程（用于「UI」测试）。
enum CLIRunner {
    static func runGameCLI(
        arguments: [String],
        stdin: String,
        environment: [String: String],
        timeout: TimeInterval = 8
    ) throws -> CLIRunResult {
        let binaryURL = try locateGameCLIBinary()
        
        let process = Process()
        process.executableURL = binaryURL
        process.arguments = arguments
        process.currentDirectoryURL = packageRootURL()
        
        var env = ProcessInfo.processInfo.environment
        for (k, v) in environment {
            env[k] = v
        }
        process.environment = env
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let stdinPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = stdinPipe
        
        let stdoutCollector = PipeCollector()
        let stderrCollector = PipeCollector()
        stdoutCollector.start(handling: stdoutPipe.fileHandleForReading)
        stderrCollector.start(handling: stderrPipe.fileHandleForReading)
        
        let semaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in semaphore.signal() }
        
        try process.run()
        
        if !stdin.isEmpty, let data = stdin.data(using: .utf8) {
            stdinPipe.fileHandleForWriting.write(data)
        }
        stdinPipe.fileHandleForWriting.closeFile()
        
        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            // 超时：尽力终止并收集部分输出，避免 CI 卡死
            process.terminate()
            _ = semaphore.wait(timeout: .now() + 1.0)
            
            stdoutCollector.stop()
            stderrCollector.stop()
            
            let partialOut = (try? stdoutCollector.collectedString(prefixLimit: 4000)) ?? ""
            let partialErr = (try? stderrCollector.collectedString(prefixLimit: 4000)) ?? ""
            throw CLIRunnerError.timedOut(timeout: timeout, partialStdout: partialOut, partialStderr: partialErr)
        }
        
        stdoutCollector.stop()
        stderrCollector.stop()
        
        let out = try stdoutCollector.collectedString()
        let err = try stderrCollector.collectedString()
        
        return CLIRunResult(
            exitCode: process.terminationStatus,
            stdout: out,
            stderr: err
        )
    }
    
    // MARK: - Binary Location
    
    private static func packageRootURL() -> URL {
        // Tests/GameCLIUITests/Support/CLIRunner.swift -> .../Support -> .../GameCLIUITests -> .../Tests -> <root>
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
    private static func locateGameCLIBinary() throws -> URL {
        let root = packageRootURL()
        #if os(Windows)
        let binaryName = "GameCLI.exe"
        #else
        let binaryName = "GameCLI"
        #endif

        // 允许显式指定可执行文件路径（用于 CI/本地调试）
        // - 优先级最高：SALU_CLI_BINARY_PATH
        // - 用途：需要验证 release binary 时可以强制指定；默认测试仍建议走 debug（更利于覆盖率与调试）
        let overrideKey = "SALU_CLI_BINARY_PATH"
        if let overridePath = ProcessInfo.processInfo.environment[overrideKey],
           !overridePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let url = URL(fileURLWithPath: overridePath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        let candidates: [URL] = [
            // 默认优先 debug（更符合测试/覆盖率；CI 通常会先 build release 再跑 tests）
            root.appendingPathComponent(".build/debug/\(binaryName)"),
            root.appendingPathComponent(".build/release/\(binaryName)")
        ]
        
        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        throw CLIRunnerError.gameCLIBinaryNotFound(expected: candidates)
    }
}

// MARK: - Pipe Collector

private final class PipeCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()
    private var handle: FileHandle?
    
    func start(handling fileHandle: FileHandle) {
        self.handle = fileHandle
        fileHandle.readabilityHandler = { [weak self] h in
            let chunk = h.availableData
            guard !chunk.isEmpty else { return }
            self?.append(chunk)
        }
    }
    
    func stop() {
        guard let handle else { return }
        handle.readabilityHandler = nil
        self.handle = nil
    }
    
    func collectedString(prefixLimit: Int? = nil) throws -> String {
        let data = collectedData(prefixLimit: prefixLimit)
        guard let str = String(data: data, encoding: .utf8) else {
            throw CLIRunnerError.nonUTF8Output
        }
        return str
    }
    
    private func collectedData(prefixLimit: Int?) -> Data {
        lock.lock()
        defer { lock.unlock() }
        
        if let prefixLimit {
            return buffer.prefix(prefixLimit)
        }
        return buffer
    }
    
    private func append(_ data: Data) {
        lock.lock()
        buffer.append(data)
        lock.unlock()
    }
}


