import UIKit

/// A view controller that showcases all the Growth app UI components
class StyleGuideViewController: UIViewController {
    
    // MARK: - Properties
    
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupColors()
        setupTypography()
        setupButtons()
        setupCards()
        setupTextFields()
    }
    
    // MARK: - View Setup
    
    private func setupView() {
        title = "GROWTH Style Guide"
        view.backgroundColor = AppColors.backgroundLight
        
        // Set up scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Set up stack view
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        contentStackView.spacing = GrowthUITheme.Spacing.medium
        contentStackView.isLayoutMarginsRelativeArrangement = true
        contentStackView.layoutMargins = UIEdgeInsets(
            top: GrowthUITheme.Spacing.medium,
            left: GrowthUITheme.Spacing.medium, 
            bottom: GrowthUITheme.Spacing.medium,
            right: GrowthUITheme.Spacing.medium
        )
        
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    // MARK: - Component Setup

    /// Adds a section header to the content stack view
    /// - Parameter title: The section title
    private func addSectionHeader(_ title: String) {
        let headerLabel = UILabel()
        headerLabel.font = UIFont.growth(style: .h2)
        headerLabel.textColor = AppColors.darkText
        headerLabel.text = title
        contentStackView.addArrangedSubview(headerLabel)
        
        // Add some space below the header
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: GrowthUITheme.Spacing.small).isActive = true
        contentStackView.addArrangedSubview(spacer)
    }
    
    private func setupColors() {
        addSectionHeader("Colors")
        
        let colorStackView = UIStackView()
        colorStackView.axis = .vertical
        colorStackView.spacing = GrowthUITheme.Spacing.small
        colorStackView.alignment = .fill
        colorStackView.distribution = .fill
        
        // Primary colors
        addColorSection(to: colorStackView, title: "Primary Colors", colors: [
            ("Pure White", AppColors.pureWhite),
            ("Core Green", AppColors.coreGreen)
        ])
        
        // Secondary colors
        addColorSection(to: colorStackView, title: "Secondary Colors", colors: [
            ("Mint Green", AppColors.mintGreen),
            ("Pale Green", AppColors.paleGreen)
        ])
        
        // Accent colors
        addColorSection(to: colorStackView, title: "Accent Colors", colors: [
            ("Bright Teal", AppColors.brightTeal),
            ("Vital Yellow", AppColors.vitalYellow)
        ])
        
        // Functional colors
        addColorSection(to: colorStackView, title: "Functional Colors", colors: [
            ("Success Green", AppColors.successGreen),
            ("Warning Amber", AppColors.warningAmber),
            ("Error Red", AppColors.errorRed),
            ("Neutral Gray", AppColors.neutralGray),
            ("Dark Text", AppColors.darkText)
        ])
        
        // Background colors
        addColorSection(to: colorStackView, title: "Background Colors", colors: [
            ("Surface White", AppColors.surfaceWhite),
            ("Background Light", AppColors.backgroundLight)
        ])
        
        contentStackView.addArrangedSubview(colorStackView)
    }
    
    private func addColorSection(to stackView: UIStackView, title: String, colors: [(String, UIColor)]) {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.growth(style: .h3)
        titleLabel.textColor = AppColors.darkText
        titleLabel.text = title
        stackView.addArrangedSubview(titleLabel)
        
        let colorGrid = UIStackView()
        colorGrid.axis = .horizontal
        colorGrid.distribution = .fillEqually
        colorGrid.spacing = GrowthUITheme.Spacing.small
        
        for (name, color) in colors {
            let colorView = UIView()
            colorView.backgroundColor = color
            colorView.layer.cornerRadius = 8
            colorView.layer.borderWidth = 1
            colorView.layer.borderColor = UIColor.gray.withAlphaComponent(0.2).cgColor
            
            let colorLabel = UILabel()
            colorLabel.font = UIFont.growth(style: .caption)
            colorLabel.textColor = AppColors.darkText
            colorLabel.text = name
            colorLabel.textAlignment = .center
            colorLabel.numberOfLines = 0
            
            let colorStack = UIStackView()
            colorStack.axis = .vertical
            colorStack.spacing = 4
            colorStack.alignment = .fill
            
            colorView.heightAnchor.constraint(equalToConstant: 60).isActive = true
            
            colorStack.addArrangedSubview(colorView)
            colorStack.addArrangedSubview(colorLabel)
            
            colorGrid.addArrangedSubview(colorStack)
        }
        
        stackView.addArrangedSubview(colorGrid)
        
        // Add spacing after each color section
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: GrowthUITheme.Spacing.small).isActive = true
        stackView.addArrangedSubview(spacer)
    }
    
    private func setupTypography() {
        addSectionHeader("Typography")
        
        let typographyStackView = UIStackView()
        typographyStackView.axis = .vertical
        typographyStackView.spacing = GrowthUITheme.Spacing.default
        typographyStackView.alignment = .fill
        
        // Headings
        let h1Label = UILabel()
        h1Label.font = UIFont.growth(style: .h1)
        h1Label.textColor = AppColors.darkText
        h1Label.text = "H1 Heading (32/36)"
        typographyStackView.addArrangedSubview(h1Label)
        
        let h2Label = UILabel()
        h2Label.font = UIFont.growth(style: .h2)
        h2Label.textColor = AppColors.darkText
        h2Label.text = "H2 Heading (26/30)"
        typographyStackView.addArrangedSubview(h2Label)
        
        let h3Label = UILabel()
        h3Label.font = UIFont.growth(style: .h3)
        h3Label.textColor = AppColors.darkText
        h3Label.text = "H3 Heading (20/24)"
        typographyStackView.addArrangedSubview(h3Label)
        
        // Body text
        let bodyLargeLabel = UILabel()
        bodyLargeLabel.font = UIFont.growth(style: .bodyLarge)
        bodyLargeLabel.textColor = AppColors.darkText
        bodyLargeLabel.text = "Body Large (17/24) - Primary reading text for detailed content"
        bodyLargeLabel.numberOfLines = 0
        typographyStackView.addArrangedSubview(bodyLargeLabel)
        
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.growth(style: .body)
        bodyLabel.textColor = AppColors.darkText
        bodyLabel.text = "Body (15/20) - Standard text for most UI elements"
        bodyLabel.numberOfLines = 0
        typographyStackView.addArrangedSubview(bodyLabel)
        
        let bodySmallLabel = UILabel()
        bodySmallLabel.font = UIFont.growth(style: .bodySmall)
        bodySmallLabel.textColor = AppColors.darkText
        bodySmallLabel.text = "Body Small (13/18) - Secondary information and supporting text"
        bodySmallLabel.numberOfLines = 0
        typographyStackView.addArrangedSubview(bodySmallLabel)
        
        // Special text
        let captionLabel = UILabel()
        captionLabel.font = UIFont.growth(style: .caption)
        captionLabel.textColor = AppColors.darkText
        captionLabel.text = "Caption (12/16) - Used for timestamps, metadata, and labels"
        captionLabel.numberOfLines = 0
        typographyStackView.addArrangedSubview(captionLabel)
        
        let buttonTextLabel = UILabel()
        buttonTextLabel.font = UIFont.growth(style: .buttonText)
        buttonTextLabel.textColor = AppColors.darkText
        buttonTextLabel.text = "Button Text (16/20) - Used specifically for buttons and interactive elements"
        buttonTextLabel.numberOfLines = 0
        typographyStackView.addArrangedSubview(buttonTextLabel)
        
        let metricValueLabel = UILabel()
        metricValueLabel.font = UIFont.growth(style: .metricValue)
        metricValueLabel.textColor = AppColors.darkText
        metricValueLabel.text = "Metric Value (22/26) - Used for displaying progress numbers and key metrics"
        metricValueLabel.numberOfLines = 0
        typographyStackView.addArrangedSubview(metricValueLabel)
        
        let progressLabel = UILabel()
        progressLabel.font = UIFont.growth(style: .progressLabel)
        progressLabel.textColor = AppColors.coreGreen
        progressLabel.text = "Progress Label (14/18) - Used for labeling progress indicators and achievements"
        progressLabel.numberOfLines = 0
        typographyStackView.addArrangedSubview(progressLabel)
        
        contentStackView.addArrangedSubview(typographyStackView)
    }
    
    private func setupButtons() {
        addSectionHeader("Buttons")
        
        let buttonStackView = UIStackView()
        buttonStackView.axis = .vertical
        buttonStackView.spacing = GrowthUITheme.Spacing.default
        buttonStackView.alignment = .fill
        
        // Primary Button
        let primaryButton = GrowthButton.primaryButton(title: "Primary Button")
        buttonStackView.addArrangedSubview(primaryButton)
        
        // Secondary Button
        let secondaryButton = GrowthButton.secondaryButton(title: "Secondary Button")
        buttonStackView.addArrangedSubview(secondaryButton)
        
        // Text Button
        let textButton = GrowthButton.textButton(title: "Text Button")
        buttonStackView.addArrangedSubview(textButton)
        
        // Icon Buttons
        let iconButtonsStack = UIStackView()
        iconButtonsStack.axis = .horizontal
        iconButtonsStack.spacing = GrowthUITheme.Spacing.default
        iconButtonsStack.distribution = .fillEqually
        
        // Create image configurations for SF Symbols
        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        
        // Add several icon buttons with different SF Symbol icons
        let icons = ["plus", "minus", "heart", "star"]
        for iconName in icons {
            if let image = UIImage(systemName: iconName, withConfiguration: configuration) {
                let iconButton = GrowthButton.iconButton(icon: image)
                iconButtonsStack.addArrangedSubview(iconButton)
            }
        }
        
        buttonStackView.addArrangedSubview(iconButtonsStack)
        
        // Disabled Buttons
        let disabledPrimaryButton = GrowthButton.primaryButton(title: "Disabled Primary")
        disabledPrimaryButton.isEnabled = false
        
        let disabledSecondaryButton = GrowthButton.secondaryButton(title: "Disabled Secondary")
        disabledSecondaryButton.isEnabled = false
        
        let disabledButtonsStack = UIStackView()
        disabledButtonsStack.axis = .horizontal
        disabledButtonsStack.spacing = GrowthUITheme.Spacing.default
        disabledButtonsStack.distribution = .fillEqually
        
        disabledButtonsStack.addArrangedSubview(disabledPrimaryButton)
        disabledButtonsStack.addArrangedSubview(disabledSecondaryButton)
        
        buttonStackView.addArrangedSubview(disabledButtonsStack)
        
        contentStackView.addArrangedSubview(buttonStackView)
    }
    
    private func setupCards() {
        addSectionHeader("Cards")
        
        let cardStackView = UIStackView()
        cardStackView.axis = .vertical
        cardStackView.spacing = GrowthUITheme.Spacing.large
        cardStackView.alignment = .fill
        
        // Standard Card
        let standardCardLabel = UILabel()
        standardCardLabel.font = UIFont.growth(style: .caption)
        standardCardLabel.textColor = AppColors.darkText
        standardCardLabel.text = "Standard Card"
        cardStackView.addArrangedSubview(standardCardLabel)
        
        let standardCard = GrowthCard.standardCard()
        standardCard.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        let standardCardContent = UILabel()
        standardCardContent.text = "Standard Card Content"
        standardCardContent.font = UIFont.growth(style: .body)
        standardCardContent.textColor = AppColors.darkText
        standardCardContent.textAlignment = .center
        
        standardCard.addContent(standardCardContent)
        cardStackView.addArrangedSubview(standardCard)
        
        // Workout Card
        let workoutCardLabel = UILabel()
        workoutCardLabel.font = UIFont.growth(style: .caption)
        workoutCardLabel.textColor = AppColors.darkText
        workoutCardLabel.text = "Workout Card"
        cardStackView.addArrangedSubview(workoutCardLabel)
        
        let workoutCard = GrowthCard.workoutCard()
        workoutCard.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        let workoutCardStack = UIStackView()
        workoutCardStack.axis = .vertical
        workoutCardStack.spacing = GrowthUITheme.Spacing.small
        workoutCardStack.alignment = .center
        workoutCardStack.distribution = .fillEqually
        
        let workoutTitle = UILabel()
        workoutTitle.text = "Angion Method - Level 1"
        workoutTitle.font = UIFont.growth(style: .h3)
        workoutTitle.textColor = AppColors.darkText
        workoutTitle.textAlignment = .center
        
        let workoutDescription = UILabel()
        workoutDescription.text = "Beginner friendly introduction to the method"
        workoutDescription.font = UIFont.growth(style: .body)
        workoutDescription.textColor = AppColors.darkText
        workoutDescription.textAlignment = .center
        workoutDescription.numberOfLines = 0
        
        workoutCardStack.addArrangedSubview(workoutTitle)
        workoutCardStack.addArrangedSubview(workoutDescription)
        
        workoutCard.addContent(workoutCardStack)
        cardStackView.addArrangedSubview(workoutCard)
        
        // Progress Card
        let progressCardLabel = UILabel()
        progressCardLabel.font = UIFont.growth(style: .caption)
        progressCardLabel.textColor = AppColors.darkText
        progressCardLabel.text = "Progress Card"
        cardStackView.addArrangedSubview(progressCardLabel)
        
        let progressCard = GrowthCard.progressCard()
        progressCard.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        let progressCardStack = UIStackView()
        progressCardStack.axis = .vertical
        progressCardStack.spacing = GrowthUITheme.Spacing.default
        progressCardStack.alignment = .fill
        progressCardStack.distribution = .fill
        
        let progressTitle = UILabel()
        progressTitle.text = "Weekly Progress"
        progressTitle.font = UIFont.growth(style: .h3)
        progressTitle.textColor = AppColors.darkText
        
        // Progress bar (simulated)
        let progressBarContainer = UIView()
        progressBarContainer.backgroundColor = UIColor.white
        progressBarContainer.layer.cornerRadius = 4
        progressBarContainer.heightAnchor.constraint(equalToConstant: GrowthUITheme.ComponentSize.linearProgressHeight).isActive = true
        
        let progressFill = UIView()
        progressFill.backgroundColor = AppColors.coreGreen
        progressFill.layer.cornerRadius = 4
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        
        progressBarContainer.addSubview(progressFill)
        
        NSLayoutConstraint.activate([
            progressFill.topAnchor.constraint(equalTo: progressBarContainer.topAnchor),
            progressFill.leadingAnchor.constraint(equalTo: progressBarContainer.leadingAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressBarContainer.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor, multiplier: 0.7) // 70% progress
        ])
        
        let progressDetails = UILabel()
        progressDetails.text = "7 out of 10 workouts completed"
        progressDetails.font = UIFont.growth(style: .body)
        progressDetails.textColor = AppColors.darkText
        
        progressCardStack.addArrangedSubview(progressTitle)
        progressCardStack.addArrangedSubview(progressBarContainer)
        progressCardStack.addArrangedSubview(progressDetails)
        
        progressCard.addContent(progressCardStack)
        cardStackView.addArrangedSubview(progressCard)
        
        contentStackView.addArrangedSubview(cardStackView)
    }
    
    private func setupTextFields() {
        addSectionHeader("Text Fields")
        
        let textFieldStackView = UIStackView()
        textFieldStackView.axis = .vertical
        textFieldStackView.spacing = GrowthUITheme.Spacing.large
        textFieldStackView.alignment = .fill
        
        // Note: GrowthTextField component not yet implemented
        // Text fields in the app use SwiftUI's TextInputField and AuthTextField components
        
        let placeholderLabel = UILabel()
        placeholderLabel.text = "Text field components are implemented in SwiftUI.\nSee TextInputField and AuthTextField."
        placeholderLabel.font = AppTypography.font(for: .caption)
        placeholderLabel.textColor = AppColors.secondaryLabel
        placeholderLabel.numberOfLines = 0
        placeholderLabel.textAlignment = .center
        textFieldStackView.addArrangedSubview(placeholderLabel)
        
        contentStackView.addArrangedSubview(textFieldStackView)
    }
}

// MARK: - Preview Provider for SwiftUI Canvas

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct StyleGuideViewControllerPreview: PreviewProvider {
    static var previews: some View {
        // Create the UIViewController
        let viewController = StyleGuideViewController()
        
        // Wrap it in a UIViewControllerRepresentable
        UIViewControllerPreview(viewController)
            .edgesIgnoringSafeArea(.all)
            .previewDisplayName("Style Guide")
        
        // Add a dark mode preview
        UIViewControllerPreview(viewController)
            .edgesIgnoringSafeArea(.all)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Style Guide (Dark)")
    }
}

// Helper struct to create SwiftUI previews from UIViewControllers
@available(iOS 13.0, *)
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController
    
    init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }
    
    init(_ viewController: ViewController) {
        self.viewController = viewController
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Not needed
    }
}
#endif 