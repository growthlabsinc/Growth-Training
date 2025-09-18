//
//  ReportRoutineSheet.swift
//  Growth
//
//  Sheet view for reporting inappropriate routine content
//

import SwiftUI

struct ReportRoutineSheet: View {
    let routine: Routine
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reporting: \(routine.name)")
                            .font(.headline)
                        if let creatorName = routine.creatorDisplayName {
                            Text("By \(creatorName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reason.displayName)
                                        .foregroundColor(.primary)
                                    Text(reason.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Why are you reporting this routine?")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Please provide any additional information that might help us understand the issue.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $additionalDetails)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                } header: {
                    Text("Additional Details (Optional)")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Reports are reviewed by our moderation team", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("False reports may result in action against your account. Please only report content that violates our community guidelines.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Report Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Report Submitted", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep our community safe. We'll review your report and take appropriate action.")
            }
            .interactiveDismissDisabled(isSubmitting)
        }
    }
    
    private func submitReport() {
        guard let reason = selectedReason else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await RoutineService.shared.reportRoutine(
                    routine.id,
                    reason: reason,
                    details: additionalDetails.isEmpty ? nil : additionalDetails
                )
                
                await MainActor.run {
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct ReportRoutineSheet_Previews: PreviewProvider {
    static var previews: some View {
        ReportRoutineSheet(routine: Routine(
            id: "test",
            name: "Test Routine",
            description: "A test routine",
            difficulty: .beginner,
            duration: 7,
            focusAreas: ["Test"],
            stages: [1, 2],
            createdDate: Date(),
            lastUpdated: Date(),
            schedule: [],
            isCustom: true,
            createdBy: "testuser",
            shareWithCommunity: true,
            creatorUsername: "testuser",
            creatorDisplayName: "Test User"
        ))
    }
}
#endif