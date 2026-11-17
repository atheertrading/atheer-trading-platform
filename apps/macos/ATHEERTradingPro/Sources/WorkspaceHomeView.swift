import SwiftUI

/// Compatibility entry point retained for the existing application navigation.
/// The primary workspace is implemented by CommandCenterView.
struct WorkspaceHomeView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel
    let onOpenAPIConnection: () -> Void

    var body: some View {
        CommandCenterView(
            backendHealthModel: backendHealthModel,
            onOpenAPIConnection: onOpenAPIConnection
        )
    }
}
