//
//  MarkdownExample.swift
//  Growth
//
//  Created by Claude on 6/25/25.
//

import SwiftUI

/// Example view demonstrating the markdown rendering capabilities
struct MarkdownExample: View {
    @State private var fontSize: CGFloat = AppTheme.Typography.body
    @Environment(\.colorScheme) private var colorScheme
    
    let exampleContent = """
    # Markdown Rendering Example
    
    This example demonstrates the **comprehensive markdown rendering** capabilities of the Growth app's help center.
    
    ## Typography Styles
    
    The Growth app uses the *Gravity* font family for a clean, modern look. You can use **bold text** for emphasis and *italic text* for subtle highlighting.
    
    ### Headers Support
    
    We support three levels of headers (H1, H2, and H3) with appropriate spacing and sizing based on the app's design system.
    
    ## Lists and Organization
    
    ### Bullet Lists
    
    Here are the key features:
    
    - Clean and consistent typography
    - Dark mode support with adaptive colors
    - Responsive font sizing
    - Accessibility features built-in
    
    ### Numbered Lists
    
    Follow these steps to get started:
    
    1. Choose your preferred theme
    2. Adjust font size to your liking
    3. Enable accessibility features if needed
    4. Start exploring the app
    
    ## Special Content Blocks
    
    💡 **Tip**: Use the font size controls in the toolbar to adjust readability according to your preferences.
    
    ⚠️ **Warning**: Always follow safety guidelines when performing any exercises or routines.
    
    ℹ️ **Info**: The app automatically saves your progress and syncs across devices.
    
    ✅ **Success**: Your profile has been created successfully!
    
    ## Code Examples
    
    Inline code like `AppTheme.Typography.bodyFont()` is styled with a monospace font.
    
    ```swift
    // Example Swift code
    struct ContentView: View {
        var body: some View {
            Text("Hello, Growth!")
                .font(AppTheme.Typography.title1Font())
                .foregroundColor(AppTheme.Colors.primary)
        }
    }
    ```
    
    ## Block Quotes
    
    > "The journey of a thousand miles begins with a single step."
    > - Lao Tzu
    
    ## Links and References
    
    For more information, visit [our website](https://growth.app) or check out the [documentation](https://docs.growth.app).
    
    ## Tables (Future Enhancement)
    
    | Feature | Status | Priority |
    |---------|--------|----------|
    | Markdown Rendering | ✅ Complete | High |
    | Dark Mode Support | ✅ Complete | High |
    | Accessibility | ✅ Complete | High |
    | Custom Themes | 🚧 In Progress | Medium |
    """
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Markdown content
                    MarkdownRenderer(
                        content: exampleContent,
                        style: MarkdownStyle.scaled(
                            fontSize: fontSize,
                            colorScheme: colorScheme
                        )
                    )
                    .padding()
                    
                    // Additional spacing at bottom
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Markdown Example")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Font Size") {
                            Button {
                                fontSize = 14
                            } label: {
                                Label("Small", systemImage: "textformat.size.smaller")
                            }
                            
                            Button {
                                fontSize = AppTheme.Typography.body
                            } label: {
                                Label("Default", systemImage: "textformat.size")
                            }
                            
                            Button {
                                fontSize = 18
                            } label: {
                                Label("Large", systemImage: "textformat.size.larger")
                            }
                            
                            Button {
                                fontSize = 20
                            } label: {
                                Label("Extra Large", systemImage: "textformat.size.larger")
                            }
                        }
                    } label: {
                        Image(systemName: "textformat.size")
                            .font(AppTheme.Typography.bodyFont())
                    }
                }
            }
        }
    }
}

#Preview {
    MarkdownExample()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    MarkdownExample()
        .preferredColorScheme(.dark)
}