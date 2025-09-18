import SwiftUI

/// View that displays the growth methods scheduled for **today** based on the user's selected routine.
struct DailyMethodsView: View {
    @StateObject private var viewModel = DailyMethodsViewModel()
    @State private var selectedMethod: GrowthMethod?

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Today's Methods")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { viewModel.load() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
        }
        .onAppear {
            viewModel.load()
        }
        .sheet(item: $selectedMethod) { method in
            GrowthMethodDetailView(method: method)
        }
    }

    // MARK: - Sub-views
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading…")
        } else if let error = viewModel.errorMessage {
            errorView(error)
        } else if viewModel.noRoutineSelected {
            noRoutineView
        } else if viewModel.isRestDay {
            restDayView
        } else if viewModel.methods.isEmpty {
            Text("No methods scheduled for today.")
                .foregroundColor(.secondary)
        } else {
            methodsList
        }
    }

    private var restDayView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
            Text("Rest Day")
                .font(AppTheme.Typography.title3Font())
                .bold()
            Text("Take it easy and let your body recover.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var noRoutineView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
            Text("No Routine Selected")
                .font(AppTheme.Typography.title3Font())
                .bold()
            Text("Select a routine to see your scheduled methods.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Error")
                .font(AppTheme.Typography.title3Font())
                .bold()
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Retry") { viewModel.load() }
        }
        .padding()
    }

    private var methodsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let schedule = viewModel.scheduleForToday {
                    Text(schedule.dayName)
                        .font(AppTheme.Typography.headlineFont())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                ForEach(viewModel.methods) { method in
                    MethodCardView(method: method)
                        .onTapGesture { selectedMethod = method }
                }
            }
            .padding()
        }
    }
}

#if DEBUG
struct DailyMethodsView_Previews: PreviewProvider {
    static var previews: some View {
        DailyMethodsView()
    }
}
#endif 