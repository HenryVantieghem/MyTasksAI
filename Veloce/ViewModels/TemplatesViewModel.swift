//
//  TemplatesViewModel.swift
//  MyTasksAI
//
//  ViewModel for Task Templates (Common Tasks Feature)
//  CRUD operations, seeding, and usage tracking
//

import Foundation
import SwiftData

// MARK: - Templates View Model
@MainActor
@Observable
final class TemplatesViewModel {
    // MARK: State
    private(set) var templates: [TaskTemplate] = []
    private(set) var isLoading: Bool = false
    var selectedCategory: TemplateCategory? = nil

    // MARK: Context
    private var modelContext: ModelContext?

    // MARK: Filtered Templates
    var filteredTemplates: [TaskTemplate] {
        var result = templates

        // Filter by category if selected
        if let category = selectedCategory {
            result = result.filter { $0.categoryEnum == category }
        }

        // Sort by usage count (most used first)
        return result.sorted { $0.usageCount > $1.usageCount }
    }

    // MARK: Initialization
    init() {}

    // MARK: - Setup
    func setup(context: ModelContext) {
        self.modelContext = context
        loadTemplates()
        seedStarterTemplatesIfNeeded()
    }

    // MARK: - Load Templates
    func loadTemplates() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<TaskTemplate>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        do {
            templates = try context.fetch(descriptor)
        } catch {
            print("Failed to load templates: \(error)")
            templates = []
        }
    }

    // MARK: - Seed Starter Templates
    func seedStarterTemplatesIfNeeded() {
        guard let context = modelContext else { return }

        // Check if we already have system templates
        let descriptor = FetchDescriptor<TaskTemplate>(
            predicate: #Predicate { $0.isSystemTemplate == true }
        )

        do {
            let existingSystemTemplates = try context.fetch(descriptor)
            if existingSystemTemplates.isEmpty {
                // Seed starter templates
                for template in TaskTemplate.starterTemplates {
                    context.insert(template)
                }
                try context.save()
                loadTemplates()
            }
        } catch {
            print("Failed to seed templates: \(error)")
        }
    }

    // MARK: - Create Template
    func createTemplate(
        title: String,
        category: TemplateCategory,
        defaultMinutes: Int? = nil,
        defaultPriority: String? = "medium"
    ) {
        guard let context = modelContext else { return }

        let template = TaskTemplate(
            title: title,
            defaultMinutes: defaultMinutes,
            defaultPriority: defaultPriority,
            category: category.rawValue,
            isSystemTemplate: false
        )

        context.insert(template)

        do {
            try context.save()
            loadTemplates()
            HapticsService.shared.impact()
        } catch {
            print("Failed to create template: \(error)")
        }
    }

    // MARK: - Create Task from Template
    func createTaskFromTemplate(_ template: TaskTemplate, into tasksViewModel: TasksViewModel) {
        let task = template.createTask()

        // Add to tasks view model
        tasksViewModel.addTaskItem(task)

        // Save context
        do {
            try modelContext?.save()
            loadTemplates() // Refresh to update usage counts
        } catch {
            print("Failed to save after creating task from template: \(error)")
        }

        HapticsService.shared.impact()
    }

    // MARK: - Delete Template
    func deleteTemplate(_ template: TaskTemplate) {
        guard let context = modelContext else { return }

        context.delete(template)

        do {
            try context.save()
            loadTemplates()
        } catch {
            print("Failed to delete template: \(error)")
        }
    }

    // MARK: - Create Template from Task
    func createTemplateFromTask(_ task: TaskItem, category: TemplateCategory) {
        createTemplate(
            title: task.title,
            category: category,
            defaultMinutes: task.estimatedMinutes,
            defaultPriority: task.aiPriority
        )
    }

    // MARK: - Category Selection
    func selectCategory(_ category: TemplateCategory?) {
        selectedCategory = category
        HapticsService.shared.selectionFeedback()
    }

    // MARK: - Templates by Category
    func templates(for category: TemplateCategory) -> [TaskTemplate] {
        templates
            .filter { $0.categoryEnum == category }
            .sorted { $0.usageCount > $1.usageCount }
    }
}
