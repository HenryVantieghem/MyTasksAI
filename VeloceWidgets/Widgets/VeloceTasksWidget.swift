//
//  VeloceTasksWidget.swift
//  VeloceWidgets
//
//  Tasks Widget - Living Cosmos Design
//  Ethereal cosmic aesthetic with crystalline glass cards
//  Shows upcoming tasks with priority stars and XP badge
//

import WidgetKit
import SwiftUI

// MARK: - Tasks Widget

struct VeloceTasksWidget: Widget {
    let kind: String = "VeloceTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TasksTimelineProvider()) { entry in
            TasksWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCosmicBackground(
                        showStars: true,
                        showGlow: true,
                        glowIntensity: entry.progress >= 1.0 ? 0.5 : 0.35
                    )
                }
        }
        .configurationDisplayName("Today's Tasks")
        .description("See your upcoming tasks at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct TasksTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry(
            date: Date(),
            tasks: [
                WidgetTaskItem(id: UUID(), title: "Complete project", isCompleted: false, priority: "high"),
                WidgetTaskItem(id: UUID(), title: "Review documents", isCompleted: false, priority: "medium"),
                WidgetTaskItem(id: UUID(), title: "Send emails", isCompleted: true, priority: "low")
            ],
            completedCount: 3,
            totalCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> Void) {
        // Load tasks from shared container
        let tasks = loadTasks()
        let completedCount = tasks.filter { $0.isCompleted }.count

        let entry = TasksEntry(
            date: Date(),
            tasks: Array(tasks.filter { !$0.isCompleted }.prefix(5)),
            completedCount: completedCount,
            totalCount: tasks.count
        )

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadTasks() -> [WidgetTaskItem] {
        guard let defaults = UserDefaults(suiteName: "group.com.veloce.app"),
              let data = defaults.data(forKey: "widget_tasks"),
              let tasks = try? JSONDecoder().decode([WidgetTaskItem].self, from: data) else {
            return []
        }
        return tasks
    }
}

// MARK: - Entry

struct TasksEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTaskItem]
    let completedCount: Int
    let totalCount: Int
    let xpEarned: Int
    let streak: Int

    init(date: Date, tasks: [WidgetTaskItem], completedCount: Int, totalCount: Int, xpEarned: Int = 0, streak: Int = 0) {
        self.date = date
        self.tasks = tasks
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.xpEarned = xpEarned
        self.streak = streak
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var isAllComplete: Bool {
        totalCount > 0 && completedCount >= totalCount
    }
}

// MARK: - Widget Task Item

struct WidgetTaskItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let priority: String
    let scheduledTime: String?
    let starRating: Int?

    init(id: UUID, title: String, isCompleted: Bool, priority: String, scheduledTime: String? = nil, starRating: Int? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.scheduledTime = scheduledTime
        self.starRating = starRating
    }

    var priorityColor: Color {
        switch priority.lowercased() {
        case "high": return WidgetUtopian.Colors.rose
        case "medium": return WidgetUtopian.Colors.gold
        case "low": return WidgetUtopian.Colors.emerald
        default: return WidgetUtopian.Colors.textTertiary
        }
    }

    var priorityGlow: Color {
        switch priority.lowercased() {
        case "high": return WidgetUtopian.Colors.rose.opacity(0.4)
        case "medium": return WidgetUtopian.Colors.gold.opacity(0.3)
        case "low": return WidgetUtopian.Colors.emerald.opacity(0.3)
        default: return Color.clear
        }
    }

    var starCount: Int {
        starRating ?? (priority.lowercased() == "high" ? 3 : priority.lowercased() == "medium" ? 2 : 1)
    }
}

// MARK: - Widget View

struct TasksWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TasksEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        Link(destination: URL(string: "veloce://tasks")!) {
            VStack(alignment: .leading, spacing: 10) {
                // Header with star icon
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(WidgetUtopian.Colors.gold.opacity(0.2))
                            .frame(width: 24, height: 24)

                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WidgetUtopian.Colors.gold)
                    }

                    Text("Tasks")
                        .font(WidgetUtopian.Typography.caption)
                        .foregroundStyle(WidgetUtopian.Colors.textSecondary)

                    Spacer()

                    // XP earned badge
                    if entry.xpEarned > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 8))
                            Text("+\(entry.xpEarned)")
                                .font(WidgetUtopian.Typography.micro)
                        }
                        .foregroundStyle(WidgetUtopian.Colors.electric)
                    }
                }

                Spacer()

                // Progress display
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.completedCount)")
                            .font(WidgetUtopian.Typography.largeNumber)
                            .foregroundStyle(WidgetUtopian.Colors.textPrimary)

                        Text("today")
                            .font(WidgetUtopian.Typography.caption)
                            .foregroundStyle(WidgetUtopian.Colors.textTertiary)
                    }

                    // Utopian progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(WidgetUtopian.Colors.glassBorder)
                                .frame(height: 6)

                            Capsule()
                                .fill(entry.isAllComplete ? WidgetUtopian.Colors.success : WidgetUtopian.Gradients.utopian)
                                .frame(width: max(6, geo.size.width * entry.progress), height: 6)
                                .shadow(color: (entry.isAllComplete ? WidgetUtopian.Colors.success : WidgetUtopian.Colors.violet).opacity(0.5), radius: 4)
                        }
                    }
                    .frame(height: 6)
                }

                // Next task with star rating
                if let nextTask = entry.tasks.first {
                    HStack(spacing: 6) {
                        // Star rating
                        HStack(spacing: 2) {
                            ForEach(0..<nextTask.starCount, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(nextTask.priorityColor)
                            }
                        }

                        Text(nextTask.title)
                            .font(WidgetUtopian.Typography.micro)
                            .foregroundStyle(WidgetUtopian.Colors.textTertiary)
                            .lineLimit(1)
                    }
                } else if entry.isAllComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                        Text("All done!")
                            .font(WidgetUtopian.Typography.micro)
                    }
                    .foregroundStyle(WidgetUtopian.Colors.success)
                }
            }
            .padding(14)
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        Link(destination: URL(string: "veloce://tasks")!) {
            HStack(spacing: 16) {
                // Left: Utopian progress ring with XP badge
                VStack(spacing: 8) {
                    ZStack {
                        UtopianProgressRing(progress: entry.progress, size: 72, lineWidth: 7)

                        VStack(spacing: 0) {
                            Text("\(entry.completedCount)")
                                .font(WidgetUtopian.Typography.mediumNumber)
                                .foregroundStyle(WidgetUtopian.Colors.textPrimary)

                            Text("of \(entry.totalCount)")
                                .font(WidgetUtopian.Typography.micro)
                                .foregroundStyle(WidgetUtopian.Colors.textQuaternary)
                        }
                    }

                    // XP earned badge
                    if entry.xpEarned > 0 {
                        WidgetStatPill(
                            icon: "sparkle",
                            value: "+\(entry.xpEarned) XP",
                            color: WidgetUtopian.Colors.electric
                        )
                    } else {
                        Text("Today")
                            .font(WidgetUtopian.Typography.micro)
                            .foregroundStyle(WidgetUtopian.Colors.textTertiary)
                    }
                }

                // Divider with utopian gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                WidgetUtopian.Colors.glassBorder.opacity(0),
                                WidgetUtopian.Colors.violet.opacity(0.3),
                                WidgetUtopian.Colors.glassBorder.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Right: Task list with star ratings
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.tasks.prefix(3)) { task in
                        Link(destination: URL(string: "veloce://task/\(task.id.uuidString)")!) {
                            HStack(spacing: 8) {
                                // Star rating indicator
                                HStack(spacing: 2) {
                                    ForEach(0..<task.starCount, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 7))
                                            .foregroundStyle(task.priorityColor)
                                    }
                                }
                                .frame(width: 28, alignment: .leading)

                                Text(task.title)
                                    .font(WidgetUtopian.Typography.body)
                                    .foregroundStyle(WidgetUtopian.Colors.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                // Time if scheduled
                                if let time = task.scheduledTime {
                                    Text(time)
                                        .font(WidgetUtopian.Typography.micro)
                                        .foregroundStyle(WidgetUtopian.Colors.textQuaternary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(WidgetUtopian.Colors.glassBase)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(task.priorityColor.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                        }
                    }

                    if entry.tasks.count > 3 {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 10))
                            Text("\(entry.tasks.count - 3) more")
                                .font(WidgetUtopian.Typography.micro)
                        }
                        .foregroundStyle(WidgetUtopian.Colors.cyan)
                        .padding(.leading, 4)
                    } else if entry.isAllComplete {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("All tasks complete!")
                                .font(WidgetUtopian.Typography.micro)
                        }
                        .foregroundStyle(WidgetUtopian.Colors.success)
                        .padding(.leading, 4)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with utopian orb and XP
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Tasks")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(WidgetUtopian.Colors.textPrimary)

                    HStack(spacing: 8) {
                        Text("\(entry.completedCount) of \(entry.totalCount) completed")
                            .font(WidgetUtopian.Typography.caption)
                            .foregroundStyle(WidgetUtopian.Colors.textTertiary)

                        if entry.xpEarned > 0 {
                            WidgetStatPill(
                                icon: "sparkle",
                                value: "+\(entry.xpEarned)",
                                color: WidgetUtopian.Colors.electric
                            )
                        }
                    }
                }

                Spacer()

                // Mini utopian progress ring
                ZStack {
                    UtopianProgressRing(progress: entry.progress, size: 44, lineWidth: 4, showGlow: false)

                    if entry.isAllComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(WidgetUtopian.Colors.success)
                    } else {
                        Text("\(Int(entry.progress * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetUtopian.Colors.textSecondary)
                    }
                }
            }

            // Divider with utopian gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            WidgetUtopian.Colors.violet.opacity(0.3),
                            WidgetUtopian.Colors.electric.opacity(0.2),
                            WidgetUtopian.Colors.glassBorder.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Task list with glass styling and star ratings
            VStack(spacing: 8) {
                ForEach(entry.tasks.prefix(6)) { task in
                    Link(destination: URL(string: "veloce://task/\(task.id.uuidString)")!) {
                        HStack(spacing: 12) {
                            // Star rating with checkbox
                            ZStack {
                                Circle()
                                    .stroke(task.priorityColor.opacity(0.5), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)

                                if task.isCompleted {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [task.priorityColor, task.priorityColor.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 22, height: 22)
                                        .shadow(color: task.priorityGlow, radius: 4)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(WidgetUtopian.Typography.subheadline)
                                    .strikethrough(task.isCompleted, color: WidgetUtopian.Colors.textQuaternary)
                                    .foregroundStyle(task.isCompleted ? WidgetUtopian.Colors.textQuaternary : WidgetUtopian.Colors.textPrimary)
                                    .lineLimit(1)

                                // Star rating row
                                HStack(spacing: 3) {
                                    ForEach(0..<task.starCount, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 7))
                                            .foregroundStyle(task.priorityColor.opacity(task.isCompleted ? 0.4 : 1))
                                    }

                                    if let time = task.scheduledTime {
                                        Text("•")
                                            .font(.system(size: 8))
                                            .foregroundStyle(WidgetUtopian.Colors.textQuaternary)
                                        Text(time)
                                            .font(WidgetUtopian.Typography.micro)
                                            .foregroundStyle(WidgetUtopian.Colors.textQuaternary)
                                    }
                                }
                            }

                            Spacer()

                            // Points earned if completed
                            if task.isCompleted {
                                Text("+10")
                                    .font(WidgetUtopian.Typography.micro)
                                    .foregroundStyle(WidgetUtopian.Colors.success)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(WidgetUtopian.Colors.glassBase)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(task.priorityColor.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                    }
                }
            }

            Spacer()

            // Quick add button
            WidgetUtopianButton("Add Task", icon: "plus", url: URL(string: "veloce://add-task")!)
        }
        .padding(16)
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    VeloceTasksWidget()
} timeline: {
    TasksEntry(
        date: Date(),
        tasks: [
            WidgetTaskItem(id: UUID(), title: "Complete project", isCompleted: false, priority: "high")
        ],
        completedCount: 3,
        totalCount: 5
    )
}

#Preview("Medium", as: .systemMedium) {
    VeloceTasksWidget()
} timeline: {
    TasksEntry(
        date: Date(),
        tasks: [
            WidgetTaskItem(id: UUID(), title: "Complete project", isCompleted: false, priority: "high"),
            WidgetTaskItem(id: UUID(), title: "Review documents", isCompleted: false, priority: "medium"),
            WidgetTaskItem(id: UUID(), title: "Send emails", isCompleted: false, priority: "low")
        ],
        completedCount: 3,
        totalCount: 8
    )
}

#Preview("Large", as: .systemLarge) {
    VeloceTasksWidget()
} timeline: {
    TasksEntry(
        date: Date(),
        tasks: [
            WidgetTaskItem(id: UUID(), title: "Complete quarterly report", isCompleted: false, priority: "high"),
            WidgetTaskItem(id: UUID(), title: "Review team feedback", isCompleted: false, priority: "medium"),
            WidgetTaskItem(id: UUID(), title: "Update documentation", isCompleted: true, priority: "low"),
            WidgetTaskItem(id: UUID(), title: "Schedule meetings", isCompleted: false, priority: "medium")
        ],
        completedCount: 4,
        totalCount: 8
    )
}
