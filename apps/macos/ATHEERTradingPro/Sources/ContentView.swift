import SwiftUI

struct ContentView: View {
    private let background = Color(red: 18.0 / 255.0, green: 18.0 / 255.0, blue: 18.0 / 255.0)
    private let accent = Color(red: 0.0, green: 206.0 / 255.0, blue: 200.0 / 255.0)

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                Text("ATHEER")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundColor(accent)
                Text("TRADING PRO")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                Divider()
                Label("Workspace", systemImage: "square.grid.2x2")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text("FOUNDATION")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .frame(width: 210, alignment: .leading)
            .background(Color(red: 9.0 / 255.0, green: 55.0 / 255.0, blue: 50.0 / 255.0).opacity(0.35))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Workspace")
                        .font(.system(size: 22, weight: .semibold))
                    Spacer()
                    Text("DEVELOPMENT")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(accent)
                }
                Divider()
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Engineering foundation")
                        .font(.system(size: 18, weight: .semibold))
                    Text("The application shell is initialized. Market data, trading, risk, portfolio, and AI modules will be introduced only after their contracts and verification criteria are established.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: 560, alignment: .leading)
                Spacer()
                Text("No broker connection • No order execution • Trading disabled")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(background)
    }
}

#Preview {
    ContentView()
}
