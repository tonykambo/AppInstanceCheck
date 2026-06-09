// MARK: 2️⃣ ContentView.swift
// ---------------------------------------------------------------------

import SwiftUI

struct ContentView: View {
    @State private var token: String?
    @State private var status: String = "Loading …"
    @State private var showCopyAlert = false
    @State private var installationTimestamps: InstallationTimestamps?
    @State private var timestampStatus: String = ""
    @State private var simulatedRegistrationDate: Date = Date()
    
    private let detector = InstallationTimestampDetector()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Token Section
                VStack(spacing: 16) {
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
                
                Divider()
                    .padding(.vertical)
                
                // Installation Timestamp Section
                VStack(spacing: 16) {
                    Text("Installation Timestamps")
                        .font(.title2).bold()
                    
                    if let timestamps = installationTimestamps {
                        VStack(alignment: .leading, spacing: 12) {
                            // Documents Directory
                            TimestampRow(
                                icon: "📁",
                                label: "Documents Directory:",
                                date: timestamps.documentsDirectory,
                                dateFormatter: dateFormatter
                            )
                            
                            // Library Directory
                            TimestampRow(
                                icon: "📚",
                                label: "Library Directory:",
                                date: timestamps.libraryDirectory,
                                dateFormatter: dateFormatter
                            )
                            
                            // App Bundle
                            TimestampRow(
                                icon: "📦",
                                label: "App Bundle:",
                                date: timestamps.appBundle,
                                dateFormatter: dateFormatter
                            )
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Most Recent (Used for Detection)
                            if let mostRecent = timestamps.mostRecentDate {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("🎯 Most Recent (Used):")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                    }
                                    Text(dateFormatter.string(from: mostRecent))
                                        .font(.system(size: 14, design: .monospaced))
                                        .bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            // Consistency Check
                            HStack {
                                Image(systemName: timestamps.areConsistent ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(timestamps.areConsistent ? .green : .orange)
                                Text(timestamps.areConsistent ? "Timestamps are consistent" : "Timestamps vary (normal)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)
                    } else {
                        Text("Unable to determine installation dates")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    
                    // Quick Start Detection Test
                    VStack(spacing: 12) {
                        Text("Quick Start Detection Test")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Simulated Registration:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            DatePicker(
                                "Registration Date",
                                selection: $simulatedRegistrationDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        .padding(.horizontal)
                        
                        Button {
                            testQuickStartDetection()
                        } label: {
                            Label("Test Detection", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if !timestampStatus.isEmpty {
                            Text(timestampStatus)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    timestampStatus.contains("Quick Start") ?
                                    Color.red.opacity(0.1) : Color.green.opacity(0.1)
                                )
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ℹ️ How it works:")
                            .font(.caption).bold()
                        Text("• The app installation date is read from the Documents directory creation date")
                            .font(.caption)
                        Text("• If install date is after registration date (+ 1hr buffer), it indicates a Quick Start copy")
                            .font(.caption)
                        Text("• Test by setting a registration date before the install date")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .onAppear(perform: loadData)
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
    
    private func loadData() {
        loadToken()
        loadInstallationDate()
    }
    
    private func loadInstallationDate() {
        installationTimestamps = detector.getAppInstallationDate()
        
        if let timestamps = installationTimestamps,
           let mostRecent = timestamps.mostRecentDate {
            timestampStatus = "App installed: \(dateFormatter.string(from: mostRecent))"
        } else {
            timestampStatus = "⚠️ Could not determine installation date"
        }
    }
    
    private func testQuickStartDetection() {
        guard let timestamps = installationTimestamps,
              let installDate = timestamps.mostRecentDate else {
            timestampStatus = "⚠️ Cannot test: Installation date unavailable"
            return
        }
        
        let result = detector.detectQuickStartByTimestamp(
            registrationDate: simulatedRegistrationDate
        )
        
        switch result {
        case .quickStartDetected(let regDate, let instDate, let daysDiff, let timestamps):
            let consistencyNote = timestamps.areConsistent ?
                "All timestamps consistent ✅" :
                "Timestamps vary (normal) ⚠️"
            
            timestampStatus = """
            🚨 Quick Start Copy Detected!
            
            Registration: \(dateFormatter.string(from: regDate))
            Installation: \(dateFormatter.string(from: instDate))
            Difference: \(daysDiff) day(s)
            
            \(consistencyNote)
            
            ➡️ Would trigger OTP verification
            """
            
        case .likelyOriginalDevice(let timestamps):
            let timeDiff = installDate.timeIntervalSince(simulatedRegistrationDate)
            let hoursDiff = Int(timeDiff / 3600)
            let consistencyNote = timestamps.areConsistent ?
                "All timestamps consistent ✅" :
                "Timestamps vary (normal) ⚠️"
            
            timestampStatus = """
            ✅ Likely Original Device
            
            Registration: \(dateFormatter.string(from: simulatedRegistrationDate))
            Installation: \(dateFormatter.string(from: installDate))
            Difference: \(hoursDiff) hour(s)
            
            \(consistencyNote)
            
            ➡️ No OTP required
            """
            
        case .cannotDetermineInstallDate:
            timestampStatus = "⚠️ Cannot determine installation date"
        }
    }
}

// MARK: - Helper Views

struct TimestampRow: View {
    let icon: String
    let label: String
    let date: Date?
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(icon) \(label)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if let date = date {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 13, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
            } else {
                Text("Not available")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(6)
            }
        }
    }
}
