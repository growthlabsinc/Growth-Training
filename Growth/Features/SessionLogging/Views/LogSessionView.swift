import SwiftUI
// No direct FirebaseAuth/Firestore needed in View if ViewModel handles it

struct LogSessionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationContext: NavigationContext
    @EnvironmentObject var smartNavigationService: SmartNavigationService
    @StateObject private var viewModel: LogSessionViewModel
    @ObservedObject private var gainsService = GainsService.shared

    // Story 10.2: Measurement input state
    @State private var showMeasurementInputs = false
    @State private var bpelValue: String = ""
    @State private var bpfslValue: String = ""
    @State private var msegValue: String = ""
    @State private var bpelValidation: MeasurementValidationResult = .valid
    @State private var bpfslValidation: MeasurementValidationResult = .valid
    @State private var msegValidation: MeasurementValidationResult = .valid
    @State private var showingSoftLimitAlert = false
    @State private var softLimitMessage: String = ""
    
    // Initializer for logging a new session for a specific method
    init(method: TrainingProtocol) {
        _viewModel = StateObject(wrappedValue: LogSessionViewModel(protocolToLog: method))
    }
    
    // Initializer for logging from timer with duration and optional pre-session mood
    init(method: TrainingProtocol, duration: Int, preMoodBefore: Mood? = nil) {
        _viewModel = StateObject(wrappedValue: LogSessionViewModel(protocolToLog: method, durationMinutes: duration, preMoodBefore: preMoodBefore))
    }

    // Initializer for editing an existing session log
    init(sessionLogToEdit: SessionLog, method: TrainingProtocol) {
        _viewModel = StateObject(wrappedValue: LogSessionViewModel(sessionLogToEdit: sessionLogToEdit, growthProtocol: method))
    }
    
    // Initializer for logging a new session from scratch
    init() {
        _viewModel = StateObject(wrappedValue: LogSessionViewModel())
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color("GrowthGreen").opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Header
                        heroHeader
                            .padding(.top, 20)
                        
                        // Session Details Card
                        sessionDetailsCard
                            .padding(.horizontal)
                        
                        // Notes Card with Journaling Prompt
                        notesCard
                            .padding(.horizontal)
                        
                        // Mood Check-in Card
                        moodCheckInCard
                            .padding(.horizontal)

                        // Story 10.2: Pre-Session Measurements Card (Optional)
                        measurementsCard
                            .padding(.horizontal)

                        // Session Feedback Card
                        sessionFeedbackCard
                            .padding(.horizontal)
                        
                        // Save Button
                        saveButton
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert(item: $viewModel.errorAlert) { alertItem in
                Alert(
                    title: Text("Error"),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onReceive(viewModel.$saveSuccess) { success in
                if success {
                    // Execute smart return if practice flow is active
                    if navigationContext.practiceFlowActive {
                        smartNavigationService.completePracticeFlow()
                    }
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GrowthGreen"),
                        Color("BrightTeal")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 180)
                
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: viewModel.isEditMode ? "pencil.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(viewModel.isEditMode ? "Edit Session" : "Log New Session")
                        .font(AppTheme.Typography.gravityBoldFont(28))
                        .foregroundColor(.white)
                    
                    Text(viewModel.isEditMode ? "Update your session details" : "Track your practice and progress")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(20)
            }
            .cornerRadius(16)
            .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Session Details Card
    
    private var sessionDetailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color("GrowthGreen"))
                Text("Session Details")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 16) {
                // Date & Time
                HStack {
                    Label("Date & Time", systemImage: "calendar")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $viewModel.sessionDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                Divider()
                
                // Method Selection
                if viewModel.isLoadingProtocols {
                    HStack {
                        Label("Protocol", systemImage: "figure.mind.and.body")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                        Spacer()
                        ProgressView()
                    }
                } else if viewModel.isEditMode {
                    HStack {
                        Label("Protocol", systemImage: "figure.mind.and.body")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.getProtocolTitle(protocolId: viewModel.selectedProtocolId))
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.primary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Protocol", systemImage: "figure.mind.and.body")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(viewModel.protocols) { method in
                                Button {
                                    viewModel.selectedProtocolId = method.id
                                } label: {
                                    Text(method.title)
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedProtocolId != nil ? viewModel.getProtocolTitle(protocolId: viewModel.selectedProtocolId) : "Select a protocol")
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(viewModel.selectedProtocolId != nil ? .primary : .secondary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Divider()
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Label("Duration", systemImage: "timer")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $viewModel.durationMinutes)
                            .keyboardType(.numberPad)
                            .font(AppTheme.Typography.gravitySemibold(24))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                        
                        Text("minutes")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Notes Card
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(Color("GrowthGreen"))
                Text("Session Notes")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(.primary)
            }
            
            if let prompt = viewModel.currentPrompt {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reflection Prompt")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.secondary)
                        Text(prompt.text)
                            .font(AppTheme.Typography.calloutFont())
                            .foregroundColor(Color("GrowthGreen"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 12)
                    
                    Button {
                        withAnimation(.spring()) {
                            viewModel.refreshPrompt()
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(AppTheme.Typography.subheadlineFont())
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                .padding(12)
                .background(Color("GrowthGreen").opacity(0.1))
                .cornerRadius(8)
            }
            
            TextEditor(text: $viewModel.notes)
                .font(AppTheme.Typography.bodyFont())
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Mood Check-in Card
    
    private var moodCheckInCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(Color("GrowthGreen"))
                Text("Mood Check-in")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 20) {
                moodSelector(label: "Before Session", selection: $viewModel.moodBefore)
                Divider()
                moodSelector(label: "After Session", selection: $viewModel.moodAfter)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func moodSelector(label: String, selection: Binding<Mood>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.spring()) {
                            selection.wrappedValue = mood
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(AppTheme.Typography.title1Font())
                            Text(mood.displayName)
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(selection.wrappedValue == mood ? Color("GrowthGreen") : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selection.wrappedValue == mood ? Color("GrowthGreen").opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selection.wrappedValue == mood ? Color("GrowthGreen") : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Story 10.2: Measurements Card (Optional)

    private var measurementsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with expand/collapse button
            Button(action: {
                withAnimation(.spring()) {
                    showMeasurementInputs.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(Color("GrowthGreen"))
                    Text("Pre-Session Measurements (Optional)")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: showMeasurementInputs ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .buttonStyle(PlainButtonStyle())

            if showMeasurementInputs {
                VStack(alignment: .leading, spacing: 20) {
                    // Info text
                    Text("Track your baseline to measure temporary gains (yield) from this session.")
                        .font(AppTheme.Typography.calloutFont())
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    // Unit display
                    HStack {
                        Text("Unit")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(gainsService.preferredUnit.displayName)
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.primary)
                    }

                    Divider()

                    // BPEL Input
                    measurementField(
                        label: "BPEL",
                        fullName: "Bone Pressed Erect Length",
                        value: $bpelValue,
                        validation: bpelValidation,
                        measurementType: .bpel
                    )

                    Divider()

                    // BPFSL Input
                    measurementField(
                        label: "BPFSL",
                        fullName: "Bone Pressed Flaccid Stretched Length",
                        value: $bpfslValue,
                        validation: bpfslValidation,
                        measurementType: .bpfsl
                    )

                    Divider()

                    // MSEG Input
                    measurementField(
                        label: "MSEG",
                        fullName: "Mid-Shaft Erect Girth",
                        value: $msegValue,
                        validation: msegValidation,
                        measurementType: .mseg
                    )

                    // Clear measurements button
                    if !bpelValue.isEmpty || !bpfslValue.isEmpty || !msegValue.isEmpty {
                        Button(action: clearMeasurements) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Clear All Measurements")
                                    .font(AppTheme.Typography.bodyFont())
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert("Confirm Measurement", isPresented: $showingSoftLimitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Continue") {
                updateViewModelMeasurements()
            }
        } message: {
            Text(softLimitMessage)
        }
    }

    // MARK: - Measurement Field Component (Story 10.2)

    private func measurementField(
        label: String,
        fullName: String,
        value: Binding<String>,
        validation: MeasurementValidationResult,
        measurementType: MeasurementType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTheme.Typography.bodyFont())
                    .fontWeight(.semibold)
                Text(fullName)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
            }

            // Text Field
            HStack {
                TextField(
                    MeasurementFormatter.placeholder(for: measurementType, unit: gainsService.preferredUnit),
                    text: value
                )
                .keyboardType(MeasurementFormatter.keyboardType(for: gainsService.preferredUnit))
                .font(AppTheme.Typography.bodyFont())
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)
                .onChange(of: value.wrappedValue) { newValue in
                    validateMeasurement(type: measurementType, value: newValue)
                }

                Text(gainsService.preferredUnit.lengthSymbol)
                    .font(AppTheme.Typography.calloutFont())
                    .foregroundColor(.secondary)
                    .frame(width: 32)
            }

            // Validation Error Message
            if validation.isHardError {
                if case .hardLimitError(let message) = validation {
                    Text(message)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Session Feedback Card

    private var sessionFeedbackCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color("GrowthGreen"))
                Text("Session Feedback")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 20) {
                // Intensity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Intensity / Difficulty")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                withAnimation(.spring()) {
                                    viewModel.intensity = value
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: value <= viewModel.intensity ? "flame.fill" : "flame")
                                        .font(AppTheme.Typography.title2Font())
                                        .foregroundColor(value <= viewModel.intensity ? intensityColor(for: value) : Color.gray.opacity(0.4))
                                    Text("\(value)")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(value <= viewModel.intensity ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(value == viewModel.intensity ? intensityColor(for: value).opacity(0.15) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(value == viewModel.intensity ? intensityColor(for: value).opacity(0.5) : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Divider()
                
                // Variation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Variation (optional)")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Modified version, Advanced form", text: $viewModel.variation)
                        .font(AppTheme.Typography.bodyFont())
                        .padding(12)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            viewModel.saveSession()
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: viewModel.isEditMode ? "checkmark.circle.fill" : "plus.circle.fill")
                    Text(viewModel.saveButtonText)
                        .font(AppTheme.Typography.gravitySemibold(16))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        viewModel.formIsValid && !viewModel.isSaving ? Color("GrowthGreen") : Color.gray,
                        viewModel.formIsValid && !viewModel.isSaving ? Color("BrightTeal") : Color.gray.opacity(0.8)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(
                color: viewModel.formIsValid && !viewModel.isSaving ? Color("GrowthGreen").opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(!viewModel.formIsValid || viewModel.isSaving)
    }
    
    // MARK: - Measurement Helper Methods (Story 10.2)

    private func validateMeasurement(type: MeasurementType, value: String) {
        guard !value.isEmpty, let numericValue = Double(value) else {
            // Reset validation if value is empty or invalid
            switch type {
            case .bpel: bpelValidation = .valid
            case .bpfsl: bpfslValidation = .valid
            case .mseg: msegValidation = .valid
            default: break
            }
            return
        }

        // Validate using MeasurementValidator
        let result = MeasurementValidator.validate(value: numericValue, type: type, unit: gainsService.preferredUnit)

        // Update validation state
        switch type {
        case .bpel: bpelValidation = result
        case .bpfsl: bpfslValidation = result
        case .mseg: msegValidation = result
        default: break
        }

        // Automatically update viewModel if no hard errors
        updateViewModelMeasurementsIfValid()
    }

    private func updateViewModelMeasurementsIfValid() {
        // Check for hard errors
        let hasHardErrors = bpelValidation.isHardError || bpfslValidation.isHardError || msegValidation.isHardError
        guard !hasHardErrors else {
            // Don't update if there are hard errors
            viewModel.preMeasurements = nil
            return
        }

        // Check for soft limit warnings
        var softLimitWarnings: [String] = []
        var measurements: [MeasurementType: Double] = [:]

        // Collect and validate BPEL
        if let bpel = Double(bpelValue), !bpelValue.isEmpty {
            let result = MeasurementValidator.validate(value: bpel, type: .bpel, unit: measurementUnit)
            if result.isSoftWarning {
                if case .softLimitWarning(let message) = result {
                    softLimitWarnings.append("BPEL: \(message)")
                }
            }
            let valueInInches = MeasurementValidator.toInches(bpel, from: gainsService.preferredUnit)
            measurements[.bpel] = valueInInches
        }

        // Collect and validate BPFSL
        if let bpfsl = Double(bpfslValue), !bpfslValue.isEmpty {
            let result = MeasurementValidator.validate(value: bpfsl, type: .bpfsl, unit: measurementUnit)
            if result.isSoftWarning {
                if case .softLimitWarning(let message) = result {
                    softLimitWarnings.append("BPFSL: \(message)")
                }
            }
            let valueInInches = MeasurementValidator.toInches(bpfsl, from: gainsService.preferredUnit)
            measurements[.bpfsl] = valueInInches
        }

        // Collect and validate MSEG
        if let mseg = Double(msegValue), !msegValue.isEmpty {
            let result = MeasurementValidator.validate(value: mseg, type: .mseg, unit: measurementUnit)
            if result.isSoftWarning {
                if case .softLimitWarning(let message) = result {
                    softLimitWarnings.append("MSEG: \(message)")
                }
            }
            let valueInInches = MeasurementValidator.toInches(mseg, from: gainsService.preferredUnit)
            measurements[.mseg] = valueInInches
        }

        // If soft limit warnings exist, show confirmation alert
        if !softLimitWarnings.isEmpty {
            softLimitMessage = softLimitWarnings.joined(separator: "\n\n")
            showingSoftLimitAlert = true
            // Don't update yet - wait for user confirmation
        } else {
            // No warnings - update directly
            viewModel.preMeasurements = measurements.isEmpty ? nil : measurements
        }
    }

    private func updateViewModelMeasurements() {
        // Called after user confirms soft limit warning
        var measurements: [MeasurementType: Double] = [:]

        if let bpel = Double(bpelValue), !bpelValue.isEmpty {
            let valueInInches = MeasurementValidator.toInches(bpel, from: gainsService.preferredUnit)
            measurements[.bpel] = valueInInches
        }

        if let bpfsl = Double(bpfslValue), !bpfslValue.isEmpty {
            let valueInInches = MeasurementValidator.toInches(bpfsl, from: gainsService.preferredUnit)
            measurements[.bpfsl] = valueInInches
        }

        if let mseg = Double(msegValue), !msegValue.isEmpty {
            let valueInInches = MeasurementValidator.toInches(mseg, from: gainsService.preferredUnit)
            measurements[.mseg] = valueInInches
        }

        viewModel.preMeasurements = measurements.isEmpty ? nil : measurements
    }

    private func clearMeasurements() {
        withAnimation {
            bpelValue = ""
            bpfslValue = ""
            msegValue = ""
            bpelValidation = .valid
            bpfslValidation = .valid
            msegValidation = .valid
            viewModel.preMeasurements = nil
        }
    }

    // MARK: - Helper Methods

    private func intensityColor(for level: Int) -> Color {
        switch level {
        case 1: return Color("GrowthGreen")
        case 2: return Color("GrowthGreen").opacity(0.8)
        case 3: return .orange
        case 4: return Color.orange.opacity(0.8)
        case 5: return .red
        default: return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LogSessionView_Previews: PreviewProvider {
    static let mockProtocol = TrainingProtocol(
        id: "gm1",
        stage: 1,
        title: "Breathing Exercise",
        protocolDescription: "Desc",
        instructionsText: "Instr"
    )

    static let mockLog = SessionLog(
        id: "sl1",
        userId: "user123",
        duration: 20,
        startTime: Date().addingTimeInterval(-1200),
        endTime: Date(),
        userNotes: "Felt quite good after this session.",
        methodId: mockProtocol.id ?? "gm1_fallback",
        sessionIndex: nil,
        moodBefore: .neutral,
        moodAfter: .positive
    )

    static var previews: some View {
        // Preview for logging a new session from scratch
        LogSessionView()
            .previewDisplayName("New Log - Scratch")
    }
}
#endif 