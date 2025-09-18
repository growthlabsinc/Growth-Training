import SwiftUI

struct FormattedTextView: View {
    let content: String
    let textColor: Color?
    let spacing: CGFloat?
    
    init(content: String, textColor: Color? = nil, spacing: CGFloat? = nil) {
        self.content = content
        self.textColor = textColor
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing ?? AppTheme.Layout.spacingM) {
            ForEach(parseMarkdownSections(content), id: \.id) { section in
                section.view
            }
        }
    }
    
    private struct MarkdownSection: Identifiable {
        let id = UUID()
        let view: AnyView
    }
    
    private func parseMarkdownSections(_ text: String) -> [MarkdownSection] {
        var sections: [MarkdownSection] = []
        let lines = text.components(separatedBy: "\n")
        var currentParagraph = ""
        var i = 0
        
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            // Handle empty lines (paragraph breaks)
            if line.isEmpty {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph))
                    currentParagraph = ""
                }
                i += 1
                continue
            }
            
            // H1 Header
            if line.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph))
                    currentParagraph = ""
                }
                let title = String(line.dropFirst(2))
                sections.append(MarkdownSection(view: AnyView(
                    Text(title)
                        .font(AppTheme.Typography.title1Font())
                        .foregroundColor(textColor ?? AppTheme.Colors.text)
                        .padding(.top, AppTheme.Layout.spacingL)
                        .padding(.bottom, AppTheme.Layout.spacingS)
                )))
                i += 1
                continue
            }
            
            // H2 Header
            if line.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph))
                    currentParagraph = ""
                }
                let title = String(line.dropFirst(3))
                sections.append(MarkdownSection(view: AnyView(
                    Text(title)
                        .font(AppTheme.Typography.title2Font())
                        .foregroundColor(textColor ?? AppTheme.Colors.text)
                        .padding(.top, AppTheme.Layout.spacingM)
                        .padding(.bottom, AppTheme.Layout.spacingXS)
                )))
                i += 1
                continue
            }
            
            // H3 Header
            if line.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph))
                    currentParagraph = ""
                }
                let title = String(line.dropFirst(4))
                sections.append(MarkdownSection(view: AnyView(
                    Text(title)
                        .font(AppTheme.Typography.title3Font())
                        .foregroundColor(textColor ?? AppTheme.Colors.text)
                        .padding(.top, AppTheme.Layout.spacingS)
                        .padding(.bottom, AppTheme.Layout.spacingXS)
                )))
                i += 1
                continue
            }
            
            // Bullet list
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph))
                    currentParagraph = ""
                }
                
                var bulletItems: [String] = []
                while i < lines.count {
                    let currentLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if currentLine.hasPrefix("- ") || currentLine.hasPrefix("* ") {
                        bulletItems.append(String(currentLine.dropFirst(2)))
                        i += 1
                    } else if currentLine.isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                
                sections.append(MarkdownSection(view: AnyView(
                    VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                        ForEach(bulletItems, id: \.self) { item in
                            HStack(alignment: .top, spacing: AppTheme.Layout.spacingS) {
                                Text("•")
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(textColor ?? AppTheme.Colors.text)
                                formatInlineText(item)
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(textColor ?? AppTheme.Colors.text)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                )))
                continue
            }
            
            // Code block
            if line.hasPrefix("```") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph))
                    currentParagraph = ""
                }
                
                i += 1  // Skip the opening ```
                var codeLines: [String] = []
                
                while i < lines.count {
                    let codeLine = lines[i]
                    if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        i += 1  // Skip the closing ```
                        break
                    }
                    codeLines.append(codeLine)
                    i += 1
                }
                
                if !codeLines.isEmpty {
                    let codeText = codeLines.joined(separator: "\n")
                    sections.append(MarkdownSection(view: AnyView(
                        Text(codeText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(textColor ?? AppTheme.Colors.text)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    )))
                }
                continue
            }
            
            // Numbered list
            if let firstChar = line.first, firstChar.isNumber, line.dropFirst().hasPrefix(". ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph))
                    currentParagraph = ""
                }
                
                var numberedItems: [(String, String)] = []
                while i < lines.count {
                    let currentLine = lines[i].trimmingCharacters(in: .whitespaces)
                    // Check if line starts with a number followed by ". "
                    if let firstChar = currentLine.first, firstChar.isNumber,
                       let dotIndex = currentLine.firstIndex(of: "."),
                       dotIndex < currentLine.endIndex {
                        let numberPart = String(currentLine[currentLine.startIndex..<dotIndex])
                        let textPart = String(currentLine[currentLine.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
                        numberedItems.append((numberPart, textPart))
                        i += 1
                    } else if currentLine.isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                
                sections.append(MarkdownSection(view: AnyView(
                    VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                        ForEach(numberedItems, id: \.0) { item in
                            HStack(alignment: .top, spacing: AppTheme.Layout.spacingS) {
                                Text("\(item.0).")
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(textColor ?? AppTheme.Colors.text)
                                formatInlineText(item.1)
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(textColor ?? AppTheme.Colors.text)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                )))
                continue
            }
            
            // Regular paragraph line
            if !currentParagraph.isEmpty {
                currentParagraph += " "
            }
            currentParagraph += line
            i += 1
        }
        
        // Add any remaining paragraph
        if !currentParagraph.isEmpty {
            sections.append(createParagraphSection(currentParagraph))
        }
        
        return sections
    }
    
    private func createParagraphSection(_ text: String) -> MarkdownSection {
        MarkdownSection(view: AnyView(
            formatInlineText(text)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(textColor ?? AppTheme.Colors.text)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
        ))
    }
    
    private func formatInlineText(_ text: String) -> Text {
        var result = Text("")
        var currentText = ""
        var i = text.startIndex
        
        while i < text.endIndex {
            // Check for bold (**text**)
            if text[i] == "*" && i < text.index(text.endIndex, offsetBy: -1) && text[text.index(after: i)] == "*" {
                // Found start of bold
                if !currentText.isEmpty {
                    result = result + Text(currentText)
                    currentText = ""
                }
                
                // Find end of bold
                var j = text.index(i, offsetBy: 2)
                var boldText = ""
                while j < text.index(text.endIndex, offsetBy: -1) {
                    if text[j] == "*" && text[text.index(after: j)] == "*" {
                        result = result + Text(boldText).bold()
                        i = text.index(j, offsetBy: 2)
                        break
                    }
                    boldText.append(text[j])
                    j = text.index(after: j)
                }
                if j >= text.index(text.endIndex, offsetBy: -1) {
                    // No closing bold found
                    currentText += "**" + boldText
                    i = j
                }
                continue
            }
            
            // Check for inline code (`code`)
            if text[i] == "`" {
                // Found start of code
                if !currentText.isEmpty {
                    result = result + Text(currentText)
                    currentText = ""
                }
                
                // Find end of code
                var j = text.index(after: i)
                var codeText = ""
                while j < text.endIndex {
                    if text[j] == "`" {
                        result = result + Text(codeText)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(textColor ?? AppTheme.Colors.text)
                        i = text.index(after: j)
                        break
                    }
                    codeText.append(text[j])
                    j = text.index(after: j)
                }
                if j >= text.endIndex {
                    // No closing backtick found
                    currentText += "`" + codeText
                    i = j
                }
                continue
            }
            
            // Check for italic (*text*)
            if text[i] == "*" {
                // Found start of italic
                if !currentText.isEmpty {
                    result = result + Text(currentText)
                    currentText = ""
                }
                
                // Find end of italic
                var j = text.index(after: i)
                var italicText = ""
                while j < text.endIndex {
                    if text[j] == "*" {
                        result = result + Text(italicText).italic()
                        i = text.index(after: j)
                        break
                    }
                    italicText.append(text[j])
                    j = text.index(after: j)
                }
                if j >= text.endIndex {
                    // No closing italic found
                    currentText += "*" + italicText
                    i = j
                }
                continue
            }
            
            currentText.append(text[i])
            i = text.index(after: i)
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            result = result + Text(currentText)
        }
        
        return result
    }
}