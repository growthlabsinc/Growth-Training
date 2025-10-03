import SwiftUI
// No direct FirebaseAuth/Firestore needed in View if ViewModel handles it

struct LogSessionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationContext: NavigationContext
    @EnvironmentObject var smartNavigationService: SmartNavigationService
    @StateObject private var viewModel: LogSessionViewModel
    
    // Initializer for logging a new session for a specific method
    init(method: GrowthMethod) {
        _viewModel = StateObject(wrappedValue: LogSessionViewModel(methodToLog: method))
    }
    
    // Initializer for logging from timer with duration and optional pre-session mood
    init(method: GrowthMethod, duration: Int, preMoodBefore: Mood? = nil) {
        _viewModel = StateObject(wrappedValue: LogSessionViewModel(methodToLog: method, durationMinutes: duration, preMoodBefore: preMoodBefore))
    }

    // Initializer for editing an existing session log
    init(sessionLogToEdit: SessionLog, method: GrowthMethod) {
        _viewModel = StateObject(wrappedValue: LogSessionViewModel(sessionLogToEdit: sessionLogToEdit, growthMethod: method))
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
                if viewModel.isLoadingMethods {
                    HStack {
                        Label("Method", systemImage: "figure.mind.and.body")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                        Spacer()
                        ProgressView()
                    }
                } else if viewModel.isEditMode {
                    HStack {
                        Label("Method", systemImage: "figure.mind.and.body")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.getMethodTitle(methodId: viewModel.selectedMethodId))
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.primary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Method", systemImage: "figure.mind.and.body")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(viewModel.methods) { method in
                                Button {
                                    viewModel.selectedMethodId = method.id
                                } label: {
                                    Text(method.title)
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedMethodId != nil ? viewModel.getMethodTitle(methodId: viewModel.selectedMethodId) : "Select a method")
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(viewModel.selectedMethodId != nil ? .primary : .secondary)
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
    static var previews: some View {
        Group {
            // Preview for logging a new session from scratch
            LogSessionView()
                .previewDisplayName("New Log - Scratch")

            // Preview for editing an existing session
            let mockMethod = GrowthMethod(
                id: "gm1",
                stage: 1,
                title: "Breathing Exercise",
                methodDescription: "Desc",
                instructionsText: "Instr"
            )
            let mockLog = SessionLog(
                id: "sl1",
                userId: "user123",
                duration: 20,
                startTime: Date().addingTimeInterval(-1200),
                endTime: Date(),
                userNotes: "Felt quite good after this session.",
                methodId: mockMethod.id ?? "gm1_fallback",
                sessionIndex: nil,
                moodBefore: .neutral,
                moodAfter: .positive
            )
            LogSessionView(sessionLogToEdit: mockLog, method: mockMethod)
                .previewDisplayName("Edit Log")
                
            // Preview for logging from timer with duration
            LogSessionView(method: mockMethod, duration: 15)
                .previewDisplayName("Timer Log - Pre-filled Duration")
        }
    }
}
#endif 