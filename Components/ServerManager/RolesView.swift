//
//  RolesView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct RolesView: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    
    var availableRoles: [ServerRole] {
        viewModel.roles.filter { $0.status == .available }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Roles and Features")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Manage server roles, role services, and features")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 12) {
                    // Action Buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.addRoleDialogOpen = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 16))
                                Text("Add Roles and Features")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue500)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16))
                                Text("Refresh")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.zinc900)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    // Roles List
                    VStack(spacing: 12) {
                        ForEach(viewModel.roles) { role in
                            RoleCard(role: role, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct RoleCard: View {
    let role: ServerRole
    @ObservedObject var viewModel: ServerManagerViewModel
    @State private var isExpanded = false
    
    var statusColor: Color {
        switch role.status {
        case .installed: return .green500
        case .installing: return .blue500
        case .available: return .zinc400
        }
    }
    
    var statusBackground: Color {
        switch role.status {
        case .installed: return .green500.opacity(0.1)
        case .installing: return .blue500.opacity(0.1)
        case .available: return .zinc200.opacity(0.5)
        }
    }
    
    var statusText: String {
        switch role.status {
        case .installed: return "Installed"
        case .installing: return "Installing..."
        case .available: return "Available"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                    viewModel.selectedRole = isExpanded ? role.id : nil
                }
            }) {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: role.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.blue500)
                        .frame(width: 40, height: 40)
                        .background(Color.blue500.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(role.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.zinc900)
                            
                            // Status Badge
                            Text(statusText)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusBackground)
                                .cornerRadius(12)
                            
                            if let lastUpdated = role.lastUpdated {
                                Spacer()
                                Text("Updated \(lastUpdated)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.zinc500)
                            }
                        }
                        
                        Text(role.description)
                            .font(.system(size: 13))
                            .foregroundColor(.zinc600)
                            .lineLimit(2)
                        
                        if let subFeatures = role.subFeatures {
                            HStack(spacing: 4) {
                                Text("\(subFeatures.count) features")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue500)
                                
                                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue500)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons (only for installed roles)
                    if role.status == .installed {
                        HStack(spacing: 8) {
                            Button(action: {
                                viewModel.selectedRoleForAction = role
                                viewModel.configureRoleDialogOpen = true
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
                                viewModel.selectedRoleForAction = role
                                viewModel.removeRoleDialogOpen = true
                            }) {
                                Text("Remove")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red500)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red500.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isExpanded ? Color.blue500.opacity(0.5) : Color.zinc200.opacity(0.6), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            // Expanded Sub-features
            if isExpanded, let subFeatures = role.subFeatures {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Role Services and Features")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.zinc900)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(subFeatures, id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green500)
                                Text(feature)
                                    .font(.system(size: 13))
                                    .foregroundColor(.zinc700)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.zinc50)
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.zinc50.opacity(0.5))
                .cornerRadius(12)
                .padding(.top, 8)
                .padding(.leading, 56)
            }
        }
    }
}

// Dialog Views
struct AddRoleDialog: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    @Environment(\.dismiss) var dismiss
    
    var availableRoles: [ServerRole] {
        viewModel.roles.filter { $0.status == .available }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add Roles and Features")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.zinc900)
                .padding(.bottom, 8)
            
            Text("Select a role to install on this server")
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
                .padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(availableRoles) { role in
                        Button(action: {
                            viewModel.handleAddRole(roleId: role.id)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: role.iconName)
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue500)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(role.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.zinc900)
                                    Text(role.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.zinc600)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.zinc400)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 400)
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 24)
        }
        .padding(24)
        .frame(width: 600)
    }
}

struct ConfigureRoleDialog: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Configure \(viewModel.selectedRoleForAction?.name ?? "")")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.zinc900)
            
            Text("Manage configuration settings for this role")
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Service Status")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc700)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green500)
                        Text("Running")
                            .font(.system(size: 13))
                            .foregroundColor(.zinc900)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Startup Type")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc700)
                    
                    Picker("", selection: .constant("Automatic")) {
                        Text("Automatic").tag("Automatic")
                        Text("Manual").tag("Manual")
                        Text("Disabled").tag("Disabled")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let subFeatures = viewModel.selectedRoleForAction?.subFeatures {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enabled Features")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.zinc700)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(subFeatures, id: \.self) { feature in
                                HStack(spacing: 8) {
                                    Toggle("", isOn: .constant(true))
                                        .toggleStyle(.checkbox)
                                    Text(feature)
                                        .font(.system(size: 12))
                                        .foregroundColor(.zinc700)
                                }
                            }
                        }
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save Changes") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 600)
    }
}

struct RemoveRoleDialog: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Remove \(viewModel.selectedRoleForAction?.name ?? "")")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.zinc900)
            
            Text("Are you sure you want to remove this role? The server will need to restart to complete the removal.")
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Remove Role") {
                    viewModel.handleRemoveRole()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}

#Preview {
    RolesView(viewModel: ServerManagerViewModel())
        .frame(width: 1200, height: 800)
}
