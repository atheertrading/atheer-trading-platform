import AppKit
import SwiftUI

@MainActor
final class ATHEERApplicationDelegate: NSObject, NSApplicationDelegate {
    var onTerminate: (() -> Void)?

    func applicationWillTerminate(_ notification: Notification) {
        onTerminate?()
    }
}

@main
struct ATHEERTradingProApp: App {
    @NSApplicationDelegateAdaptor(ATHEERApplicationDelegate.self) private var appDelegate
    @StateObject private var backendRuntimeModel = BackendRuntimeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(backendRuntimeModel: backendRuntimeModel)
                .preferredColorScheme(.dark)
                .onAppear {
                    appDelegate.onTerminate = {
                        backendRuntimeModel.stop()
                    }
                }
        }
        .commands {
            TextEditingCommands()
        }
        .windowStyle(.titleBar)
    }
}
