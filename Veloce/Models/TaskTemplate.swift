//
//  TaskTemplate.swift
//  MyTasksAI
//
//  Task Template Model for Common Tasks Feature
//  Stores reusable task templates with categories and usage tracking
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Task Template Model
@Model
final class TaskTemplate {
    // MARK: Core Properties
    var id: UUID
    var title: String
    var defaultMinutes: Int?
    var defaultPriority: String?

    // MARK: Organization
    var category: String // TemplateCategory.rawValue

    // MARK: Usage Tracking
    var usageCount: Int
    var lastUsedAt: Date?
    var createdAt: Date

    // MARK: System Templates
    var isSystemTemplate: Bool

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        title: String,
        defaultMinutes: Int? = nil,
        defaultPriority: String? = "medium",
        category: String = TemplateCategory.custom.rawValue,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = .now,
        isSystemTemplate: Bool = false
    ) {
        self.id = id
        self.title = title
        self.defaultMinutes = defaultMinutes
        self.defaultPriority = defaultPriority
        self.category = category
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.isSystemTemplate = isSystemTemplate
    }
}

// MARK: - Computed Properties
extension TaskTemplate {
    /// Category as enum
    var categoryEnum: TemplateCategory {
        TemplateCategory(rawValue: category) ?? .custom
    }

    /// Priority as enum
    var priority: TaskPriority {
        guard let priorityString = defaultPriority?.lowercased() else { return .medium }
        switch priorityString {
        case "low", "1": return .low
        case "medium", "2": return .medium
        case "high", "3": return .high
        default: return .medium
        }
    }

    /// Formatted time estimate
    var estimatedTimeFormatted: String? {
        guard let minutes = defaultMinutes else { return nil }
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Methods
extension TaskTemplate {
    /// Record template usage
    func recordUsage() {
        usageCount += 1
        lastUsedAt = .now
    }

    /// Create a TaskItem from this template
    func createTask() -> TaskItem {
        let task = TaskItem(
            title: title,
            estimatedMinutes: defaultMinutes,
            aiPriority: defaultPriority
        )
        recordUsage()
        return task
    }
}

// MARK: - Template Category
enum TemplateCategory: String, Codable, CaseIterable {
    case work
    case personal
    case health
    case errands
    case custom

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health"
        case .errands: return "Errands"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .errands: return "cart.fill"
        case .custom: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: return Theme.Colors.aiBlue
        case .personal: return Theme.Colors.aiPurple
        case .health: return Theme.Colors.success
        case .errands: return Theme.Colors.warning
        case .custom: return Theme.Colors.accent
        }
    }
}

// MARK: - Starter Templates
extension TaskTemplate {
    /// Pre-populated starter templates
    static var starterTemplates: [TaskTemplate] {
        [
            // Work
            TaskTemplate(
                title: "Team standup",
                defaultMinutes: 15,
                defaultPriority: "medium",
                category: TemplateCategory.work.rawValue,
                isSystemTemplate: true
            ),
            TaskTemplate(
                title: "Review PRs",
                defaultMinutes: 30,
                defaultPriority: "high",
                category: TemplateCategory.work.rawValue,
                isSystemTemplate: true
            ),
            TaskTemplate(
                title: "Reply to emails",
                defaultMinutes: 20,
                defaultPriority: "medium",
                category: TemplateCategory.work.rawValue,
                isSystemTemplate: true
            ),

            // Personal
            TaskTemplate(
                title: "Call family",
                defaultMinutes: 15,
                defaultPriority: "medium",
                category: TemplateCategory.personal.rawValue,
                isSystemTemplate: true
            ),
            TaskTemplate(
                title: "Read",
                defaultMinutes: 30,
                defaultPriority: "low",
                category: TemplateCategory.personal.rawValue,
                isSystemTemplate: true
            ),

            // Health
            TaskTemplate(
                title: "Morning workout",
                defaultMinutes: 45,
                defaultPriority: "high",
                category: TemplateCategory.health.rawValue,
                isSystemTemplate: true
            ),
            TaskTemplate(
                title: "Meditate",
                defaultMinutes: 10,
                defaultPriority: "medium",
                category: TemplateCategory.health.rawValue,
                isSystemTemplate: true
            ),
            TaskTemplate(
                title: "Walk",
                defaultMinutes: 20,
                defaultPriority: "low",
                category: TemplateCategory.health.rawValue,
                isSystemTemplate: true
            ),

            // Errands
            TaskTemplate(
                title: "Groceries",
                defaultMinutes: 45,
                defaultPriority: "medium",
                category: TemplateCategory.errands.rawValue,
                isSystemTemplate: true
            ),
            TaskTemplate(
                title: "Pay bills",
                defaultMinutes: 15,
                defaultPriority: "high",
                category: TemplateCategory.errands.rawValue,
                isSystemTemplate: true
            )
        ]
    }
}
