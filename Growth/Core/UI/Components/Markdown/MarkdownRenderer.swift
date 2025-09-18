//
//  MarkdownRenderer.swift
//  Growth
//
//  Created by Claude on 6/25/25.
//

import SwiftUI

/// A comprehensive markdown renderer that supports various markdown elements with consistent styling
struct MarkdownRenderer: View {
    let content: String
    let style: MarkdownStyle
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var renderedSections: [MarkdownSection] = []
    
    init(content: String, fontSize: CGFloat = AppTheme.Typography.body) {
        self.content = content
        self.style = MarkdownStyle.scaled(fontSize: fontSize, colorScheme: .light)
    }
    
    init(content: String, style: MarkdownStyle) {
        self.content = content
        self.style = style
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(renderedSections) { section in
                section.view
            }
        }
        .padding(style.layout.contentPadding)
        .onAppear {
            renderedSections = parseMarkdown(content)
        }
        .onChange(of: content) { newValue in
            renderedSections = parseMarkdown(newValue)
        }
        .onChange(of: colorScheme) { _ in
            // Re-render with updated color scheme
            renderedSections = parseMarkdown(content)
        }
    }
    
    // MARK: - Markdown Parsing
    private func parseMarkdown(_ text: String) -> [MarkdownSection] {
        var sections: [MarkdownSection] = []
        let lines = text.components(separatedBy: "\n")
        var currentParagraph = ""
        var i = 0
        
        // Use the existing style, just update it for the current color scheme if needed
        let currentStyle = style
        
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            // Handle empty lines (paragraph breaks)
            if line.isEmpty {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                i += 1
                continue
            }
            
            // Headers
            if line.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                sections.append(createHeaderSection(String(line.dropFirst(4)), level: 3, style: currentStyle))
                i += 1
                continue
            } else if line.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                sections.append(createHeaderSection(String(line.dropFirst(3)), level: 2, style: currentStyle))
                i += 1
                continue
            } else if line.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                sections.append(createHeaderSection(String(line.dropFirst(2)), level: 1, style: currentStyle))
                i += 1
                continue
            }
            
            // Enhanced components
            if let enhancedComponent = detectEnhancedComponent(line) {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                let (component, nextIndex) = parseEnhancedComponent(enhancedComponent, from: lines, startingAt: i, style: currentStyle)
                sections.append(component)
                i = nextIndex
                continue
            }
            
            // Special blocks
            if let blockType = detectSpecialBlock(line) {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                let (blockContent, nextIndex) = extractBlockContent(from: lines, startingAt: i)
                sections.append(createSpecialBlock(blockContent, type: blockType, style: currentStyle))
                i = nextIndex
                continue
            }
            
            // Checklist
            if line.hasPrefix("- [ ]") || line.hasPrefix("- [x]") || line.hasPrefix("- [X]") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                let (checklistItems, nextIndex) = extractChecklist(from: lines, startingAt: i)
                sections.append(createInteractiveChecklist(checklistItems, style: currentStyle))
                i = nextIndex
                continue
            }
            
            // Bullet lists
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                let (listItems, nextIndex) = extractBulletList(from: lines, startingAt: i)
                sections.append(createBulletList(listItems, style: currentStyle))
                i = nextIndex
                continue
            }
            
            // Numbered lists
            if let firstChar = line.first, firstChar.isNumber, line.dropFirst().hasPrefix(". ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                let (listItems, nextIndex) = extractNumberedList(from: lines, startingAt: i)
                sections.append(createNumberedList(listItems, style: currentStyle))
                i = nextIndex
                continue
            }
            
            // Code blocks
            if line.hasPrefix("```") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                let (codeContent, language, nextIndex) = extractCodeBlock(from: lines, startingAt: i)
                sections.append(createCodeBlock(codeContent, language: language, style: currentStyle))
                i = nextIndex
                continue
            }
            
            // Block quotes
            if line.hasPrefix("> ") {
                if !currentParagraph.isEmpty {
                    sections.append(createParagraphSection(currentParagraph, style: currentStyle))
                    currentParagraph = ""
                }
                let (quoteContent, nextIndex) = extractBlockQuote(from: lines, startingAt: i)
                sections.append(createBlockQuote(quoteContent, style: currentStyle))
                i = nextIndex
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
            sections.append(createParagraphSection(currentParagraph, style: currentStyle))
        }
        
        return sections
    }
    
    // MARK: - Section Creation
    private func createHeaderSection(_ text: String, level: Int, style: MarkdownStyle) -> MarkdownSection {
        let font: Font
        let topSpacing: CGFloat
        
        switch level {
        case 1:
            font = style.typography.h1
            topSpacing = style.typography.h1TopSpacing
        case 2:
            font = style.typography.h2
            topSpacing = style.typography.h2TopSpacing
        default:
            font = style.typography.h3
            topSpacing = style.typography.h3TopSpacing
        }
        
        return MarkdownSection(view: AnyView(
            Text(text)
                .font(font)
                .foregroundColor(style.colors.text)
                .padding(.top, topSpacing)
                .padding(.bottom, AppTheme.Layout.spacingXS)
        ))
    }
    
    private func createParagraphSection(_ text: String, style: MarkdownStyle) -> MarkdownSection {
        MarkdownSection(view: AnyView(
            formatInlineText(text, style: style)
                .font(style.typography.body)
                .foregroundColor(style.colors.text)
                .lineSpacing(style.typography.lineSpacing)
                .multilineTextAlignment(.leading)
                .padding(.bottom, style.typography.paragraphSpacing)
        ))
    }
    
    private func createBulletList(_ items: [String], style: MarkdownStyle) -> MarkdownSection {
        MarkdownSection(view: AnyView(
            VStack(alignment: .leading, spacing: style.typography.listItemSpacing) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: AppTheme.Layout.spacingS) {
                        Text("•")
                            .font(style.typography.body)
                            .foregroundColor(style.colors.text)
                        formatInlineText(item, style: style)
                            .font(style.typography.body)
                            .foregroundColor(style.colors.text)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.leading, style.layout.listIndentation)
            .padding(.bottom, style.typography.paragraphSpacing)
        ))
    }
    
    private func createNumberedList(_ items: [(String, String)], style: MarkdownStyle) -> MarkdownSection {
        MarkdownSection(view: AnyView(
            VStack(alignment: .leading, spacing: style.typography.listItemSpacing) {
                ForEach(items, id: \.0) { item in
                    HStack(alignment: .top, spacing: AppTheme.Layout.spacingS) {
                        Text("\(item.0).")
                            .font(style.typography.body)
                            .foregroundColor(style.colors.text)
                            .frame(minWidth: 20, alignment: .trailing)
                        formatInlineText(item.1, style: style)
                            .font(style.typography.body)
                            .foregroundColor(style.colors.text)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.leading, style.layout.listIndentation)
            .padding(.bottom, style.typography.paragraphSpacing)
        ))
    }
    
    private func createCodeBlock(_ code: String, language: String?, style: MarkdownStyle) -> MarkdownSection {
        MarkdownSection(view: AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(style.typography.code)
                    .foregroundColor(style.colors.text)
                    .padding(style.layout.codeBlockPadding)
            }
            .frame(maxWidth: .infinity)
            .background(style.colors.codeBackground)
            .overlay(
                RoundedRectangle(cornerRadius: style.layout.codeCornerRadius)
                    .stroke(style.colors.codeBorder, lineWidth: 1)
            )
            .cornerRadius(style.layout.codeCornerRadius)
            .padding(.bottom, style.typography.paragraphSpacing)
        ))
    }
    
    private func createBlockQuote(_ text: String, style: MarkdownStyle) -> MarkdownSection {
        MarkdownSection(view: AnyView(
            HStack(spacing: 0) {
                Rectangle()
                    .fill(style.colors.secondaryText.opacity(0.3))
                    .frame(width: 4)
                
                formatInlineText(text, style: style)
                    .font(style.typography.body.italic())
                    .foregroundColor(style.colors.secondaryText)
                    .padding(.leading, AppTheme.Layout.spacingM)
                    .padding(.vertical, AppTheme.Layout.spacingS)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, style.typography.paragraphSpacing)
        ))
    }
    
    private func createSpecialBlock(_ content: String, type: MarkdownBlockType, style: MarkdownStyle) -> MarkdownSection {
        MarkdownSection(view: AnyView(
            HStack(alignment: .top, spacing: AppTheme.Layout.spacingM) {
                Image(systemName: type.icon)
                    .font(style.typography.body)
                    .foregroundColor(type.iconColor(from: style))
                
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                    Text(type.title)
                        .font(style.typography.body.weight(.semibold))
                        .foregroundColor(style.colors.text)
                    
                    formatInlineText(content, style: style)
                        .font(style.typography.body)
                        .foregroundColor(style.colors.text)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(style.layout.blockPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(type.backgroundColor(from: style))
            .overlay(
                RoundedRectangle(cornerRadius: style.layout.blockCornerRadius)
                    .stroke(type.borderColor(from: style), lineWidth: 1)
            )
            .cornerRadius(style.layout.blockCornerRadius)
            .padding(.bottom, style.typography.paragraphSpacing)
        ))
    }
    
    // MARK: - Inline Text Formatting
    private func formatInlineText(_ text: String, style: MarkdownStyle) -> Text {
        var result = Text("")
        var currentText = ""
        var i = text.startIndex
        
        while i < text.endIndex {
            // Check for bold (**text**)
            if text[i] == "*" && i < text.index(text.endIndex, offsetBy: -1) && text[text.index(after: i)] == "*" {
                if !currentText.isEmpty {
                    result = result + Text(currentText)
                    currentText = ""
                }
                
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
                    currentText += "**" + boldText
                    i = j
                }
                continue
            }
            
            // Check for italic (*text* or _text_)
            if (text[i] == "*" || text[i] == "_") && i < text.index(text.endIndex, offsetBy: -1) {
                let delimiter = text[i]
                if !currentText.isEmpty {
                    result = result + Text(currentText)
                    currentText = ""
                }
                
                var j = text.index(after: i)
                var italicText = ""
                while j < text.endIndex {
                    if text[j] == delimiter {
                        result = result + Text(italicText).italic()
                        i = text.index(after: j)
                        break
                    }
                    italicText.append(text[j])
                    j = text.index(after: j)
                }
                if j >= text.endIndex {
                    currentText += String(delimiter) + italicText
                    i = j
                }
                continue
            }
            
            // Check for inline code (`code`)
            if text[i] == "`" {
                if !currentText.isEmpty {
                    result = result + Text(currentText)
                    currentText = ""
                }
                
                var j = text.index(after: i)
                var codeText = ""
                while j < text.endIndex {
                    if text[j] == "`" {
                        result = result + Text(codeText)
                            .font(style.typography.code)
                            .foregroundColor(style.colors.text)
                        i = text.index(after: j)
                        break
                    }
                    codeText.append(text[j])
                    j = text.index(after: j)
                }
                if j >= text.endIndex {
                    currentText += "`" + codeText
                    i = j
                }
                continue
            }
            
            // Check for links [text](url)
            if text[i] == "[" {
                if !currentText.isEmpty {
                    result = result + Text(currentText)
                    currentText = ""
                }
                
                if let linkResult = extractLink(from: text, startingAt: i) {
                    result = result + Text(linkResult.text)
                        .foregroundColor(style.colors.link)
                        .underline()
                    i = linkResult.endIndex
                    continue
                }
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
    
    // MARK: - Helper Methods
    private enum EnhancedComponentType {
        case hero
        case banner
        case step
        case expandable
        case featureCard
        case pullQuote
        case divider
        case dropCap
        case highlight
        case progress
        case video
        case videoThumbnail
    }
    
    private func detectEnhancedComponent(_ line: String) -> EnhancedComponentType? {
        if line.hasPrefix("![hero]") {
            return .hero
        } else if line.hasPrefix("![banner]") {
            return .banner
        } else if line.hasPrefix("![step]") {
            return .step
        } else if line.hasPrefix("![expandable]") {
            return .expandable
        } else if line.hasPrefix("![feature]") {
            return .featureCard
        } else if line.hasPrefix("![quote]") {
            return .pullQuote
        } else if line == "---" || line == "***" || line == "* * *" {
            return .divider
        } else if line.hasPrefix("![dropcap]") {
            return .dropCap
        } else if line.hasPrefix("![highlight]") {
            return .highlight
        } else if line.hasPrefix("![progress]") {
            return .progress
        } else if line.hasPrefix("![video]") {
            return .video
        } else if line.hasPrefix("![video-thumbnail]") {
            return .videoThumbnail
        }
        return nil
    }
    
    private func parseEnhancedComponent(_ type: EnhancedComponentType, from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        switch type {
        case .hero:
            return parseHeroImage(from: lines, startingAt: index, style: style)
        case .banner:
            return parseVisualBanner(from: lines, startingAt: index, style: style)
        case .step:
            return parseStepIndicator(from: lines, startingAt: index, style: style)
        case .expandable:
            return parseExpandableSection(from: lines, startingAt: index, style: style)
        case .featureCard:
            return parseFeatureCard(from: lines, startingAt: index, style: style)
        case .pullQuote:
            return parsePullQuote(from: lines, startingAt: index, style: style)
        case .divider:
            return (createVisualDivider(style: style), index + 1)
        case .dropCap:
            return parseDropCap(from: lines, startingAt: index, style: style)
        case .highlight:
            return parseHighlightBox(from: lines, startingAt: index, style: style)
        case .progress:
            return parseProgressCard(from: lines, startingAt: index, style: style)
        case .video:
            return parseVideoEmbed(from: lines, startingAt: index, style: style)
        case .videoThumbnail:
            return parseVideoThumbnail(from: lines, startingAt: index, style: style)
        }
    }
    
    private func parseHeroImage(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![hero](imageName, title, subtitle)
        let line = lines[index]
        if let match = line.range(of: #"!\[hero\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(8).dropLast(1)
            let components = params.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            let imageName = components.count > 0 ? components[0] : "placeholder"
            let title = components.count > 1 ? components[1] : nil
            let subtitle = components.count > 2 ? components[2] : nil
            
            return (MarkdownSection(view: AnyView(
                MarkdownHeroImage(
                    imageName: imageName,
                    title: title,
                    subtitle: subtitle,
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func parseVisualBanner(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![banner](icon, title, subtitle, color)
        let line = lines[index]
        if let match = line.range(of: #"!\[banner\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(9).dropLast(1)
            let components = params.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            let icon = components.count > 0 ? components[0] : "star.fill"
            let title = components.count > 1 ? components[1] : "Banner"
            let subtitle = components.count > 2 ? components[2] : nil
            let colorName = components.count > 3 ? components[3] : "blue"
            
            let color: Color = {
                switch colorName.lowercased() {
                case "green": return AppTheme.Colors.success
                case "red": return .red
                case "yellow": return .yellow
                case "purple": return .purple
                default: return AppTheme.Colors.accent
                }
            }()
            
            return (MarkdownSection(view: AnyView(
                MarkdownVisualBanner(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    color: color,
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func parseStepIndicator(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![step](current, total, title)
        let line = lines[index]
        if let match = line.range(of: #"!\[step\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(7).dropLast(1)
            let components = params.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            let current = Int(components.count > 0 ? components[0] : "1") ?? 1
            let total = Int(components.count > 1 ? components[1] : "3") ?? 3
            let title = components.count > 2 ? components[2] : "Step"
            
            return (MarkdownSection(view: AnyView(
                MarkdownStepIndicator(
                    currentStep: current,
                    totalSteps: total,
                    title: title,
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func parseExpandableSection(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![expandable](title)
        // Content on following lines until empty line
        let line = lines[index]
        if let match = line.range(of: #"!\[expandable\]\((.*?)\)"#, options: .regularExpression) {
            let title = String(line[match]).dropFirst(13).dropLast(1).trimmingCharacters(in: .whitespaces)
            
            var contentLines: [String] = []
            var i = index + 1
            while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                contentLines.append(lines[i])
                i += 1
            }
            
            let content = contentLines.joined(separator: "\n")
            
            return (MarkdownSection(view: AnyView(
                MarkdownExpandableSection(
                    title: title,
                    content: content,
                    style: style
                )
            )), i)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func parseFeatureCard(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![feature](icon, title, description)
        let line = lines[index]
        if let match = line.range(of: #"!\[feature\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(10).dropLast(1)
            let components = params.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            let icon = components.count > 0 ? components[0] : "star.fill"
            let title = components.count > 1 ? components[1] : "Feature"
            let description = components.count > 2 ? components[2] : ""
            
            return (MarkdownSection(view: AnyView(
                MarkdownFeatureCard(
                    icon: icon,
                    title: title,
                    description: description,
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func parsePullQuote(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![quote](text, author)
        let line = lines[index]
        if let match = line.range(of: #"!\[quote\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(8).dropLast(1)
            let components = params.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            
            let text = components.count > 0 ? components[0] : ""
            let author = components.count > 1 ? components[1] : nil
            
            return (MarkdownSection(view: AnyView(
                MarkdownPullQuote(
                    text: text,
                    author: author,
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func createVisualDivider(style: MarkdownStyle) -> MarkdownSection {
        MarkdownSection(view: AnyView(MarkdownVisualDivider(style: style)))
    }
    
    private func parseDropCap(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![dropcap]
        // Following line contains the paragraph
        if index + 1 < lines.count {
            let paragraph = lines[index + 1]
            if !paragraph.isEmpty {
                let firstLetter = String(paragraph.prefix(1))
                let remainingText = String(paragraph.dropFirst())
                
                return (MarkdownSection(view: AnyView(
                    MarkdownDropCap(
                        letter: firstLetter,
                        remainingText: remainingText,
                        style: style
                    )
                )), index + 2)
            }
        }
        return (createParagraphSection(lines[index], style: style), index + 1)
    }
    
    private func parseHighlightBox(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![highlight](title, content, color)
        let line = lines[index]
        if let match = line.range(of: #"!\[highlight\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(12).dropLast(1)
            let components = params.split(separator: ",", maxSplits: 2).map { $0.trimmingCharacters(in: .whitespaces) }
            
            let title = components.count > 0 ? components[0] : nil
            let content = components.count > 1 ? components[1] : ""
            let colorName = components.count > 2 ? components[2] : "blue"
            
            let color: Color = {
                switch colorName.lowercased() {
                case "green": return AppTheme.Colors.success
                case "red": return .red
                case "yellow": return .yellow
                case "purple": return .purple
                default: return AppTheme.Colors.accent
                }
            }()
            
            return (MarkdownSection(view: AnyView(
                MarkdownHighlightedBox(
                    title: title == "null" ? nil : title,
                    content: content,
                    color: color,
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func parseProgressCard(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![progress](title, percentage, description)
        let line = lines[index]
        if let match = line.range(of: #"!\[progress\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(11).dropLast(1)
            let components = params.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            let title = components.count > 0 ? components[0] : "Progress"
            let progress = Double(components.count > 1 ? components[1] : "0") ?? 0
            let description = components.count > 2 ? components[2] : nil
            
            return (MarkdownSection(view: AnyView(
                MarkdownProgressCard(
                    title: title,
                    progress: progress / 100.0,
                    description: description,
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func parseVideoEmbed(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![video](url, title, aspectRatio)
        let line = lines[index]
        if let match = line.range(of: #"!\[video\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(8).dropLast(1)
            let components = params.split(separator: ",", maxSplits: 2).map { $0.trimmingCharacters(in: .whitespaces) }
            
            let url = components.count > 0 ? components[0] : ""
            let title = components.count > 1 ? components[1] : nil
            let aspectRatio = Double(components.count > 2 ? components[2] : "1.778") ?? 16/9 // Default to 16:9
            
            return (MarkdownSection(view: AnyView(
                MarkdownVideoEmbed(
                    url: url,
                    title: title == "null" ? nil : title,
                    aspectRatio: CGFloat(aspectRatio),
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func parseVideoThumbnail(from lines: [String], startingAt index: Int, style: MarkdownStyle) -> (MarkdownSection, Int) {
        // Format: ![video-thumbnail](thumbnailURL, videoURL, title, duration)
        let line = lines[index]
        if let match = line.range(of: #"!\[video-thumbnail\]\((.*?)\)"#, options: .regularExpression) {
            let params = String(line[match]).dropFirst(19).dropLast(1)
            let components = params.split(separator: ",", maxSplits: 3).map { $0.trimmingCharacters(in: .whitespaces) }
            
            let thumbnailURL = components.count > 0 ? components[0] : ""
            let videoURL = components.count > 1 ? components[1] : ""
            let title = components.count > 2 ? components[2] : nil
            let duration = components.count > 3 ? components[3] : nil
            
            return (MarkdownSection(view: AnyView(
                MarkdownVideoThumbnail(
                    thumbnailURL: thumbnailURL,
                    videoURL: videoURL,
                    title: title == "null" ? nil : title,
                    duration: duration == "null" ? nil : duration,
                    style: style
                )
            )), index + 1)
        }
        return (createParagraphSection(line, style: style), index + 1)
    }
    
    private func detectSpecialBlock(_ line: String) -> MarkdownBlockType? {
        if line.hasPrefix("💡") || line.lowercased().hasPrefix("**tip**:") {
            return .tip
        } else if line.hasPrefix("⚠️") || line.lowercased().hasPrefix("**warning**:") {
            return .warning
        } else if line.hasPrefix("ℹ️") || line.lowercased().hasPrefix("**info**:") {
            return .info
        } else if line.hasPrefix("✅") || line.lowercased().hasPrefix("**success**:") {
            return .success
        } else if line.lowercased().hasPrefix("**note**:") {
            return .note
        }
        return nil
    }
    
    private func extractBlockContent(from lines: [String], startingAt index: Int) -> (String, Int) {
        let line = lines[index]
        var content = ""
        
        // Extract content from the same line
        if line.contains(":") {
            content = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        } else {
            // Remove emoji or prefix
            content = line.replacingOccurrences(of: "💡", with: "")
                .replacingOccurrences(of: "⚠️", with: "")
                .replacingOccurrences(of: "ℹ️", with: "")
                .replacingOccurrences(of: "✅", with: "")
                .replacingOccurrences(of: "**Tip**:", with: "")
                .replacingOccurrences(of: "**Warning**:", with: "")
                .replacingOccurrences(of: "**Info**:", with: "")
                .replacingOccurrences(of: "**Success**:", with: "")
                .replacingOccurrences(of: "**Note**:", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        
        return (content, index + 1)
    }
    
    private func extractChecklist(from lines: [String], startingAt index: Int) -> ([(String, Bool)], Int) {
        var items: [(String, Bool)] = []
        var i = index
        
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("- [ ]") {
                let text = String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))
                items.append((text, false))
                i += 1
            } else if line.hasPrefix("- [x]") || line.hasPrefix("- [X]") {
                let text = String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))
                items.append((text, true))
                i += 1
            } else if line.isEmpty {
                i += 1
                break
            } else {
                break
            }
        }
        
        return (items, i)
    }
    
    private func createInteractiveChecklist(_ items: [(String, Bool)], style: MarkdownStyle) -> MarkdownSection {
        MarkdownSection(view: AnyView(
            MarkdownInteractiveChecklist(items: items, style: style)
        ))
    }
    
    private func extractBulletList(from lines: [String], startingAt index: Int) -> ([String], Int) {
        var items: [String] = []
        var i = index
        
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
                items.append(String(line.dropFirst(2).trimmingCharacters(in: .whitespaces)))
                i += 1
            } else if line.isEmpty {
                i += 1
                break
            } else {
                break
            }
        }
        
        return (items, i)
    }
    
    private func extractNumberedList(from lines: [String], startingAt index: Int) -> ([(String, String)], Int) {
        var items: [(String, String)] = []
        var i = index
        
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            // Check if line starts with a number followed by ". "
            if let firstChar = line.first, firstChar.isNumber,
               let dotIndex = line.firstIndex(of: "."),
               dotIndex < line.endIndex {
                let numberPart = String(line[line.startIndex..<dotIndex])
                let textPart = String(line[line.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
                items.append((numberPart, textPart))
                i += 1
            } else if line.isEmpty {
                i += 1
                break
            } else {
                break
            }
        }
        
        return (items, i)
    }
    
    private func extractCodeBlock(from lines: [String], startingAt index: Int) -> (String, String?, Int) {
        var i = index + 1
        var codeLines: [String] = []
        var language: String?
        
        // Extract language if specified
        let firstLine = lines[index].trimmingCharacters(in: .whitespaces)
        if firstLine.count > 3 {
            language = String(firstLine.dropFirst(3))
        }
        
        while i < lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                i += 1
                break
            }
            codeLines.append(line)
            i += 1
        }
        
        return (codeLines.joined(separator: "\n"), language, i)
    }
    
    private func extractBlockQuote(from lines: [String], startingAt index: Int) -> (String, Int) {
        var quoteLines: [String] = []
        var i = index
        
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("> ") {
                quoteLines.append(String(line.dropFirst(2)))
                i += 1
            } else if line.isEmpty {
                i += 1
                break
            } else {
                break
            }
        }
        
        return (quoteLines.joined(separator: " "), i)
    }
    
    private func extractLink(from text: String, startingAt index: String.Index) -> (text: String, url: String, endIndex: String.Index)? {
        var i = text.index(after: index)
        var linkText = ""
        
        // Extract link text
        while i < text.endIndex {
            if text[i] == "]" {
                i = text.index(after: i)
                break
            }
            linkText.append(text[i])
            i = text.index(after: i)
        }
        
        // Check for opening parenthesis
        guard i < text.endIndex, text[i] == "(" else {
            return nil
        }
        i = text.index(after: i)
        
        // Extract URL
        var url = ""
        while i < text.endIndex {
            if text[i] == ")" {
                i = text.index(after: i)
                return (linkText, url, i)
            }
            url.append(text[i])
            i = text.index(after: i)
        }
        
        return nil
    }
}

// MARK: - Markdown Section
private struct MarkdownSection: Identifiable {
    let id = UUID()
    let view: AnyView
}

// MARK: - Preview Helper
struct MarkdownRenderer_Previews: PreviewProvider {
    static let sampleMarkdown = """
    # Welcome to Growth
    
    This is a **comprehensive** guide to using the Growth app effectively.
    
    ## Getting Started
    
    Follow these steps to begin your journey:
    
    1. Complete your profile
    2. Choose your first routine
    3. Take initial measurements
    
    ### Important Tips
    
    💡 **Tip**: Always warm up before starting any session.
    
    ⚠️ **Warning**: Stop immediately if you experience any discomfort.
    
    ## Code Example
    
    Here's how to use inline `code` in your text.
    
    ```swift
    let growth = "continuous improvement"
    print(growth)
    ```
    
    > "The journey of a thousand miles begins with a single step."
    
    ### Features
    
    - Smart progress tracking
    - AI-powered coaching
    - Customizable routines
    - Privacy-first design
    
    For more information, visit [our website](https://growth.app).
    """
    
    static var previews: some View {
        ScrollView {
            MarkdownRenderer(content: sampleMarkdown)
                .padding()
        }
    }
}