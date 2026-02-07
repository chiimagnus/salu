import SwiftUI

import GameCore

struct ControlPanelView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(RunSession.self) private var runSession

    var body: some View {
        @Bindable var runSession = runSession
        @Bindable var appModel = appModel

        VStack(alignment: .center, spacing: 14) {
            Text("SaluAVP")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                TextField("Seed (UInt64)", text: $runSession.seedText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)

                Button("New Run") {
                    runSession.startNewRun()
                }
                .fontWeight(.semibold)
            }

            if let error = runSession.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let run = runSession.runState {
                Text("Run: Act \(run.floor)/\(run.maxFloor)  HP \(run.player.currentHP)/\(run.player.maxHP)")
                    .font(.caption)
                Text("Route: \(routeLabel(runSession.route))  Current: \(run.currentNodeId ?? "-")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("No run started.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 12) {
                ImmersiveSpaceToggleButton()

                Text("Immersive: \(String(describing: appModel.immersiveSpaceState))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Card Display Mode")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Card Display Mode", selection: $appModel.cardDisplayMode) {
                    ForEach(CardDisplayMode.allCases) { mode in
                        Text(mode.shortLabel).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(appModel.cardDisplayMode.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
    }

    private func routeLabel(_ route: RunSession.Route) -> String {
        switch route {
        case .map:
            return "map"
        case .room(_, let roomType):
            return "room(\(roomType.rawValue))"
        case .battle(_, let roomType):
            return "battle(\(roomType.rawValue))"
        case .cardReward(_, let roomType, _, _):
            return "cardReward(\(roomType.rawValue))"
        case .runOver(_, let won, let floor):
            return "runOver(won:\(won), floor:\(floor))"
        }
    }
}

#Preview {
    ControlPanelView()
        .environment(AppModel())
        .environment(RunSession())
}
