//
//  AppCheckDiagnosticView.swift
//  Growth
//
//  SwiftUI view for App Check diagnostics and troubleshooting
//

import SwiftUI
import FirebaseAppCheck

struct AppCheckDiagnosticView: View {
    @State private var diagnosticReport: DiagnosticReport?
    @State private var isRunningDiagnostics = false
    @State private var showGenerateTokenAlert = false
    @State private var showClearTokenAlert = false
    @State private var copiedToken = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("App Check Diagnostics")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Troubleshoot Firebase App Check issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Run Diagnostics Button
                Button(action: runDiagnostics) {
                    HStack {
                        if isRunningDiagnostics {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "stethoscope")
                        }
                        Text(isRunningDiagnostics ? "Running..." : "Run Diagnostics")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isRunningDiagnostics)
                
                // Diagnostic Results
                if let report = diagnosticReport {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Diagnostic Results")
                            .font(.headline)
                        
                        // Status Items
                        DiagnosticStatusRow(
                            title: "Debug Token",
                            status: report.debugTokenExists,
                            detail: report.debugToken != nil ? "Token: \(report.debugToken!)" : "Not found"
                        )
                        
                        if report.debugToken != nil {
                            Button(action: {
                                UIPasteboard.general.string = report.debugToken
                                copiedToken = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedToken = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: copiedToken ? "checkmark" : "doc.on.doc")
                                    Text(copiedToken ? "Copied!" : "Copy Token")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        
                        DiagnosticStatusRow(
                            title: "Debug Flag (-FIRDebugEnabled)",
                            status: report.hasDebugFlag,
                            detail: report.hasDebugFlag ? "Enabled" : "Not set"
                        )
                        
                        DiagnosticStatusRow(
                            title: "Firebase Configured",
                            status: report.firebaseConfigured,
                            detail: report.firebaseConfigured ? "Yes" : "No"
                        )
                        
                        DiagnosticStatusRow(
                            title: "Token Retrieval",
                            status: report.tokenRetrievalSuccess,
                            detail: report.tokenRetrievalError ?? "Success"
                        )
                        
                        if !report.recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recommendations")
                                    .font(.headline)
                                    .padding(.top)
                                
                                ForEach(report.recommendations, id: \.self) { recommendation in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                        Text(recommendation)
                                            .font(.caption)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: { showGenerateTokenAlert = true }) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Generate New Token")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: { showClearTokenAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clear Debug Token")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Link(destination: URL(string: "https://console.firebase.google.com/project/growth-70a85/appcheck/apps")!) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Open Firebase Console")
                            Image(systemName: "arrow.up.right.square")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("App Check Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Generate New Token?", isPresented: $showGenerateTokenAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Generate", role: .destructive) {
                generateNewToken()
            }
        } message: {
            Text("This will generate a new debug token. You'll need to restart the app and register the new token in Firebase Console.")
        }
        .alert("Clear Token?", isPresented: $showClearTokenAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearToken()
            }
        } message: {
            Text("This will clear the current debug token. The app will generate a new one on next launch.")
        }
    }
    
    private func runDiagnostics() {
        isRunningDiagnostics = true
        
        AppCheckDiagnostics.shared.runDiagnostics { report in
            DispatchQueue.main.async {
                self.diagnosticReport = report
                self.isRunningDiagnostics = false
                
                // Also print to console
                AppCheckDiagnostics.shared.printReport(report)
            }
        }
    }
    
    private func generateNewToken() {
        _ = AppCheckDiagnostics.shared.forceGenerateNewToken()
        
        // Re-run diagnostics to show new token
        runDiagnostics()
    }
    
    private func clearToken() {
        AppCheckDiagnostics.shared.clearDebugToken()
        
        // Re-run diagnostics
        runDiagnostics()
    }
}

struct DiagnosticStatusRow: View {
    let title: String
    let status: Bool
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(status ? .green : .red)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

struct AppCheckDiagnosticView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppCheckDiagnosticView()
        }
    }
}