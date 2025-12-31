//
//  KanbanColumnView.swift
//  Veloce
//
//  Kanban Column with Vibrant Gradient Headers
//  Features: Drag-and-drop, 3D orb headers, Apple-widget-style gradients
//

import SwiftUI

// MARK: - Task Section Type

enum TaskSection: String, CaseIterable, Identifiable {
    case inProgress = "In Progress"
    case toDo = "To Do"
    case done = "Done"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .inProgress: return "bolt.fill"
        case .toDo: return "circle.dotted"
        case .done: return "checkmark.circle.fill"
        }
    }

    var gradient: LinearGradient {
        Theme.TaskSectionColors.gradient(for: rawValue)
    }

    var primaryColor: Color {
        Theme.TaskSectionColors.primaryColor(for: rawValue)
    }
}

// MARK: - Kanban Column View

struct KanbanColumnView: View {
    let section: TaskSection
    let tasks: [TaskItem]
    let onTaskTap: (TaskItem) -> Void
    let onToggleComplete: (TaskItem) -> Void
    let onTaskDrop: (TaskItem, TaskSection) -> Void
    var onStartFocus: ((TaskItem, Int) -> Void)?
    var onSnooze: ((TaskItem) -> Void)?
    var onDelete: ((TaskItem) -> Void)?

    @Environment(\.responsiveLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Column width calculated based on size class
    /// Uses fixed widths that work well across device sizes
    private var columnWidth: CGFloat {
        switch sizeClass {
        case .compact:
            // For compact, use a reasonable fixed width that fits most devices
            return 280
        case .regular:
            return 320
        default:
            return 280
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Column header
            KanbanColumnHeader(
                section: section,
                taskCount: tasks.count
            )
            .padding(.horizontal, layout.spacing)
            .padding(.bottom, layout.spacing)

            // Tasks list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: layout.spacing) {
                    if tasks.isEmpty {
                        KanbanEmptyColumnPlaceholder(section: section)
                    } else {
                        ForEach(tasks) { task in
                            TaskCardV5(
                                task: task,
                                onTap: { onTaskTap(task) },
                                onToggleComplete: { onToggleComplete(task) },
                                onStartFocus: onStartFocus,
                                onSnooze: onSnooze,
                                onDelete: onDelete
                            )
                            .draggable(task.id.uuidString) {
                                // Drag preview
                                TaskCardDragPreview(task: task, section: section)
                            }
                        }
                    }
                }
                .padding(.horizontal, layout.spacing)
                .padding(.bottom, 100)
            }
        }
        .frame(width: columnWidth)
        .background(columnBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .dropDestination(for: String.self) { items, _ in
            guard let taskIdString = items.first else { return false }
            // Find the task and notify parent
            if let task = findTask(by: taskIdString) {
                HapticsService.shared.impact(.medium)
                onTaskDrop(task, section)
                return true
            }
            return false
        }
    }

    // MARK: - Column Background

    private var columnBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

            // Section tint
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            section.primaryColor.opacity(0.08),
                            section.primaryColor.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            section.primaryColor.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        }
        .shadow(color: section.primaryColor.opacity(0.15), radius: 16, y: 8)
    }

    // Helper to find task by ID string
    private func findTask(by idString: String) -> TaskItem? {
        // This would need access to all tasks - parent should provide this
        // For now, return nil and let parent handle the lookup
        return nil
    }
}

// MARK: - Kanban Column Header

struct KanbanColumnHeader: View {
    let section: TaskSection
    let taskCount: Int

    @State private var orbPulse: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // 3D Glowing orb
            glowingOrb

            // Section title
            Text(section.rawValue)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            // Count badge
            countBadge
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(headerBackground)
        .onAppear {
            if !reduceMotion && section == .inProgress {
                startPulseAnimation()
            }
        }
    }

    // MARK: - Glowing Orb

    private var glowingOrb: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(section.primaryColor)
                .frame(width: 28, height: 28)
                .blur(radius: 8)
                .opacity(0.4 + orbPulse * 0.2)

            // 3D orb gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            section.primaryColor.opacity(0.9),
                            section.primaryColor,
                            section.primaryColor.opacity(0.7)
                        ],
                        center: .init(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 14
                    )
                )
                .frame(width: 24, height: 24)

            // Highlight
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: 24, height: 24)
                .mask {
                    Circle()
                        .frame(width: 10, height: 10)
                        .offset(x: -4, y: -4)
                        .blur(radius: 2)
                }

            // Icon
            Image(systemName: section.icon)
                .dynamicTypeFont(base: 10, weight: .bold)
                .foregroundStyle(.white)
        }
        .scaleEffect(1 + orbPulse * 0.1)
    }

    // MARK: - Count Badge

    private var countBadge: some View {
        Text("\(taskCount)")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(section.primaryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(section.primaryColor.opacity(0.15))
            }
            .overlay {
                Capsule()
                    .strokeBorder(section.primaryColor.opacity(0.3), lineWidth: 0.5)
            }
    }

    // MARK: - Header Background

    private var headerBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(section.gradient.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.2),
                            section.primaryColor.opacity(0.3),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        }
        .shadow(color: section.primaryColor.opacity(0.2), radius: 8, y: 4)
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            orbPulse = 1.0
        }
    }
}

// MARK: - Empty Column Placeholder

struct KanbanEmptyColumnPlaceholder: View {
    let section: TaskSection

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: section.icon)
                .dynamicTypeFont(base: 32, weight: .light)
                .foregroundStyle(section.primaryColor.opacity(0.4))

            Text(emptyMessage)
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(section.primaryColor.opacity(0.05))
                .strokeBorder(
                    section.primaryColor.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )
        }
    }

    private var emptyMessage: String {
        switch section {
        case .inProgress:
            return "No tasks in progress\nDrag a task here to start"
        case .toDo:
            return "All clear!\nAdd new tasks to get started"
        case .done:
            return "Complete tasks to\nsee them here"
        }
    }
}

// MARK: - Task Card Drag Preview

struct TaskCardDragPreview: View {
    let task: TaskItem
    let section: TaskSection

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(section.primaryColor)
                .frame(width: 8, height: 8)

            Text(task.title)
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .overlay {
            Capsule()
                .strokeBorder(section.primaryColor.opacity(0.4), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview("Kanban Column") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            ForEach(TaskSection.allCases) { section in
                KanbanColumnView(
                    section: section,
                    tasks: section == .toDo ? [
                        {
                            let t = TaskItem(title: "Design new feature")
                            t.estimatedMinutes = 45
                            t.starRating = 3
                            return t
                        }(),
                        {
                            let t = TaskItem(title: "Review code changes")
                            t.estimatedMinutes = 20
                            t.starRating = 2
                            return t
                        }()
                    ] : [],
                    onTaskTap: { _ in },
                    onToggleComplete: { _ in },
                    onTaskDrop: { _, _ in },
                    onStartFocus: { _, _ in },
                    onSnooze: { _ in },
                    onDelete: { _ in }
                )
            }
        }
        .padding(20)
    }
    .frame(height: 600)
    .background(Theme.CelestialColors.void.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
