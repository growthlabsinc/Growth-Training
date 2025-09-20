//
//  GrowthMethodDetailView.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import SwiftUI

/// Detail view for a specific growth method
struct GrowthMethodDetailView: View {
    /// The growth method to display
    let method: GrowthMethod
    
    /// Environment value to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    
    /// State for tracking expanded sections
    @State private var expandedSections = Set<String>()
    
    /// State for tracking errors
    @State private var hasError = false
    @State private var errorMessage: String? = nil
    
    @StateObject var viewModel: GrowthMethodDetailViewModel
    @State private var showTimerView = false
    
    init(method: GrowthMethod) {
        self.method = method
        _viewModel = StateObject(wrappedValue: GrowthMethodDetailViewModel(method: method))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color("GrowthGreen").opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero header with image
                    heroHeader
                        .padding(.bottom, 24)
                    
                    // Content
                    if let id = method.id, !id.isEmpty {
                        if hasError {
                            errorView
                        } else {
                            methodContentView
                                .padding(.horizontal)
                        }
                    } else {
                        errorView
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                                .font(AppTheme.Typography.gravitySemibold(14))
                        }
                        .foregroundColor(Color("GrowthGreen"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showTimerView = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text("Start")
                                .font(AppTheme.Typography.gravitySemibold(14))
                        }
                        .foregroundColor(Color("GrowthGreen"))
                    }
                }
            }
            .onAppear {
                validateMethod()
            }
        .sheet(isPresented: $showTimerView) {
            QuickPracticeTimerView(preSelectedMethod: method)
                    .environmentObject(NavigationContext())
            }
            .navigationViewStyle(.stack)
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(spacing: 0) {
            // Method image or placeholder
            ZStack {
                if method.id == "angio_pumping" || method.title.lowercased().contains("angio pumping") {
                    Image("angio_pumping")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 280)
                        .clipped()
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 280)
                        .clipped()
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 280)
                        .clipped()
                } else if method.id == "am2_5" || method.title.lowercased().contains("angion method 2.5") {
                    Image("am2_5")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 280)
                        .clipped()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("GrowthGreen"),
                            Color("BrightTeal")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 280)
                    .overlay(
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                    )
                }
                
                // Gradient overlay for text readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Method info overlay
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()
                    
                    // Stage badge
                    HStack(spacing: 8) {
                        Text("Stage \(method.stage)")
                            .font(AppTheme.Typography.gravitySemibold(12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(stageColor(for: method.stage))
                            .cornerRadius(20)
                        
                        if let duration = method.estimatedDurationMinutes {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text("\(duration) min")
                                    .font(AppTheme.Typography.gravitySemibold(12))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                        }
                    }
                    
                    Text(method.title)
                        .font(AppTheme.Typography.gravityBoldFont(28))
                        .foregroundColor(.white)
                    
                    if let classification = viewModel.classification {
                        Text(classification)
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Content View
    
    private var methodContentView: some View {
        VStack(spacing: 20) {
            // Description Card
            GrowthMethodRoundedCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(Color("GrowthGreen"))
                        Text("Description")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Show citation badge for vascular/flow-mediated methods
                        if method.title.lowercased().contains("angion") ||
                           method.title.lowercased().contains("vascular") ||
                           method.methodDescription.contains("flow") ||
                           method.methodDescription.contains("shear stress") ||
                           method.methodDescription.contains("nitric oxide") {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                Text("Research-Based")
                                    .font(AppTheme.Typography.captionFont())
                            }
                            .foregroundColor(Color("GrowthGreen"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("GrowthGreen").opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Text(method.methodDescription)
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Add citation link for methods with scientific basis
                    if method.title.lowercased().contains("angion") ||
                       method.methodDescription.contains("vascular") {
                        NavigationLink(destination: AllCitationsView()) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 12))
                                Text("View Scientific References")
                                    .font(AppTheme.Typography.captionFont())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(Color("GrowthGreen"))
                            .padding(.top, 8)
                        }
                    }
                }
            }
            
            // Video Tutorial Card
            GrowthMethodRoundedCard {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "play.rectangle")
                            .foregroundColor(Color("GrowthGreen"))
                        Text("Video Tutorial")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color("GrowthGreen"))
                            Text("Video Coming Soon")
                                .font(AppTheme.Typography.gravitySemibold(14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Instructions Card
            expandableCard(
                title: "Instructions",
                icon: "list.number",
                id: "instructions"
            ) {
                if !method.instructionsText.isEmpty && method.instructionsText != "No instructions provided" {
                    Text(method.instructionsText)
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No specific instructions available for this method.")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // Equipment Card
            if !method.equipmentNeeded.isEmpty {
                expandableCard(
                    title: "Equipment Needed",
                    icon: "wrench.and.screwdriver",
                    id: "equipment"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(method.equipmentNeeded, id: \.self) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color("GrowthGreen"))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                Text(item)
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Progression Criteria Card
            expandableCard(
                title: "Progression Criteria",
                icon: "chart.line.uptrend.xyaxis",
                id: "progression"
            ) {
                Text(viewModel.formattedProgressionCriteria)
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Safety Notes Card
            if viewModel.hasSafetyNotes {
                GrowthMethodRoundedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Safety Notes")
                                .font(AppTheme.Typography.gravitySemibold(16))
                                .foregroundColor(.red)
                        }
                        
                        Text(viewModel.formattedSafetyNotes)
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(.red.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Benefits Card
            if let benefits = viewModel.benefits, !benefits.isEmpty {
                expandableCard(
                    title: "Benefits",
                    icon: "sparkles",
                    id: "benefits"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("GrowthGreen"))
                                    .font(.system(size: 16))
                                Text(benefit)
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Start Session Button
            Button(action: {
                showTimerView = true
            }) {
                HStack {
                    Image(systemName: "timer")
                    Text("Start Session")
                        .font(AppTheme.Typography.gravitySemibold(16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("GrowthGreen"),
                            Color("BrightTeal")
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func expandableCard(
        title: String,
        icon: String,
        id: String,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        GrowthMethodRoundedCard {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if expandedSections.contains(id) {
                            expandedSections.remove(id)
                        } else {
                            expandedSections.insert(id)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(Color("GrowthGreen"))
                        Text(title)
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: expandedSections.contains(id) ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
                
                if expandedSections.contains(id) {
                    content()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color("ErrorColor"))
            
            Text("Unable to Load Method")
                .font(AppTheme.Typography.gravitySemibold(20))
                .foregroundColor(.primary)
            
            Text(errorMessage ?? "The method details could not be loaded. Please try again.")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Go Back") {
                dismiss()
            }
            .font(AppTheme.Typography.gravitySemibold(14))
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color("GrowthGreen"))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func validateMethod() {
        if let id = method.id, id.isEmpty {
            hasError = true
            errorMessage = "Method data is incomplete"
        }
        
        if method.title.isEmpty {
            hasError = true
            errorMessage = "Method data is incomplete"
        }
        
        if method.methodDescription.isEmpty || method.methodDescription == "No description available" {
            hasError = true
            errorMessage = "Method data is incomplete"
        }
    }
    
    private func stageColor(for stage: Int) -> Color {
        switch stage {
        case 0:
            return Color("ErrorColor")
        case 1:
            return Color("GrowthGreen")
        case 2:
            return Color("BrightTeal")
        case 3:
            return Color.purple
        case 4:
            return Color.orange
        default:
            return Color.gray
        }
    }
}

// MARK: - RoundedCard Component

struct GrowthMethodRoundedCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    // Create a sample method for preview
    let sampleMethod = GrowthMethod(
        id: "preview",
        stage: 2,
        title: "Deliberate Practice",
        methodDescription: "A structured form of practice aimed at effectively improving specific aspects of performance through repetition, feedback, and focused attention.",
        instructionsText: "1. Identify a specific skill to improve\n2. Break it down into components\n3. Focus intensely on one component at a time\n4. Get immediate feedback\n5. Repeat with adjustments based on feedback",
        visualPlaceholderUrl: "https://example.com/deliberate-practice.jpg",
        equipmentNeeded: ["Notebook", "Timer", "Recording device (optional)"],
        estimatedDurationMinutes: 30,
        categories: ["Skill Development", "Performance", "Focus"]
    )
    
    GrowthMethodDetailView(method: sampleMethod)
} 