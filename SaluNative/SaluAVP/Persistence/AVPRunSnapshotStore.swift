import Foundation
import GameCore

struct AVPRunSnapshotStore: Sendable {
    enum StoreError: Error, Sendable, Equatable {
        case missing
        case invalidData
    }

    private let fileName = "run_snapshot.json"

    func snapshotExists() -> Bool {
        (try? snapshotURL().checkResourceIsReachable()) == true
    }

    func save(_ snapshot: RunSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)

        let url = try snapshotURL()
        try data.write(to: url, options: [.atomic])
    }

    func load() throws -> RunSnapshot {
        let url = try snapshotURL()
        guard (try? url.checkResourceIsReachable()) == true else {
            throw StoreError.missing
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        guard let snapshot = try? decoder.decode(RunSnapshot.self, from: data) else {
            throw StoreError.invalidData
        }
        return snapshot
    }

    func delete() throws {
        let url = try snapshotURL()
        guard (try? url.checkResourceIsReachable()) == true else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func snapshotURL() throws -> URL {
        try AVPDataDirectory.rootURL().appendingPathComponent(fileName, isDirectory: false)
    }
}

