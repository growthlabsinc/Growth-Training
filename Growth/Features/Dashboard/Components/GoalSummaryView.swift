import SwiftUI

/// A dashboard component that displays a list of the user's active goals with their progress.
struct GoalSummaryView: View {
    @ObservedObject var viewModel: GoalProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Goals")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("GrowthGreen"))
            if viewModel.isLoading {
                SwiftUI.ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.secondary)
            } else if viewModel.activeGoals.isEmpty {
                Text("No active goals yet").foregroundColor(.secondary)
            } else {
                ForEach(viewModel.activeGoals.prefix(3)) { goal in
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.title)
                                .font(AppTheme.Typography.subheadlineFont())
                                .bold()
                            Text("\(Int(goal.currentValue))/\(Int(goal.targetValue)) \(goal.valueType.rawValue)")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.secondary)
                            GoalProgressBar(progress: viewModel.progress(for: goal), height: 8)
                                .frame(height: 8)
                        }
                        Spacer()
                        if viewModel.progress(for: goal) >= 1.0 {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                        } else if let deadline = goal.deadline {
                            // Deadline indicator
                            Text(daysRemainingText(deadline: deadline))
                                .font(AppTheme.Typography.captionFont())
                                .padding(4)
                                .background(Color(.systemGray5))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadGoals()
        }
    }

    private func daysRemainingText(deadline: Date) -> String {
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        if remaining < 0 { return "Past due" }
        switch remaining {
        case 0: return "Due today"
        case 1: return "1 day left"
        default: return "\(remaining) days left"
        }
    }
}

#if DEBUG
struct GoalSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        var goal1 = Goal(userId: "demo", title: "Complete 10 Sessions", description: "", associatedMethodIds: [], targetValue: 10, valueType: .sessions, timeframe: .shortTerm)
        goal1.currentValue = 3
        var goal2 = Goal(userId: "demo", title: "Meditate 300 minutes", description: "", associatedMethodIds: [], targetValue: 300, valueType: .minutes, timeframe: .mediumTerm)
        goal2.currentValue = 150

        let vm = GoalProgressViewModel(previewGoals: [goal1, goal2])
        return GoalSummaryView(viewModel: vm)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 