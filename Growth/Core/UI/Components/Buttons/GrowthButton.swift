import UIKit

/// A customizable button that follows the Growth app styling guidelines
class GrowthButton: UIButton {
    
    // MARK: - Button Types
    
    enum GrowthButtonStyle {
        case primary
        case secondary
        case text
        case icon
    }
    
    // MARK: - Properties
    
    private let growthButtonStyle: GrowthButtonStyle
    private var isButtonHighlighted = false
    private var iconImage: UIImage?
    private var normalBackgroundColor: UIColor = .clear
    
    // MARK: - Initialization
    
    /// Creates a new GrowthButton with the specified type
    /// - Parameter type: The button type
    init(type: GrowthButtonStyle) {
        self.growthButtonStyle = type
        super.init(frame: .zero)
        setup()
    }
    
    /// Creates a new GrowthButton with the specified type and title
    /// - Parameters:
    ///   - type: The button type
    ///   - title: The button title
    convenience init(type: GrowthButtonStyle, title: String) {
        self.init(type: type)
        setTitle(title, for: .normal)
    }
    
    /// Creates a new GrowthButton with the specified type and icon
    /// - Parameters:
    ///   - type: The button type
    ///   - icon: The icon image to display
    convenience init(type: GrowthButtonStyle, icon: UIImage) {
        self.init(type: type)
        iconImage = icon
        setImage(icon, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        self.growthButtonStyle = .primary
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    
    private func setup() {
        titleLabel?.font = UIFont.growth(style: .buttonText)
        translatesAutoresizingMaskIntoConstraints = false
        
        // Configure based on button type
        switch growthButtonStyle {
        case .primary:
            setupPrimaryButton()
        case .secondary:
            setupSecondaryButton()
        case .text:
            setupTextButton()
        case .icon:
            setupIconButton()
        }
        
        // Add targets for highlighting
        addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // Register for trait changes using the new API in iOS 17+
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (button: GrowthButton, previousTraitCollection: UITraitCollection) in
                guard let self = self else { return }
                if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                    // Update colors for the current state
                    switch self.growthButtonStyle {
                    case .secondary:
                        self.layer.borderColor = AppColors.mintGreen.cgColor
                        
                        var updatedConfig = self.configuration
                        updatedConfig?.background.strokeColor = AppColors.mintGreen
                        self.configuration = updatedConfig
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func setupPrimaryButton() {
        backgroundColor = AppColors.mintGreen
        normalBackgroundColor = AppColors.mintGreen
        setTitleColor(AppColors.darkText, for: .normal)
        layer.cornerRadius = GrowthUITheme.ComponentSize.primaryButtonCornerRadius
        
        // Set height constraint
        heightAnchor.constraint(equalToConstant: GrowthUITheme.ComponentSize.primaryButtonHeight).isActive = true
        
        // Use configuration for content insets if available (iOS 15+)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            configuration.background.backgroundColor = AppColors.mintGreen
            configuration.background.cornerRadius = GrowthUITheme.ComponentSize.primaryButtonCornerRadius
            configuration.baseForegroundColor = AppColors.darkText
            self.configuration = configuration
        } else {
            // Fallback for earlier versions
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        // Disabled state
        setTitleColor(AppColors.darkText.withAlphaComponent(0.7), for: .disabled)
    }
    
    private func setupSecondaryButton() {
        backgroundColor = UIColor.clear
        normalBackgroundColor = UIColor.clear
        setTitleColor(AppColors.mintGreen, for: .normal)
        layer.cornerRadius = GrowthUITheme.ComponentSize.secondaryButtonCornerRadius
        layer.borderWidth = 1.5
        layer.borderColor = AppColors.mintGreen.cgColor
        
        // Set height constraint
        heightAnchor.constraint(equalToConstant: GrowthUITheme.ComponentSize.secondaryButtonHeight).isActive = true
        
        // Use configuration for content insets if available (iOS 15+)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            configuration.background.cornerRadius = GrowthUITheme.ComponentSize.secondaryButtonCornerRadius
            configuration.baseForegroundColor = AppColors.mintGreen
            
            // Create a custom background configuration with border
            configuration.background.strokeColor = AppColors.mintGreen
            configuration.background.strokeWidth = 1.5
            
            self.configuration = configuration
        } else {
            // Fallback for earlier versions
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        // Disabled state
        setTitleColor(AppColors.mintGreen.withAlphaComponent(0.4), for: .disabled)
    }
    
    private func setupTextButton() {
        backgroundColor = UIColor.clear
        normalBackgroundColor = UIColor.clear
        setTitleColor(AppColors.mintGreen, for: .normal)
        
        // Set height constraint
        heightAnchor.constraint(equalToConstant: GrowthUITheme.ComponentSize.textButtonHeight).isActive = true
        
        // Use configuration if available (iOS 15+)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.baseForegroundColor = AppColors.mintGreen
            self.configuration = configuration
        }
        
        // Disabled state
        setTitleColor(AppColors.mintGreen.withAlphaComponent(0.4), for: .disabled)
    }
    
    private func setupIconButton() {
        backgroundColor = UIColor.clear
        normalBackgroundColor = UIColor.clear
        tintColor = AppColors.mintGreen
        
        // Set size constraints
        let size = GrowthUITheme.ComponentSize.iconButtonSize
        heightAnchor.constraint(equalToConstant: size).isActive = true
        widthAnchor.constraint(equalToConstant: size).isActive = true
        
        // Center the image
        imageView?.contentMode = .center
        
        // Use configuration if available (iOS 15+)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.baseForegroundColor = AppColors.mintGreen
            
            // Configure image padding for icon button
            if let iconImage = iconImage {
                configuration.image = iconImage
                configuration.imagePadding = 0
            }
            
            self.configuration = configuration
        } else {
            // Disabled state - for iOS 14 and below
            adjustsImageWhenDisabled = true
        }
    }
    
    // MARK: - Overrides
    
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : GrowthUITheme.ComponentState.disabled.alpha
            
            if #available(iOS 15.0, *) {
                // Update configuration for disabled state
                updateButtonConfigurationState()
            }
        }
    }
    
    // Keep for backward compatibility with iOS versions prior to 17.0
    @available(iOS, deprecated: 17.0, message: "Use the trait change registration APIs declared in the UITraitChangeObservable protocol")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // For iOS 16 and below, use the old method
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // Update colors for dark mode changes
            switch growthButtonStyle {
            case .secondary:
                layer.borderColor = AppColors.mintGreen.cgColor
                
                if #available(iOS 15.0, *) {
                    var updatedConfig = configuration
                    updatedConfig?.background.strokeColor = AppColors.mintGreen
                    configuration = updatedConfig
                }
            default:
                break
            }
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        // Handle dynamic color changes for dark mode
        switch growthButtonStyle {
        case .secondary:
            layer.borderColor = AppColors.mintGreen.cgColor
            
            if #available(iOS 15.0, *) {
                var updatedConfig = configuration
                updatedConfig?.background.strokeColor = AppColors.mintGreen
                configuration = updatedConfig
            }
        default:
            break
        }
    }
    
    // MARK: - Configuration update for iOS 15+
    
    @available(iOS 15.0, *)
    private func updateButtonConfigurationState() {
        var updatedConfig = configuration
        
        switch growthButtonStyle {
        case .primary:
            updatedConfig?.background.backgroundColor = isEnabled ? 
                AppColors.mintGreen : 
                AppColors.mintGreen.withAlphaComponent(0.7)
            
        case .secondary, .text, .icon:
            updatedConfig?.baseForegroundColor = isEnabled ? 
                AppColors.mintGreen : 
                AppColors.mintGreen.withAlphaComponent(0.4)
        }
        
        configuration = updatedConfig
    }
    
    // MARK: - Touch Handling
    
    @objc private func buttonTouchDown() {
        isButtonHighlighted = true
        updateHighlightedState()
    }
    
    @objc private func buttonTouchUp() {
        isButtonHighlighted = false
        updateHighlightedState()
    }
    
    private func updateHighlightedState() {
        UIView.animate(withDuration: 0.1) {
            if #available(iOS 15.0, *) {
                self.updateHighlightedStateWithConfiguration()
            } else {
                self.updateHighlightedStateClassic()
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func updateHighlightedStateWithConfiguration() {
        var updatedConfig = configuration
        
        switch self.growthButtonStyle {
        case .primary:
            updatedConfig?.background.backgroundColor = self.isButtonHighlighted ? 
                AppColors.mintGreen.darkened(by: 15) : 
                self.normalBackgroundColor
            
        case .secondary, .text, .icon:
            updatedConfig?.background.backgroundColor = self.isButtonHighlighted ? 
                AppColors.mintGreen.withAlphaComponent(0.1) : 
                self.normalBackgroundColor
        }
        
        configuration = updatedConfig
    }
    
    private func updateHighlightedStateClassic() {
        switch self.growthButtonStyle {
        case .primary:
            self.backgroundColor = self.isButtonHighlighted ? 
                AppColors.mintGreen.darkened(by: 15) : 
                self.normalBackgroundColor
            
        case .secondary:
            self.backgroundColor = self.isButtonHighlighted ? 
                AppColors.mintGreen.withAlphaComponent(0.1) : 
                self.normalBackgroundColor
            
        case .text:
            self.backgroundColor = self.isButtonHighlighted ? 
                AppColors.mintGreen.withAlphaComponent(0.1) : 
                self.normalBackgroundColor
            
        case .icon:
            self.backgroundColor = self.isButtonHighlighted ? 
                AppColors.mintGreen.withAlphaComponent(0.1) : 
                self.normalBackgroundColor
        }
    }
}

// MARK: - Factory Methods

extension GrowthButton {
    
    /// Creates a primary button with the specified title
    /// - Parameter title: The button title
    /// - Returns: A configured primary button
    static func primaryButton(title: String) -> GrowthButton {
        return GrowthButton(type: .primary, title: title)
    }
    
    /// Creates a secondary button with the specified title
    /// - Parameter title: The button title
    /// - Returns: A configured secondary button
    static func secondaryButton(title: String) -> GrowthButton {
        return GrowthButton(type: .secondary, title: title)
    }
    
    /// Creates a text button with the specified title
    /// - Parameter title: The button title
    /// - Returns: A configured text button
    static func textButton(title: String) -> GrowthButton {
        return GrowthButton(type: .text, title: title)
    }
    
    /// Creates an icon button with the specified icon
    /// - Parameter icon: The icon image
    /// - Returns: A configured icon button
    static func iconButton(icon: UIImage) -> GrowthButton {
        return GrowthButton(type: .icon, icon: icon)
    }
} 