//
//  FixedGrowthMethodsListView.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import SwiftUI
import Foundation  // For Logger

/// Main view for displaying and filtering growth methods with fixed sheet presentation
struct FixedGrowthMethodsListView: View {
    /// View model for methods data and interactions
    @StateObject private var viewModel = GrowthMethodsViewModel()
    
    /// State for tracking the currently selected method
    @State private var selectedMethod: GrowthMethod?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBarView
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Category filters
                if !viewModel.categories.isEmpty {
                    categoryFiltersView
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
                
                // Content area
                ZStack {
                    // Main content when loaded
                    if !viewModel.isLoading && viewModel.errorMessage == nil {
                        if viewModel.filteredMethods.isEmpty {
                            emptyStateView
                        } else {
                            methodsListView
                        }
                    }
                    
                    // Loading view
                    if viewModel.isLoading {
                        SwiftUI.ProgressView("Loading methods...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    // Error view
                    if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Growth Methods")
            .navigationBarItems(trailing: refreshButton)
            .onAppear {
                viewModel.loadMethods()
            }
            // Using isPresented instead of item binding
            .sheet(item: $selectedMethod) { method in
                GrowthMethodDetailView(method: method)
                    .onAppear {
                        Logger.debug("Detail sheet appeared with method ID: \(method.id ?? "nil")")
                        Logger.debug("Detail sheet method title: \(method.title)")
                        Logger.debug("Detail sheet has description length: \(method.methodDescription.count)")
                    }
            }
        }
    }
    
    // MARK: - Component Views
    
    /// Search bar for filtering methods
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search methods", text: $viewModel.searchText)
                .foregroundColor(.primary)
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    /// Filter button for category selection
    private struct CategoryFilterButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(AppTheme.Typography.subheadlineFont())
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundColor(isSelected ? .white : .primary)
                    .background(isSelected ? Color.mintGreenColor : Color(.systemGray5))
                    .cornerRadius(20)
            }
        }
    }
    
    /// Horizontal scrolling category filter buttons
    private var categoryFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All categories button
                CategoryFilterButton(
                    title: "All",
                    isSelected: viewModel.selectedCategory == "All",
                    action: { viewModel.selectedCategory = "All" }
                )
                
                // Individual category buttons
                ForEach(viewModel.categories.filter { $0 != "All" }, id: \.self) { category in
                    CategoryFilterButton(
                        title: category,
                        isSelected: viewModel.selectedCategory == category,
                        action: { viewModel.selectedCategory = category }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// Main list view for displaying methods
    private var methodsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Using id as the identifier, ensuring proper non-binding array usage
                ForEach(viewModel.filteredMethods, id: \.id) { method in
                    // Pass method as a direct value, not a binding
                    MethodCardView(method: method)
                        .onTapGesture {
                            Logger.debug("Method tapped in fixed view - ID: \(method.id ?? "nil"), Title: \(method.title)")
                            Logger.debug("Description length: \(method.methodDescription.count), Instructions length: \(method.instructionsText.count)")
                            // Create a copy of the method to avoid reference issues
                            let methodCopy = GrowthMethod(
                                id: method.id,
                                stage: method.stage,
                                title: method.title,
                                methodDescription: method.methodDescription,
                                instructionsText: method.instructionsText,
                                visualPlaceholderUrl: method.visualPlaceholderUrl,
                                equipmentNeeded: method.equipmentNeeded,
                                estimatedDurationMinutes: method.estimatedDurationMinutes,
                                categories: method.categories,
                                isFeatured: method.isFeatured,
                                progressionCriteria: method.progressionCriteria,
                                safetyNotes: method.safetyNotes,
                                timerConfig: method.timerConfig
                            )
                            selectedMethod = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                Logger.debug("Setting method: \(methodCopy.id ?? "nil") - \(methodCopy.title)")
                                selectedMethod = methodCopy
                            }
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await withCheckedContinuation { continuation in
                viewModel.refreshMethods()
                continuation.resume()
            }
        }
    }
    
    /// Empty state view when no methods are available
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            if viewModel.filteredMethods.isEmpty {
                Text("No methods available")
                    .font(AppTheme.Typography.title3Font())
                    .fontWeight(.medium)
                
                Text("Check back later for growth methods")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("No matching methods")
                    .font(AppTheme.Typography.title3Font())
                    .fontWeight(.medium)
                
                Text("Try adjusting your search or filters")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button("Reset Filters") {
                    viewModel.searchText = ""
                    viewModel.selectedCategory = "All"
                }
                .padding(.top, 8)
                .foregroundColor(.blue)
            }
        }
    }
    
    /// Error view for displaying error messages
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("Error Loading Methods")
                .font(AppTheme.Typography.title3Font())
                .fontWeight(.medium)
            
            Text(message)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Try Again") {
                viewModel.loadMethods()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    /// Refresh button for manually refreshing methods
    private var refreshButton: some View {
        Button(action: {
            viewModel.refreshMethods()
        }) {
            Image(systemName: "arrow.clockwise")
        }
    }
}

#Preview {
    FixedGrowthMethodsListView()
} 