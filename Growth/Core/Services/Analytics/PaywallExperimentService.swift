/**
 * PaywallExperimentService.swift
 * Growth App A/B Testing Framework
 *
 * Advanced A/B testing service for paywall optimization with statistical
 * significance testing, multi-variant support, and automated experiment management.
 */

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

/// Advanced A/B testing service for paywall conversion optimization
public class PaywallExperimentService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = PaywallExperimentService()
    
    // MARK: - Published Properties
    
    @Published public private(set) var activeExperiments: [Experiment] = []
    @Published public private(set) var userAssignments: [String: ExperimentVariant] = [:]
    @Published public private(set) var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private let firestore = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // Statistical configuration
    private let minimumSampleSize = 1000
    private let confidenceLevel = 0.95
    private let statisticalPower = 0.80
    private let maxExperimentDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    // A/B testing configuration
    private let experimentTypes: [ExperimentType] = [
        .headerMessaging, .ctaButtonText, .pricingDisplay, .featureHighlights,
        .socialProofPlacement, .exitIntentTiming, .discountStrategy
    ]
    
    private init() {
        loadActiveExperiments()
        setupExperimentMonitoring()
    }
    
    // MARK: - Experiment Management
    
    /// Create a new A/B test experiment
    public func createExperiment(_ config: ExperimentConfig) -> Experiment {
        let experiment = Experiment(
            id: generateExperimentId(),
            name: config.name,
            description: config.description,
            type: config.type,
            variants: config.variants,
            trafficAllocation: config.trafficAllocation,
            targetMetric: config.targetMetric,
            minimumDetectableEffect: config.minimumDetectableEffect,
            startDate: config.startDate,
            endDate: config.endDate,
            status: .created,
            createdBy: Auth.auth().currentUser?.uid ?? "unknown"
        )
        
        // Save to Firestore
        saveExperiment(experiment)
        
        Logger.info("PaywallExperiment: Created experiment \(experiment.name) with \(experiment.variants.count) variants")
        
        return experiment
    }
    
    /// Start an experiment
    public func startExperiment(_ experimentId: String, completion: @escaping (Result<Experiment, ExperimentError>) -> Void) {
        guard var experiment = getExperiment(experimentId) else {
            completion(.failure(.experimentNotFound))
            return
        }
        
        // Validate experiment can be started
        let validationResult = validateExperimentForStart(experiment)
        if case .failure(let error) = validationResult {
            completion(.failure(error))
            return
        }
        
        // Update status and start date
        experiment.status = .running
        experiment.actualStartDate = Date()
        
        // Save updated experiment
        saveExperiment(experiment)
        
        // Add to active experiments
        if !activeExperiments.contains(where: { $0.id == experiment.id }) {
            activeExperiments.append(experiment)
        }
        
        // Initialize statistical tracking
        initializeExperimentTracking(experiment)
        
        completion(.success(experiment))
        
        Logger.info("PaywallExperiment: Started experiment \(experiment.name)")
    }
    
    /// Stop an experiment
    public func stopExperiment(_ experimentId: String, reason: StopReason, completion: @escaping (Result<ExperimentResults, ExperimentError>) -> Void) {
        guard var experiment = getExperiment(experimentId) else {
            completion(.failure(.experimentNotFound))
            return
        }
        
        experiment.status = .stopped
        experiment.actualEndDate = Date()
        experiment.stopReason = reason
        
        // Calculate final results
        calculateExperimentResults(experiment) { results in
            experiment.results = results
            
            // Save final state
            self.saveExperiment(experiment)
            
            // Remove from active experiments
            self.activeExperiments.removeAll { $0.id == experiment.id }
            
            completion(.success(results))
            
            Logger.info("PaywallExperiment: Stopped experiment \(experiment.name) - \(reason.rawValue)")
        }
    }
    
    /// Get user's assignment for an experiment
    public func enrollUser(in experiment: Experiment) -> ExperimentVariant? {
        guard experiment.status == .running else { return nil }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            Logger.warning("PaywallExperiment: No authenticated user for experiment enrollment")
            return nil
        }
        
        // Check if user already assigned
        if let existingAssignment = userAssignments[experiment.id] {
            return existingAssignment
        }
        
        // Check exclusion criteria
        if shouldExcludeUser(userId, from: experiment) {
            return nil
        }
        
        // Assign user to variant using consistent hashing
        let variant = assignUserToVariant(userId: userId, experiment: experiment)
        
        // Store assignment
        userAssignments[experiment.id] = variant
        saveUserAssignment(userId: userId, experimentId: experiment.id, variant: variant)
        
        // Track enrollment event
        trackExperimentEvent(
            experimentId: experiment.id,
            variant: variant,
            event: .enrolled,
            metadata: ["enrollment_timestamp": Date().timeIntervalSince1970]
        )
        
        Logger.debug("PaywallExperiment: Enrolled user in experiment \(experiment.name) - variant \(variant.name)")
        
        return variant
    }
    
    /// Track experiment conversion event
    public func trackExperimentConversion(
        _ experiment: Experiment,
        variant: ExperimentVariant,
        conversionValue: Double? = nil,
        metadata: [String: Any] = [:]
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Record conversion event
        let conversionEvent = ExperimentConversion(
            experimentId: experiment.id,
            userId: userId,
            variant: variant,
            conversionValue: conversionValue ?? 0,
            timestamp: Date(),
            metadata: metadata
        )
        
        saveConversionEvent(conversionEvent)
        
        // Track in analytics
        trackExperimentEvent(
            experimentId: experiment.id,
            variant: variant,
            event: .converted,
            metadata: metadata
        )
        
        // Check for statistical significance
        let _ = calculateStatisticalSignificance(experiment)
        
        Logger.info("PaywallExperiment: Tracked conversion for \(experiment.name) - variant \(variant.name)")
    }
    
    // MARK: - Statistical Analysis
    
    /// Calculate statistical significance for an experiment
    public func calculateStatisticalSignificance(_ experiment: Experiment) -> SignificanceResult {
        // Load conversion data for all variants
        var variantResults: [String: VariantResults] = [:]
        
        for variant in experiment.variants {
            let results = getVariantResults(experimentId: experiment.id, variant: variant)
            variantResults[variant.id] = results
        }
        
        // Calculate statistical significance between control and variants
        guard let controlVariant = experiment.variants.first(where: { $0.isControl }),
              let controlResults = variantResults[controlVariant.id] else {
            return SignificanceResult.inconclusive(reason: "No control variant found")
        }
        
        var significantVariants: [SignificantVariant] = []
        
        for variant in experiment.variants where !variant.isControl {
            guard let variantResults = variantResults[variant.id] else { continue }
            
            let significance = calculateTwoSampleZTest(
                control: controlResults,
                variant: variantResults,
                confidenceLevel: confidenceLevel
            )
            
            if significance.isSignificant {
                significantVariants.append(SignificantVariant(
                    variant: variant,
                    pValue: significance.pValue,
                    confidenceInterval: significance.confidenceInterval,
                    effect: significance.effect
                ))
            }
        }
        
        if significantVariants.isEmpty {
            return .inconclusive(reason: "No statistically significant variants found")
        } else {
            let winner = significantVariants.max(by: { $0.effect < $1.effect })!
            return .significant(winner: winner.variant, results: significantVariants)
        }
    }
    
    /// Get comprehensive experiment results
    public func getExperimentResults(_ experimentId: String, completion: @escaping (ExperimentResults?) -> Void) {
        guard let experiment = getExperiment(experimentId) else {
            completion(nil)
            return
        }
        
        calculateExperimentResults(experiment, completion: completion)
    }
    
    // MARK: - Variant Assignment
    
    private func assignUserToVariant(userId: String, experiment: Experiment) -> ExperimentVariant {
        // Use deterministic hash-based assignment for consistency
        let hash = hashUser(userId: userId, experimentId: experiment.id)
        let hashValue = Double(hash % 10000) / 10000.0 // 0.0 to 1.0
        
        // Apply traffic allocation
        if hashValue >= experiment.trafficAllocation {
            // User not in experiment, return control
            return experiment.variants.first(where: { $0.isControl }) ?? experiment.variants[0]
        }
        
        // Assign to variant based on split ratios
        var cumulativeRatio: Double = 0
        let adjustedHashValue = hashValue / experiment.trafficAllocation
        
        for variant in experiment.variants {
            cumulativeRatio += variant.splitRatio
            if adjustedHashValue <= cumulativeRatio {
                return variant
            }
        }
        
        // Fallback to control
        return experiment.variants.first(where: { $0.isControl }) ?? experiment.variants[0]
    }
    
    private func hashUser(userId: String, experimentId: String) -> UInt32 {
        let input = "\(userId):\(experimentId)"
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.withUnsafeBytes { bytes in
            bytes.load(as: UInt32.self)
        }
    }
    
    // MARK: - Statistical Calculations
    
    private func calculateTwoSampleZTest(
        control: VariantResults,
        variant: VariantResults,
        confidenceLevel: Double
    ) -> StatisticalTest {
        let n1 = Double(control.sampleSize)
        let n2 = Double(variant.sampleSize)
        let p1 = control.conversionRate
        let p2 = variant.conversionRate
        
        // Check minimum sample size
        guard n1 >= Double(minimumSampleSize) && n2 >= Double(minimumSampleSize) else {
            return StatisticalTest(
                isSignificant: false,
                pValue: 1.0,
                effect: 0.0,
                confidenceInterval: (0.0, 0.0)
            )
        }
        
        // Calculate pooled proportion
        let pooledP = (control.conversions + variant.conversions) / (n1 + n2)
        
        // Calculate standard error
        let standardError = sqrt(pooledP * (1 - pooledP) * (1/n1 + 1/n2))
        
        // Calculate z-score
        let zScore = (p2 - p1) / standardError
        
        // Calculate p-value (two-tailed test)
        let pValue = 2 * (1 - standardNormalCDF(abs(zScore)))
        
        // Calculate confidence interval for difference
        let marginOfError = 1.96 * standardError // 95% confidence
        let lowerBound = (p2 - p1) - marginOfError
        let upperBound = (p2 - p1) + marginOfError
        
        // Effect size (relative improvement)
        let effect = p1 > 0 ? (p2 - p1) / p1 : 0
        
        return StatisticalTest(
            isSignificant: pValue < (1 - confidenceLevel),
            pValue: pValue,
            effect: effect,
            confidenceInterval: (lowerBound, upperBound)
        )
    }
    
    private func standardNormalCDF(_ x: Double) -> Double {
        // Approximation of standard normal cumulative distribution function
        return 0.5 * (1 + erf(x / sqrt(2)))
    }
    
    private func erf(_ x: Double) -> Double {
        // Approximation of error function
        let a1 =  0.254829592
        let a2 = -0.284496736
        let a3 =  1.421413741
        let a4 = -1.453152027
        let a5 =  1.061405429
        let p  =  0.3275911
        
        let sign = x < 0 ? -1.0 : 1.0
        let x = abs(x)
        
        let t = 1.0 / (1.0 + p * x)
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x)
        
        return sign * y
    }
    
    // MARK: - Data Management
    
    private func loadActiveExperiments() {
        isLoading = true
        
        firestore.collection("experiments")
            .whereField("status", isEqualTo: ExperimentStatus.running.rawValue)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        Logger.error("PaywallExperiment: Error loading active experiments: \(error)")
                        return
                    }
                    
                    let experiments = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: Experiment.self)
                    } ?? []
                    
                    self?.activeExperiments = experiments
                    
                    Logger.info("PaywallExperiment: Loaded \(experiments.count) active experiments")
                }
            }
    }
    
    private func setupExperimentMonitoring() {
        // Monitor experiments for auto-stopping conditions
        Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { _ in // Check hourly
            self.checkExperimentStopConditions()
        }
    }
    
    private func checkExperimentStopConditions() {
        for experiment in activeExperiments {
            // Check for statistical significance with early stopping
            let significance = calculateStatisticalSignificance(experiment)
            
            if case .significant(let winner, _) = significance {
                // Check if we have enough confidence for early stopping
                if shouldStopEarly(experiment: experiment, winner: winner) {
                    stopExperiment(experiment.id, reason: .earlyStop) { _ in }
                }
            }
            
            // Check for maximum duration
            if let startDate = experiment.actualStartDate,
               Date().timeIntervalSince(startDate) > maxExperimentDuration {
                stopExperiment(experiment.id, reason: .completed) { _ in }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateExperimentId() -> String {
        return "exp_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(8))"
    }
    
    private func getExperiment(_ id: String) -> Experiment? {
        return activeExperiments.first { $0.id == id }
    }
    
    private func shouldExcludeUser(_ userId: String, from experiment: Experiment) -> Bool {
        // Check user eligibility criteria
        // This would integrate with user segmentation service
        return false
    }
    
    private func shouldStopEarly(experiment: Experiment, winner: ExperimentVariant) -> Bool {
        // Implement early stopping logic based on statistical power
        // and practical significance thresholds
        return true // Simplified for now
    }
    
    private func trackExperimentEvent(
        experimentId: String,
        variant: ExperimentVariant,
        event: ExperimentEventType,
        metadata: [String: Any] = [:]
    ) {
        PaywallAnalyticsService.shared.trackExperimentEvent(
            experimentId: experimentId,
            variant: variant.name,
            event: event.rawValue,
            context: .general, // This would be passed in real implementation
            metadata: metadata
        )
    }
    
    // MARK: - Persistence Methods
    
    private func saveExperiment(_ experiment: Experiment) {
        do {
            let data = try Firestore.Encoder().encode(experiment)
            firestore.collection("experiments").document(experiment.id).setData(data)
        } catch {
            Logger.error("PaywallExperiment: Error saving experiment: \(error)")
        }
    }
    
    private func saveUserAssignment(userId: String, experimentId: String, variant: ExperimentVariant) {
        let assignment = UserAssignment(
            userId: userId,
            experimentId: experimentId,
            variant: variant,
            assignedAt: Date()
        )
        
        do {
            let data = try Firestore.Encoder().encode(assignment)
            firestore.collection("experimentAssignments").document("\(userId)_\(experimentId)").setData(data)
        } catch {
            Logger.error("PaywallExperiment: Error saving user assignment: \(error)")
        }
    }
    
    private func saveConversionEvent(_ conversion: ExperimentConversion) {
        do {
            let data = try Firestore.Encoder().encode(conversion)
            firestore.collection("experimentConversions").document(conversion.id).setData(data)
        } catch {
            Logger.error("PaywallExperiment: Error saving conversion event: \(error)")
        }
    }
    
    private func getVariantResults(experimentId: String, variant: ExperimentVariant) -> VariantResults {
        // This would fetch from Firestore in real implementation
        // For now, return mock results
        return VariantResults(
            variant: variant,
            sampleSize: 1200,
            conversions: 84,
            conversionRate: 0.07,
            averageOrderValue: 29.99
        )
    }
    
    private func calculateExperimentResults(_ experiment: Experiment, completion: @escaping (ExperimentResults) -> Void) {
        // This would perform comprehensive analysis
        // For now, return mock results
        let results = ExperimentResults(
            experimentId: experiment.id,
            status: experiment.status,
            significance: calculateStatisticalSignificance(experiment),
            variantResults: [],
            duration: experiment.actualStartDate?.timeIntervalSinceNow ?? 0,
            totalSampleSize: 5000,
            conclusionReached: true
        )
        
        completion(results)
    }
    
    private func validateExperimentForStart(_ experiment: Experiment) -> Result<Void, ExperimentError> {
        // Validate experiment configuration
        if experiment.variants.isEmpty {
            return .failure(.invalidConfiguration("No variants defined"))
        }
        
        if !experiment.variants.contains(where: { $0.isControl }) {
            return .failure(.invalidConfiguration("No control variant defined"))
        }
        
        let totalSplit = experiment.variants.reduce(0) { $0 + $1.splitRatio }
        if abs(totalSplit - 1.0) > 0.001 {
            return .failure(.invalidConfiguration("Variant split ratios don't sum to 1.0"))
        }
        
        return .success(())
    }
    
    private func initializeExperimentTracking(_ experiment: Experiment) {
        // Initialize tracking infrastructure for the experiment
        Logger.info("PaywallExperiment: Initialized tracking for experiment \(experiment.name)")
    }
}

// MARK: - Supporting Enums and Models

/// Experiment event types for tracking
public enum ExperimentEventType: String, CaseIterable, Codable {
    case enrolled = "enrolled"
    case exposed = "exposed"
    case interacted = "interacted"
    case converted = "converted"
    case excluded = "excluded"
}

/// Reasons for stopping an experiment  
public enum ExperimentStopReason: String, CaseIterable, Codable {
    case statisticalSignificance = "statistical_significance"
    case maxDurationReached = "max_duration_reached"
    case insufficientData = "insufficient_data"
    case businessDecision = "business_decision"
    case technicalIssues = "technical_issues"
}

/// Experiment error types
public enum ExperimentError: Error, LocalizedError {
    case experimentNotFound
    case invalidConfiguration(String)
    case insufficientData
    case accessDenied
    
    public var errorDescription: String? {
        switch self {
        case .experimentNotFound:
            return "Experiment not found"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .insufficientData:
            return "Insufficient data for analysis"
        case .accessDenied:
            return "Access denied"
        }
    }
}