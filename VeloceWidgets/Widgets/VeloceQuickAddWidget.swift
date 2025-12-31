//
//  VeloceQuickAddWidget.swift
//  VeloceWidgets
//
//  Quick Add Widget - Living Cosmos Design
//  One-tap task capture with utopian-styled button
//  Opens app with keyboard ready for quick input
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Quick Add Widget

struct VeloceQuickAddWidget: Widget {
    let kind: String = "VeloceQuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddTimelineProvider()) { entry in
            QuickAddWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCosmicBackground(
                        showStars: true,
                        showGlow: true,
                        glowIntensity: 0.4
                    )
                }
        }
        .configurationDisplayName("Quick Add")
        .description("Capture tasks instantly with one tap")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct QuickAddTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddEntry {
        QuickAddEntry(date: Date(), pendingTasks: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> Void) {
        completion(QuickAddEntry(date: Date(), pendingTasks: 5))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void) {
        let tasks = loadTaskCount()
        let entry = QuickAddEntry(date: Date(), pendingTasks: tasks)

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadTaskCount() -> Int {
        guard let defaults = UserDefaults(suiteName: "group.com.veloce.app"),
              let data = defaults.data(forKey: "widget_tasks"),
              let tasks = try? JSONDecoder().decode([WidgetTaskItem].self, from: data) else {
            return 0
        }
        return tasks.filter { !$0.isCompleted }.count
    }
}

// MARK: - Entry

struct QuickAddEntry: TimelineEntry {
    let date: Date
    let pendingTasks: Int
}

// MARK: - Widget View

struct QuickAddWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuickAddEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .accessoryCircular:
            circularAccessory
        case .accessoryRectangular:
            rectangularAccessory
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        Link(destination: URL(string: "veloce://add-task")!) {
            VStack(spacing: 12) {
                // Utopian quick add button
                QuickAddButton(size: 56)

                // Label
                VStack(spacing: 4) {
                    Text("Add Task")
                        .font(WidgetUtopian.Typography.headline)
                        .foregroundStyle(WidgetUtopian.Colors.textPrimary)

                    Text("Tap to capture")
                        .font(WidgetUtopian.Typography.micro)
                        .foregroundStyle(WidgetUtopian.Colors.textTertiary)
                }

                // Pending count
                if entry.pendingTasks > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 10))
                        Text("\(entry.pendingTasks) pending")
                            .font(WidgetUtopian.Typography.micro)
                    }
                    .foregroundStyle(WidgetUtopian.Colors.textQuaternary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(WidgetUtopian.Colors.glassBase)
                            .overlay(
                                Capsule()
                                    .stroke(WidgetUtopian.Colors.glassBorder, lineWidth: 0.5)
                            )
                    )
                }
            }
            .padding(14)
        }
    }

    // MARK: - Circular Accessory

    private var circularAccessory: some View {
        Link(destination: URL(string: "veloce://add-task")!) {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 2) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))

                    Text("Add")
                        .font(.system(size: 9, weight: .medium))
                }
            }
        }
    }

    // MARK: - Rectangular Accessory

    private var rectangularAccessory: some View {
        Link(destination: URL(string: "veloce://add-task")!) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.quaternary)
                        .frame(width: 32, height: 32)

                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Add Task")
                        .font(.system(size: 13, weight: .semibold))

                    if entry.pendingTasks > 0 {
                        Text("\(entry.pendingTasks) tasks pending")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Tap to capture a task")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - App Intent for Quick Add (iOS 17+)

@available(iOS 17.0, *)
struct QuickAddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Task"
    static var description = IntentDescription("Opens Veloce to quickly add a new task")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        // This opens the app to the add task screen
        return .result(opensIntent: OpenURLIntent(URL(string: "veloce://add-task")!))
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    VeloceQuickAddWidget()
} timeline: {
    QuickAddEntry(date: Date(), pendingTasks: 5)
}

#Preview("Small - No Tasks", as: .systemSmall) {
    VeloceQuickAddWidget()
} timeline: {
    QuickAddEntry(date: Date(), pendingTasks: 0)
}

#Preview("Circular", as: .accessoryCircular) {
    VeloceQuickAddWidget()
} timeline: {
    QuickAddEntry(date: Date(), pendingTasks: 3)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    VeloceQuickAddWidget()
} timeline: {
    QuickAddEntry(date: Date(), pendingTasks: 8)
}
