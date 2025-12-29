//
//  GoalIntents.swift
//  MyTasksAI
//
//  AppIntents for interactive goal snippets
//

import AppIntents
import SwiftUI

// MARK: - Goal Entity (for AppIntents)

struct GoalEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal")

    static var defaultQuery = GoalEntityQuery()

    var id: String  // UUID as string for AppIntents compatibility
    var title: String
    var progress: Double
    var category: String?
    var timeframe: String?
    var themeColor: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(Int(progress * 100))% complete",
            image: .init(systemName: iconName)
        )
    }

    private var iconName: String {
        if let timeframe = timeframe {
            return GoalTimeframe(rawValue: timeframe)?.icon ?? "target"
        } else if let category = category {
            return GoalCategory(rawValue: category)?.icon ?? "target"
        }
        return "target"
    }
}

// MARK: - Goal Entity Query

struct GoalEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [GoalEntity] {
        // In real implementation, fetch from your model context
        return []
    }

    func suggestedEntities() async throws -> [GoalEntity] {
        // Return suggested goals (e.g., active goals)
        return []
    }
}

// MARK: - Check In Goal Intent

struct CheckInGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In on Goal"
    static var description = IntentDescription("Record progress on your goal")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Goal ID")
    var goalId: String

    init() {}

    init(goalId: UUID) {
        self.goalId = goalId.uuidString
    }

    func perform() async throws -> some IntentResult {
        // Update check-in streak and date
        // In real implementation, access your model using UUID(uuidString: goalId)

        return .result()
    }
}

// MARK: - View Goal Intent

struct ViewGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "View Goal"
    static var description = IntentDescription("Open and view goal details")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Goal ID")
    var goalId: String

    init() {}

    init(goalId: UUID) {
        self.goalId = goalId.uuidString
    }

    func perform() async throws -> some IntentResult {
        // Navigate to goal detail view using UUID(uuidString: goalId)
        return .result()
    }
}

// MARK: - Update Progress Intent

struct UpdateGoalProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Goal Progress"
    static var description = IntentDescription("Update the progress of a goal")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Goal")
    var goal: GoalEntity
    
    @Parameter(title: "New Progress", controlStyle: .slider)
    var progress: Double
    
    func perform() async throws -> some IntentResult & ReturnsValue<GoalEntity> {
        // Update goal progress
        var updatedGoal = goal
        updatedGoal.progress = progress
        
        return .result(value: updatedGoal)
    }
}

// MARK: - Complete Milestone Intent

struct CompleteMilestoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Milestone"
    static var description = IntentDescription("Mark a milestone as complete")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Goal ID")
    var goalId: String

    @Parameter(title: "Milestone Name")
    var milestoneName: String

    init() {}

    init(goalId: UUID, milestoneName: String) {
        self.goalId = goalId.uuidString
        self.milestoneName = milestoneName
    }

    func perform() async throws -> some IntentResult {
        // Mark milestone as complete using UUID(uuidString: goalId)
        // Show celebratory snippet

        return .result()
    }
}

// MARK: - Get Today's Goals Intent (for Siri/Shortcuts)

struct GetTodaysGoalsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Goals"
    static var description = IntentDescription("See goals you should focus on today")
    static var openAppWhenRun: Bool = false
    static var supportedModes: IntentModes = [.background, .foreground(.dynamic)]
    
    func perform() async throws -> some IntentResult & ReturnsValue<[GoalEntity]> & ProvidesDialog {
        // Fetch goals that need attention
        let goals = await fetchPriorityGoals()
        
        let dialog: IntentDialog
        if goals.isEmpty {
            dialog = "You don't have any goals that need attention today. Great job staying on track!"
        } else {
            dialog = "You have \(goals.count) goals that could use your attention today."
        }
        
        return .result(value: goals, dialog: dialog)
    }
    
    private func fetchPriorityGoals() async -> [GoalEntity] {
        // In real implementation, fetch from your model
        return []
    }
}

// MARK: - Goal Snippet View (Interactive Snippet Component)

struct GoalSnippetView: View {
    let goal: GoalEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(themeColor)

                Text(goal.title)
                    .font(.headline)

                Spacer()
            }

            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.title.weight(.bold))
                        .foregroundStyle(themeColor)

                    Text("complete")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: goal.progress)
                    .tint(themeColor)
            }

            // Action buttons
            if let uuid = UUID(uuidString: goal.id) {
                HStack(spacing: 12) {
                    Button(intent: CheckInGoalIntent(goalId: uuid)) {
                        Label("Check In", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeColor)

                    Button(intent: ViewGoalIntent(goalId: uuid)) {
                        Label("Open", systemImage: "arrow.up.right")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .glassEffect(.regular.tint(themeColor).interactive(), in: .rect(cornerRadius: 20))
    }

    private var iconName: String {
        if let timeframe = goal.timeframe {
            return GoalTimeframe(rawValue: timeframe)?.icon ?? "target"
        } else if let category = goal.category {
            return GoalCategory(rawValue: category)?.icon ?? "target"
        }
        return "target"
    }

    private var themeColor: Color {
        // Parse stored color string to Color
        if let timeframe = goal.timeframe {
            return GoalTimeframe(rawValue: timeframe)?.color ?? .blue
        } else if let category = goal.category {
            return GoalCategory(rawValue: category)?.color ?? .blue
        }
        return .blue
    }
}

// MARK: - App Shortcuts
// Note: Goal shortcuts are merged into VeloceShortcuts in SiriShortcutsService.swift
// Only one AppShortcutsProvider conformance is allowed per app
