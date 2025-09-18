//
//  GrowthMethodsListView.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import SwiftUI

/// Main view for displaying and filtering growth methods
struct GrowthMethodsListView: View {
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
                if viewModel.categories.count > 1 {
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
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color("ErrorColor"))
                            
                            Text("Error Loading Methods")
                                .font(AppTheme.Typography.gravitySemibold(18))
                                .foregroundColor(Color("TextColor"))
                            
                            Text(errorMessage)
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(Color("TextSecondaryColor"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Button(action: { viewModel.refreshMethods() }) {
                                Text("Try Again")
                                    .font(AppTheme.Typography.gravitySemibold(14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color("GrowthGreen"))
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Growth Methods")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: Button(action: { viewModel.refreshMethods() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color("GrowthGreen"))
                }
            )
        }
        .onAppear {
            viewModel.loadMethods()
        }
        .sheet(item: $selectedMethod) { method in
            GrowthMethodDetailView(method: method)
        }
    }
    
    // MARK: - Search Bar View
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("TextSecondaryColor"))
            
            TextField("Search methods...", text: $viewModel.searchText)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextColor"))
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Category Filters View
    
    private var categoryFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" button
                categoryPill(name: "All", isSelected: viewModel.selectedCategory == "All") {
                    viewModel.selectedCategory = "All"
                }
                
                // Category pills
                ForEach(viewModel.categories.filter { $0 != "All" }, id: \.self) { category in
                    categoryPill(name: category, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }
    
    private func categoryPill(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(AppTheme.Typography.gravitySemibold(12))
                .foregroundColor(isSelected ? .white : Color("TextColor"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color("GrowthGreen") : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
    
    // MARK: - Methods List View
    
    private var methodsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredMethods) { method in
                    methodRowView(method: method)
                        .onTapGesture {
                            selectedMethod = method
                        }
                    
                    // Divider between methods (but not after the last one)
                    if method.id != viewModel.filteredMethods.last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // MARK: - Method Row View
    
    private func methodRowView(method: GrowthMethod) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Stage indicator
            ZStack {
                Circle()
                    .fill(stageColor(for: method.stage))
                    .frame(width: 40, height: 40)
                
                Text("\(method.stage)")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(.white)
            }
            
            // Method info
            VStack(alignment: .leading, spacing: 4) {
                Text(method.title)
                    .font(AppTheme.Typography.gravitySemibold(15))
                    .foregroundColor(Color("TextColor"))
                    .lineLimit(1)
                
                Text(method.methodDescription)
                    .font(AppTheme.Typography.gravityBook(13))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .lineLimit(2)
                
                // Tags
                HStack(spacing: 6) {
                    if let duration = method.estimatedDurationMinutes {
                        Label("\(duration) min", systemImage: "clock")
                            .font(AppTheme.Typography.gravityBook(11))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                    
                    if !method.equipmentNeeded.isEmpty {
                        Label("Equipment", systemImage: "wrench.and.screwdriver")
                            .font(AppTheme.Typography.gravityBook(11))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .padding()
        .background(Color.white)
        .contentShape(Rectangle())
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(Color("TextSecondaryColor"))
            
            Text("No methods found")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))
            
            Text(!viewModel.searchText.isEmpty || viewModel.selectedCategory != "All" ? 
                 "Try adjusting your filters" : 
                 "Pull to refresh or check back later")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
            
            if !viewModel.searchText.isEmpty || viewModel.selectedCategory != "All" {
                Button(action: { 
                    viewModel.searchText = ""
                    viewModel.selectedCategory = "All"
                }) {
                    Text("Clear Filters")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color("GrowthGreen"))
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func stageColor(for stage: Int) -> Color {
        switch stage {
        case 1: return Color("GrowthGreen")
        case 2: return Color("BrightTeal")
        case 3: return Color.blue
        case 4: return Color.purple
        case 5: return Color.orange
        default: return Color.gray
        }
    }
}

// MARK: - Preview

#Preview {
    GrowthMethodsListView()
}