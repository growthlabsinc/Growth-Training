import UIKit

/// A text field component that follows the Growth app styling guidelines
class GrowthTextField: UITextField {
    
    // MARK: - Text Field State
    
    enum TextFieldState {
        case normal
        case focused
        case error(message: String?)
        case disabled
    }
    
    // MARK: - Properties
    
    private var textFieldState: TextFieldState = .normal
    private let borderLayer = CALayer()
    private let errorLabel = UILabel()
    
    /// The current state of the text field
    var fieldState: TextFieldState {
        get {
            return textFieldState
        }
        set {
            textFieldState = newValue
            updateAppearanceForState()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    /// Creates a new GrowthTextField with the specified placeholder
    /// - Parameter placeholder: The placeholder text
    convenience init(placeholder: String) {
        self.init(frame: .zero)
        self.placeholder = placeholder
    }
    
    // MARK: - Setup
    
    private func setupTextField() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Set up font and text color
        font = UIFont.growth(style: .body)
        textColor = AppColors.darkText
        
        // Set up placeholder appearance
        attributedPlaceholder = NSAttributedString(
            string: placeholder ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: AppColors.neutralGray]
        )
        
        // Set up basic appearance
        backgroundColor = AppColors.surfaceWhite
        layer.cornerRadius = GrowthUITheme.ComponentSize.textInputCornerRadius
        clipsToBounds = false
        
        // Set up border
        borderLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        borderLayer.borderWidth = 1.0
        borderLayer.borderColor = AppColors.neutralGray.cgColor
        borderLayer.cornerRadius = GrowthUITheme.ComponentSize.textInputCornerRadius
        layer.addSublayer(borderLayer)
        
        // Set up error label
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = UIFont.growth(style: .caption)
        errorLabel.textColor = AppColors.errorRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        
        // Add error label as subview of superview when a superview is available
        addSubview(errorLabel)
        
        // Set up constraints for the error label
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: GrowthUITheme.ComponentSize.textInputHeight),
            errorLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        ])
        
        // Set up text padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: frame.size.height))
        leftView = paddingView
        leftViewMode = .always
        
        // Set up delegates
        delegate = self
        
        // Add target for editing events
        addTarget(self, action: #selector(textFieldEditingDidBegin), for: .editingDidBegin)
        addTarget(self, action: #selector(textFieldEditingDidEnd), for: .editingDidEnd)
        
        // Register for trait changes using the new API in iOS 17+
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (textField: GrowthTextField, previousTraitCollection: UITraitCollection) in
                guard let self = self else { return }
                if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                    // Update border colors for the current state
                    self.updateAppearanceForState()
                }
            }
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update border layer frame
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        borderLayer.frame = bounds
        CATransaction.commit()
    }
    
    // MARK: - State Management
    
    private func updateAppearanceForState() {
        switch textFieldState {
        case .normal:
            isEnabled = true
            borderLayer.borderColor = AppColors.neutralGray.cgColor
            borderLayer.borderWidth = 1.0
            errorLabel.isHidden = true
            
        case .focused:
            isEnabled = true
            borderLayer.borderColor = AppColors.mintGreen.cgColor
            borderLayer.borderWidth = 2.0
            errorLabel.isHidden = true
            
        case .error(let message):
            isEnabled = true
            borderLayer.borderColor = AppColors.errorRed.cgColor
            borderLayer.borderWidth = 2.0
            errorLabel.text = message
            errorLabel.isHidden = message == nil
            
        case .disabled:
            isEnabled = false
            borderLayer.borderColor = AppColors.neutralGray.withAlphaComponent(0.4).cgColor
            borderLayer.borderWidth = 1.0
            errorLabel.isHidden = true
        }
    }
    
    // MARK: - Event Handlers
    
    @objc private func textFieldEditingDidBegin() {
        if case .error = textFieldState {} else {
            textFieldState = .focused
            updateAppearanceForState()
        }
    }
    
    @objc private func textFieldEditingDidEnd() {
        if case .error = textFieldState {} else {
            textFieldState = .normal
            updateAppearanceForState()
        }
    }
    
    // MARK: - Overrides
    
    override var isEnabled: Bool {
        didSet {
            if !isEnabled {
                if case .disabled = textFieldState {} else {
                    textFieldState = .disabled
                    updateAppearanceForState()
                }
            } else {
                if case .disabled = textFieldState {
                    textFieldState = .normal
                    updateAppearanceForState()
                }
            }
            
            alpha = isEnabled ? 1.0 : GrowthUITheme.ComponentState.disabled.alpha
        }
    }
    
    // Keep for backward compatibility with iOS versions prior to 17.0
    @available(iOS, deprecated: 17.0, message: "Use the trait change registration APIs declared in the UITraitChangeObservable protocol")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 17.0, *) {
            // Using the new API registered in setupTextField()
        } else {
            // For iOS 16 and below, use the old method
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                // Update border colors for the current state
                updateAppearanceForState()
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension GrowthTextField: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if case .error = textFieldState {} else {
            textFieldState = .focused
            updateAppearanceForState()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if case .error = textFieldState {} else {
            textFieldState = .normal
            updateAppearanceForState()
        }
    }
}

// MARK: - Factory Methods

extension GrowthTextField {
    
    /// Creates a text field with the specified placeholder
    /// - Parameter placeholder: The placeholder text
    /// - Returns: A configured text field
    static func textField(placeholder: String) -> GrowthTextField {
        return GrowthTextField(placeholder: placeholder)
    }
    
    /// Creates a text field with the specified placeholder and keyboard type
    /// - Parameters:
    ///   - placeholder: The placeholder text
    ///   - keyboardType: The keyboard type
    /// - Returns: A configured text field
    static func textField(placeholder: String, keyboardType: UIKeyboardType) -> GrowthTextField {
        let textField = GrowthTextField(placeholder: placeholder)
        textField.keyboardType = keyboardType
        return textField
    }
} 