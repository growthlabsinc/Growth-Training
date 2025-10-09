//
//  DebugMockDataView.swift
//  Growth
//
//  Debug view for managing mock session data
//

import SwiftUI
import FirebaseAuth

#if DEBUG
struct DebugMockDataView: View {
    @State private var isGenerating = false
    @State private var isClearing = false
    @State private var hasMockData = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mock Session Data")
                            .font(.headline)
                        Text("Generate sample sessions for testing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if hasMockData {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Debug Tools")
            } footer: {
                Text("Mock data is only available in debug builds and will be flagged as test data.")
            }
            
            Section {
                Button(action: generateMockData) {
                    HStack {
                        Label("Generate Mock Sessions", systemImage: "plus.circle")
                        Spacer()
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isGenerating || isClearing)
                
                Button(action: forceRegenerateMockData) {
                    HStack {
                        Label("Force Regenerate Mock Data", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                        Spacer()
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isGenerating || isClearing)
                
                Button(action: clearMockData) {
                    HStack {
                        Label("Clear Mock Data", systemImage: "trash")
                            .foregroundColor(.red)
                        Spacer()
                        if isClearing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isGenerating || isClearing || !hasMockData)
                
                Button(action: refreshStatus) {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
                .disabled(isGenerating || isClearing)
            } header: {
                Text("Actions")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Environment", value: EnvironmentDetector.currentEnvironmentDescription)
                    InfoRow(label: "Debug Mode", value: "Enabled")
                    InfoRow(label: "Mock Data Available", value: hasMockData ? "Yes" : "No")
                }
            } header: {
                Text("Status")
            }
        }
        .navigationTitle("Mock Data Manager")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkMockDataStatus()
        }
        .alert("Mock Data", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func generateMockData() {
        isGenerating = true

        Task {
            // First check if user is authenticated
            guard Auth.auth().currentUser != nil else {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = "Error: No authenticated user. Please sign in first."
                    showingAlert = true
                }
                return
            }

            // Check if mock data already exists
            let hasMock = await withCheckedContinuation { continuation in
                DebugMockDataService.shared.hasMockData { exists in
                    continuation.resume(returning: exists)
                }
            }

            if hasMock {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = "Mock data already exists. Use 'Force Regenerate' to replace it, or 'Clear' to remove it first."
                    showingAlert = true
                }
                return
            }

            // Generate new mock data
            await withCheckedContinuation { continuation in
                DebugMockDataService.shared.generateMockDataForced { error in
                    continuation.resume()
                }
            }

            // Wait a moment for data to propagate
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            await MainActor.run {
                isGenerating = false
                checkMockDataStatus()
                alertMessage = "Mock data generated successfully!\n\n✓ Session history\n✓ Progress tracking\n\nCheck the Progress and History tabs to see your data."
                showingAlert = true
            }
        }
    }
    
    private func forceRegenerateMockData() {
        isGenerating = true

        Task {
            // First check if user is authenticated
            guard Auth.auth().currentUser != nil else {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = "Error: No authenticated user. Please sign in first."
                    showingAlert = true
                }
                return
            }

            // Force regenerate (clears and creates new)
            let error = await withCheckedContinuation { continuation in
                DebugMockDataService.shared.forceRegenerateMockData { error in
                    continuation.resume(returning: error)
                }
            }

            // Wait a moment for data to propagate
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            await MainActor.run {
                isGenerating = false

                if let error = error {
                    alertMessage = "Failed to regenerate: \(error.localizedDescription)"
                } else {
                    alertMessage = "Mock data regenerated successfully!\n\n✓ Previous data cleared\n✓ New sessions created\n✓ Progress data added\n\nCheck Progress and History tabs."
                    hasMockData = true
                }
                showingAlert = true
                checkMockDataStatus()
            }
        }
    }
    
    private func clearMockData() {
        isClearing = true

        Task {
            // First check if user is authenticated
            guard Auth.auth().currentUser != nil else {
                await MainActor.run {
                    isClearing = false
                    alertMessage = "Error: No authenticated user. Please sign in first."
                    showingAlert = true
                }
                return
            }

            let error = await withCheckedContinuation { continuation in
                DebugMockDataService.shared.clearAllMockData { error in
                    continuation.resume(returning: error)
                }
            }

            await MainActor.run {
                isClearing = false

                if let error = error {
                    alertMessage = "Failed to clear: \(error.localizedDescription)"
                } else {
                    alertMessage = "All mock data cleared successfully!\n\nYour Progress and History tabs are now empty."
                    hasMockData = false
                }
                showingAlert = true
                checkMockDataStatus()
            }
        }
    }
    
    private func refreshStatus() {
        checkMockDataStatus()
        alertMessage = "Status refreshed"
        showingAlert = true
    }
    
    private func checkMockDataStatus() {
        DebugMockDataService.shared.hasMockData { exists in
            DispatchQueue.main.async {
                hasMockData = exists
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct DebugMockDataView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DebugMockDataView()
        }
    }
}
#endif