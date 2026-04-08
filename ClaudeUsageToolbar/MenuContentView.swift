import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var model: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Token Usage Menubar")
                .font(.headline)

            if let err = model.lastError {
                Text(err)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .textSelection(.enabled)
            } else {
                ForEach(Array(model.detailLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            if let updated = model.lastUpdated {
                Text("Updated \(RelativeDateTimeFormatter().localizedString(for: updated, relativeTo: Date()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Refresh now") { Task { await model.refresh() } }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding()
        .frame(minWidth: 300)
    }
}
