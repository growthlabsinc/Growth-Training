//
//  GrowthMethodsViewModel.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation
import Combine

class GrowthMethodsViewModel: ObservableObject {
    @Published var methods: [GrowthMethod] = []
    @Published var filteredMethods: [GrowthMethod] = []
    @Published var selectedCategory: String = "All"
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var sortOrder: SortOrder = .default
    
    private let growthMethodService = GrowthMethodService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum SortOrder: String, CaseIterable {
        case `default` = "Default"
        case alphabetical = "A-Z"
        case difficulty = "Difficulty"
        case duration = "Duration"
    }
    
    var categories: [String] {
        let allCategories = Set(methods.flatMap { $0.categories })
        return ["All"] + allCategories.sorted()
    }
    
    init() {
        loadMethods()
        setupSearchFilter()
    }
    
    private func setupSearchFilter() {
        Publishers.CombineLatest($searchText, $selectedCategory)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText, category in
                self?.filterMethods(searchText: searchText, category: category)
            }
            .store(in: &cancellables)
        
        $sortOrder
            .sink { [weak self] _ in
                self?.sortMethods()
            }
            .store(in: &cancellables)
    }
    
    func loadMethods() {
        isLoading = true
        errorMessage = nil
        
        growthMethodService.fetchAllMethods { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let methods):
                    self?.methods = methods
                    self?.filterMethods(searchText: self?.searchText ?? "", 
                                       category: self?.selectedCategory ?? "All")
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func filterMethods(searchText: String, category: String) {
        var filtered = methods
        
        // Filter by category
        if category != "All" {
            filtered = filtered.filter { $0.categories.contains(category) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { method in
                method.title.localizedCaseInsensitiveContains(searchText) ||
                method.methodDescription.localizedCaseInsensitiveContains(searchText) ||
                method.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        filteredMethods = filtered
        sortMethods()
    }
    
    private func sortMethods() {
        switch sortOrder {
        case .default:
            // Keep original order
            break
        case .alphabetical:
            filteredMethods.sort { (method1: GrowthMethod, method2: GrowthMethod) in
                method1.title < method2.title
            }
        case .difficulty:
            filteredMethods.sort { (method1: GrowthMethod, method2: GrowthMethod) in
                method1.stage < method2.stage
            }
        case .duration:
            filteredMethods.sort { (method1: GrowthMethod, method2: GrowthMethod) in
                (method1.estimatedDurationMinutes ?? 0) < (method2.estimatedDurationMinutes ?? 0)
            }
        }
    }
    
    func selectCategory(_ category: String) {
        selectedCategory = category
    }
    
    func method(byId id: String) -> GrowthMethod? {
        return methods.first { $0.id == id }
    }
    
    func methodsByStage(_ stage: Int) -> [GrowthMethod] {
        return methods.filter { $0.stage == stage }
    }
    
    func refreshMethods() {
        loadMethods()
    }
}