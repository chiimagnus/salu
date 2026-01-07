import Foundation

#if os(Windows)
// P1：Windows 先退化为非交互（保持可编译）。
struct TerminalKeyReader {
    static func isInteractiveTTY() -> Bool { false }
    static func withRawMode<T>(_ body: () throws -> T) rethrows -> T { try body() }
    mutating func readKey() -> TerminalKey { .unknown }
}

enum TerminalKey: Equatable {
    case tab
    case shiftTab
    case escape
    case enter
    case backspace
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case printable(Character)
    case unknown
}
#else
import Darwin

enum TerminalKey: Equatable {
    case tab
    case shiftTab
    case escape
    case enter
    case backspace
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case printable(Character)
    case unknown
}

struct TerminalKeyReader {
    static func isInteractiveTTY() -> Bool {
        guard isatty(STDIN_FILENO) == 1 else { return false }
        // XCTest 下即使在交互终端里跑 swift test，也要强制退化为旧行为，避免卡在单键输入。
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return false }
        if ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil { return false }
        return true
    }

    static func withRawMode<T>(_ body: () throws -> T) rethrows -> T {
        var original = termios()
        guard tcgetattr(STDIN_FILENO, &original) == 0 else {
            return try body()
        }

        var raw = original
        raw.c_lflag &= ~tcflag_t(ICANON | ECHO)
        withUnsafeMutableBytes(of: &raw.c_cc) { bytes in
            let vminIndex = Int(VMIN)
            let vtimeIndex = Int(VTIME)
            if bytes.count > vminIndex {
                bytes[vminIndex] = 1
            }
            if bytes.count > vtimeIndex {
                bytes[vtimeIndex] = 0
            }
        }

        _ = tcsetattr(STDIN_FILENO, TCSANOW, &raw)
        defer {
            _ = tcsetattr(STDIN_FILENO, TCSANOW, &original)
        }

        return try body()
    }

    mutating func readKey() -> TerminalKey {
        let first = readByteBlocking()

        switch first {
        case 9:
            return .tab
        case 10, 13:
            return .enter
        case 127:
            return .backspace
        case 27:
            return readEscapeSequenceOrEscape()
        default:
            if first >= 32, let scalar = UnicodeScalar(Int(first)) {
                return .printable(Character(scalar))
            }
            return .unknown
        }
    }

    // MARK: - Private

    private func readByteBlocking() -> UInt8 {
        var byte: UInt8 = 0
        while true {
            let n = read(STDIN_FILENO, &byte, 1)
            if n == 1 { return byte }
            if n == 0 { return 0 }
        }
    }

    private func readByteIfAvailable(timeoutMs: Int) -> UInt8? {
        var fds = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        let ready = poll(&fds, 1, Int32(timeoutMs))
        guard ready > 0 else { return nil }
        guard (fds.revents & Int16(POLLIN)) != 0 else { return nil }

        var byte: UInt8 = 0
        let n = read(STDIN_FILENO, &byte, 1)
        return n == 1 ? byte : nil
    }

    private func readEscapeSequenceOrEscape() -> TerminalKey {
        // 可能是单独的 ESC，也可能是方向键/Shift+Tab 的 ESC 序列。
        guard let second = readByteIfAvailable(timeoutMs: 10) else {
            return .escape
        }

        if second != 91 { // '['
            return .escape
        }

        guard let third = readByteIfAvailable(timeoutMs: 10) else {
            return .escape
        }

        switch third {
        case 65:
            return .arrowUp
        case 66:
            return .arrowDown
        case 67:
            return .arrowRight
        case 68:
            return .arrowLeft
        case 90:
            return .shiftTab
        default:
            return .unknown
        }
    }
}
#endif
