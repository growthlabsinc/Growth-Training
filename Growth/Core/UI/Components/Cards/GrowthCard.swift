import UIKit

/// A card view component that follows the Growth app styling guidelines
class GrowthCard: UIView, ShadowProvider, BorderProvider {
    
    // MARK: - Card Types
    
    enum CardType {
        case standard
        case workout
        case progress
    }
    
    // MARK: - Properties
    
    private let cardType: CardType
    private let contentView = UIView()
    
    var shadowStyle: GrowthUITheme.ShadowStyle? {
        return .medium
    }
    
    var borderStyle: GrowthUITheme.BorderStyle? {
        // Default to no border in light mode, but dark mode will add one in updateAppearance
        return GrowthUITheme.BorderStyle.none
    }
    
    /// Provides access to the card's content view for adding subviews
    var content: UIView {
        return contentView
    }
    
    // MARK: - Initialization
    
    /// Creates a new GrowthCard with the specified type
    /// - Parameter type: The card type
    init(type: CardType) {
        self.cardType = type
        super.init(frame: .zero)
        setupView()
    }
    
    /// Creates a new GrowthCard with the specified type and content
    /// - Parameters:
    ///   - type: The card type
    ///   - contentView: The view to add as content
    convenience init(type: CardType, contentView: UIView) {
        self.init(type: type)
        addContent(contentView)
    }
    
    required init?(coder: NSCoder) {
        self.cardType = .standard
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add content view
        addSubview(contentView)
        
        // Set up constraints for content view with padding
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: GrowthUITheme.Spacing.default),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: GrowthUITheme.Spacing.default),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -GrowthUITheme.Spacing.default),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -GrowthUITheme.Spacing.default)
        ])
        
        // Configure based on card type
        switch cardType {
        case .standard:
            setupStandardCard()
        case .workout:
            setupWorkoutCard()
        case .progress:
            setupProgressCard()
        }
        
        // Apply shadow (this ensures the shadow path is set correctly)
        setNeedsLayout()
        
        // Register for trait changes using the new API in iOS 17+
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (card: GrowthCard, previousTraitCollection) in
                guard let self = self else { return }
                if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                    // Update appearance for dark mode changes
                    GrowthUITheme.updateAppearance(for: self, with: self.traitCollection)
                }
            }
        }
    }
    
    private func setupStandardCard() {
        backgroundColor = AppColors.surfaceWhite
        layer.cornerRadius = GrowthUITheme.ComponentSize.standardCardCornerRadius
        clipsToBounds = false
    }
    
    private func setupWorkoutCard() {
        backgroundColor = AppColors.surfaceWhite
        layer.cornerRadius = GrowthUITheme.ComponentSize.workoutCardCornerRadius
        clipsToBounds = false
    }
    
    private func setupProgressCard() {
        backgroundColor = AppColors.paleGreen // This already uses the appropriate color
        layer.cornerRadius = GrowthUITheme.ComponentSize.progressCardCornerRadius
        clipsToBounds = false
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Set shadow path for better performance
        if let shadowStyle = shadowStyle {
            shadowStyle.apply(to: self)
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        }
    }
    
    // MARK: - Trait Collection Changes
    
    // Keep for backward compatibility with iOS versions prior to 17.0
    @available(iOS, deprecated: 17.0, message: "Use the trait change registration APIs declared in the UITraitChangeObservable protocol")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 17.0, *) {
            // Using the new API registered in setupView()
        } else {
            // For iOS 16 and below, use the old method
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                // Update appearance for dark mode changes
                GrowthUITheme.updateAppearance(for: self, with: traitCollection)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Adds a view as content to the card
    /// - Parameter view: The view to add as content
    func addContent(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    /// Applies a gradient overlay to the card (primarily for workout cards)
    /// - Parameter colors: The gradient colors
    func applyGradientOverlay(colors: [UIColor]) {
        guard cardType == .workout else { return }
        
        // Remove any existing gradient
        layer.sublayers?.forEach { sublayer in
            if sublayer is CAGradientLayer {
                sublayer.removeFromSuperlayer()
            }
        }
        
        // Create new gradient
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        
        // Insert gradient at index 0 so it's below content
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

// MARK: - Factory Methods

extension GrowthCard {
    
    /// Creates a standard card
    /// - Returns: A configured standard card
    static func standardCard() -> GrowthCard {
        return GrowthCard(type: .standard)
    }
    
    /// Creates a workout card
    /// - Returns: A configured workout card
    static func workoutCard() -> GrowthCard {
        return GrowthCard(type: .workout)
    }
    
    /// Creates a progress card
    /// - Returns: A configured progress card
    static func progressCard() -> GrowthCard {
        return GrowthCard(type: .progress)
    }
} 