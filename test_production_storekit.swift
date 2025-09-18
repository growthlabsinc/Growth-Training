// Simple StoreKit test following Apple's recommended pattern
// Run this in the "Growth Production" scheme on physical device

import StoreKit
import SwiftUI

@MainActor
class SimpleStoreTest: ObservableObject {
    @Published var products: [Product] = []
    @Published var status: String = "Loading..."
    
    private let productIDs: Set<String> = [
        "com.growthlabs.growthmethod.subscription.premium.weekly",
        "com.growthlabs.growthmethod.subscription.premium.quarterly", 
        "com.growthlabs.growthmethod.subscription.premium.yearly"
    ]
    
    init() {
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        print("🧪 Simple StoreKit Test - Loading products...")
        print("🧪 Environment: Physical Device")
        print("🧪 Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("🧪 Product IDs: \(productIDs)")
        
        do {
            // This is the exact same call as in your main app
            let loadedProducts = try await Product.products(for: productIDs)
            
            await MainActor.run {
                self.products = loadedProducts
                
                if loadedProducts.isEmpty {
                    status = "❌ No products loaded"
                    print("🧪 FAIL: No products returned")
                    print("🧪 Check:")
                    print("🧪 1. Using 'Growth Production' scheme?")
                    print("🧪 2. Products approved in App Store Connect?")
                    print("🧪 3. Bundle ID matches exactly?")
                } else {
                    status = "✅ Loaded \(loadedProducts.count) products"
                    print("🧪 SUCCESS: Loaded \(loadedProducts.count) products!")
                    
                    for product in loadedProducts {
                        print("🧪 Product: \(product.id)")
                        print("🧪   Name: \(product.displayName)")
                        print("🧪   Price: \(product.displayPrice)")
                    }
                }
            }
        } catch {
            await MainActor.run {
                status = "❌ Error: \(error.localizedDescription)"
                print("🧪 ERROR: \(error)")
            }
        }
    }
}

struct SimpleStoreTestView: View {
    @StateObject private var store = SimpleStoreTest()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Simple StoreKit Test")
                .font(.title)
            
            Text(store.status)
                .foregroundColor(store.products.isEmpty ? .red : .green)
            
            if !store.products.isEmpty {
                ForEach(store.products, id: \.id) { product in
                    VStack(alignment: .leading) {
                        Text(product.displayName)
                            .font(.headline)
                        Text(product.id)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(product.displayPrice)
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Button("Reload Products") {
                Task {
                    await store.loadProducts()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

// To test this:
// 1. Add this view to your main app temporarily
// 2. Switch to "Growth Production" scheme 
// 3. Run on physical device
// 4. Check console output