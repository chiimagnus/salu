import Foundation
import XCTest
@testable import GameCLI

final class RunLogPersistenceTests: XCTestCase {
    func testRunLogService_stripsANSIAndAddsTimestamp() {
        print("🧪 测试：testRunLogService_stripsANSIAndAddsTimestamp")
        let store = InMemoryRunLogStore()
        let service = RunLogService(store: store)
        
        service.appendSystem("系统信息")
        service.append(uiLine: "\(Terminal.red)红色文本\(Terminal.reset)")
        
        XCTAssertEqual(store.lines.count, 2)
        XCTAssertTrue(store.lines[0].contains("=== 系统信息 ==="))
        XCTAssertTrue(store.lines[0].hasPrefix("\n["))
        XCTAssertTrue(store.lines[1].contains("红色文本"))
        XCTAssertFalse(store.lines[1].contains(Terminal.red), "落盘日志应去除 ANSI 颜色码")
        XCTAssertTrue(store.lines[1].hasPrefix("["))
    }
    
    func testFileRunLogStore_appendAndClear() throws {
        print("🧪 测试：testFileRunLogStore_appendAndClear")
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("salu_runlog_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        
        let key = "SALU_DATA_DIR"
        let old = getenv(key).flatMap { String(cString: $0) }
        defer {
            if let old {
                setenv(key, old, 1)
            } else {
                unsetenv(key)
            }
        }
        setenv(key, tmp.path, 1)
        
        let store = FileRunLogStore()
        store.appendLine("line1\n")
        store.appendLine("line2\n")
        
        let logURL = tmp.appendingPathComponent("run_log.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: logURL.path))
        let content = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(content.contains("line1"))
        XCTAssertTrue(content.contains("line2"))
        
        store.clear()
        XCTAssertFalse(FileManager.default.fileExists(atPath: logURL.path))
    }
}

// MARK: - Test Helpers

private final class InMemoryRunLogStore: RunLogStore, @unchecked Sendable {
    var lines: [String] = []
    
    func appendLine(_ line: String) {
        lines.append(line)
    }
    
    func clear() {
        lines.removeAll()
    }
}


