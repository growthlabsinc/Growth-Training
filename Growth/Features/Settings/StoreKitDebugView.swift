/**
 * StoreKitDebugView.swift
 * Growth App StoreKit Debug Information View
 *
 * Displays detailed StoreKit debugging information for troubleshooting
 * subscription loading issues in TestFlight/Production.
 */

import SwiftUI
import StoreKit

@available(iOS 15.0, *)
struct StoreKitDebugView: View {
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManager
    @EnvironmentObject private var purchaseManager: SimplifiedPurchaseManager
    @State private var debugInfo: String = "Loading debug information..."
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("StoreKit Debug Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Use this information to diagnose subscription loading issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Debug Info
                VStack(alignment: .leading, spacing: 12) {
                    // Copy button
                    Button(action: copyDebugInfo) {
                        Label("Copy Debug Info", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    // Refresh button
                    Button(action: {
                        Task {
                            await refreshDebugInfo()
                        }
                    }) {
                        Label("Refresh Debug Info", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    // Debug text
                    Text(debugInfo)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("StoreKit Debug")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDebugInfo()
        }
    }
    
    private func loadDebugInfo() async {
        await refreshDebugInfo()
    }
    
    private func refreshDebugInfo() async {
        isLoading = true
        debugInfo = await generateDebugInfo()
        isLoading = false
    }
    
    private func generateDebugInfo() async -> String {
        var info = "=== StoreKit Debug Report ===\n"
        info += "Generated: \(Date().formatted())\n\n"
        
        // Environment Info
        info += "ENVIRONMENT:\n"
        let environment = StoreKitEnvironmentHandler.shared.currentEnvironment
        info += "- Environment: \(environment.displayName)\n"
        info += "- Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")\n"
        info += "- App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")\n"
        info += "- Build Number: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")\n"
        
        // Receipt Info
        info += "\nRECEIPT:\n"
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            info += "- Receipt URL: \(receiptURL.lastPathComponent)\n"
            let receiptExists = FileManager.default.fileExists(atPath: receiptURL.path)
            info += "- Receipt Exists: \(receiptExists)\n"
            if receiptExists {
                do {
                    let receiptData = try Data(contentsOf: receiptURL)
                    info += "- Receipt Size: \(receiptData.count) bytes\n"
                } catch {
                    info += "- Receipt Read Error: \(error.localizedDescription)\n"
                }
            }
        } else {
            info += "- No receipt URL\n"
        }
        
        // Build Configuration
        info += "\nBUILD:\n"
        #if DEBUG
        info += "- Configuration: DEBUG\n"
        #else
        info += "- Configuration: RELEASE\n"
        #endif
        
        #if targetEnvironment(simulator)
        info += "- Device: Simulator\n"
        #else
        info += "- Device: Physical Device\n"
        #endif
        
        // Product IDs
        info += "\nPRODUCT IDS REQUESTED:\n"
        for productId in SubscriptionProductIDs.allProductIDs {
            info += "- \(productId)\n"
        }
        
        // Load products
        info += "\nPRODUCT LOADING:\n"
        info += "- Loading products...\n"
        
        // Force a fresh product load
        do {
            try await purchaseManager.loadProducts()
        } catch {
            info += "Failed to load products: \(error)\n"
        }
        
        // Available Products
        info += "\nAVAILABLE PRODUCTS:\n"
        if purchaseManager.products.isEmpty {
            info += "- No products loaded ❌\n"
        } else {
            info += "- Products loaded: \(purchaseManager.products.count) ✅\n"
            for product in purchaseManager.products {
                info += "  • \(product.id) - \(product.displayName) - \(product.displayPrice)\n"
            }
        }
        
        // Current Entitlements
        info += "\nCURRENT ENTITLEMENTS:\n"
        if purchaseManager.purchasedProductIDs.isEmpty {
            info += "- No active subscriptions\n"
        } else {
            info += "- Active subscriptions: \(purchaseManager.purchasedProductIDs.count)\n"
            for productID in purchaseManager.purchasedProductIDs {
                info += "  • Product: \(productID)\n"
            }
        }
        
        // StoreKit Status
        info += "\nSTOREKIT STATUS:\n"
        info += "- Can Make Payments: \(SKPaymentQueue.canMakePayments())\n"
        
        // Additional Debug Info
        info += "\nADDITIONAL INFO:\n"
        info += "- Timestamp: \(Date().timeIntervalSince1970)\n"
        info += "- Locale: \(Locale.current.identifier)\n"
        if #available(iOS 16.0, *) {
            info += "- Region: \(Locale.current.region?.identifier ?? "unknown")\n"
        } else {
            info += "- Region: \(Locale.current.regionCode ?? "unknown")\n"
        }
        
        return info
    }
    
    private func copyDebugInfo() {
        UIPasteboard.general.string = debugInfo
    }
}

@available(iOS 15.0, *)
struct StoreKitDebugView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreKitDebugView()
        }
    }
}