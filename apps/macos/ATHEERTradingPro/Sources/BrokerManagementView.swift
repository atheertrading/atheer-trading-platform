import SwiftUI

struct BrokerManagementView: View {
    @ObservedObject var model: BrokerManagementViewModel
    @State private var showingCredentials = false
    @State private var showingClearConfirmation = false
    @State private var credentialError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ATHEERDesignTokens.Spacing.section) {
                header
                capitalComCard
                securityNotice
            }
            .padding(ATHEERDesignTokens.Spacing.page)
            .frame(maxWidth: 980, alignment: .leading)
        }
        .task { await model.monitorSession() }
        .sheet(isPresented: $showingCredentials) {
            CapitalComCredentialsView(model: model, onClose: { showingCredentials = false })
        }
        .alert("Clear Capital.com Credentials?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Credentials", role: .destructive) {
                Task {
                    do { try await model.clearCredentials() }
                    catch { credentialError = "Credentials could not be removed from Keychain." }
                }
            }
        } message: {
            Text("This removes the saved DEMO API key and password from this Mac's Keychain and disconnects the current session.")
        }
        .alert("Credential Operation Failed", isPresented: Binding(
            get: { credentialError != nil },
            set: { if !$0 { credentialError = nil } }
        )) {
            Button("OK", role: .cancel) { credentialError = nil }
        } message: {
            Text(credentialError ?? "The operation could not be completed.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Brokers")
                .font(ATHEERDesignTokens.Typography.screenTitle)
            Text("Manage broker connections and secure API credentials.")
                .font(ATHEERDesignTokens.Typography.body)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var capitalComCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 42, height: 42)
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Capital.com")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Broker integration · REST authentication")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                statusBadge
            }

            Divider().overlay(ATHEERDesignTokens.ColorRole.separator)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), alignment: .leading)], alignment: .leading, spacing: 14) {
                metric("ENVIRONMENT", value: "DEMO", tint: ATHEERDesignTokens.ColorRole.attention)
                metric("CREDENTIALS", value: model.hasSavedCredentials ? "Stored in Keychain" : "Not configured")
                metric("AUTHENTICATION", value: model.state.title)
                metric("SESSION", value: model.state == .connected ? "Active" : (model.state == .sessionExpired ? "Expired" : "Inactive"))
                metric("LAST CONNECTED", value: model.lastSuccessfulConnection?.formatted(date: .abbreviated, time: .shortened) ?? "Not verified this session")
                metric("LAST BACKEND STATUS CHECK", value: model.lastSessionVerification?.formatted(date: .abbreviated, time: .shortened) ?? "Not verified")
                metric("MARKET STREAM", value: "Not connected", tint: .secondary)
                metric("TRADING", value: "Disabled", tint: .secondary)
            }

            if let key = model.maskedAPIKey {
                HStack {
                    Text("API KEY")
                        .font(ATHEERDesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(key)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .textSelection(.disabled)
                }
            }

            if let account = model.account {
                Divider().overlay(ATHEERDesignTokens.ColorRole.separator)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LOGIN IDENTITY")
                            .font(ATHEERDesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                        Text(account.maskedLoginIdentifier)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    }
                    Spacer()
                    if let currency = account.currencyCode {
                        metric("CURRENCY", value: currency)
                    }
                }
            }

            if let message = model.state.message {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.attention)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            HStack(spacing: 8) {
                Button {
                    showingCredentials = true
                } label: {
                    Label(model.hasSavedCredentials ? "Edit Credentials" : "Configure Credentials", systemImage: "key")
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await model.testConnection() }
                } label: {
                    if model.isWorking {
                        ProgressView().controlSize(.small)
                        Text("Authenticating…")
                    } else {
                        Label(model.state == .connected ? "Test Connection" : "Connect", systemImage: "checkmark.shield")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.teal)
                .disabled(!model.hasSavedCredentials || model.isWorking)

                if model.hasSavedCredentials && model.state != .credentialsSaved {
                    Button("Disconnect") {
                        Task { await model.disconnect() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isWorking)
                }
                Spacer()
                if model.hasSavedCredentials {
                    Button("Clear Credentials", role: .destructive) {
                        showingClearConfirmation = true
                    }
                    .buttonStyle(.borderless)
                    .disabled(model.isWorking)
                }
            }
        }
        .padding(18)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusBadge: some View {
        let color: Color
        switch model.state {
        case .connected, .authenticated: color = ATHEERDesignTokens.ColorRole.success
        case .connecting: color = ATHEERDesignTokens.ColorRole.attention
        case .authenticationFailed, .connectionFailed, .sessionExpired: color = ATHEERDesignTokens.ColorRole.danger
        default: color = .secondary
        }
        return HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(model.state.title)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }

    private var securityNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Connection and permissions are separate", systemImage: "lock.shield")
                .font(.system(size: 12, weight: .semibold))
            Text("This DEMO-only connection sends credentials to the managed backend over authenticated loopback IPC and creates a Capital.com DEMO session. The screen displays sanitized backend session state; it does not currently retrieve or display broker account details. ATHEER does not submit orders, modify positions, enable trading, or connect to a LIVE endpoint from this screen. Market-data streaming is not established by REST authentication.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panelElevated)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func metric(_ title: String, value: String, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(ATHEERDesignTokens.Typography.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(tint)
                .lineLimit(2)
        }
    }
}

private struct CapitalComCredentialsView: View {
    @ObservedObject var model: BrokerManagementViewModel
    let onClose: () -> Void
    @State private var apiKey = ""
    @State private var identifier = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capital.com Credentials")
                        .font(.system(size: 18, weight: .semibold))
                    Text("DEMO environment · Stored in macOS Keychain")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Close", action: onClose)
                    .keyboardShortcut(.cancelAction)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Environment").font(.system(size: 11, weight: .semibold))
                HStack {
                    Text("DEMO").font(.system(size: 12, weight: .bold))
                    Spacer()
                    Text("LIVE is disabled").font(.system(size: 10)).foregroundColor(.secondary)
                }
                .padding(10)
                .background(ATHEERDesignTokens.ColorRole.panel)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("API Key").font(.system(size: 11, weight: .semibold))
                SecureField("Enter Capital.com API key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Capital.com API key")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Account Login / Identifier").font(.system(size: 11, weight: .semibold))
                TextField("Email or account login", text: $identifier)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Capital.com account login identifier")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("API Key Password").font(.system(size: 11, weight: .semibold))
                SecureField("Enter API key custom password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Capital.com API key password")
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button("Save Credentials") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.teal)
                .disabled(isSaving || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
            }
        }
        .padding(22)
        .frame(width: 460)
    }

    private func save() {
        isSaving = true
        Task { @MainActor in
            do {
                try await model.saveCredentials(BrokerCredential(
                    apiKey: apiKey,
                    identifier: identifier,
                    password: password
                ))
                apiKey = ""
                identifier = ""
                password = ""
                onClose()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
