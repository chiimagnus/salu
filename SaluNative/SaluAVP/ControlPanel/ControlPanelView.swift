import SwiftUI

import GameCore

struct ControlPanelView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(RunSession.self) private var runSession

    var body: some View {
        @Bindable var runSession = runSession

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
        }
        .padding(24)
    }
}

#Preview(windowStyle: .volumetric) {
    ControlPanelView()
        .environment(AppModel())
        .environment(RunSession())
}

