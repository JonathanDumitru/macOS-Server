//
//  Colors.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

extension Color {
    // MARK: - Hex Color Initializer

    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count

        switch length {
        case 6: // RGB (e.g., "FF5733")
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
        case 8: // RGBA (e.g., "FF5733FF")
            let r = Double((rgb & 0xFF000000) >> 24) / 255.0
            let g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            let b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            let a = Double(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        default:
            return nil
        }
    }

    var hexString: String {
        guard let components = NSColor(self).cgColor.components else {
            return "#000000"
        }
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    // MARK: - Named Colors
    // Zinc colors matching Tailwind
    static let zinc50 = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let zinc100 = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let zinc200 = Color(red: 0.91, green: 0.91, blue: 0.91)
    static let zinc300 = Color(red: 0.83, green: 0.83, blue: 0.83)
    static let zinc400 = Color(red: 0.64, green: 0.64, blue: 0.64)
    static let zinc500 = Color(red: 0.45, green: 0.45, blue: 0.45)
    static let zinc600 = Color(red: 0.35, green: 0.35, blue: 0.35)
    static let zinc700 = Color(red: 0.27, green: 0.27, blue: 0.27)
    static let zinc800 = Color(red: 0.20, green: 0.20, blue: 0.20)
    static let zinc900 = Color(red: 0.13, green: 0.13, blue: 0.13)
    
    // Blue colors
    static let blue500 = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    static let blue600 = Color(red: 0.0, green: 0.40, blue: 0.85)
    
    // Green colors
    static let green400 = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
    static let green500 = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let green600 = Color(red: 0.15, green: 0.70, blue: 0.30)
    
    // Red colors
    static let red500 = Color(red: 1.0, green: 0.18, blue: 0.33) // #FF2D55
    static let red600 = Color(red: 0.90, green: 0.15, blue: 0.28)
    
    // Yellow/Orange colors
    static let yellow500 = Color(red: 1.0, green: 0.73, blue: 0.18) // #FFB524
    static let orange500 = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
    
    // Purple colors
    static let purple500 = Color(red: 0.35, green: 0.34, blue: 0.84) // #5856D6
    
    // Traffic light colors
    static let trafficLightRed = Color(red: 1.0, green: 0.37, blue: 0.34) // #FF5F57
    static let trafficLightYellow = Color(red: 1.0, green: 0.74, blue: 0.18) // #FEBC2E
    static let trafficLightGreen = Color(red: 0.16, green: 0.78, blue: 0.25) // #28C840
}
