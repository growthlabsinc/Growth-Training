/**
 * CustomRoutinesPremiumGateView.swift
 * Premium Gate for Custom Routines Feature
 *
 * Displays when user attempts to save a custom routine without premium access.
 * Uses app-consistent styling with Growth brand colors and design patterns.
 */

import SwiftUI

struct CustomRoutinesPremiumGateView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingPaywall = false

    private let benefits = [
        "Create unlimited custom routines",
        "Customize every aspect of your practice",
        "Schedule routines across multiple weeks",
        "Share your routines with the community",
        "Access all premium features"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Lock Icon with Gradient Background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("GrowthGreen").opacity(0.2), Color("BrightTeal").opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                    .padding(.top, 40)

                    // Title
                    VStack(spacing: 12) {
                        Text("Custom Routines")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Premium Feature")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("GrowthGreen"))
                    }

                    // Description
                    Text("Unlock the ability to create personalized practice routines tailored to your needs.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Benefits List
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(benefits, id: \.self) { benefit in
                            BenefitRow(benefit: benefit)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)

                    // Upgrade Button
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                            Text("Upgrade to Premium")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
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
                        .cornerRadius(16)
                        .shadow(color: Color("GrowthGreen").opacity(0.4), radius: 12, y: 6)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            StoreKit2PaywallView()
        }
    }
}

// MARK: - Supporting Views

private struct BenefitRow: View {
    let benefit: String

    var body: some View {
        HStack(spacing: 16) {
            // Checkmark Circle
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen").opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("GrowthGreen"))
            }

            Text(benefit)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

struct CustomRoutinesPremiumGateView_Previews: PreviewProvider {
    static var previews: some View {
        CustomRoutinesPremiumGateView()
    }
}