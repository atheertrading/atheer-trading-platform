import SwiftUI

enum WorkspacePanelID: String, CaseIterable, Identifiable, Hashable, Codable {
    case marketWatch
    case charts
    case accountRisk
    case platformHealth

    var id: String { rawValue }

    var isPrimaryRegion: Bool {
        switch self {
        case .charts, .platformHealth: return true
        case .marketWatch, .accountRisk: return false
        }
    }

    var title: String {
        switch self {
        case .marketWatch: return "Market Watch"
        case .charts: return "Chart Workspace"
        case .accountRisk: return "Account & Risk"
        case .platformHealth: return "Platform Health"
        }
    }

    static let defaultVisible = Set(WorkspacePanelID.allCases)
}

struct WorkspacePanelCard<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    let status: String
    let statusColor: Color
    private let content: Content

    init(
        title: String,
        subtitle: String,
        symbol: String,
        status: String,
        statusColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.status = status
        self.statusColor = statusColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ATHEERDesignTokens.Spacing.standard) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                    .frame(width: 28, height: 28)
                    .background(ATHEERDesignTokens.ColorRole.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(ATHEERDesignTokens.Typography.panelTitle)
                    Text(subtitle)
                        .font(ATHEERDesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                Text(status)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.10))
                    .clipShape(Capsule())
            }

            Divider()
                .overlay(ATHEERDesignTokens.ColorRole.separator)

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 174, alignment: .topLeading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

struct WorkspaceUnavailableState: View {
    let symbol: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 18)

            Text(message)
                .font(ATHEERDesignTokens.Typography.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct WorkspaceStatusTile: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .foregroundColor(tint)
                Text(title.uppercased())
                    .font(ATHEERDesignTokens.Typography.caption)
                    .tracking(0.6)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(ATHEERDesignTokens.Typography.numeric)
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(11)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
