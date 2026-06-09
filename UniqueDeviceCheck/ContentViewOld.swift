//
//  ContentView 2.swift
//  UniqueDeviceCheck
//
//  Created by Tony Kambourakis on 19/5/2026.
//


// MARK: 2️⃣ ContentView.swift
// ---------------------------------------------------------------------

import SwiftUI

struct ContentViewOld: View {
    @State private var token: String?
    @State private var status: String = "Loading …"
    @State private var showCopyAlert = false

    var body: some View {
        VStack(spacing: 28) {
            Text("Device Binding Token")
                .font(.title2).bold()

            // Token display
            Group {
                if let token {
                    Text(token)
                        .font(.system(size: 14, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("No token present")
                        .foregroundColor(.secondary)
                }
            }
            .animation(.easeInOut, value: token)

            // Status banner
            Text(status)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            // Action buttons
            HStack {
                Button {
                    let result = KeychainDeviceToken.create()
                    token  = result.token
                    status = result.createdNew ? "🔑 Created new token." : "✅ Loaded existing token."
                } label: {
                    Label("Generate Token", systemImage: "plus.circle")
                }

                Button(role: .destructive) {
                    KeychainDeviceToken.delete()
                    token  = nil
                    status = "🗑 Token deleted."
                } label: {
                    Label("Delete Token", systemImage: "trash")
                }
            }

            Button {
                if let token {
                    UIPasteboard.general.string = token
                    showCopyAlert = true
                }
            } label: {
                Label("Copy Token", systemImage: "doc.on.doc")
            }
            .disabled(token == nil)
        }
        .padding()
        .onAppear(perform: loadToken)
        .alert("Token copied!", isPresented: $showCopyAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    private func loadToken() {
        if let existing = KeychainDeviceToken.load() {
            token  = existing
            status = "✅ Loaded existing token."
        } else {
            let result = KeychainDeviceToken.create()
            token  = result.token
            status = "🔑 Created new token."
        }
    }
}
