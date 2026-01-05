import XCTest
@testable import GameCLI

final class TerminalAndLogPanelTests: XCTestCase {
    func testTerminal_healthBarAndColor() {
        print("🧪 测试：testTerminal_healthBarAndColor")
        let bar = Terminal.healthBar(percent: 0.5, width: 10)
        XCTAssertEqual(bar.count, 12) // "[" + 10 + "]"
        
        XCTAssertEqual(Terminal.colorForPercent(0.6), Terminal.green)
        XCTAssertEqual(Terminal.colorForPercent(0.3), Terminal.yellow)
        XCTAssertEqual(Terminal.colorForPercent(0.1), Terminal.red)
    }
    
    func testANSI_stripping() {
        print("🧪 测试：testANSI_stripping")
        let raw = "\(Terminal.red)红色\(Terminal.reset) 文本"
        let stripped = raw.strippingANSICodes()
        XCTAssertEqual(stripped, "红色 文本")
        XCTAssertFalse(stripped.contains("\u{001B}["))
    }
    
    func testTerminal_clearAndFlush_doNotCrash() {
        print("🧪 测试：testTerminal_clearAndFlush_doNotCrash")
        Terminal.clear()
        Terminal.flush()
    }
}


