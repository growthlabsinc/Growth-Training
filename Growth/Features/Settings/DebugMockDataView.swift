//
//  DebugMockDataView.swift
//  Growth
//
//  Debug view for managing mock session data
//

import SwiftUI

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
        
        // Force re-initialization which will generate data
        DebugMockDataService.shared.initializeMockDataIfNeeded()
        
        // Wait a bit for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isGenerating = false
            checkMockDataStatus()
            alertMessage = "Mock sessions have been generated. Check your Session History to see them."
            showingAlert = true
        }
    }
    
    private func forceRegenerateMockData() {
        isGenerating = true
        
        DebugMockDataService.shared.forceRegenerateMockData { error in
            DispatchQueue.main.async {
                isGenerating = false
                
                if let error = error {
                    alertMessage = "Failed to regenerate mock data: \(error.localizedDescription)"
                } else {
                    alertMessage = "Mock data has been regenerated. Check your Progress tab to see the data."
                    hasMockData = true
                }
                showingAlert = true
                checkMockDataStatus()
            }
        }
    }
    
    private func clearMockData() {
        isClearing = true
        
        DebugMockDataService.shared.clearAllMockData { error in
            DispatchQueue.main.async {
                isClearing = false
                
                if let error = error {
                    alertMessage = "Failed to clear mock data: \(error.localizedDescription)"
                } else {
                    alertMessage = "All mock data has been cleared."
                    hasMockData = false
                }
                showingAlert = true
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