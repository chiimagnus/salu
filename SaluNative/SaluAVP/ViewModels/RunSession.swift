import Foundation
import SwiftUI
import GameCore

@MainActor
@Observable
final class RunSession {
    enum Route: Equatable, Sendable {
        case map
        case room(nodeId: String, roomType: RoomType)
        case runOver(lastNodeId: String, won: Bool, floor: Int)
    }

    var seedText: String = ""
    private(set) var seed: UInt64?
    var lastError: String?
    var runState: RunState?
    var route: Route = .map

    func startNewRun() {
        let seed: UInt64
        if seedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            seed = Self.generateSeed()
        } else if let parsed = UInt64(seedText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            seed = parsed
        } else {
            lastError = "Invalid seed. Please enter a UInt64 number."
            return
        }

        self.seed = seed
        runState = RunState.newRun(seed: seed)
        seedText = String(seed)
        lastError = nil
        route = .map
    }

    func selectAccessibleNode(_ nodeId: String) {
        guard var runState else { return }
        guard runState.enterNode(nodeId) else { return }

        self.runState = runState

        guard let node = runState.map.node(withId: nodeId) else {
            lastError = "Node not found: \(nodeId)"
            return
        }

        route = .room(nodeId: nodeId, roomType: node.roomType)
    }

    func completeCurrentRoomAndReturnToMap() {
        let lastNodeId: String?
        if case .room(let nodeId, _) = route {
            lastNodeId = nodeId
        } else {
            lastNodeId = nil
        }

        guard var runState else { return }
        runState.completeCurrentNode()
        self.runState = runState

        if runState.isOver, let lastNodeId {
            route = .runOver(lastNodeId: lastNodeId, won: runState.won, floor: runState.floor)
        } else {
            route = .map
        }
    }

    private static func generateSeed() -> UInt64 {
        UInt64(Date().timeIntervalSince1970 * 1000)
    }

    func resetToControlPanel() {
        runState = nil
        route = .map
        lastError = nil
    }
}
