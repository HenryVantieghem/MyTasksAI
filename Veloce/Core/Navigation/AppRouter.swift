//
//  AppRouter.swift
//  Veloce
//
//  Central navigation state management using @Observable
//  Manages tab selection and sheet presentation
//

import SwiftUI

/// Central router for app navigation state
/// Uses @Observable for automatic SwiftUI integration
@Observable
final class AppRouter {
    // MARK: - Tab State

    /// Currently selected tab
    var selectedTab: AppTab

    // MARK: - Sheet State

    /// Currently presented sheet (if any)
    var presentedSheet: PresentedSheet?

    // MARK: - Initialization

    init(initialTab: AppTab = .tasks) {
        self.selectedTab = initialTab
    }

    // MARK: - Navigation Methods

    /// Switch to a specific tab
    func navigate(to tab: AppTab) {
        guard selectedTab != tab else { return }
        selectedTab = tab
        HapticsService.shared.tabSwitch()
    }

    /// Present a sheet
    func present(_ sheet: PresentedSheet) {
        presentedSheet = sheet
        HapticsService.shared.selectionFeedback()
    }

    /// Dismiss the current sheet
    func dismissSheet() {
        presentedSheet = nil
    }
}

// MARK: - Presented Sheet Types

/// Identifiable sheet types for navigation
enum PresentedSheet: Identifiable {
    case taskDetail(task: TaskItem)
    case settings
    case stats
    case addTask
    case brainDump
    case schedulePicker(onSelect: (Date) -> Void)
    case priorityPicker(onSelect: (Int) -> Void)

    var id: String {
        switch self {
        case .taskDetail(let task):
            return "taskDetail-\(task.id)"
        case .settings:
            return "settings"
        case .stats:
            return "stats"
        case .addTask:
            return "addTask"
        case .brainDump:
            return "brainDump"
        case .schedulePicker:
            return "schedulePicker"
        case .priorityPicker:
            return "priorityPicker"
        }
    }
}
