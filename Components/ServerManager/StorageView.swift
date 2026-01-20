//
//  StorageView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct StorageView: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Storage Management")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Manage volumes, storage pools, and disk configurations")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Action Buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.newVolumeDialogOpen = true
                        }) {
                            Text("New Volume")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue500)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            Text("Manage Storage Spaces")
                                .font(.system(size: 13))
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
                    
                    // Volumes List
                    VStack(spacing: 16) {
                        ForEach(viewModel.volumes) { volume in
                            VolumeCard(volume: volume, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Storage Pools
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Storage Pools")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.zinc900)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "cylinder.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue500)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Storage Pool 1")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.zinc900)
                                Text("4 Physical Disks • 8 TB Total")
                                    .font(.system(size: 11))
                                    .foregroundColor(.zinc600)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green500)
                        }
                        .padding(12)
                        .background(Color.zinc50.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct VolumeCard: View {
    let volume: StorageVolume
    @ObservedObject var viewModel: ServerManagerViewModel
    
    var usedPercent: Double {
        volume.usedPercent
    }
    
    var progressColor: Color {
        if usedPercent > 80 {
            return .red500
        } else if usedPercent > 60 {
            return .yellow500
        } else {
            return .blue500
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple500)
                        .frame(width: 48, height: 48)
                        .background(Color.purple500.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(volume.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.zinc900)
                        Text("\(volume.type) • \(volume.total) GB Total")
                            .font(.system(size: 12))
                            .foregroundColor(.zinc600)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(volume.freeSpace) GB")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.zinc900)
                    Text("Free Space")
                        .font(.system(size: 12))
                        .foregroundColor(.zinc600)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.zinc200)
                        .frame(height: 12)
                        .cornerRadius(6)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(usedPercent / 100), height: 12)
                        .cornerRadius(6)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(volume.used) GB Used")
                    .font(.system(size: 12))
                    .foregroundColor(.zinc600)
                
                Spacer()
                
                Text(String(format: "%.1f%% Full", usedPercent))
                    .font(.system(size: 12))
                    .foregroundColor(.zinc600)
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.selectedVolume = volume
                    viewModel.volumePropertiesDialogOpen = true
                }) {
                    Text("Properties")
                        .font(.system(size: 12))
                        .foregroundColor(.zinc900)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.zinc100)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.selectedVolume = volume
                    viewModel.extendVolumeDialogOpen = true
                }) {
                    Text("Extend Volume")
                        .font(.system(size: 12))
                        .foregroundColor(.zinc900)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.zinc100)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Text("Defragment")
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

// Dialog Views
struct NewVolumeDialog: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Create New Volume")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.zinc900)
            
            Text("Configure the new storage volume")
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volume Name")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc700)
                    
                    TextField("e.g., F:\\ (Storage)", text: $viewModel.newVolumeName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size (GB)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc700)
                    
                    TextField("1000", text: $viewModel.newVolumeSize)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("File System")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc700)
                    
                    Picker("", selection: $viewModel.newVolumeType) {
                        Text("NTFS").tag("NTFS")
                        Text("ReFS").tag("ReFS")
                        Text("FAT32").tag("FAT32")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Create Volume") {
                    viewModel.handleCreateVolume()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.newVolumeName.isEmpty || viewModel.newVolumeSize.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}

struct VolumePropertiesDialog: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Volume Properties")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.zinc900)
            
            if let volume = viewModel.selectedVolume {
                VStack(alignment: .leading, spacing: 12) {
                    PropertyRow(label: "Name:", value: volume.name)
                    PropertyRow(label: "Type:", value: volume.type)
                    PropertyRow(label: "Total Size:", value: "\(volume.total) GB")
                    PropertyRow(label: "Used Space:", value: "\(volume.used) GB")
                    PropertyRow(label: "Free Space:", value: "\(volume.freeSpace) GB")
                }
                
                HStack {
                    Button(action: {
                        viewModel.handleDeleteVolume(volume.name)
                        dismiss()
                    }) {
                        Text("Delete Volume")
                            .font(.system(size: 13))
                            .foregroundColor(.red500)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red500.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}

struct PropertyRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.zinc900)
        }
    }
}

struct ExtendVolumeDialog: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Extend Volume")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.zinc900)
            
            if let volume = viewModel.selectedVolume {
                Text("Add more space to \(volume.name)")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Current Size: \(volume.total) GB")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.zinc700)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Space (GB)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.zinc700)
                        
                        TextField("500", text: $viewModel.extendVolumeAmount)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if !viewModel.extendVolumeAmount.isEmpty,
                       let amount = Int(viewModel.extendVolumeAmount) {
                        Text("New size will be: \(volume.total + amount) GB")
                            .font(.system(size: 13))
                            .foregroundColor(.blue500)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue500.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Extend Volume") {
                        viewModel.handleExtendVolume()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.extendVolumeAmount.isEmpty)
                }
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}

#Preview {
    StorageView(viewModel: ServerManagerViewModel())
        .frame(width: 1200, height: 800)
}
