//
//  CitationView.swift
//  Growth
//
//  UI component for displaying medical citations
//

import SwiftUI

/// A view that displays a citation reference with expandable details
struct CitationView: View {
    let citation: MedicalCitation
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
            // Citation reference button
            Button(action: {
                withAnimation(AppTheme.Animation.quickAnimation) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: AppTheme.Layout.spacingXS) {
                    Image(systemName: "doc.text.fill")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.secondary)
                    
                    Text(citation.shortCitation)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.secondary)
                        .underline()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.secondary)
                        .scaleEffect(0.8)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Citation: \(citation.shortCitation)")
            .accessibilityHint("Tap to expand citation details")
            
            // Expanded citation details
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                    Text(citation.formattedCitation)
                        .font(AppTheme.Typography.footnoteFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let doiUrl = citation.doi.map({ "https://doi.org/\($0)" }),
                       let url = URL(string: doiUrl) {
                        Link(destination: url) {
                            HStack(spacing: AppTheme.Layout.spacingXS) {
                                Image(systemName: "link.circle.fill")
                                    .font(AppTheme.Typography.captionFont())
                                Text("View Source")
                                    .font(AppTheme.Typography.captionFont())
                            }
                            .foregroundColor(AppTheme.Colors.secondary)
                        }
                        .accessibilityLabel("View source on DOI.org")
                    } else if let pmid = citation.pmid,
                              let url = URL(string: "https://pubmed.ncbi.nlm.nih.gov/\(pmid)/") {
                        Link(destination: url) {
                            HStack(spacing: AppTheme.Layout.spacingXS) {
                                Image(systemName: "link.circle.fill")
                                    .font(AppTheme.Typography.captionFont())
                                Text("View on PubMed")
                                    .font(AppTheme.Typography.captionFont())
                            }
                            .foregroundColor(AppTheme.Colors.secondary)
                        }
                        .accessibilityLabel("View source on PubMed")
                    }
                }
                .padding(AppTheme.Layout.spacingM)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(AppTheme.Layout.cornerRadiusM)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// A view that displays multiple citations in a list
struct CitationsListView: View {
    let citations: [MedicalCitation]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
            HStack(spacing: AppTheme.Layout.spacingS) {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(AppTheme.Colors.secondary)
                    .font(AppTheme.Typography.headlineFont())
                
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(AppTheme.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
                ForEach(citations) { citation in
                    CitationView(citation: citation)
                    
                    if citation.id != citations.last?.id {
                        Divider()
                            .opacity(0.3)
                    }
                }
            }
        }
        .padding(AppTheme.Layout.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppTheme.Layout.cornerRadiusL)
    }
}

/// An inline citation reference that can be embedded in text
struct InlineCitationView: View {
    let citation: MedicalCitation
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            Text(citation.shortCitation)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.secondary)
                .underline()
        }
        .accessibilityLabel("Citation: \(citation.shortCitation)")
        .accessibilityHint("Tap to view full citation")
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                CitationDetailView(citation: citation)
            }
        }
    }
}

/// Simple superscript citation number
struct InlineCitationNumber: View {
    let number: Int
    let citation: MedicalCitation
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            Text("\(number)")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.secondary)
                .baselineOffset(6)
                .scaleEffect(0.7)
        }
        .accessibilityLabel("Citation \(number)")
        .accessibilityHint("Tap to view citation details")
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                CitationDetailView(citation: citation)
            }
        }
    }
}

/// Detailed view of a citation
struct CitationDetailView: View {
    let citation: MedicalCitation
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingL) {
                // Title Section
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
                    Text(citation.title)
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(AppTheme.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Authors Section
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                    Text("Authors")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text(citation.authors.joined(separator: ", "))
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(AppTheme.Colors.text)
                }
                
                // Journal Info Section
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                    Text("Publication")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(citation.journal)
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        if let volume = citation.volume {
                            Text("Volume \(volume)")
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(AppTheme.Colors.text)
                        }
                        
                        if let pages = citation.pages {
                            Text("Pages \(pages)")
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(AppTheme.Colors.text)
                        }
                        
                        Text("Year: \(citation.year)")
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(AppTheme.Colors.text)
                    }
                }
                
                // Identifiers Section
                if citation.doi != nil || citation.pmid != nil {
                    VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                        Text("Identifiers")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let doi = citation.doi {
                                HStack {
                                    Text("DOI:")
                                        .font(AppTheme.Typography.gravityBook(14))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    Text(doi)
                                        .font(AppTheme.Typography.gravityBook(14))
                                        .foregroundColor(AppTheme.Colors.text)
                                }
                            }
                            
                            if let pmid = citation.pmid {
                                HStack {
                                    Text("PubMed ID:")
                                        .font(AppTheme.Typography.gravityBook(14))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    Text(pmid)
                                        .font(AppTheme.Typography.gravityBook(14))
                                        .foregroundColor(AppTheme.Colors.text)
                                }
                            }
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: AppTheme.Layout.spacingM) {
                    // Copy Citation Button
                    Button(action: {
                        UIPasteboard.general.string = citation.formattedCitation
                        withAnimation(AppTheme.Animation.quickAnimation) {
                            copiedToClipboard = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(AppTheme.Animation.quickAnimation) {
                                copiedToClipboard = false
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            Text(copiedToClipboard ? "Copied!" : "Copy Citation")
                            Spacer()
                        }
                        .foregroundColor(copiedToClipboard ? AppTheme.Colors.success : AppTheme.Colors.secondary)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(AppTheme.Layout.cornerRadiusM)
                    }
                    
                    // External Links
                    if let doi = citation.doi,
                       let url = URL(string: "https://doi.org/\(doi)") {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                Text("View on DOI.org")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundColor(AppTheme.Colors.secondary)
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(AppTheme.Layout.cornerRadiusM)
                        }
                    }
                    
                    if let pmid = citation.pmid,
                       let url = URL(string: "https://pubmed.ncbi.nlm.nih.gov/\(pmid)/") {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                Text("View on PubMed")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundColor(AppTheme.Colors.secondary)
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(AppTheme.Layout.cornerRadiusM)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Citation Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .font(AppTheme.Typography.gravitySemibold(16))
                .foregroundColor(AppTheme.Colors.secondary)
            }
        }
    }
}

/// A disclaimer view with citations
struct MedicalDisclaimerWithCitationsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
            HStack(spacing: AppTheme.Layout.spacingS) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(AppTheme.Typography.headlineFont())
                
                Text("Medical Information Notice")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(AppTheme.Colors.text)
            }
            
            Text("The information provided in this app is based on peer-reviewed scientific research. Always consult with a qualified healthcare provider before starting any new exercise or wellness program.")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            NavigationLink {
                AllCitationsView()
            } label: {
                HStack {
                    Image(systemName: "text.book.closed.fill")
                    Text("View All Scientific References")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(AppTheme.Colors.secondary)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(AppTheme.Layout.cornerRadiusM)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppTheme.Layout.cornerRadiusL)
    }
}

/// View showing all citations organized by category with search
struct AllCitationsView: View {
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingYearFilter = false
    @State private var startYear = 2000
    @State private var endYear = Calendar.current.component(.year, from: Date())
    
    var filteredCitations: [String: [MedicalCitation]] {
        var result = MedicalCitations.allCitations
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.mapValues { citations in
                citations.filter { citation in
                    citation.title.localizedCaseInsensitiveContains(searchText) ||
                    citation.authors.joined().localizedCaseInsensitiveContains(searchText) ||
                    citation.journal.localizedCaseInsensitiveContains(searchText)
                }
            }.filter { !$0.value.isEmpty }
        }
        
        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.key == category }
        }
        
        // Filter by year range
        if showingYearFilter {
            result = result.mapValues { citations in
                citations.filter { $0.year >= startYear && $0.year <= endYear }
            }.filter { !$0.value.isEmpty }
        }
        
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Layout.spacingL) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextField("Search citations...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(AppTheme.Typography.gravityBook(16))
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(AppTheme.Layout.cornerRadiusM)
                .padding(.horizontal)
                
                // Filter Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Layout.spacingS) {
                        // Year Filter Toggle
                        Button(action: { showingYearFilter.toggle() }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text(showingYearFilter ? "\(startYear)-\(endYear)" : "All Years")
                            }
                            .font(AppTheme.Typography.gravityBook(14))
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                            .padding(.vertical, AppTheme.Layout.spacingS)
                            .background(showingYearFilter ? AppTheme.Colors.secondary : Color(.tertiarySystemBackground))
                            .foregroundColor(showingYearFilter ? .white : AppTheme.Colors.text)
                            .cornerRadius(AppTheme.Layout.cornerRadiusM)
                        }
                        
                        // Category Filters
                        ForEach(Array(MedicalCitations.allCitations.keys.sorted()), id: \.self) { category in
                            Button(action: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }) {
                                Text(category)
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .padding(.horizontal, AppTheme.Layout.spacingM)
                                    .padding(.vertical, AppTheme.Layout.spacingS)
                                    .background(selectedCategory == category ? AppTheme.Colors.secondary : Color(.tertiarySystemBackground))
                                    .foregroundColor(selectedCategory == category ? .white : AppTheme.Colors.text)
                                    .cornerRadius(AppTheme.Layout.cornerRadiusM)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Year Range Slider (if enabled)
                if showingYearFilter {
                    VStack(spacing: AppTheme.Layout.spacingS) {
                        HStack {
                            Text("Year Range:")
                                .font(AppTheme.Typography.gravitySemibold(14))
                            Spacer()
                            Text("\(startYear) - \(endYear)")
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        HStack {
                            Slider(value: Binding(
                                get: { Double(startYear) },
                                set: { startYear = Int($0) }
                            ), in: 2000...Double(endYear - 1), step: 1)
                            
                            Slider(value: Binding(
                                get: { Double(endYear) },
                                set: { endYear = Int($0) }
                            ), in: Double(startYear + 1)...2024, step: 1)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(AppTheme.Layout.cornerRadiusM)
                    .padding(.horizontal)
                }
                
                // Citation Lists
                ForEach(Array(filteredCitations.keys.sorted()), id: \.self) { category in
                    if let citations = filteredCitations[category], !citations.isEmpty {
                        CitationsListView(citations: citations, title: category)
                            .padding(.horizontal)
                    }
                }
                
                // Results Summary
                if filteredCitations.isEmpty {
                    VStack(spacing: AppTheme.Layout.spacingM) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("No citations found")
                            .font(AppTheme.Typography.gravitySemibold(18))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Text("Try adjusting your search or filters")
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(AppTheme.Layout.spacingXXL)
                } else {
                    Text("\(filteredCitations.values.flatMap { $0 }.count) citations found")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Scientific References")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Citation Badge for Method Cards
struct CitationBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacingXS) {
            Image(systemName: "checkmark.seal.fill")
                .font(AppTheme.Typography.captionFont())
            
            Text("\(count) Citations")
                .font(AppTheme.Typography.gravitySemibold(12))
        }
        .foregroundColor(AppTheme.Colors.secondary)
        .padding(.horizontal, AppTheme.Layout.spacingS)
        .padding(.vertical, 4)
        .background(AppTheme.Colors.secondary.opacity(0.1))
        .cornerRadius(AppTheme.Layout.cornerRadiusS)
    }
}

#Preview("Citation View") {
    CitationView(citation: MedicalCitations.bloodFlowBenefits)
        .padding()
}

#Preview("Citations List") {
    CitationsListView(
        citations: [
            MedicalCitations.bloodFlowBenefits,
            MedicalCitations.vascularHealth
        ],
        title: "Blood Flow Research"
    )
    .padding()
}

#Preview("All Citations") {
    NavigationStack {
        AllCitationsView()
    }
}

#Preview("Citation Badge") {
    CitationBadge(count: 5)
        .padding()
}