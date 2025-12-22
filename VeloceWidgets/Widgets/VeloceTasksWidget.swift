//
//  VeloceTasksWidget.swift
//  VeloceWidgets
//
//  Tasks Widget - Aurora Design System
//  Ethereal cosmic aesthetic with crystalline glass cards
//  Shows upcoming tasks on home screen
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
                    WidgetCosmicBackground(showStars: true, showAurora: true, auroraIntensity: 0.35)
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

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}

// MARK: - Widget Task Item

struct WidgetTaskItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let priority: String

    var priorityColor: Color {
        switch priority.lowercased() {
        case "high": return WidgetAurora.Colors.rose
        case "medium": return WidgetAurora.Colors.gold
        case "low": return WidgetAurora.Colors.emerald
        default: return WidgetAurora.Colors.textTertiary
        }
    }

    var priorityGlow: Color {
        switch priority.lowercased() {
        case "high": return WidgetAurora.Colors.rose.opacity(0.4)
        case "medium": return WidgetAurora.Colors.gold.opacity(0.3)
        case "low": return WidgetAurora.Colors.emerald.opacity(0.3)
        default: return Color.clear
        }
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
        VStack(alignment: .leading, spacing: 10) {
            // Header with aurora accent
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(WidgetAurora.Colors.violet.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetAurora.Colors.violet)
                }

                Text("Tasks")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textSecondary)

                Spacer()
            }

            Spacer()

            // Progress with aurora ring mini
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.completedCount)")
                        .font(WidgetAurora.Typography.largeNumber)
                        .foregroundStyle(WidgetAurora.Colors.textPrimary)

                    Text("/ \(entry.totalCount)")
                        .font(WidgetAurora.Typography.subheadline)
                        .foregroundStyle(WidgetAurora.Colors.textTertiary)
                }

                // Aurora progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(WidgetAurora.Colors.glassBorder)
                            .frame(height: 6)

                        // Progress with glow
                        Capsule()
                            .fill(WidgetAurora.Gradients.aurora)
                            .frame(width: max(6, geo.size.width * entry.progress), height: 6)
                            .shadow(color: WidgetAurora.Colors.violet.opacity(0.5), radius: 4)
                    }
                }
                .frame(height: 6)
            }

            // Next task preview
            if let nextTask = entry.tasks.first {
                HStack(spacing: 6) {
                    Circle()
                        .fill(nextTask.priorityColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: nextTask.priorityGlow, radius: 3)

                    Text(nextTask.title)
                        .font(WidgetAurora.Typography.micro)
                        .foregroundStyle(WidgetAurora.Colors.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left: Aurora progress ring
            VStack(spacing: 8) {
                ZStack {
                    AuroraProgressRing(progress: entry.progress, size: 72, lineWidth: 7)

                    VStack(spacing: 0) {
                        Text("\(entry.completedCount)")
                            .font(WidgetAurora.Typography.mediumNumber)
                            .foregroundStyle(WidgetAurora.Colors.textPrimary)

                        Text("of \(entry.totalCount)")
                            .font(WidgetAurora.Typography.micro)
                            .foregroundStyle(WidgetAurora.Colors.textQuaternary)
                    }
                }

                Text("Today")
                    .font(WidgetAurora.Typography.micro)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)
            }

            // Divider with aurora gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            WidgetAurora.Colors.glassBorder.opacity(0),
                            WidgetAurora.Colors.glassBorder,
                            WidgetAurora.Colors.glassBorder.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right: Task list with glass cards
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.tasks.prefix(3)) { task in
                    HStack(spacing: 8) {
                        // Priority indicator with glow
                        ZStack {
                            Circle()
                                .fill(task.priorityGlow)
                                .frame(width: 14, height: 14)
                                .blur(radius: 3)

                            Circle()
                                .fill(task.priorityColor)
                                .frame(width: 8, height: 8)
                        }

                        Text(task.title)
                            .font(WidgetAurora.Typography.body)
                            .foregroundStyle(WidgetAurora.Colors.textPrimary)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WidgetAurora.Colors.glassBase)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(WidgetAurora.Colors.glassBorder, lineWidth: 0.5)
                            )
                    )
                }

                if entry.tasks.count > 3 {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                        Text("\(entry.tasks.count - 3) more")
                            .font(WidgetAurora.Typography.micro)
                    }
                    .foregroundStyle(WidgetAurora.Colors.electric)
                    .padding(.leading, 4)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with aurora orb
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Tasks")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(WidgetAurora.Colors.textPrimary)

                    Text("\(entry.completedCount) of \(entry.totalCount) completed")
                        .font(WidgetAurora.Typography.caption)
                        .foregroundStyle(WidgetAurora.Colors.textTertiary)
                }

                Spacer()

                // Mini aurora progress ring
                ZStack {
                    AuroraProgressRing(progress: entry.progress, size: 44, lineWidth: 4, showGlow: false)

                    Text("\(Int(entry.progress * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetAurora.Colors.textSecondary)
                }
            }

            // Divider with aurora gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            WidgetAurora.Colors.violet.opacity(0.3),
                            WidgetAurora.Colors.electric.opacity(0.2),
                            WidgetAurora.Colors.glassBorder.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Task list with glass styling
            VStack(spacing: 8) {
                ForEach(entry.tasks) { task in
                    HStack(spacing: 12) {
                        // Checkbox with aurora styling
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

                        Text(task.title)
                            .font(WidgetAurora.Typography.subheadline)
                            .strikethrough(task.isCompleted, color: WidgetAurora.Colors.textQuaternary)
                            .foregroundStyle(task.isCompleted ? WidgetAurora.Colors.textQuaternary : WidgetAurora.Colors.textPrimary)

                        Spacer()

                        // Priority pill
                        Circle()
                            .fill(task.priorityColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: task.priorityGlow, radius: 3)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(WidgetAurora.Colors.glassBase)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(WidgetAurora.Colors.glassBorder, lineWidth: 0.5)
                            )
                    )
                }
            }

            Spacer()

            // Open app button with aurora gradient
            WidgetAuroraButton("Open MyTasksAI", icon: "arrow.right", url: URL(string: "veloce://tasks")!)
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
