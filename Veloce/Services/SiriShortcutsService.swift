//
//  SiriShortcutsService.swift
//  Veloce
//

import Foundation
import Intents
import AppIntents

// MARK: - App Intents for iOS 16+

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Add a new task to MyTasksAI")

    @Parameter(title: "Task Title")
    var title: String

    @Parameter(title: "Priority", default: "medium")
    var priority: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Add task logic here
        return .result(dialog: "Added '\(title)' to your tasks!")
    }
}

struct GetNextTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "What's My Next Task"
    static var description = IntentDescription("Get your next priority task")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get next task logic
        return .result(dialog: "Your next task is: Review project proposal")
    }
}

struct StartFocusModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Mode"
    static var description = IntentDescription("Start a focused work session")

    @Parameter(title: "Duration (minutes)", default: 25)
    var duration: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            PomodoroTimerService.shared.startSession(taskTitle: "Focus Session", duration: duration * 60)
        }
        return .result(dialog: "Starting \(duration) minute focus session!")
    }
}

struct GetTodayProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Today's Progress"
    static var description = IntentDescription("Check how many tasks you've completed today")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get progress logic
        return .result(dialog: "You've completed 5 of 8 tasks today. Keep going!")
    }
}

// MARK: - App Shortcuts Provider

struct VeloceShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: ["Add a task to \(.applicationName)", "Create task in \(.applicationName)"],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: GetNextTaskIntent(),
            phrases: ["What's my next task in \(.applicationName)", "Next task \(.applicationName)"],
            shortTitle: "Next Task",
            systemImageName: "list.bullet"
        )
        AppShortcut(
            intent: StartFocusModeIntent(),
            phrases: ["Start focus mode in \(.applicationName)", "Focus time \(.applicationName)"],
            shortTitle: "Focus Mode",
            systemImageName: "brain.head.profile"
        )
        AppShortcut(
            intent: GetTodayProgressIntent(),
            phrases: ["How many tasks did I complete in \(.applicationName)", "Today's progress \(.applicationName)"],
            shortTitle: "Progress",
            systemImageName: "chart.bar"
        )
        // Goal shortcuts
        AppShortcut(
            intent: GetTodaysGoalsIntent(),
            phrases: [
                "Show my goals in \(.applicationName)",
                "What goals should I focus on with \(.applicationName)",
                "Check my progress in \(.applicationName)"
            ],
            shortTitle: "Today's Goals",
            systemImageName: "target"
        )
    }
}
