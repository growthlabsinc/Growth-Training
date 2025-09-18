/**
 * SocialProofSection.swift
 * Growth App Social Proof Components
 *
 * Displays user testimonials, statistics, and social validation
 * to increase paywall conversion rates.
 */

import SwiftUI

/// Social proof section for paywall conversion optimization
struct SocialProofSection: View {
    
    @State private var currentTestimonialIndex = 0
    @State private var showStatistics = false
    
    private let testimonials = [
        Testimonial(
            quote: "The AI Coach completely transformed my practice. I've never been more consistent!",
            author: "Sarah M.",
            feature: .aiCoach
        ),
        Testimonial(
            quote: "Custom routines helped me create the perfect workflow. Highly recommend!",
            author: "Alex K.",
            feature: .customRoutines
        ),
        Testimonial(
            quote: "The progress tracking keeps me motivated every single day.",
            author: "Jordan L.",
            feature: .progressTracking
        )
    ]
    
    private let statistics = [
        Statistic(value: "10,000+", label: "Happy Users"),
        Statistic(value: "85%", label: "Report Improved Focus"),
        Statistic(value: "4.8★", label: "App Store Rating")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Statistics Row
            statisticsRow
            
            // Testimonial Carousel
            testimonialCarousel
        }
        .onAppear {
            startTestimonialTimer()
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                showStatistics = true
            }
        }
    }
    
    // MARK: - Statistics Row
    
    private var statisticsRow: some View {
        HStack {
            ForEach(Array(statistics.enumerated()), id: \.offset) { index, stat in
                VStack(spacing: 4) {
                    Text(stat.value)
                        .font(AppTheme.Typography.gravityBoldFont(20))
                        .foregroundColor(Color("GrowthGreen"))
                        .scaleEffect(showStatistics ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: showStatistics)
                    
                    Text(stat.label)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.center)
                        .opacity(showStatistics ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1 + 0.2), value: showStatistics)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Testimonial Carousel
    
    private var testimonialCarousel: some View {
        VStack(spacing: 16) {
            // Testimonial Card
            TestimonialCard(testimonial: testimonials[currentTestimonialIndex])
                .id(currentTestimonialIndex) // Force view update on index change
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            
            // Carousel Indicators
            HStack(spacing: 8) {
                ForEach(testimonials.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentTestimonialIndex ? Color("GrowthGreen") : Color("TextSecondaryColor").opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentTestimonialIndex ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentTestimonialIndex)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startTestimonialTimer() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentTestimonialIndex = (currentTestimonialIndex + 1) % testimonials.count
            }
        }
    }
}

// MARK: - Testimonial Card

struct TestimonialCard: View {
    let testimonial: Testimonial
    
    var body: some View {
        VStack(spacing: 12) {
            // Feature Icon
            ZStack {
                Circle()
                    .fill(featureColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: featureIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(featureColor)
            }
            
            // Quote
            Text("\"\(testimonial.quote)\"")
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // Author
            Text("— \(testimonial.author)")
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(featureColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var featureColor: Color {
        switch testimonial.feature {
        case .aiCoach:
            return Color("GrowthBlue")
        case .customRoutines:
            return Color("GrowthGreen")
        case .progressTracking:
            return Color.orange
        default:
            return Color("GrowthGreen")
        }
    }
    
    private var featureIcon: String {
        switch testimonial.feature {
        case .aiCoach:
            return "brain.head.profile"
        case .customRoutines:
            return "list.bullet.rectangle"
        case .progressTracking:
            return "chart.line.uptrend.xyaxis"
        default:
            return "star.fill"
        }
    }
}

// MARK: - Data Models

struct Testimonial {
    let quote: String
    let author: String
    let feature: FeatureType
}

struct Statistic {
    let value: String
    let label: String
}

// MARK: - Preview
#Preview {
    SocialProofSection()
        .padding()
        .background(Color(.systemGroupedBackground))
}