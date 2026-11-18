import SwiftUI

@main
struct ATHEERTradingProApp: App {
    @AppStorage(ATHEERAppearance.storageKey)
    private var appearancePreference = ATHEERAppearance.dark.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    ATHEERAppearance.resolve(appearancePreference).colorScheme
                )
        }
        .commands {
            TextEditingCommands()
        }
        .windowStyle(.titleBar)
    }
}
