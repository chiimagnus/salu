import SwiftUI
import GameCore

struct MapHUDPanel: View {
    @Environment(RunSession.self) private var runSession
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var runSession = runSession

        VStack(alignment: .leading, spacing: 8) {
            Text("SaluAVP")
                .font(.headline)

            if let run = runSession.runState {
                Text("Act \(run.floor)/\(run.maxFloor)  HP \(run.player.currentHP)/\(run.player.maxHP)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Gold \(run.gold)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("No run.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button("Exit") {
                    Task { @MainActor in
                        await dismissImmersiveSpace()
                        openWindow(id: AppModel.controlPanelWindowID)
                    }
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 200)
    }
}
