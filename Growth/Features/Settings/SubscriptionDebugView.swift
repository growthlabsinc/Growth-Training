//
//  SubscriptionDebugView.swift
//  Growth
//
//  Created by Growth on 1/19/25.
//

import SwiftUI

/// Debug view for monitoring subscription state
@available(iOS 15.0, *)
struct SubscriptionDebugView: View {
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManager
    @EnvironmentObject private var purchaseManager: SimplifiedPurchaseManager
    @State private var showRefreshConfirmation = false
    @State private var isRefreshing = false
    @State private var refreshError: String?
    
    var body: some View {
        List {
            Section("Current State") {
                HStack {
                    Text("Subscription Tier")
                    Spacer()
                    Text(entitlementManager.subscriptionTier.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Has Premium")
                    Spacer()
                    Text(entitlementManager.hasPremium ? "Yes" : "No")
                        .foregroundColor(entitlementManager.hasPremium ? .green : .secondary)
                }
                HStack {
                    Text("Has Any Premium Access")
                    Spacer()
                    Text(entitlementManager.hasPremium ? "Yes" : "No")
                        .foregroundColor(entitlementManager.hasPremium ? .green : .secondary)
                }
                HStack {
                    Text("Active Subscriptions")
                    Spacer()
                    Text("\(purchaseManager.purchasedProductIDs.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Available Products") {
                if purchaseManager.products.isEmpty {
                    Text("No products loaded")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(purchaseManager.products) { product in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.displayName)
                                    .font(.caption)
                                Text(product.id)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(product.displayPrice)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Purchased Product IDs") {
                if purchaseManager.purchasedProductIDs.isEmpty {
                    Text("No active purchases")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(purchaseManager.purchasedProductIDs), id: \.self) { productID in
                        HStack {
                            Text(productID)
                                .font(.caption)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            Section("Debug Actions") {
                Button("Refresh Products") {
                    Task {
                        isRefreshing = true
                        do {
                            try await purchaseManager.loadProducts()
                            await purchaseManager.updatePurchasedProducts()
                            showRefreshConfirmation = true
                        } catch {
                            refreshError = error.localizedDescription
                        }
                        isRefreshing = false
                    }
                }
                .disabled(isRefreshing)
                
                Button("Restore Purchases") {
                    Task {
                        isRefreshing = true
                        do {
                            try await purchaseManager.restorePurchases()
                            showRefreshConfirmation = true
                        } catch {
                            refreshError = error.localizedDescription
                        }
                        isRefreshing = false
                    }
                }
                .disabled(isRefreshing)
                
                Button("Reset Entitlements") {
                    entitlementManager.reset()
                    showRefreshConfirmation = true
                }
                .foregroundColor(.red)
        }
        .navigationTitle("Subscription Debug")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Action Complete", isPresented: $showRefreshConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = refreshError {
                Text("Error: \(error)")
            } else {
                Text("Products: \(purchaseManager.products.count) loaded\nPurchases: \(purchaseManager.purchasedProductIDs.count) active")
            }
        }
        .alert("Error", isPresented: .constant(refreshError != nil)) {
            Button("OK") { refreshError = nil }
        } message: {
            if let error = refreshError {
                Text(error)
            }
        }
    }
}

}
// MARK: - Preview
@available(iOS 15.0, *)
struct SubscriptionDebugView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubscriptionDebugView()
                .environmentObject(SimplifiedEntitlementManager())
                .environmentObject(SimplifiedPurchaseManager(entitlementManager: SimplifiedEntitlementManager()))
        }
    }
}
