import AppKit
import SwiftUI

@MainActor
final class ATHEERApplicationDelegate: NSObject, NSApplicationDelegate {
    var onTerminate: (() async throws -> Void)?
    private var terminationPending = false

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let onTerminate else { return .terminateNow }
        guard !terminationPending else { return .terminateLater }

        terminationPending = true
        Task { @MainActor [weak self] in
            do {
                try await onTerminate()
                sender.reply(toApplicationShouldTerminate: true)
            } catch {
                self?.terminationPending = false
                sender.reply(toApplicationShouldTerminate: false)
            }
        }
        return .terminateLater
    }
}

@main
@MainActor
struct ATHEERTradingProApp: App {
    @NSApplicationDelegateAdaptor(ATHEERApplicationDelegate.self) private var appDelegate
    @StateObject private var backendRuntimeModel = BackendRuntimeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(backendRuntimeModel: backendRuntimeModel)
                .preferredColorScheme(.dark)
                .onAppear {
                    appDelegate.onTerminate = {
                        try await backendRuntimeModel.stop()
                    }
                }
        }
        .commands {
            TextEditingCommands()
        }
        .windowStyle(.titleBar)
    }
}
