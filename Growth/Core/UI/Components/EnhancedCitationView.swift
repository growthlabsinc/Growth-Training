//
//  EnhancedCitationView.swift
//  Growth
//
//  Enhanced citation views using the updated Citation model
//  Created by Developer on 10/6/25.
//

import SwiftUI

/// Enhanced citation view with new fields (pmid, issue, citationType, accessDate)
struct EnhancedCitationView: View {
    let citation: Citation
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
                    // Citation type icon
                    citationTypeIcon
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.secondary)

                    Text(shortCitation)
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

            // Expanded citation details
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
                    Text(citation.formattedAPA)
                        .font(AppTheme.Typography.footnoteFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Links (DOI or PMID or URL)
                    if let doi = citation.doi, !doi.isEmpty,
                       let url = URL(string: "https://doi.org/\(doi)") {
                        Link(destination: url) {
                            linkRow(icon: "link.circle.fill", text: "View on DOI.org")
                        }
                    } else if let pmid = citation.pmid, !pmid.isEmpty,
                              let url = URL(string: "https://pubmed.ncbi.nlm.nih.gov/\(pmid)/") {
                        Link(destination: url) {
                            linkRow(icon: "link.circle.fill", text: "View on PubMed")
                        }
                    } else if let urlString = citation.url, !urlString.isEmpty,
                              let url = URL(string: urlString) {
                        Link(destination: url) {
                            linkRow(icon: "link.circle.fill", text: "View Source")
                        }
                    }
                }
                .padding(AppTheme.Layout.spacingM)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(AppTheme.Layout.cornerRadiusM)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var citationTypeIcon: some View {
        let iconName: String
        switch citation.citationType {
        case .journalArticle:
            iconName = "doc.text.fill"
        case .book:
            iconName = "book.fill"
        case .bookChapter:
            iconName = "book.pages.fill"
        case .report:
            iconName = "doc.plaintext.fill"
        case .thesis:
            iconName = "graduationcap.fill"
        case .conference:
            iconName = "person.3.fill"
        }
        return Image(systemName: iconName)
    }

    private var shortCitation: String {
        // Extract first author last name
        let firstAuthor = citation.authors.components(separatedBy: ",").first ?? "Unknown"
        let lastName = firstAuthor.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").first ?? "Unknown"

        if citation.authors.contains("et al.") {
            return "(\(lastName) et al., \(citation.year))"
        } else {
            return "(\(lastName), \(citation.year))"
        }
    }

    private func linkRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Layout.spacingXS) {
            Image(systemName: icon)
                .font(AppTheme.Typography.captionFont())
            Text(text)
                .font(AppTheme.Typography.captionFont())
        }
        .foregroundColor(AppTheme.Colors.secondary)
    }
}

/// Enhanced citation detail view with export options
struct EnhancedCitationDetailView: View {
    let citation: Citation
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false
    @State private var showingExportSheet = false
    @State private var selectedExportFormat: ExportFormat = .apa

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingL) {
                // Citation Type Badge
                HStack {
                    citationTypeBadge
                    Spacer()
                }

                // Title Section
                Text(citation.title)
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(AppTheme.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)

                // Authors Section
                sectionView(title: "Authors", content: citation.authors)

                // Publication Info
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                    Text("Publication")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(citation.journal)
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(AppTheme.Colors.text)

                        if let volume = citation.volume {
                            if let issue = citation.issue {
                                Text("Volume \(volume)(\(issue))")
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .foregroundColor(AppTheme.Colors.text)
                            } else {
                                Text("Volume \(volume)")
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .foregroundColor(AppTheme.Colors.text)
                            }
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
                                identifierRow(label: "DOI:", value: doi)
                            }

                            if let pmid = citation.pmid {
                                identifierRow(label: "PubMed ID:", value: pmid)
                            }
                        }
                    }
                }

                // Action Buttons
                VStack(spacing: AppTheme.Layout.spacingM) {
                    // Copy Citation Button
                    Button(action: {
                        UIPasteboard.general.string = citation.formattedAPA
                        withAnimation(AppTheme.Animation.quickAnimation) {
                            copiedToClipboard = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(AppTheme.Animation.quickAnimation) {
                                copiedToClipboard = false
                            }
                        }
                    }) {
                        actionButton(
                            icon: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc.fill",
                            text: copiedToClipboard ? "Copied!" : "Copy Citation (APA)",
                            color: copiedToClipboard ? AppTheme.Colors.success : AppTheme.Colors.secondary
                        )
                    }

                    // Export Button
                    Button(action: { showingExportSheet = true }) {
                        actionButton(
                            icon: "square.and.arrow.up.fill",
                            text: "Export Citation",
                            color: AppTheme.Colors.secondary
                        )
                    }

                    // External Links
                    if let doi = citation.doi,
                       let url = URL(string: "https://doi.org/\(doi)") {
                        Link(destination: url) {
                            actionButton(
                                icon: "link.circle.fill",
                                text: "View on DOI.org",
                                color: AppTheme.Colors.secondary,
                                showArrow: true
                            )
                        }
                    }

                    if let pmid = citation.pmid,
                       let url = URL(string: "https://pubmed.ncbi.nlm.nih.gov/\(pmid)/") {
                        Link(destination: url) {
                            actionButton(
                                icon: "link.circle.fill",
                                text: "View on PubMed",
                                color: AppTheme.Colors.secondary,
                                showArrow: true
                            )
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
        .sheet(isPresented: $showingExportSheet) {
            ExportFormatSelectionView(citation: citation)
        }
    }

    private var citationTypeBadge: some View {
        HStack(spacing: AppTheme.Layout.spacingXS) {
            let typeText: String
            switch citation.citationType {
            case .journalArticle: typeText = "Journal Article"
            case .book: typeText = "Book"
            case .bookChapter: typeText = "Book Chapter"
            case .report: typeText = "Report"
            case .thesis: typeText = "Thesis"
            case .conference: typeText = "Conference"
            }

            Text(typeText)
                .font(AppTheme.Typography.gravitySemibold(12))
        }
        .foregroundColor(AppTheme.Colors.secondary)
        .padding(.horizontal, AppTheme.Layout.spacingM)
        .padding(.vertical, AppTheme.Layout.spacingS)
        .background(AppTheme.Colors.secondary.opacity(0.1))
        .cornerRadius(AppTheme.Layout.cornerRadiusM)
    }

    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
            Text(title)
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text(content)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(AppTheme.Colors.text)
        }
    }

    private func identifierRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(AppTheme.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(AppTheme.Colors.text)
        }
    }

    private func actionButton(icon: String, text: String, color: Color, showArrow: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
            Text(text)
            Spacer()
            if showArrow {
                Image(systemName: "arrow.up.right.square")
            }
        }
        .foregroundColor(color)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(AppTheme.Layout.cornerRadiusM)
    }
}

/// Export format selection sheet
struct ExportFormatSelectionView: View {
    let citation: Citation
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .apa

    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Layout.spacingL) {
                Text("Choose export format")
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.top)

                VStack(spacing: AppTheme.Layout.spacingM) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: { selectedFormat = format }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(format.rawValue)
                                        .font(AppTheme.Typography.gravitySemibold(16))
                                    Text(".\(format.fileExtension)")
                                        .font(AppTheme.Typography.gravityBook(12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                Spacer()
                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.Colors.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(AppTheme.Layout.cornerRadiusM)
                        }
                        .foregroundColor(AppTheme.Colors.text)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Export Button
                Button(action: shareExport) {
                    Text("Export & Share")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.Colors.secondary)
                        .cornerRadius(AppTheme.Layout.cornerRadiusM)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Export Citation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shareExport() {
        let exportService = CitationExportService.shared
        let exportedText = exportService.formatCitationForCopy(citation, format: selectedFormat)

        // Create temporary file for sharing
        let fileName = "citation.\(selectedFormat.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try exportedText.write(to: tempURL, atomically: true, encoding: .utf8)

            // Present share sheet
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }

            dismiss()
        } catch {
            print("Error creating export file: \(error)")
        }
    }
}

#Preview("Enhanced Citation View") {
    EnhancedCitationView(citation: Citation(
        id: "preview1",
        authors: "Smith, J. & Jones, A.",
        year: "2024",
        title: "Sample Article",
        journal: "Journal of Research",
        volume: "10",
        issue: "2",
        doi: "10.1234/sample",
        pmid: "12345678",
        citationType: .journalArticle
    ))
    .padding()
}

#Preview("Enhanced Citation Detail") {
    NavigationStack {
        EnhancedCitationDetailView(citation: Citation(
            id: "preview1",
            authors: "Smith, J. & Jones, A.",
            year: "2024",
            title: "Sample Article on Important Research Topic",
            journal: "Journal of Research",
            volume: "10",
            issue: "2",
            pages: "123-145",
            doi: "10.1234/sample",
            pmid: "12345678",
            url: "https://example.com/article",
            citationType: .journalArticle
        ))
    }
}
