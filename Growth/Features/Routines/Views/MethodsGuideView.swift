//
//  MethodsGuideView.swift
//  Growth
//
//  Created for Methods Guide feature
//

import SwiftUI

struct MethodsGuideView: View {
    @StateObject private var viewModel = MethodsGuideViewModel()
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedMethod: GrowthMethod?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Search Bar
                searchBar
                
                // Category Filter
                categoryFilter
                
                // Methods Grid
                methodsGrid
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(isPresented: .constant(selectedMethod != nil)) {
            if let method = selectedMethod {
                MethodDetailGuideView(method: method) {
                    selectedMethod = nil
                }
            }
        }
        .onAppear {
            viewModel.loadMethods()
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("TextSecondaryColor"))
                .font(.system(size: 16))
            
            TextField("Search methods...", text: $searchText)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextColor"))
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("TextSecondaryColor"))
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }
    
    // MARK: - Methods Grid
    private var methodsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(filteredMethods) { method in
                MethodCard(method: method) {
                    selectedMethod = method
                }
            }
        }
    }
    
    // MARK: - Filtering Logic
    private var filteredMethods: [GrowthMethod] {
        viewModel.methods.filter { method in
            let matchesSearch = searchText.isEmpty || 
                method.title.localizedCaseInsensitiveContains(searchText) ||
                method.methodDescription.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == "All" || 
                method.categories.contains(selectedCategory)
            
            return matchesSearch && matchesCategory
        }
    }
}

// MARK: - Category Chip Component
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(isSelected ? .white : Color("TextSecondaryColor"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color("GrowthGreen") : Color(.tertiarySystemBackground))
                )
        }
    }
}

// MARK: - Method Card Component
struct MethodCard: View {
    let method: GrowthMethod
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Method Icon/Stage
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color("GrowthGreen").opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Text("\(method.stage)")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                    
                    Spacer()
                    
                    if let duration = method.estimatedDurationMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text("\(duration)m")
                                .font(AppTheme.Typography.gravityBook(12))
                        }
                        .foregroundColor(Color("TextSecondaryColor"))
                    }
                }
                
                // Title and Description
                VStack(alignment: .leading, spacing: 6) {
                    Text(method.title)
                        .font(AppTheme.Typography.gravitySemibold(15))
                        .foregroundColor(Color("TextColor"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(method.methodDescription)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                // Equipment if any
                if !method.equipmentNeeded.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 10))
                        Text(method.equipmentNeeded.prefix(2).joined(separator: ", "))
                            .font(AppTheme.Typography.gravityBook(10))
                    }
                    .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("GrowthGreen").opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Method Detail Guide View
struct MethodDetailGuideView: View {
    let method: GrowthMethod
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                methodHeader
                
                // Quick Info
                quickInfoSection
                
                // Safety Notes
                if let safetyNotes = method.safetyNotes, !safetyNotes.isEmpty {
                    safetySection(notes: safetyNotes)
                }
                
                // Equipment Section
                if !method.equipmentNeeded.isEmpty {
                    equipmentSection
                }
                
                // Benefits Section
                if let benefits = method.benefits, !benefits.isEmpty {
                    benefitsSection(benefits: benefits)
                }
                
                // Step by Step Instructions
                instructionsSection
                
                // Timer Configuration
                if let timerConfig = method.timerConfig {
                    timerConfigSection(config: timerConfig)
                }
                
                // Related Methods
                if let relatedMethods = method.relatedMethods, !relatedMethods.isEmpty {
                    relatedMethodsSection(methods: relatedMethods)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    onDismiss()
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(AppTheme.Typography.gravitySemibold(16))
                    }
                    .foregroundColor(Color("GrowthGreen"))
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var methodHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Stage Badge
                HStack(spacing: 6) {
                    Text("Stage")
                        .font(AppTheme.Typography.gravityBook(12))
                    Text("\(method.stage)")
                        .font(AppTheme.Typography.gravitySemibold(14))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color("GrowthGreen").opacity(0.15))
                )
                .foregroundColor(Color("GrowthGreen"))
                
                Spacer()
                
                // Classification if available
                if let classification = method.classification {
                    Text(classification)
                        .font(AppTheme.Typography.gravitySemibold(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(Color("TextSecondaryColor").opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            Text(method.title)
                .font(AppTheme.Typography.gravitySemibold(24))
                .foregroundColor(Color("TextColor"))
            
            Text(method.methodDescription)
                .font(AppTheme.Typography.gravityBook(16))
                .foregroundColor(Color("TextSecondaryColor"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Quick Info Section
    private var quickInfoSection: some View {
        HStack(spacing: 20) {
            // Duration
            if let duration = method.estimatedDurationMinutes {
                InfoChip(
                    icon: "clock.fill",
                    title: "Duration",
                    value: "\(duration) min"
                )
            }
            
            // Category
            if let category = method.categories.first {
                InfoChip(
                    icon: "tag.fill",
                    title: "Category",
                    value: category
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Safety Section
    private func safetySection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Safety Notes")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(Color("TextColor"))
            }
            
            Text(notes)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
        }
    }
    
    // MARK: - Equipment Section
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment Needed")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(method.equipmentNeeded, id: \.self) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("GrowthGreen"))
                            .font(.system(size: 16))
                        Text(item)
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(Color("TextColor"))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Benefits Section
    private func benefitsSection(benefits: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benefits")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color("GrowthGreen"))
                            .font(.system(size: 12))
                            .padding(.top, 2)
                        Text(benefit)
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(Color("TextColor"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("GrowthGreen").opacity(0.05))
            )
        }
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step-by-Step Instructions")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))
            
            // Use structured steps if available, otherwise parse instructionsText
            if let structuredSteps = method.steps, !structuredSteps.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(structuredSteps) { step in
                        StructuredStepView(
                            step: step,
                            isFirst: step.stepNumber == 1,
                            isLast: step.stepNumber == structuredSteps.count
                        )
                    }
                }
            } else {
                // Fallback to parsing instructionsText
                let steps = parseInstructions(method.instructionsText)
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        StepView(
                            stepNumber: index + 1,
                            content: step,
                            isFirst: index == 0,
                            isLast: index == steps.count - 1
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Timer Configuration Section
    private func timerConfigSection(config: TimerConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer Settings")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 12) {
                if let recommended = config.recommendedDurationSeconds {
                    HStack {
                        Label("Recommended Duration", systemImage: "timer")
                            .font(AppTheme.Typography.gravityBook(14))
                        Spacer()
                        Text("\(recommended / 60) minutes")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                
                if config.hasIntervals == true, let intervals = config.intervals {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intervals")
                            .font(AppTheme.Typography.gravitySemibold(14))
                        ForEach(intervals) { interval in
                            HStack {
                                Text(interval.name)
                                    .font(AppTheme.Typography.gravityBook(13))
                                Spacer()
                                Text("\(interval.durationSeconds)s")
                                    .font(AppTheme.Typography.gravityBook(13))
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Related Methods Section
    private func relatedMethodsSection(methods: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Methods")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))
            
            Text("Explore these related techniques to enhance your practice")
                .font(AppTheme.Typography.gravityBook(13))
                .foregroundColor(Color("TextSecondaryColor"))
            
            // In a real implementation, you'd fetch and display the actual method cards
            // For now, just show the method IDs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(methods, id: \.self) { methodId in
                        RelatedMethodPlaceholder(methodId: methodId)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func parseInstructions(_ text: String) -> [String] {
        var steps = [String]()
        let lines = text.components(separatedBy: .newlines)
        var currentStep = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check if line starts with a number followed by period or parenthesis
            let startsWithNumber = trimmed.range(of: #"^\d+[.)]"#, options: .regularExpression) != nil
            
            if startsWithNumber && !currentStep.isEmpty {
                // New numbered step found, save current and start new
                steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
                currentStep = trimmed
            } else if trimmed.isEmpty && !currentStep.isEmpty {
                // Empty line might indicate step boundary
                steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
                currentStep = ""
            } else if !trimmed.isEmpty {
                // Continue building current step
                if !currentStep.isEmpty {
                    currentStep += " "
                }
                currentStep += trimmed
            }
        }
        
        // Don't forget the last step
        if !currentStep.isEmpty {
            steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        // If no clear steps found, try splitting by double newlines
        if steps.isEmpty || steps.count == 1 {
            steps = text.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        // If still no clear separation, create reasonable chunks
        if steps.count <= 1 {
            let sentences = text.replacingOccurrences(of: "\n", with: " ")
                .components(separatedBy: ". ")
                .filter { !$0.isEmpty }
            
            if sentences.count > 4 {
                // Group sentences into 3-4 steps
                let groupSize = (sentences.count + 3) / 4
                steps = []
                
                for i in stride(from: 0, to: sentences.count, by: groupSize) {
                    let endIndex = min(i + groupSize, sentences.count)
                    let group = sentences[i..<endIndex].joined(separator: ". ")
                    if !group.isEmpty {
                        steps.append(group + (group.hasSuffix(".") ? "" : "."))
                    }
                }
            }
        }
        
        return steps.isEmpty ? [text] : steps
    }
}

// MARK: - Supporting Components

struct InfoChip: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(AppTheme.Typography.gravityBook(11))
            }
            .foregroundColor(Color("TextSecondaryColor"))
            
            Text(value)
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))
        }
    }
}

struct StepView: View {
    let stepNumber: Int
    let content: String
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step indicator with connecting line
            VStack(spacing: 0) {
                // Step number circle
                ZStack {
                    Circle()
                        .fill(Color("GrowthGreen"))
                        .frame(width: 32, height: 32)
                    
                    Text("\(stepNumber)")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(.white)
                }
                
                // Connecting line (except for last step)
                if !isLast {
                    Rectangle()
                        .fill(Color("GrowthGreen").opacity(0.3))
                        .frame(width: 2, height: 40)
                        .padding(.top, 4)
                }
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 8) {
                Text("Step \(stepNumber)")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text(content)
                    .font(AppTheme.Typography.gravityBook(15))
                    .foregroundColor(Color("TextColor"))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, isLast ? 0 : 16)
            
            Spacer()
        }
    }
}

struct RelatedMethodPlaceholder: View {
    let methodId: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("GrowthGreen").opacity(0.1))
                .frame(width: 120, height: 80)
                .overlay(
                    Text("Method")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                )
        }
    }
}

// MARK: - Structured Step View
struct StructuredStepView: View {
    let step: MethodStep
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step indicator with connecting line
            VStack(spacing: 0) {
                // Step number circle
                ZStack {
                    Circle()
                        .fill(Color("GrowthGreen"))
                        .frame(width: 32, height: 32)
                    
                    Text("\(step.stepNumber)")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(.white)
                }
                
                // Connecting line (except for last step)
                if !isLast {
                    Rectangle()
                        .fill(Color("GrowthGreen").opacity(0.3))
                        .frame(width: 2, height: 40)
                        .padding(.top, 4)
                }
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text(step.description)
                    .font(AppTheme.Typography.gravityBook(15))
                    .foregroundColor(Color("TextColor"))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Optional duration
                if let duration = step.duration {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("\(duration) seconds")
                            .font(AppTheme.Typography.gravityBook(12))
                    }
                    .foregroundColor(Color("TextSecondaryColor"))
                    .padding(.top, 4)
                }
                
                // Tips if available
                if let tips = step.tips, !tips.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Tips", systemImage: "lightbulb")
                            .font(AppTheme.Typography.gravitySemibold(13))
                            .foregroundColor(Color("BrightTeal"))
                        
                        ForEach(tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(Color("BrightTeal"))
                                Text(tip)
                                    .font(AppTheme.Typography.gravityBook(13))
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("BrightTeal").opacity(0.1))
                    )
                }
                
                // Warnings if available
                if let warnings = step.warnings, !warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Caution", systemImage: "exclamationmark.triangle")
                            .font(AppTheme.Typography.gravitySemibold(13))
                            .foregroundColor(.orange)
                        
                        ForEach(warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text(warning)
                                    .font(AppTheme.Typography.gravityBook(13))
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
            
            Spacer()
        }
    }
}


// MARK: - Preview
#Preview {
    NavigationStack {
        MethodsGuideView()
    }
}