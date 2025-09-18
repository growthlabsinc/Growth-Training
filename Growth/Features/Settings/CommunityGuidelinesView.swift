import SwiftUI

struct CommunityGuidelinesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("GrowthGreen"))
                        
                        Text("Community Guidelines")
                            .font(AppTheme.Typography.title2Font())
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Text("Help us build a supportive and safe community")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    // Guidelines sections
                    Group {
                        GuidelineSection(
                            title: "Be Respectful",
                            icon: "heart.fill",
                            content: [
                                "Treat all community members with respect and kindness",
                                "No harassment, hate speech, or discriminatory content",
                                "Respect privacy - don't share others' personal information",
                                "Be constructive with feedback and criticism"
                            ]
                        )
                        
                        GuidelineSection(
                            title: "Create Quality Content",
                            icon: "star.fill",
                            content: [
                                "Share routines based on the Growth app methods",
                                "Provide clear descriptions and helpful tips",
                                "Test your routines before sharing",
                                "Keep content focused on health and wellness"
                            ]
                        )
                        
                        GuidelineSection(
                            title: "Avoid Harmful Content",
                            icon: "exclamationmark.shield.fill",
                            content: [
                                "No medical advice or health claims",
                                "Don't promote dangerous or extreme practices",
                                "No content that could cause physical harm",
                                "Follow all applicable laws and regulations"
                            ]
                        )
                        
                        GuidelineSection(
                            title: "Respect Intellectual Property",
                            icon: "c.circle.fill",
                            content: [
                                "Only share original content you created",
                                "Don't copy routines from other creators",
                                "Respect copyrights and trademarks",
                                "Give credit where credit is due"
                            ]
                        )
                        
                        GuidelineSection(
                            title: "Keep It Appropriate",
                            icon: "hand.raised.fill",
                            content: [
                                "No explicit or inappropriate content",
                                "Keep language family-friendly",
                                "No spam or promotional content",
                                "Stay on topic - focus on growth methods"
                            ]
                        )
                    }
                    
                    // Consequences section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Consequences for Violations")
                            .font(AppTheme.Typography.headlineFont())
                            .foregroundColor(AppTheme.Colors.text)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ConsequenceRow(level: "First Violation", action: "Warning and content removal", color: .orange)
                            ConsequenceRow(level: "Second Violation", action: "Temporary suspension (7 days)", color: .red)
                            ConsequenceRow(level: "Third Violation", action: "Permanent ban from sharing", color: .purple)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    // Report section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Help Us Maintain Standards", systemImage: "flag.fill")
                            .font(AppTheme.Typography.headlineFont())
                            .foregroundColor(Color("GrowthGreen"))
                        
                        Text("If you see content that violates these guidelines, please report it. We review all reports and take appropriate action.")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("GrowthGreen").opacity(0.1))
                    )
                    
                    // Footer
                    Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GuidelineSection: View {
    let title: String
    let icon: String
    let content: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("GrowthGreen"))
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(content, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text(item)
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct ConsequenceRow: View {
    let level: String
    let action: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 8, height: 8)
            
            Text(level)
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(color)
            
            Spacer()
            
            Text(action)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

struct CommunityGuidelinesView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityGuidelinesView()
    }
}