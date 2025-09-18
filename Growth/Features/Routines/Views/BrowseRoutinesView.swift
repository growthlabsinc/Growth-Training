//
//  BrowseRoutinesView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI
import Foundation  // For Logger

struct BrowseRoutinesView: View {
    @ObservedObject var routinesViewModel: RoutinesViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var selectedCategory: RoutineCategory = .all
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedDifficulty: String? = nil
    @State private var selectedDuration: DurationFilter = .all
    @State private var showingRoutineDetail: Routine? = nil
    @State private var showingCreateCustom = false
    @State private var showingPremiumCreation = false
    
    // Categories for routines
    enum RoutineCategory: String, CaseIterable {
        case all = "All"
        case featured = "Featured"
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case custom = "Custom"
        case community = "Community"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .featured: return "star.fill"
            case .beginner: return "leaf.fill"
            case .intermediate: return "flame.fill"
            case .advanced: return "bolt.fill"
            case .custom: return "person.fill"
            case .community: return "person.2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return Color("GrowthGreen")
            case .featured: return Color.yellow
            case .beginner: return Color("MintGreen")
            case .intermediate: return Color.orange
            case .advanced: return Color.red
            case .custom: return Color.purple
            case .community: return Color.blue
            }
        }
    }
    
    enum DurationFilter: String, CaseIterable {
        case all = "All Durations"
        case week = "1 Week"
        case twoWeeks = "2 Weeks"
        case month = "4 Weeks"
        case custom = "Custom"
        
        var days: Int? {
            switch self {
            case .all: return nil
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 28
            case .custom: return nil
            }
        }
    }
    
    init(routinesViewModel: RoutinesViewModel) {
        self.routinesViewModel = routinesViewModel
    }
    
    var filteredRoutines: [Routine] {
        var results = routinesViewModel.routines
        
        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { routine in
                routine.name.localizedCaseInsensitiveContains(searchText) ||
                routine.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        switch selectedCategory {
        case .all:
            break
        case .featured:
            // Show only verified standard routines, explicitly exclude custom/community routines
            results = results.filter { routine in
                // Must be a known standard routine ID
                let standardRoutineIds = ["standard_growth_routine", "janus_protocol_12week", "advanced_intensive", 
                                         "beginner_express", "intermediate_progressive", "two_week_transformation"]
                let isStandardRoutine = standardRoutineIds.contains(routine.id)
                
                // Must NOT be a custom routine (handle nil properly)
                let isNotCustom = (routine.isCustom == nil || routine.isCustom == false)
                
                // Must NOT be shared with community
                let isNotCommunityShared = (routine.shareWithCommunity == nil || routine.shareWithCommunity == false)
                
                return isStandardRoutine && isNotCustom && isNotCommunityShared
            }
        case .beginner:
            results = results.filter { $0.difficultyLevel.lowercased() == "beginner" }
        case .intermediate:
            results = results.filter { $0.difficultyLevel.lowercased() == "intermediate" }
        case .advanced:
            results = results.filter { $0.difficultyLevel.lowercased() == "advanced" }
        case .custom:
            // Filter for user-created routines (would need a flag in the model)
            results = results.filter { $0.isCustom == true && $0.shareWithCommunity != true }
        case .community:
            // Filter for community-shared routines
            results = results.filter { 
                $0.isCustom == true && 
                $0.shareWithCommunity == true && 
                ($0.moderationStatus == "approved" || $0.moderationStatus == "pending")
            }
            // Filter out blocked users
            let blockedUsers = Array(BlockingService.shared.blockedUserIds)
            results = results.filter { routine in
                if let creatorId = routine.createdBy {
                    return !blockedUsers.contains(creatorId)
                }
                return true
            }
        }
        
        // Filter by difficulty (if selected separately)
        if let difficulty = selectedDifficulty {
            results = results.filter { $0.difficultyLevel == difficulty }
        }
        
        // Filter by duration
        if let days = selectedDuration.days {
            results = results.filter { $0.schedule.count == days }
        }
        
        return results
    }
    
    var body: some View {
        ZStack {
            // Background
            Color("GrowthBackgroundLight")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Hero card section
                    heroCardSection
                        .padding(.horizontal)
                        .padding(.top)
                    
                    VStack(spacing: 0) {
                        // Header with search
                        headerSection
                        
                        // Category pills
                        categorySection
                        
                        // Content
                        if routinesViewModel.isLoading {
                            loadingView
                        } else if filteredRoutines.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 16) {
                                // Featured section (if showing all or featured)
                                if selectedCategory == .all || selectedCategory == .featured {
                                    featuredSection
                                }
                                
                                // Regular routines grid
                                routinesGrid
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .sheet(item: $showingRoutineDetail) { routine in
            NavigationView {
                RoutineDetailView(routineId: routine.id)
            }
        }
        .sheet(isPresented: $showingCreateCustom) {
            PremiumCreateCustomRoutineView()
                .onDisappear {
                    // Reload routines when sheet closes to include newly created custom routines
                    routinesViewModel.loadRoutines()
                }
        }
        .sheet(isPresented: $showingFilters) {
            filtersView
        }
        .onAppear {
            // Force reload routines when view appears
            routinesViewModel.loadRoutines()
        }
    }
    
    // MARK: - Hero Card Section
    
    private var heroCardSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image
            Image("waterfall-hero")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
            
            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Text overlay
            VStack(alignment: .leading, spacing: 8) {
                Text("Find Your Perfect Routine")
                    .font(AppTheme.Typography.gravitySemibold(28))
                    .foregroundColor(.white)
                
                Text("Scientifically-backed methods for natural growth")
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(height: 200)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Browse Routines")
                        .font(AppTheme.Typography.gravitySemibold(24))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("\(filteredRoutines.count) routines available")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Filter button
                Button {
                    showingFilters = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        if selectedDifficulty != nil || selectedDuration != .all {
                            Circle()
                                .fill(Color("GrowthGreen"))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(AppTheme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Color("BackgroundColor"))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                }
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextField("Search routines...", text: $searchText)
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(AppTheme.Colors.text)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(12)
            .background(Color("BackgroundColor"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        }
        .padding()
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RoutineCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Featured Section
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Featured", systemImage: "star.fill")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(filteredRoutines.prefix(3)) { routine in
                        FeaturedRoutineCard(
                            routine: routine,
                            isSelected: routinesViewModel.selectedRoutineId == routine.id,
                            action: {
                                showingRoutineDetail = routine
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Routines Grid
    
    private var routinesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(filteredRoutines) { routine in
                RoutineGridCard(
                    routine: routine,
                    isSelected: routinesViewModel.selectedRoutineId == routine.id,
                    action: {
                        showingRoutineDetail = routine
                    }
                )
            }
            
            // Add custom routine button
            if selectedCategory == .all || selectedCategory == .custom {
                CreateCustomCard {
                    showingCreateCustom = true
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color("GrowthGreen"))
            
            Text("Loading routines...")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(AppTheme.Typography.gravitySemibold(48))
                .foregroundColor(Color("GrowthGreen").opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No routines found")
                    .font(AppTheme.Typography.gravitySemibold(20))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("Try adjusting your filters or search")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Button {
                searchText = ""
                selectedCategory = .all
                selectedDifficulty = nil
                selectedDuration = .all
            } label: {
                Text("Clear Filters")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("GrowthGreen"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("GrowthGreen"), lineWidth: 1.5)
                    )
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Filters View
    
    private var filtersView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Difficulty filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("Difficulty Level")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    VStack(spacing: 8) {
                        ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                            FilterOption(
                                title: level,
                                isSelected: selectedDifficulty == level,
                                action: {
                                    if selectedDifficulty == level {
                                        selectedDifficulty = nil
                                    } else {
                                        selectedDifficulty = level
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Duration filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("Routine Duration")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    VStack(spacing: 8) {
                        ForEach(DurationFilter.allCases, id: \.self) { duration in
                            FilterOption(
                                title: duration.rawValue,
                                isSelected: selectedDuration == duration,
                                action: {
                                    selectedDuration = duration
                                }
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        selectedDifficulty = nil
                        selectedDuration = .all
                    } label: {
                        Text("Clear All")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(AppTheme.Colors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("GrowthNeutralGray"), lineWidth: 1)
                            )
                    }
                    
                    Button {
                        showingFilters = false
                    } label: {
                        Text("Apply Filters")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("GrowthGreen"))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilters = false
                    }
                }
            }
        }
    }
    
}

// MARK: - Supporting Views

struct CategoryPill: View {
    let category: BrowseRoutinesView.RoutineCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(AppTheme.Typography.gravityBook(12))
                Text(category.rawValue)
                    .font(AppTheme.Typography.gravitySemibold(14))
            }
            .foregroundColor(isSelected ? .white : AppTheme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color : Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.clear : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct FeaturedRoutineCard: View {
    let routine: Routine
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with gradient and optional image
                ZStack(alignment: .topTrailing) {
                    if routine.id == "standard_growth_routine" {
                        // Buddha image background for standard growth routine
                        ZStack {
                            Image("standard_routine_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                            
                            // Overlay gradient for text readability
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.6)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }
                    } else if routine.id == "beginner_express" {
                        // Mountain path sunrise image for beginner express routine
                        ZStack {
                            Image("beginner_express_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                            
                            // Lighter overlay to preserve the golden sunrise
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.1),
                                    Color.black.opacity(0.4)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }
                    } else if routine.id == "intermediate_progressive" {
                        // Waterfall image for intermediate progressive routine
                        ZStack {
                            Image("waterfall-hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                            
                            // Gradient overlay for text readability
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.black.opacity(0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }
                    } else if routine.id == "advanced_intensive" {
                        // Advanced Intensive hero image
                        ZStack {
                            Image("advanced_intensive_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                            
                            // Gradient overlay for text readability
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.7)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }
                    } else if routine.id == "janus_protocol_12week" {
                        // Janus Protocol hero image
                        ZStack {
                            Image("janus_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                            
                            // Gradient overlay for text readability
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.black.opacity(0.6)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }
                    } else if routine.id == "two_week_transformation" {
                        // Two Week Transformation hero image
                        ZStack {
                            Image("two_week_transformation_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                            
                            // Gradient overlay for text readability
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.black.opacity(0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }
                    } else if routine.id == "recovery_focus" {
                        // Recovery Focus hero image
                        ZStack {
                            Image("recovery_focus_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                            
                            // Gradient overlay for text readability
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.black.opacity(0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }
                    } else {
                        // Default gradient for other routines
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("GrowthGreen"),
                                Color("BrightTeal")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 120)
                    }
                    
                    if isSelected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(AppTheme.Typography.gravityBook(11))
                            Text("Active")
                                .font(AppTheme.Typography.gravityBook(11))
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                        .padding(12)
                    }
                    
                    VStack(alignment: .leading) {
                        Spacer()
                        HStack {
                            Image(systemName: routineIcon(for: routine.id))
                                .font(AppTheme.Typography.gravitySemibold(22))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(16)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(routine.name)
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(AppTheme.Colors.text)
                        .lineLimit(1)
                    
                    Text(routine.description)
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                    
                    HStack {
                        Label(routine.difficultyLevel, systemImage: "chart.bar.fill")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(difficultyColor(for: routine.difficultyLevel))
                        
                        Spacer()
                        
                        Text("\(routine.schedule.count) days")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(16)
            }
            .background(Color("BackgroundColor"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
            .frame(width: 280)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func routineIcon(for routineId: String) -> String {
        switch routineId {
        case "standard_growth_routine":
            return "leaf.fill"
        case "beginner_express":
            return "sun.max.fill"
        case "intermediate_progressive":
            return "flame.fill"
        case "janus_protocol_12week":
            return "bolt.circle.fill"
        case "two_week_transformation":
            return "calendar.badge.clock"
        case "recovery_focus":
            return "leaf.circle.fill"
        default:
            return "star.fill"
        }
    }
    
    private func difficultyColor(for level: String) -> Color {
        switch level.lowercased() {
        case "beginner": return Color("MintGreen")
        case "intermediate": return Color.orange
        case "advanced": return Color.red
        default: return Color.gray
        }
    }
}

struct RoutineGridCard: View {
    let routine: Routine
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon or Image
                ZStack {
                    if routine.id == "standard_growth_routine" {
                        // Buddha image for standard growth routine
                        ZStack {
                            Image("standard_routine_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(12)
                            
                            // Subtle overlay for text readability
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.2))
                                .frame(height: 60)
                            
                            // Icon overlay
                            Image(systemName: "leaf.fill")
                                .font(AppTheme.Typography.gravitySemibold(20))
                                .foregroundColor(.white)
                        }
                    } else if routine.id == "beginner_express" {
                        // Mountain path image for beginner express routine
                        ZStack {
                            Image("beginner_express_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(12)
                            
                            // Light overlay to preserve golden tones
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.15))
                                .frame(height: 60)
                            
                            // Icon overlay
                            Image(systemName: "sun.max.fill")
                                .font(AppTheme.Typography.gravitySemibold(20))
                                .foregroundColor(.white)
                        }
                    } else if routine.id == "intermediate_progressive" {
                        // Waterfall image for intermediate progressive routine
                        ZStack {
                            Image("waterfall-hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(12)
                            
                            // Overlay for text readability
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.25))
                                .frame(height: 60)
                            
                            // Icon overlay
                            Image(systemName: "flame.fill")
                                .font(AppTheme.Typography.gravitySemibold(20))
                                .foregroundColor(.white)
                        }
                    } else if routine.id == "janus_protocol_12week" {
                        // Janus Protocol hero image
                        ZStack {
                            Image("janus_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(12)
                            
                            // Overlay for text readability
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .frame(height: 60)
                            
                            // Icon overlay
                            Image(systemName: "bolt.circle.fill")
                                .font(AppTheme.Typography.gravitySemibold(20))
                                .foregroundColor(.white)
                        }
                    } else if routine.id == "advanced_intensive" {
                        // Advanced Intensive hero image
                        ZStack {
                            Image("advanced_intensive_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(12)
                            
                            // Overlay for text readability
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .frame(height: 60)
                            
                            // Icon overlay
                            Image(systemName: "bolt.fill")
                                .font(AppTheme.Typography.gravitySemibold(20))
                                .foregroundColor(.white)
                        }
                    } else if routine.id == "two_week_transformation" {
                        // Two Week Transformation hero image
                        ZStack {
                            Image("two_week_transformation_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(12)
                            
                            // Overlay for text readability
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.25))
                                .frame(height: 60)
                            
                            // Icon overlay
                            Image(systemName: "calendar.badge.clock")
                                .font(AppTheme.Typography.gravitySemibold(20))
                                .foregroundColor(.white)
                        }
                    } else if routine.id == "recovery_focus" {
                        // Recovery Focus hero image
                        ZStack {
                            Image("recovery_focus_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(12)
                            
                            // Overlay for text readability
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.25))
                                .frame(height: 60)
                            
                            // Icon overlay
                            Image(systemName: "leaf.circle.fill")
                                .font(AppTheme.Typography.gravitySemibold(20))
                                .foregroundColor(.white)
                        }
                    } else {
                        // Default icon background for other routines
                        RoundedRectangle(cornerRadius: 12)
                            .fill(difficultyColor(for: routine.difficultyLevel).opacity(0.1))
                            .frame(height: 60)
                        
                        Image(systemName: difficultyIcon(for: routine.difficultyLevel))
                            .font(AppTheme.Typography.gravitySemibold(24))
                            .foregroundColor(difficultyColor(for: routine.difficultyLevel))
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(routine.name)
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(AppTheme.Colors.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(AppTheme.Typography.gravityBook(12))
                                .foregroundColor(Color("GrowthGreen"))
                        }
                    }
                    
                    // Community creator info
                    if routine.shareWithCommunity == true, let creatorName = routine.creatorDisplayName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("by \(creatorName)")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("\(routine.schedule.count) days • \(routine.difficultyLevel)")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        // Download count for community routines
                        if routine.shareWithCommunity == true && routine.downloadCount > 0 {
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.caption2)
                                Text("\(routine.downloadCount)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(Color("BackgroundColor"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("GrowthGreen") : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func difficultyIcon(for level: String) -> String {
        switch level.lowercased() {
        case "beginner": return "leaf.fill"
        case "intermediate": return "flame.fill"
        case "advanced": return "bolt.fill"
        default: return "star.fill"
        }
    }
    
    private func difficultyColor(for level: String) -> Color {
        switch level.lowercased() {
        case "beginner": return Color("MintGreen")
        case "intermediate": return Color.orange
        case "advanced": return Color.red
        default: return Color.gray
        }
    }
}

struct CreateCustomCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("GrowthGreen").opacity(0.1))
                        .frame(height: 60)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(AppTheme.Typography.gravitySemibold(28))
                        .foregroundColor(Color("GrowthGreen"))
                }
                
                Text("Create Custom")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("GrowthGreen"))
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .foregroundColor(Color("GrowthGreen").opacity(0.5))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct FilterOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("GrowthGreen"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("GrowthGreen").opacity(0.1) : Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color("GrowthGreen") : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    BrowseRoutinesView(routinesViewModel: RoutinesViewModel(userId: "preview"))
}