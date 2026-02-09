import SwiftUI

struct ReplayPanel: View {
    @Environment(RunSession.self) private var runSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trace / Replay")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("Export Trace") {
                    runSession.exportRunTrace()
                }
                .buttonStyle(.bordered)
                .disabled(runSession.runTrace == nil)

                Button("Replay") {
                    runSession.replayFromSavedTrace()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!runSession.hasSavedRunTrace)

                Button("Clear Trace") {
                    runSession.clearRunTrace()
                }
                .buttonStyle(.bordered)
                .disabled(runSession.runTrace == nil)

                Button("Delete Trace") {
                    runSession.deleteSavedTrace()
                }
                .buttonStyle(.bordered)
                .disabled(!runSession.hasSavedRunTrace)
            }

            if let trace = runSession.runTrace {
                Text("Trace entries: \(trace.entries.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Trace: off (replay mode or no run).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let path = runSession.lastTracePath {
                Text("Trace file: \(path)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let replayError = runSession.lastReplayError {
                Text(replayError)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }
}

