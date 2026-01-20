//
//  NetworkView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct NetworkView: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Network Configuration")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Manage network adapters and settings")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(viewModel.adapters.enumerated()), id: \.element.id) { index, adapter in
                        AdapterCard(adapter: adapter, index: index, viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

struct AdapterCard: View {
    let adapter: NetworkAdapter
    let index: Int
    @ObservedObject var viewModel: ServerManagerViewModel
    
    var statusColor: Color {
        adapter.status == .connected ? .green500 : .zinc400
    }
    
    var statusBackground: Color {
        adapter.status == .connected ? Color.green500.opacity(0.1) : Color.zinc200.opacity(0.5)
    }
    
    var macAddress: String {
        "00-15-5D-\(String(format: "%02d", Int.random(in: 10...99)))-\(String(format: "%02d", Int.random(in: 10...99)))-\(String(format: "%02d", Int.random(in: 10...99)))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.system(size: 24))
                        .foregroundColor(.blue500)
                        .frame(width: 48, height: 48)
                        .background(Color.blue500.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(adapter.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.zinc900)
                        Text(adapter.ip)
                            .font(.system(size: 12))
                            .foregroundColor(.zinc600)
                    }
                }
                
                Spacer()
                
                Text(adapter.status.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBackground)
                    .cornerRadius(12)
            }
            
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speed")
                        .font(.system(size: 11))
                        .foregroundColor(.zinc600)
                    Text(adapter.speed)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc900)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("MAC Address")
                        .font(.system(size: 11))
                        .foregroundColor(.zinc600)
                    Text(macAddress)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc900)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("DHCP Enabled")
                        .font(.system(size: 11))
                        .foregroundColor(.zinc600)
                    Text(index == 0 ? "No" : "Yes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc900)
                }
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.selectedAdapter = adapter
                    viewModel.adapterIP = adapter.ip
                    viewModel.adapterDHCP = adapter.ip == "Not assigned"
                    viewModel.networkConfigDialogOpen = true
                }) {
                    Text("Configure")
                        .font(.system(size: 12))
                        .foregroundColor(.zinc900)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.zinc100)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.handleToggleAdapter(adapter.name)
                }) {
                    Text(adapter.status == .connected ? "Disable" : "Enable")
                        .font(.system(size: 12))
                        .foregroundColor(.zinc900)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.zinc100)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Text("Advanced")
                        .font(.system(size: 12))
                        .foregroundColor(.zinc900)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.zinc100)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
        )
    }
}

struct NetworkConfigDialog: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Configure \(viewModel.selectedAdapter?.name ?? "")")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.zinc900)
            
            Text("Manage network adapter settings")
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Obtain IP address automatically (DHCP)", isOn: $viewModel.adapterDHCP)
                    .font(.system(size: 13))
                
                if !viewModel.adapterDHCP {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IP Address")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.zinc700)
                        
                        TextField("192.168.1.100", text: $viewModel.adapterIP)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc700)
                    
                    Text(viewModel.selectedAdapter?.speed ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.zinc900)
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save Changes") {
                    viewModel.handleSaveNetworkConfig()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}

#Preview {
    NetworkView(viewModel: ServerManagerViewModel())
        .frame(width: 1200, height: 800)
}
