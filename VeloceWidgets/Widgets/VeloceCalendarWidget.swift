//
//  VeloceCalendarWidget.swift
//  VeloceWidgets
//
//  Calendar Widget - Living Cosmos Design
//  Ethereal date display with upcoming events
//  Shows today's schedule at a glance
//

import WidgetKit
import SwiftUI

// MARK: - Calendar Widget

struct VeloceCalendarWidget: Widget {
    let kind: String = "VeloceCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarTimelineProvider()) { entry in
            CalendarWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCosmicBackground(
                        showStars: true,
                        showAurora: true,
                        auroraIntensity: 0.35
                    )
                }
        }
        .configurationDisplayName("Today's Schedule")
        .description("See your upcoming events and tasks")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct CalendarTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(
            date: Date(),
            events: [
                WidgetCalendarEvent(id: UUID(), title: "Team standup", time: "9:00 AM", color: .blue, isTask: false),
                WidgetCalendarEvent(id: UUID(), title: "Complete project", time: "10:30 AM", color: .purple, isTask: true),
                WidgetCalendarEvent(id: UUID(), title: "Client call", time: "2:00 PM", color: .green, isTask: false)
            ],
            tasksToday: 5,
            eventsToday: 3
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let events = loadEvents()
        let stats = loadStats()

        let entry = CalendarEntry(
            date: Date(),
            events: events,
            tasksToday: stats?.tasksCompletedToday ?? 0,
            eventsToday: events.filter { !$0.isTask }.count
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEvents() -> [WidgetCalendarEvent] {
        guard let defaults = UserDefaults(suiteName: "group.com.veloce.app"),
              let data = defaults.data(forKey: "widget_calendar_events"),
              let events = try? JSONDecoder().decode([WidgetCalendarEvent].self, from: data) else {
            return []
        }
        return events
    }

    private func loadStats() -> WidgetStatsData? {
        guard let defaults = UserDefaults(suiteName: "group.com.veloce.app"),
              let data = defaults.data(forKey: "widget_stats"),
              let stats = try? JSONDecoder().decode(WidgetStatsData.self, from: data) else {
            return nil
        }
        return stats
    }
}

// MARK: - Models

struct WidgetCalendarEvent: Codable, Identifiable {
    let id: UUID
    let title: String
    let time: String
    let colorHex: String?
    let isTask: Bool

    var color: Color {
        if let hex = colorHex {
            return Color(hex: hex)
        }
        return isTask ? WidgetAurora.Colors.violet : WidgetAurora.Colors.electric
    }

    init(id: UUID, title: String, time: String, color: Color, isTask: Bool) {
        self.id = id
        self.title = title
        self.time = time
        self.colorHex = nil
        self.isTask = isTask
    }

    init(id: UUID, title: String, time: String, colorHex: String?, isTask: Bool) {
        self.id = id
        self.title = title
        self.time = time
        self.colorHex = colorHex
        self.isTask = isTask
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Entry

struct CalendarEntry: TimelineEntry {
    let date: Date
    let events: [WidgetCalendarEvent]
    let tasksToday: Int
    let eventsToday: Int

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    var isEmpty: Bool {
        events.isEmpty
    }
}

// MARK: - Widget View

struct CalendarWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CalendarEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        default:
            mediumWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        Link(destination: URL(string: "veloce://calendar")!) {
            VStack(spacing: 8) {
                // Date display
                CalendarDateDisplay(date: entry.date, size: .compact)

                Spacer()

                // Next event or empty state
                if let nextEvent = entry.events.first {
                    VStack(spacing: 4) {
                        Text("Next")
                            .font(WidgetAurora.Typography.micro)
                            .foregroundStyle(WidgetAurora.Colors.textQuaternary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(nextEvent.color)
                                .frame(width: 6, height: 6)
                                .shadow(color: nextEvent.color.opacity(0.5), radius: 2)

                            Text(nextEvent.time)
                                .font(WidgetAurora.Typography.caption)
                                .foregroundStyle(WidgetAurora.Colors.textSecondary)
                        }

                        Text(nextEvent.title)
                            .font(WidgetAurora.Typography.body)
                            .foregroundStyle(WidgetAurora.Colors.textPrimary)
                            .lineLimit(1)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 16))
                            .foregroundStyle(WidgetAurora.Colors.success)

                        Text("All clear!")
                            .font(WidgetAurora.Typography.caption)
                            .foregroundStyle(WidgetAurora.Colors.textTertiary)
                    }
                }
            }
            .padding(14)
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        Link(destination: URL(string: "veloce://calendar")!) {
            HStack(spacing: 16) {
                // Left: Date display with orb
                VStack(spacing: 8) {
                    ZStack {
                        // Subtle orb glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        WidgetAurora.Colors.cyan.opacity(0.2),
                                        WidgetAurora.Colors.violet.opacity(0.1),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 90, height: 90)
                            .blur(radius: 10)

                        CalendarDateDisplay(date: entry.date, size: .full)
                    }

                    // Stats pills
                    HStack(spacing: 8) {
                        if entry.tasksToday > 0 {
                            WidgetStatPill(
                                icon: "checkmark.circle",
                                value: "\(entry.tasksToday)",
                                color: WidgetAurora.Colors.success
                            )
                        }
                        if entry.eventsToday > 0 {
                            WidgetStatPill(
                                icon: "calendar",
                                value: "\(entry.eventsToday)",
                                color: WidgetAurora.Colors.electric
                            )
                        }
                    }
                }
                .frame(width: 100)

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                WidgetAurora.Colors.glassBorder.opacity(0),
                                WidgetAurora.Colors.cyan.opacity(0.3),
                                WidgetAurora.Colors.glassBorder.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Right: Event list
                VStack(alignment: .leading, spacing: 6) {
                    if entry.events.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(entry.events.prefix(3)) { event in
                            WidgetEventCard(
                                title: event.title,
                                time: event.time,
                                color: event.color,
                                isTask: event.isTask
                            )
                        }

                        if entry.events.count > 3 {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 10))
                                Text("\(entry.events.count - 3) more")
                                    .font(WidgetAurora.Typography.micro)
                            }
                            .foregroundStyle(WidgetAurora.Colors.cyan)
                            .padding(.leading, 4)
                        }
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
        Link(destination: URL(string: "veloce://calendar")!) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.formattedDate)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(WidgetAurora.Colors.textPrimary)

                        Text("Your schedule")
                            .font(WidgetAurora.Typography.caption)
                            .foregroundStyle(WidgetAurora.Colors.textTertiary)
                    }

                    Spacer()

                    // Mini date orb
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [WidgetAurora.Colors.cyan, WidgetAurora.Colors.electric],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: WidgetAurora.Colors.cyan.opacity(0.4), radius: 6)

                        Text("\(Calendar.current.component(.day, from: entry.date))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                WidgetAurora.Colors.cyan.opacity(0.4),
                                WidgetAurora.Colors.violet.opacity(0.2),
                                WidgetAurora.Colors.glassBorder.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // Event list
                if entry.events.isEmpty {
                    Spacer()
                    emptyStateLargeView
                    Spacer()
                } else {
                    VStack(spacing: 8) {
                        ForEach(entry.events.prefix(6)) { event in
                            HStack(spacing: 12) {
                                // Time column
                                Text(event.time)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(WidgetAurora.Colors.textTertiary)
                                    .frame(width: 60, alignment: .trailing)

                                // Color bar
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(event.color)
                                    .frame(width: 3)
                                    .shadow(color: event.color.opacity(0.5), radius: 2)

                                // Event info
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(WidgetAurora.Typography.subheadline)
                                        .foregroundStyle(WidgetAurora.Colors.textPrimary)
                                        .lineLimit(1)

                                    HStack(spacing: 4) {
                                        Image(systemName: event.isTask ? "checkmark.circle" : "calendar")
                                            .font(.system(size: 9))
                                        Text(event.isTask ? "Task" : "Event")
                                            .font(WidgetAurora.Typography.micro)
                                    }
                                    .foregroundStyle(WidgetAurora.Colors.textQuaternary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(WidgetAurora.Colors.glassBase)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(event.color.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                        }
                    }

                    if entry.events.count > 6 {
                        HStack(spacing: 4) {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 12))
                            Text("\(entry.events.count - 6) more items")
                                .font(WidgetAurora.Typography.caption)
                        }
                        .foregroundStyle(WidgetAurora.Colors.cyan)
                        .padding(.top, 4)
                    }
                }

                Spacer()

                // Open button
                WidgetAuroraButton("View Calendar", icon: "calendar", url: URL(string: "veloce://calendar")!)
            }
            .padding(16)
        }
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Spacer()

            ZStack {
                Circle()
                    .fill(WidgetAurora.Colors.success.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 20))
                    .foregroundStyle(WidgetAurora.Colors.success)
            }

            Text("All clear today!")
                .font(WidgetAurora.Typography.subheadline)
                .foregroundStyle(WidgetAurora.Colors.textSecondary)

            Text("No events scheduled")
                .font(WidgetAurora.Typography.micro)
                .foregroundStyle(WidgetAurora.Colors.textQuaternary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyStateLargeView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                WidgetAurora.Colors.success.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)

                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(WidgetAurora.Colors.success)
            }

            Text("Your day is clear")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WidgetAurora.Colors.textPrimary)

            Text("No events or tasks scheduled for today")
                .font(WidgetAurora.Typography.body)
                .foregroundStyle(WidgetAurora.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    VeloceCalendarWidget()
} timeline: {
    CalendarEntry(
        date: Date(),
        events: [
            WidgetCalendarEvent(id: UUID(), title: "Team standup", time: "9:00 AM", color: .blue, isTask: false)
        ],
        tasksToday: 3,
        eventsToday: 2
    )
}

#Preview("Small - Empty", as: .systemSmall) {
    VeloceCalendarWidget()
} timeline: {
    CalendarEntry(date: Date(), events: [], tasksToday: 0, eventsToday: 0)
}

#Preview("Medium", as: .systemMedium) {
    VeloceCalendarWidget()
} timeline: {
    CalendarEntry(
        date: Date(),
        events: [
            WidgetCalendarEvent(id: UUID(), title: "Team standup", time: "9:00 AM", color: .blue, isTask: false),
            WidgetCalendarEvent(id: UUID(), title: "Complete project", time: "10:30 AM", color: .purple, isTask: true),
            WidgetCalendarEvent(id: UUID(), title: "Client call", time: "2:00 PM", color: .green, isTask: false)
        ],
        tasksToday: 5,
        eventsToday: 3
    )
}

#Preview("Large", as: .systemLarge) {
    VeloceCalendarWidget()
} timeline: {
    CalendarEntry(
        date: Date(),
        events: [
            WidgetCalendarEvent(id: UUID(), title: "Morning meditation", time: "7:00 AM", color: .cyan, isTask: true),
            WidgetCalendarEvent(id: UUID(), title: "Team standup", time: "9:00 AM", color: .blue, isTask: false),
            WidgetCalendarEvent(id: UUID(), title: "Complete project review", time: "10:30 AM", color: .purple, isTask: true),
            WidgetCalendarEvent(id: UUID(), title: "Lunch with Sarah", time: "12:30 PM", color: .orange, isTask: false),
            WidgetCalendarEvent(id: UUID(), title: "Client presentation", time: "2:00 PM", color: .green, isTask: false),
            WidgetCalendarEvent(id: UUID(), title: "Code review", time: "4:00 PM", color: .pink, isTask: true)
        ],
        tasksToday: 8,
        eventsToday: 4
    )
}

#Preview("Large - Empty", as: .systemLarge) {
    VeloceCalendarWidget()
} timeline: {
    CalendarEntry(date: Date(), events: [], tasksToday: 0, eventsToday: 0)
}
