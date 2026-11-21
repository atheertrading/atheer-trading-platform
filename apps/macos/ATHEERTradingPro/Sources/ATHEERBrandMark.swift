import SwiftUI

/// Geometric ATHEER mark. Coordinates match atheer-mark-primary.svg.
struct ATHEERBrandMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: rect.minX + (x / 100.0) * rect.width,
                y: rect.minY + (y / 100.0) * rect.height
            )
        }

        var path = Path()
        path.move(to: point(50, 3))
        path.addLine(to: point(97, 94))
        path.addLine(to: point(73, 94))
        path.addLine(to: point(50, 50))
        path.addLine(to: point(27, 94))
        path.addLine(to: point(3, 94))
        path.closeSubpath()

        path.move(to: point(50, 51))
        path.addLine(to: point(63, 78))
        path.addLine(to: point(37, 78))
        path.closeSubpath()
        return path
    }
}

struct ATHEERBrandMark: View {
    var size: CGFloat = 28

    var body: some View {
        ATHEERBrandMarkShape()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        ATHEERDesignTokens.ColorRole.brandGold,
                        ATHEERDesignTokens.ColorRole.brandTurquoise
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: FillStyle(eoFill: true)
            )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct ATHEERBrandLockup: View {
    var markSize: CGFloat = 32

    var body: some View {
        HStack(spacing: ATHEERDesignTokens.Spacing.small) {
            ATHEERBrandMark(size: markSize)
            VStack(alignment: .leading, spacing: 1) {
                Text("ATHEER")
                    .font(ATHEERDesignTokens.Typography.brand)
                    .tracking(1.4)
                Text("Trading Pro")
                    .font(ATHEERDesignTokens.Typography.caption)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ATHEER Trading Pro")
    }
}
