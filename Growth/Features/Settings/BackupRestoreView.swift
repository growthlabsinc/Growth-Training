//
//  BackupRestoreView.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI
import FirebaseAuth

struct BackupRestoreView: View {
    @State private var lastBackupDate: Date?
    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var showRestoreConfirmation = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    @State private var backupProgress: Double = 0
    @State private var autoBackupEnabled = true
    @State private var backupFrequency: BackupFrequency = .weekly
    
    enum BackupFrequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        
        var days: Int {
            switch self {
            case .daily: return 1
            case .weekly: return 7
            case .monthly: return 30
            }
        }
    }
    
    var body: some View {
        Form {
            // Backup Status Section
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 50))
                        .foregroundColor(Color("GrowthGreen"))
                    
                    Text("Cloud Backup")
                        .font(AppTheme.Typography.gravitySemibold(20))
                        .foregroundColor(Color("TextColor"))
                    
                    if let lastBackup = lastBackupDate {
                        VStack(spacing: 4) {
                            Text("Last backup")
                                .font(AppTheme.Typography.gravityBook(12))
                                .foregroundColor(Color("TextSecondaryColor"))
                            
                            Text(lastBackup, style: .relative)
                                .font(AppTheme.Typography.gravitySemibold(14))
                                .foregroundColor(Color("GrowthGreen"))
                        }
                    } else {
                        Text("No backups yet")
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            // Auto Backup Section
            Section(header: Text("Automatic Backup").font(AppTheme.Typography.gravitySemibold(13))) {
                Toggle(isOn: $autoBackupEnabled) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                            .foregroundColor(.blue)
                        Text("Enable Auto Backup")
                            .font(AppTheme.Typography.gravityBook(14))
                    }
                }
                
                if autoBackupEnabled {
                    Picker("Backup Frequency", selection: $backupFrequency) {
                        ForEach(BackupFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    
                    Text("Your data will be automatically backed up \(backupFrequency.rawValue.lowercased())")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            
            // Manual Backup Section
            Section(header: Text("Manual Backup").font(AppTheme.Typography.gravitySemibold(13))) {
                Button(action: performBackup) {
                    if isBackingUp {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Backing up... \(Int(backupProgress * 100))%")
                                .font(AppTheme.Typography.gravitySemibold(14))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Backup Now")
                                .font(AppTheme.Typography.gravitySemibold(14))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .foregroundColor(isBackingUp ? Color("TextSecondaryColor") : Color("GrowthGreen"))
                .disabled(isBackingUp || isRestoring)
                
                Text("Create a backup of all your data including routines, progress, and settings")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // Restore Section
            Section(header: Text("Restore Data").font(AppTheme.Typography.gravitySemibold(13))) {
                Button(action: { showRestoreConfirmation = true }) {
                    if isRestoring {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Restoring...")
                                .font(AppTheme.Typography.gravitySemibold(14))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("Restore from Backup")
                                .font(AppTheme.Typography.gravitySemibold(14))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .foregroundColor(isRestoring ? Color("TextSecondaryColor") : .orange)
                .disabled(isBackingUp || isRestoring || lastBackupDate == nil)
                
                Text("Replace current data with your most recent backup")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // What's Included Section
            Section(header: Text("What's Included").font(AppTheme.Typography.gravitySemibold(13))) {
                BackupItemRow(icon: "ruler", title: "Measurements", description: "All growth tracking data")
                BackupItemRow(icon: "clock", title: "Session History", description: "Practice logs and statistics")
                BackupItemRow(icon: "list.bullet", title: "Routines", description: "Custom and saved routines")
                BackupItemRow(icon: "gear", title: "Settings", description: "App preferences and configurations")
                BackupItemRow(icon: "note.text", title: "Notes", description: "Session notes and reflections")
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLastBackupDate()
        }
        .alert("Restore from Backup?", isPresented: $showRestoreConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                performRestore()
            }
        } message: {
            Text("This will replace all current data with your backup from \(lastBackupDate?.formatted() ?? "unknown date"). This action cannot be undone.")
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadLastBackupDate() {
        // TODO: Load actual last backup date from backend
        // For demo, set a sample date
        lastBackupDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
    }
    
    private func performBackup() {
        isBackingUp = true
        backupProgress = 0
        
        // Simulate backup progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            backupProgress += 0.05
            
            if backupProgress >= 1.0 {
                timer.invalidate()
                isBackingUp = false
                lastBackupDate = Date()
                alertMessage = "Backup completed successfully!"
                showSuccessAlert = true
            }
        }
    }
    
    private func performRestore() {
        isRestoring = true
        
        // TODO: Implement actual restore logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isRestoring = false
            alertMessage = "Data restored successfully!"
            showSuccessAlert = true
        }
    }
}

// MARK: - Backup Item Row
struct BackupItemRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color("GrowthGreen"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))
                Text(description)
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(Color("GrowthGreen").opacity(0.5))
        }
    }
}

#Preview {
    NavigationStack {
        BackupRestoreView()
    }
}