import SwiftUI

struct ChapterEndPanel: View {
    let previousFloor: Int
    let nextFloor: Int
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chapter Cleared")
                .font(.headline)

            Text("Act \(previousFloor) complete")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Next: Act \(nextFloor)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 320)
    }
}

