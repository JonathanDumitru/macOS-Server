//
//  MacWindow.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct MacWindow<Content: View>: View {
    let title: String
    let content: Content
    var onClose: (() -> Void)?
    var onMinimize: (() -> Void)?
    var onMaximize: (() -> Void)?
    
    @State private var isHoveringClose = false
    @State private var isHoveringMinimize = false
    @State private var isHoveringMaximize = false
    
    init(
        title: String,
        onClose: (() -> Void)? = nil,
        onMinimize: (() -> Void)? = nil,
        onMaximize: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onClose = onClose
        self.onMinimize = onMinimize
        self.onMaximize = onMaximize
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Bar
            HStack {
                // Traffic Lights
                HStack(spacing: 8) {
                    // Close button
                    Button(action: { onClose?() }) {
                        Circle()
                            .fill(Color.trafficLightRed)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Group {
                                    if isHoveringClose {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(Color(red: 0.3, green: 0, blue: 0))
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHoveringClose = hovering
                    }
                    
                    // Minimize button
                    Button(action: { onMinimize?() }) {
                        Circle()
                            .fill(Color.trafficLightYellow)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Group {
                                    if isHoveringMinimize {
                                        Image(systemName: "minus")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(Color(red: 0.6, green: 0.33, blue: 0))
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHoveringMinimize = hovering
                    }
                    
                    // Maximize button
                    Button(action: { onMaximize?() }) {
                        Circle()
                            .fill(Color.trafficLightGreen)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Group {
                                    if isHoveringMaximize {
                                        Rectangle()
                                            .fill(Color(red: 0, green: 0.24, blue: 0.05))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHoveringMaximize = hovering
                    }
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // Title
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Color.zinc700)
                
                Spacer()
                
                // Spacer for symmetry
                HStack(spacing: 8)
                    .frame(width: 52)
            }
            .frame(height: 52)
            .background(
                Color.zinc100.opacity(0.8)
                    .background(.ultraThinMaterial)
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.zinc200.opacity(0.6)),
                alignment: .bottom
            )
            
            // Content
            content
        }
        .background(Color.white.opacity(0.95))
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    MacWindow(title: "Server Manager") {
        Text("Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(width: 800, height: 600)
}
