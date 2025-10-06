//
//  CitationRowView.swift
//  Growth
//
//  Created by Developer on 10/6/25.
//

import SwiftUI

/// View component for displaying a single scientific citation with optional source link
struct CitationRowView: View {
    /// The citation to display
    let citation: Citation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Display APA formatted citation
            Text(citation.formattedAPA)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.text)
                .fixedSize(horizontal: false, vertical: true) // Allow text wrapping

            // "View Source" link (if URL available)
            if let url = citation.url, let validURL = URL(string: url) {
                Link("View Source →", destination: validURL)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, AppTheme.Layout.spacingS)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Citation: \(citation.formattedAPA)")
    }
}

#if DEBUG
struct CitationRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CitationRowView(citation: Citation(
                id: "citation1",
                authors: "Smith, J., & Jones, A.",
                year: "2023",
                title: "The Science of PE Training",
                journal: "Journal of PE Research",
                volume: "12",
                pages: "45-67",
                doi: "10.1234/example",
                url: "https://example.com"
            ))

            CitationRowView(citation: Citation(
                id: "citation2",
                authors: "Reddit Community",
                year: "2024",
                title: "PE Discussion Thread",
                journal: "r/TheScienceOfPE",
                url: nil
            ))
        }
        .padding()
    }
}
#endif
