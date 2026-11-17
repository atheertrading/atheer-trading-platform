import SwiftUI

@main
struct ATHEERTradingProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .commands {
            TextEditingCommands()
        }
        .windowStyle(.titleBar)
    }
}
