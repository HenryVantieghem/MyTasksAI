//
//  VeloceFocusWidget.swift
//  VeloceWidgets
//
//  Focus Timer Widget - Living Cosmos Design
//  Ethereal amber timer ring with state-aware styling
//  Shows focus session status on home screen
//

import WidgetKit
import SwiftUI

// MARK: - Focus Widget

struct VeloceFocusWidget: Widget {
    let kind: String = "VeloceFocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusTimelineProvider()) { entry in
            FocusWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCosmicBackground(
                        showStars: true,
                        showAurora: true,
                        auroraIntensity: entry.state == .active ? 0.5 : 0.35
                    )
                }
        }
        .configurationDisplayName("Focus Timer")
        .description("Track your focus sessions at a glance")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

// MARK: - Timeline Provider

struct FocusTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusEntry {
        FocusEntry(
            date: Date(),
            state: .idle,
            remainingSeconds: 0,
            totalSeconds: 1500, // 25 min
            sessionTitle: "Focus Session",
            mode: "Deep Work"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusEntry) -> Void) {
        // Show active state in gallery
        let entry = FocusEntry(
            date: Date(),
            state: .active,
            remainingSeconds: 847,
            totalSeconds: 1500,
            sessionTitle: "Complete project",
            mode: "Deep Work"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusEntry>) -> Void) {
        let session = loadFocusSession()

        let entry: FocusEntry
        if let session = session {
            let now = Date()
            let remaining = max(0, Int(session.endTime.timeIntervalSince(now)))

            entry = FocusEntry(
                date: now,
                state: remaining > 0 ? .active : .idle,
                remainingSeconds: remaining,
                totalSeconds: session.duration,
                sessionTitle: session.title,
                mode: session.isDeepFocus ? "Deep Focus" : "Focus"
            )
        } else {
            entry = FocusEntry(
                date: Date(),
                state: .idle,
                remainingSeconds: 0,
                totalSeconds: 1500,
                sessionTitle: "Ready to focus",
                mode: "Start a session"
            )
        }

        // Update frequently during active sessions, otherwise every 15 min
        let nextUpdate: Date
        if entry.state == .active {
            nextUpdate = Calendar.current.date(byAdding: .second, value: 30, to: Date())!
        } else {
            nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadFocusSession() -> WidgetFocusSession? {
        guard let defaults = UserDefaults(suiteName: "group.com.veloce.app"),
              let data = defaults.data(forKey: "widget_focus_session"),
              let session = try? JSONDecoder().decode(WidgetFocusSession.self, from: data) else {
            return nil
        }
        // Only return if session is still active
        if session.endTime > Date() {
            return session
        }
        return nil
    }
}

// MARK: - Shared Models

struct WidgetFocusSession: Codable {
    let id: UUID
    let title: String
    let duration: Int // total seconds
    let startTime: Date
    let endTime: Date
    let isDeepFocus: Bool
}

// MARK: - Entry

struct FocusEntry: TimelineEntry {
    let date: Date
    let state: FocusWidgetState
    let remainingSeconds: Int
    let totalSeconds: Int
    let sessionTitle: String
    let mode: String

    enum FocusWidgetState {
        case idle, active, paused, breakTime

        var timerState: FocusTimerRing.FocusTimerState {
            switch self {
            case .idle: return .idle
            case .active: return .active
            case .paused: return .paused
            case .breakTime: return .breakTime
            }
        }

        var statusText: String {
            switch self {
            case .idle: return "Ready"
            case .active: return "Focusing"
            case .paused: return "Paused"
            case .breakTime: return "Break"
            }
        }

        var icon: String {
            switch self {
            case .idle: return "play.fill"
            case .active: return "timer"
            case .paused: return "pause.fill"
            case .breakTime: return "cup.and.saucer.fill"
            }
        }

        var accentColor: Color {
            switch self {
            case .idle: return WidgetAurora.Colors.textTertiary
            case .active: return Color(red: 1.0, green: 0.55, blue: 0.20)
            case .paused: return WidgetAurora.Colors.gold
            case .breakTime: return WidgetAurora.Colors.emerald
            }
        }
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Widget View

struct FocusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FocusEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .accessoryCircular:
            circularAccessory
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        Link(destination: URL(string: "veloce://focus")!) {
            VStack(spacing: 8) {
                // Timer ring with state-aware styling
                ZStack {
                    FocusTimerRing(
                        progress: entry.progress,
                        state: entry.state.timerState,
                        size: 70,
                        lineWidth: 7
                    )

                    // Center content
                    VStack(spacing: 2) {
                        if entry.state == .idle {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(WidgetAurora.Colors.textSecondary)
                        } else {
                            Text(entry.formattedTime)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundStyle(WidgetAurora.Colors.textPrimary)
                                .contentTransition(.numericText())
                        }
                    }
                }

                // Status info
                VStack(spacing: 4) {
                    if entry.state == .idle {
                        Text("Start Focus")
                            .font(WidgetAurora.Typography.subheadline)
                            .foregroundStyle(WidgetAurora.Colors.textPrimary)

                        Text("Tap to begin")
                            .font(WidgetAurora.Typography.micro)
                            .foregroundStyle(WidgetAurora.Colors.textTertiary)
                    } else {
                        // Status pill
                        HStack(spacing: 4) {
                            Circle()
                                .fill(entry.state.accentColor)
                                .frame(width: 6, height: 6)
                                .shadow(color: entry.state.accentColor.opacity(0.6), radius: 3)

                            Text(entry.state.statusText)
                                .font(WidgetAurora.Typography.micro)
                                .foregroundStyle(entry.state.accentColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(entry.state.accentColor.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(entry.state.accentColor.opacity(0.3), lineWidth: 0.5)
                                )
                        )

                        // Mode label
                        Text(entry.mode)
                            .font(WidgetAurora.Typography.micro)
                            .foregroundStyle(WidgetAurora.Colors.textQuaternary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
        }
    }

    // MARK: - Circular Accessory

    private var circularAccessory: some View {
        ZStack {
            AccessoryWidgetBackground()

            if entry.state == .idle {
                VStack(spacing: 1) {
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .medium))

                    Text("Focus")
                        .font(.system(size: 9, weight: .medium))
                }
            } else {
                ZStack {
                    // Progress ring
                    Circle()
                        .stroke(.quaternary, lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(
                            AngularGradient(
                                colors: [.orange, .yellow, .orange],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    // Time
                    VStack(spacing: -2) {
                        Text("\(entry.remainingSeconds / 60)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))

                        Text("min")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(4)
            }
        }
    }
}

// MARK: - Preview

#Preview("Small - Idle", as: .systemSmall) {
    VeloceFocusWidget()
} timeline: {
    FocusEntry(
        date: Date(),
        state: .idle,
        remainingSeconds: 0,
        totalSeconds: 1500,
        sessionTitle: "Ready",
        mode: "Deep Work"
    )
}

#Preview("Small - Active", as: .systemSmall) {
    VeloceFocusWidget()
} timeline: {
    FocusEntry(
        date: Date(),
        state: .active,
        remainingSeconds: 847,
        totalSeconds: 1500,
        sessionTitle: "Complete project",
        mode: "Deep Focus"
    )
}

#Preview("Small - Break", as: .systemSmall) {
    VeloceFocusWidget()
} timeline: {
    FocusEntry(
        date: Date(),
        state: .breakTime,
        remainingSeconds: 180,
        totalSeconds: 300,
        sessionTitle: "Break time",
        mode: "Rest"
    )
}

#Preview("Circular", as: .accessoryCircular) {
    VeloceFocusWidget()
} timeline: {
    FocusEntry(
        date: Date(),
        state: .active,
        remainingSeconds: 847,
        totalSeconds: 1500,
        sessionTitle: "Focus",
        mode: "Deep Work"
    )
}
