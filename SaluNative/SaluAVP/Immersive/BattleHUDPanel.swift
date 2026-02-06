import SwiftUI
import GameCore

struct BattleHUDPanel: View {
    @Environment(RunSession.self) private var runSession
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    @State private var isLogExpanded: Bool = false

    var body: some View {
        @Bindable var runSession = runSession

        let battleState = runSession.battleState
        let engine = runSession.battleEngine

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Battle")
                    .font(.headline)

                Spacer(minLength: 0)

                Button(isLogExpanded ? "Hide" : "Log") {
                    isLogExpanded.toggle()
                }
                .font(.caption2)
                .buttonStyle(.bordered)
            }

            if let state = battleState {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Player HP \(state.player.currentHP)/\(state.player.maxHP)  Block \(state.player.block)")
                        .font(.caption)
                    let enemy = state.enemies.first
                    Text("Enemy: \(enemy.map { $0.name.resolved(for: .zhHans) } ?? "-")  HP \(enemy?.currentHP ?? 0)/\(enemy?.maxHP ?? 0)  Block \(enemy?.block ?? 0)")
                        .font(.caption)
                    Text("Turn \(state.turn)  Energy \(state.energy)/\(state.maxEnergy)  \(state.isPlayerTurn ? "Player" : "Enemy")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let pending = engine?.pendingInput {
                        Text("Pending: \(pendingLabel(pending))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No battle state.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button("End Turn") {
                    runSession.endTurn()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!(battleState?.isPlayerTurn ?? false) || (engine?.pendingInput != nil))

                Button("Exit") {
                    Task { @MainActor in
                        await dismissImmersiveSpace()
                        openWindow(id: AppModel.controlPanelWindowID)
                    }
                }
                .buttonStyle(.bordered)
            }

            if isLogExpanded, let events = engine?.events, !events.isEmpty {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(events.suffix(8).enumerated()), id: \.offset) { _, event in
                            Text(event.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 260)
    }

    private func pendingLabel(_ pending: BattlePendingInput) -> String {
        switch pending {
        case .foresight(_, let fromCount):
            return "Foresight(\(fromCount))"
        }
    }
}
