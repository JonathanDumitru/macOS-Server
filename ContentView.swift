//
//  ContentView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.95, green: 0.93, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            MacWindow(title: "Server Manager") {
                ServerManagerView()
            }
            .frame(maxWidth: 1600, maxHeight: 900)
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
