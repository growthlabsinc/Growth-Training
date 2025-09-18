//
//  ContactSupportView.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI
import MessageUI

struct ContactSupportView: View {
    @State private var subject = ""
    @State private var message = ""
    @State private var category: SupportCategory = .general
    @State private var priority: Priority = .medium
    @State private var includeDeviceInfo = true
    @State private var includeAccountInfo = true
    @State private var showMailComposer = false
    @State private var showSuccessAlert = false
    @State private var isSubmitting = false
    
    enum SupportCategory: String, CaseIterable {
        case general = "General Question"
        case bug = "Report a Bug"
        case feature = "Feature Request"
        case account = "Account Issue"
        case payment = "Payment & Subscription"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .general: return "questionmark.circle"
            case .bug: return "ant"
            case .feature: return "lightbulb"
            case .account: return "person.crop.circle"
            case .payment: return "creditcard"
            case .other: return "ellipsis.circle"
            }
        }
    }
    
    enum Priority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            case .urgent: return .purple
            }
        }
    }
    
    var body: some View {
        Form {
            // Contact Method Section
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("GrowthGreen"))
                    
                    Text("We're here to help!")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Fill out the form below and we'll get back to you within 24-48 hours")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            // Category Section
            Section(header: Text("What can we help with?").font(AppTheme.Typography.gravitySemibold(13))) {
                Picker("Category", selection: $category) {
                    ForEach(SupportCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category)
                    }
                }
                
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        HStack {
                            Circle()
                                .fill(priority.color)
                                .frame(width: 10, height: 10)
                            Text(priority.rawValue)
                        }
                        .tag(priority)
                    }
                }
            }
            
            // Message Section
            Section(header: Text("Your Message").font(AppTheme.Typography.gravitySemibold(13))) {
                TextField("Subject", text: $subject)
                    .font(AppTheme.Typography.gravityBook(14))
                
                TextEditor(text: $message)
                    .font(AppTheme.Typography.gravityBook(14))
                    .frame(minHeight: 150)
                    .overlay(
                        Group {
                            if message.isEmpty {
                                Text("Describe your issue or question in detail...")
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .foregroundColor(Color("TextSecondaryColor"))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    )
            }
            
            // Additional Info Section
            Section(header: Text("Additional Information").font(AppTheme.Typography.gravitySemibold(13))) {
                Toggle(isOn: $includeDeviceInfo) {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Include Device Info")
                                .font(AppTheme.Typography.gravityBook(14))
                            Text("Helps us troubleshoot technical issues")
                                .font(AppTheme.Typography.gravityBook(12))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                    }
                }
                
                Toggle(isOn: $includeAccountInfo) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Include Account Info")
                                .font(AppTheme.Typography.gravityBook(14))
                            Text("Helps us assist with account-specific issues")
                                .font(AppTheme.Typography.gravityBook(12))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                    }
                }
            }
            
            // Alternative Contact Section
            Section(header: Text("Other Ways to Reach Us").font(AppTheme.Typography.gravitySemibold(13))) {
                ContactMethodRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: "support@growthlabs.coach",
                    action: {
                        if MFMailComposeViewController.canSendMail() {
                            showMailComposer = true
                        }
                    }
                )
                
                ContactMethodRow(
                    icon: "globe",
                    title: "Website",
                    value: "growthlabs.coach/support",
                    action: {
                        if let url = URL(string: "https://growthlabs.coach/support.html") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            
            // Submit Button
            Section {
                Button(action: submitRequest) {
                    if isSubmitting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Submitting...")
                                .font(AppTheme.Typography.gravitySemibold(16))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Submit Request")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .frame(maxWidth: .infinity)
                    }
                }
                .foregroundColor(canSubmit ? Color("GrowthGreen") : Color("TextSecondaryColor"))
                .disabled(!canSubmit || isSubmitting)
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                subject: subject.isEmpty ? "Support Request" : subject,
                body: composeEmailBody(),
                recipients: ["support@growthlabs.coach"]
            )
        }
        .alert("Request Submitted", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("We've received your support request and will respond within 24-48 hours.")
        }
    }
    
    private var canSubmit: Bool {
        !subject.isEmpty && !message.isEmpty
    }
    
    private func submitRequest() {
        isSubmitting = true
        
        // TODO: Implement actual submission to backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            showSuccessAlert = true
            
            // Clear form
            subject = ""
            message = ""
            category = .general
            priority = .medium
        }
    }
    
    private func composeEmailBody() -> String {
        var body = message + "\n\n---\n"
        body += "Category: \(category.rawValue)\n"
        body += "Priority: \(priority.rawValue)\n"
        
        if includeDeviceInfo {
            body += "\nDevice Info:\n"
            body += "Model: \(UIDevice.current.model)\n"
            body += "OS: iOS \(UIDevice.current.systemVersion)\n"
            body += "App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        }
        
        if includeAccountInfo {
            // TODO: Add actual user info
            body += "\nAccount Info:\n"
            body += "User ID: [UserID]\n"
            body += "Email: [UserEmail]\n"
        }
        
        return body
    }
}

// MARK: - Contact Method Row
struct ContactMethodRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("GrowthGreen"))
                    .frame(width: 25)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))
                    Text(value)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
        }
    }
}

// MARK: - Mail Composer
struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let recipients: [String]
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.setToRecipients(recipients)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        ContactSupportView()
    }
}