//
//  AppTab.swift
//  Veloce
//
//  Tab enumeration for main navigation
//  Following Apple's recommended pattern for tab-based apps
//  Note: Circles moved to CirclesPill (top-left floating pill)
//

import SwiftUI

/// Main app tab enumeration
/// Defines all primary navigation destinations with their display properties
/// Note: Circles is no longer a tab - it's accessed via CirclesPill
enum AppTab: Int, CaseIterable {
    case tasks = 0
    case calendar = 1
    case focus = 2
    case momentum = 3
    case journal = 4

    // MARK: - Display Properties

    var title: String {
        switch self {
        case .tasks:
            return "Tasks"
        case .calendar:
            return "Calendar"
        case .focus:
            return "Focus"
        case .momentum:
            return "Momentum"
        case .journal:
            return "Journal"
        }
    }

    /// Icon for unselected state
    var icon: String {
        switch self {
        case .tasks:
            return "plus.bubble"
        case .calendar:
            return "calendar"
        case .focus:
            return "timer"
        case .momentum:
            return "flame"
        case .journal:
            return "book"
        }
    }

    /// Icon for selected state (filled variants)
    var selectedIcon: String {
        switch self {
        case .tasks:
            return "plus.bubble.fill"
        case .calendar:
            return "calendar"
        case .focus:
            return "timer"
        case .momentum:
            return "flame.fill"
        case .journal:
            return "book.fill"
        }
    }
}
