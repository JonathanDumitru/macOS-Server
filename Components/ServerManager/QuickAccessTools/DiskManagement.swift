//
//  DiskManagement.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct DiskManagement: View {
    let disks = [
        DiskInfo(name: "Disk 0", partitions: [
            PartitionInfo(name: "System Reserved", size: "500 MB", type: "NTFS"),
            PartitionInfo(name: "Windows", size: "476.44 GB", type: "NTFS"),
            PartitionInfo(name: "Unallocated", size: "23.56 GB", type: "-")
        ]),
        DiskInfo(name: "Disk 1", partitions: [
            PartitionInfo(name: "Data", size: "1.5 TB", type: "NTFS"),
            PartitionInfo(name: "Backup", size: "500 GB", type: "ReFS")
        ]),
        DiskInfo(name: "Disk 2", partitions: [
            PartitionInfo(name: "Archive", size: "2 TB", type: "NTFS")
        ])
    ]
    
    struct DiskInfo {
        let name: String
        let partitions: [PartitionInfo]
    }
    
    struct PartitionInfo {
        let name: String
        let size: String
        let type: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Disk Management")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("View and manage disk partitions")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(disks, id: \.name) { disk in
                        DiskCard(disk: disk)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

struct DiskCard: View {
    let disk: DiskManagement.DiskInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(disk.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.zinc900)
                
                Spacer()
                
                Text("Online")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green500)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(disk.partitions, id: \.name) { partition in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(partition.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.zinc900)
                        Text("\(partition.size) • \(partition.type)")
                            .font(.system(size: 11))
                            .foregroundColor(.zinc600)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.zinc50.opacity(0.3))
                    .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview {
    DiskManagement()
        .frame(width: 1200, height: 800)
}
