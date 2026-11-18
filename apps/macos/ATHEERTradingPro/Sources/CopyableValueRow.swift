import AppKit
import SwiftUI

/// A selectable, explicitly copyable row for non-sensitive diagnostic values.
struct CopyableValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
            Button(action: copyValue) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .help("Copy \(title)")
            .accessibilityLabel("Copy \(title)")
            .contextMenu {
                Button("Copy \(title)", action: copyValue)
            }
        }
    }

    private func copyValue() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
