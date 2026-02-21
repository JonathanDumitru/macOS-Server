//
//  CredentialsView.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI
import SwiftData

// MARK: - Credentials Editor View

struct CredentialsEditorView: View {
    @Bindable var server: Server
    @Environment(\.dismiss) private var dismiss

    @State private var credentials = ServerCredentials()
    @State private var showPassword = false
    @State private var showPassphrase = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Authentication Type", selection: $credentials.authType) {
                        ForEach(ServerCredentials.AuthenticationType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                } header: {
                    Text("Authentication Method")
                }

                Section {
                    TextField("Username", text: $credentials.username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocorrectionDisabled()

                    if credentials.authType == .password {
                        HStack {
                            if showPassword {
                                TextField("Password", text: $credentials.password)
                            } else {
                                SecureField("Password", text: $credentials.password)
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("Credentials")
                }

                if credentials.authType != .password {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Private Key")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextEditor(text: Binding(
                                get: { credentials.privateKey ?? "" },
                                set: { credentials.privateKey = $0.isEmpty ? nil : $0 }
                            ))
                            .font(.system(size: 11, design: .monospaced))
                            .frame(minHeight: 100)
                            .border(Color.gray.opacity(0.3), width: 1)

                            Button("Load from File...") {
                                loadPrivateKeyFromFile()
                            }
                            .font(.caption)
                        }

                        if credentials.authType == .privateKeyWithPassphrase {
                            HStack {
                                if showPassphrase {
                                    TextField("Key Passphrase", text: Binding(
                                        get: { credentials.privateKeyPassphrase ?? "" },
                                        set: { credentials.privateKeyPassphrase = $0.isEmpty ? nil : $0 }
                                    ))
                                } else {
                                    SecureField("Key Passphrase", text: Binding(
                                        get: { credentials.privateKeyPassphrase ?? "" },
                                        set: { credentials.privateKeyPassphrase = $0.isEmpty ? nil : $0 }
                                    ))
                                }

                                Button {
                                    showPassphrase.toggle()
                                } label: {
                                    Image(systemName: showPassphrase ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .textFieldStyle(.roundedBorder)
                        }
                    } header: {
                        Text("Private Key")
                    }
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if server.hasStoredCredentials {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Credentials", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    } header: {
                        Text("Danger Zone")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(server.hasStoredCredentials ? "Edit Credentials" : "Add Credentials")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCredentials()
                    }
                    .disabled(!credentials.isValid)
                }
            }
            .onAppear {
                loadExistingCredentials()
            }
            .confirmationDialog(
                "Delete Credentials",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteCredentials()
                }
            } message: {
                Text("Are you sure you want to delete the stored credentials for this server? This action cannot be undone.")
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }

    private func loadExistingCredentials() {
        if let existing = server.loadCredentials() {
            credentials = existing
        }
        isLoading = false
    }

    private func saveCredentials() {
        do {
            if server.hasStoredCredentials {
                try server.updateCredentials(credentials)
            } else {
                try server.saveCredentials(credentials)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteCredentials() {
        do {
            try server.deleteCredentials()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPrivateKeyFromFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.text, .plainText]
        panel.message = "Select your private key file"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                credentials.privateKey = content
            } catch {
                errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Credentials Summary View

struct CredentialsSummaryView: View {
    let server: Server
    let onEdit: () -> Void

    var body: some View {
        GroupBox {
            HStack(spacing: 12) {
                Image(systemName: server.hasStoredCredentials ? "key.fill" : "key")
                    .font(.system(size: 20))
                    .foregroundStyle(server.hasStoredCredentials ? .green : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    if server.hasStoredCredentials {
                        Text("Credentials Stored")
                            .font(.system(size: 13, weight: .medium))

                        if let username = server.credentialUsername {
                            Text("Username: \(username)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No Credentials")
                            .font(.system(size: 13, weight: .medium))

                        Text("Add credentials for SSH/SFTP access")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    onEdit()
                } label: {
                    Text(server.hasStoredCredentials ? "Edit" : "Add")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(4)
        } label: {
            Label("Authentication", systemImage: "lock.fill")
        }
    }
}

// MARK: - Inline Credentials Badge

struct CredentialsBadge: View {
    let hasCredentials: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: hasCredentials ? "key.fill" : "key")
                .font(.system(size: 10))
            Text(hasCredentials ? "Auth" : "No Auth")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(hasCredentials ? .green : .secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(hasCredentials ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
        )
    }
}

#Preview {
    CredentialsEditorView(server: Server(name: "Test", host: "example.com", port: 22, serverType: .ssh))
        .modelContainer(for: Server.self, inMemory: true)
}
