//
//  PowerShellConsole.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct PowerShellConsole: View {
    let commands = [
        CommandLine(prompt: "PS C:\\Users\\Administrator>", command: "Get-Service | Where-Object {$_.Status -eq \"Running\"}", output: "Running services listed..."),
        CommandLine(prompt: "PS C:\\Users\\Administrator>", command: "Get-Process", output: "Process list displayed...")
    ]
    
    struct CommandLine {
        let prompt: String
        let command: String
        let output: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Windows PowerShell")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Command-line interface for system administration")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // PowerShell Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Windows PowerShell")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("Copyright (C) Microsoft Corporation. All rights reserved.")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("Install the latest PowerShell for new features and improvements!")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 16)
                    
                    // Command History
                    ForEach(Array(commands.enumerated()), id: \.offset) { _, cmd in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cmd.prompt)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.yellow)
                            
                            Text(cmd.command)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.leading, 16)
                            
                            Text(cmd.output)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                                .padding(.top, 4)
                        }
                        .padding(.bottom, 12)
                    }
                    
                    // Current Prompt
                    HStack(spacing: 4) {
                        Text("PS C:\\Users\\Administrator>")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.yellow)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 16)
                            .opacity(1.0)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.004, green: 0.141, blue: 0.337)) // #012456
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    PowerShellConsole()
        .frame(width: 1200, height: 800)
}
