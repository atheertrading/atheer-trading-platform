import SwiftUI

struct ContentView: View {
    private let background = Color(red: 18.0 / 255.0, green: 18.0 / 255.0, blue: 18.0 / 255.0)
    @State private var selection: AppSection? = .workspace
    @StateObject private var backendHealthModel = BackendHealthViewModel()

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ATHEER")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundColor(Color(red: 0.0, green: 206.0 / 255.0, blue: 200.0 / 255.0))
                    Text("TRADING PRO")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)

                List(selection: $selection) {
                    Section("WORKSPACE") {
                        Label(AppSection.workspace.title, systemImage: AppSection.workspace.systemImage)
                            .tag(AppSection.workspace)
                    }
                    Section("SYSTEM") {
                        Label(AppSection.apiConnection.title, systemImage: AppSection.apiConnection.systemImage)
                            .tag(AppSection.apiConnection)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 190)
            .background(Color(red: 9.0 / 255.0, green: 55.0 / 255.0, blue: 50.0 / 255.0).opacity(0.22))
        } detail: {
            Group {
                switch selection ?? .workspace {
                case .workspace:
                    WorkspaceHomeView(backendHealthModel: backendHealthModel)
                case .apiConnection:
                    APIConnectionView(model: backendHealthModel)
                }
            }
            .frame(minWidth: 620, minHeight: 520)
            .background(background)
            .navigationTitle((selection ?? .workspace).title)
        }
        .frame(minWidth: 900, minHeight: 600)
        .task {
            await backendHealthModel.refresh()
        }
    }
}
