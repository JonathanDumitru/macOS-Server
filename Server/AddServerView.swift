//
//  AddServerView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData

struct AddServerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = 80
    @State private var serverType: ServerType = .http
    @State private var notes = ""
    
    var isValid: Bool {
        !name.isEmpty && !host.isEmpty && port > 0 && port <= 65535
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server Information") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Host", text: $host)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)
                    
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("Port", value: $port, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Type", selection: $serverType) {
                        ForEach(ServerType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    HStack {
                        Text("URL Preview")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(urlPreview)
                            .font(.caption.monospaced())
                            .foregroundStyle(.blue)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addServer()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var urlPreview: String {
        switch serverType {
        case .http: return "http://\(host.isEmpty ? "example.com" : host):\(port)"
        case .https: return "https://\(host.isEmpty ? "example.com" : host):\(port)"
        case .ftp: return "ftp://\(host.isEmpty ? "example.com" : host):\(port)"
        case .ssh: return "ssh://\(host.isEmpty ? "example.com" : host):\(port)"
        default: return "\(host.isEmpty ? "example.com" : host):\(port)"
        }
    }
    
    private func addServer() {
        let newServer = Server(
            name: name,
            host: host,
            port: port,
            serverType: serverType,
            notes: notes
        )
        
        modelContext.insert(newServer)
        dismiss()
    }
}

#Preview {
    AddServerView()
        .modelContainer(for: Server.self, inMemory: true)
}
