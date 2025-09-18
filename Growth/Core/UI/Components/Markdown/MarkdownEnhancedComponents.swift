//
//  MarkdownEnhancedComponents.swift
//  Growth
//
//  Enhanced visual components for beautiful markdown rendering
//

import SwiftUI

// MARK: - Hero Image
struct MarkdownHeroImage: View {
    let imageName: String
    let title: String?
    let subtitle: String?
    let style: MarkdownStyle
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 220)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.4)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Text overlay
            VStack(alignment: .leading, spacing: 4) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.white.opacity(0.9))
                }
                
                if let title = title {
                    Text(title)
                        .font(AppTheme.Typography.gravitySemibold(28))
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Visual Banner
struct MarkdownVisualBanner: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    let style: MarkdownStyle
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacingM) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(20))
                    .foregroundColor(style.colors.text)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(style.colors.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16)
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Step Indicator
struct MarkdownStepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let title: String
    let style: MarkdownStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
            // Progress bar
            HStack(spacing: 4) {
                ForEach(1...totalSteps, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= currentStep ? AppTheme.Colors.accent : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            
            // Step info
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.accent)
                
                Spacer()
                
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(style.colors.text)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Expandable Section
struct MarkdownExpandableSection: View {
    let title: String
    let content: String
    let style: MarkdownStyle
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(style.colors.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(style.colors.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
            }
            
            // Content
            if isExpanded {
                Divider()
                
                MarkdownRenderer(content: content, style: style)
                    .padding()
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Feature Card
struct MarkdownFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let style: MarkdownStyle
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 64, height: 64)
                .background(AppTheme.Colors.accent.opacity(0.1))
                .cornerRadius(16)
            
            // Title
            Text(title)
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(style.colors.text)
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(style.colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Pull Quote
struct MarkdownPullQuote: View {
    let text: String
    let author: String?
    let style: MarkdownStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
            // Quote mark
            Text("\"")
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundColor(AppTheme.Colors.accent.opacity(0.3))
                .offset(x: -4, y: 10)
            
            // Quote text
            Text(text)
                .font(AppTheme.Typography.gravityBook(20))
                .foregroundColor(style.colors.text)
                .italic()
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
            
            // Author
            if let author = author {
                Text("— \(author)")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(style.colors.secondaryText)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .overlay(
            HStack {
                Rectangle()
                    .fill(AppTheme.Colors.accent)
                    .frame(width: 4)
                Spacer()
            }
        )
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Visual Divider
struct MarkdownVisualDivider: View {
    let style: MarkdownStyle
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacingM) {
            Rectangle()
                .fill(style.colors.secondaryText.opacity(0.2))
                .frame(height: 1)
            
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundColor(style.colors.secondaryText.opacity(0.4))
            
            Rectangle()
                .fill(style.colors.secondaryText.opacity(0.2))
                .frame(height: 1)
        }
        .frame(height: 20)
        .padding(.vertical, style.typography.paragraphSpacing / 2)
    }
}

// MARK: - Drop Cap
struct MarkdownDropCap: View {
    let letter: String
    let remainingText: String
    let style: MarkdownStyle
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Drop cap letter
            Text(letter)
                .font(.system(size: 64, weight: .bold, design: .serif))
                .foregroundColor(AppTheme.Colors.accent)
                .padding(.trailing, 8)
                .offset(y: -8)
            
            // Remaining text
            Text(remainingText)
                .font(style.typography.body)
                .foregroundColor(style.colors.text)
                .lineSpacing(style.typography.lineSpacing)
                .multilineTextAlignment(.leading)
                .offset(y: 4)
        }
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Highlighted Box
struct MarkdownHighlightedBox: View {
    let title: String?
    let content: String
    let color: Color
    let style: MarkdownStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
            if let title = title {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    
                    Text(title)
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(style.colors.text)
                }
            }
            
            Text(content)
                .font(style.typography.body)
                .foregroundColor(style.colors.text)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Progress Card
struct MarkdownProgressCard: View {
    let title: String
    let progress: Double
    let description: String?
    let style: MarkdownStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
            // Title and percentage
            HStack {
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(style.colors.text)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(AppTheme.Colors.accent)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.accent)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
            
            // Description
            if let description = description {
                Text(description)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(style.colors.secondaryText)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Video Embed
import AVKit

struct MarkdownVideoEmbed: View {
    let url: String
    let title: String?
    let aspectRatio: CGFloat
    let style: MarkdownStyle
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showControls = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            if let title = title {
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(style.colors.text)
                    .padding(.bottom, AppTheme.Layout.spacingS)
            }
            
            // Video player
            GeometryReader { geometry in
                ZStack {
                    // Video player
                    if let player = player {
                        VideoPlayer(player: player)
                            .aspectRatio(aspectRatio, contentMode: .fit)
                            .cornerRadius(12)
                    } else {
                        // Placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.1))
                            
                            VStack(spacing: AppTheme.Layout.spacingM) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color.gray.opacity(0.5))
                                
                                if url.contains("youtube.com") || url.contains("youtu.be") {
                                    Text("YouTube videos open in browser")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(style.colors.secondaryText)
                                    
                                    Button {
                                        openInBrowser()
                                    } label: {
                                        Text("Watch on YouTube")
                                            .font(AppTheme.Typography.gravitySemibold(14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.red)
                                            .cornerRadius(20)
                                    }
                                } else {
                                    Text("Loading video...")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(style.colors.secondaryText)
                                }
                            }
                        }
                        .aspectRatio(aspectRatio, contentMode: .fit)
                    }
                }
            }
            .aspectRatio(aspectRatio, contentMode: .fit)
            .background(Color.black)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .padding(.bottom, style.typography.paragraphSpacing)
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        // Handle YouTube URLs differently
        if url.contains("youtube.com") || url.contains("youtu.be") {
            // YouTube videos need to be opened in browser or use YouTube player
            return
        }
        
        // Load regular video URLs
        if let videoURL = URL(string: url) {
            player = AVPlayer(url: videoURL)
        }
    }
    
    private func openInBrowser() {
        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Video Thumbnail
struct MarkdownVideoThumbnail: View {
    let thumbnailURL: String
    let videoURL: String
    let title: String?
    let duration: String?
    let style: MarkdownStyle
    @State private var isPressed = false
    
    var body: some View {
        Button {
            if let url = URL(string: videoURL) {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail with play button overlay
                ZStack {
                    // Thumbnail image
                    AsyncImage(url: URL(string: thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(16/9, contentMode: .fill)
                    }
                    .clipped()
                    
                    // Dark overlay
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                    
                    // Play button
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .offset(x: 2) // Slight offset for visual balance
                    }
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    
                    // Duration badge
                    if let duration = duration {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(duration)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                                    .padding(8)
                            }
                        }
                    }
                }
                .cornerRadius(12)
                
                // Title
                if let title = title {
                    Text(title)
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(style.colors.text)
                        .multilineTextAlignment(.leading)
                        .padding(.top, AppTheme.Layout.spacingS)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}