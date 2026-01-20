//
//  StorageVolume.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import Foundation

struct StorageVolume: Identifiable, Codable {
    let id = UUID()
    var name: String
    var total: Int // in GB
    var used: Int // in GB
    var type: String // NTFS, ReFS, FAT32
    
    var freeSpace: Int {
        total - used
    }
    
    var usedPercent: Double {
        guard total > 0 else { return 0 }
        return (Double(used) / Double(total)) * 100
    }
}
