import Foundation

struct AVPRunTraceStore: Sendable {
    enum StoreError: Error, Sendable, Equatable {
        case missing
        case invalidData
    }

    private let fileName = "run_trace.json"

    func traceExists() -> Bool {
        (try? traceURL().checkResourceIsReachable()) == true
    }

    func save(_ trace: RunTrace) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(trace)
        let url = try traceURL()
        try data.write(to: url, options: [.atomic])
    }

    func load() throws -> RunTrace {
        let url = try traceURL()
        guard (try? url.checkResourceIsReachable()) == true else {
            throw StoreError.missing
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        guard let trace = try? decoder.decode(RunTrace.self, from: data) else {
            throw StoreError.invalidData
        }
        return trace
    }

    func delete() throws {
        let url = try traceURL()
        guard (try? url.checkResourceIsReachable()) == true else { return }
        try FileManager.default.removeItem(at: url)
    }

    func tracePathString() -> String? {
        (try? traceURL().path)
    }

    private func traceURL() throws -> URL {
        try AVPDataDirectory.rootURL().appendingPathComponent(fileName, isDirectory: false)
    }
}

