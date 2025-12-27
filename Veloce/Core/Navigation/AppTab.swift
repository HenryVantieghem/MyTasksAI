//
//  AppTab.swift
//  Veloce
//
//  Tab enumeration for main navigation
//  Following Apple's recommended pattern for tab-based apps
//  5 tabs: Tasks, Plan, Grow, Flow, Journal
//  Note: Circles is now part of Grow tab (Stats/Goals/Circles segments)
//

import SwiftUI

/// Main app tab enumeration
/// Defines all primary navigation destinations with their display properties
enum AppTab: Int, CaseIterable {
    case tasks = 0
    case plan = 1       // Renamed from calendar
    case grow = 2       // Replaces momentum, contains Circles
    case flow = 3       // Renamed from focus
    case journal = 4

    // MARK: - Display Properties

    var title: String {
        switch self {
        case .tasks:
            return "Tasks"
        case .plan:
            return "Plan"
        case .grow:
            return "Grow"
        case .flow:
            return "Flow"
        case .journal:
            return "Journal"
        }
    }

    /// Icon for unselected state
    var icon: String {
        switch self {
        case .tasks:
            return "checkmark.circle"
        case .plan:
            return "calendar"
        case .grow:
            return "leaf"
        case .flow:
            return "scope"
        case .journal:
            return "book"
        }
    }

    /// Icon for selected state (filled variants)
    var selectedIcon: String {
        switch self {
        case .tasks:
            return "checkmark.circle.fill"
        case .plan:
            return "calendar.circle.fill"
        case .grow:
            return "leaf.fill"
        case .flow:
            return "scope"
        case .journal:
            return "book.fill"
        }
    }
}
