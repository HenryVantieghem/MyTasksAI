//
//  PomodoroLiveActivity.swift
//  VeloceWidgets
//
//  Pomodoro Live Activity - Utopian Design System
//  Ethereal cosmic timer with utopian gradients
//  Dynamic Island & Lock Screen with glass styling
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Pomodoro Live Activity

@available(iOS 16.2, *)
struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // Lock Screen / Banner View
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }

                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Compact leading (left of notch)
                CompactLeadingView(context: context)
            } compactTrailing: {
                // Compact trailing (right of notch)
                CompactTrailingView(context: context)
            } minimal: {
                // Minimal view (when other Live Activity is present)
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.2, *)
struct LockScreenView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Timer ring with utopian gradient
            ZStack {
                // Ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                stateColor.opacity(0.3),
                                stateColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 6)

                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 5)
                    .frame(width: 52, height: 52)

                // Progress ring with utopian gradient
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: progressColors,
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: stateColor.opacity(0.5), radius: 4)

                // Timer icon
                Image(systemName: stateIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(stateColor)
            }

            // Info with glass styling
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.taskTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Time display
                    Text(context.state.formattedTime)
                        .font(.system(size: 26, weight: .light, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    // State label pill
                    Text(stateLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(stateColor.opacity(0.25))
                                .overlay(
                                    Capsule()
                                        .stroke(stateColor.opacity(0.4), lineWidth: 0.5)
                                )
                        )
                }
            }

            Spacer()

            // End time with glass styling
            VStack(alignment: .trailing, spacing: 2) {
                Text("Ends at")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Text(context.state.endTime, style: .time)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .padding(16)
        .background(
            // Utopian cosmic background
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.02, blue: 0.10),
                        Color(red: 0.02, green: 0.03, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Utopian glow based on state
                stateUtopianGlow
            }
        )
    }

    private var stateUtopianGlow: some View {
        ZStack {
            // Primary glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [stateColor.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 100)
                .offset(x: -60, y: 0)
                .blur(radius: 20)

            // Secondary accent
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [secondaryStateColor.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 150, height: 80)
                .offset(x: 80, y: 10)
                .blur(radius: 15)
        }
    }

    private var progress: Double {
        let total = Double(context.attributes.totalSeconds)
        let remaining = Double(context.state.remainingSeconds)
        guard total > 0 else { return 0 }
        return 1.0 - (remaining / total)
    }

    private var progressColors: [Color] {
        switch context.state.state {
        case .running:
            return [
                Color(red: 0.48, green: 0.12, blue: 0.74),  // violet
                Color(red: 0.58, green: 0.22, blue: 0.88),  // purple
                Color(red: 0.24, green: 0.56, blue: 0.98),  // electric
                Color(red: 0.14, green: 0.82, blue: 0.94),  // cyan
                Color(red: 0.48, green: 0.12, blue: 0.74)   // violet (loop)
            ]
        case .paused:
            return [Color(red: 1.0, green: 0.76, blue: 0.28), Color(red: 1.0, green: 0.55, blue: 0.20)]
        case .breakTime:
            return [Color(red: 0.20, green: 0.88, blue: 0.56), Color(red: 0.14, green: 0.82, blue: 0.94)]
        case .completed:
            return [Color(red: 0.20, green: 0.88, blue: 0.56), Color(red: 0.14, green: 0.82, blue: 0.94)]
        default:
            return [.gray, .gray.opacity(0.5)]
        }
    }

    private var stateColor: Color {
        switch context.state.state {
        case .running: return Color(red: 0.58, green: 0.22, blue: 0.88)   // purple
        case .paused: return Color(red: 1.0, green: 0.76, blue: 0.28)     // gold
        case .breakTime: return Color(red: 0.20, green: 0.88, blue: 0.56) // emerald
        case .completed: return Color(red: 0.20, green: 0.88, blue: 0.56) // emerald
        default: return .gray
        }
    }

    private var secondaryStateColor: Color {
        switch context.state.state {
        case .running: return Color(red: 0.24, green: 0.56, blue: 0.98)   // electric
        case .paused: return Color(red: 1.0, green: 0.55, blue: 0.20)     // orange
        case .breakTime: return Color(red: 0.14, green: 0.82, blue: 0.94) // cyan
        case .completed: return Color(red: 0.14, green: 0.82, blue: 0.94) // cyan
        default: return .gray
        }
    }

    private var stateIcon: String {
        switch context.state.state {
        case .running: return "timer"
        case .paused: return "pause.fill"
        case .breakTime: return "cup.and.saucer.fill"
        case .completed: return "checkmark.circle.fill"
        default: return "timer"
        }
    }

    private var stateLabel: String {
        switch context.state.state {
        case .running: return "Focus"
        case .paused: return "Paused"
        case .breakTime: return "Break"
        case .completed: return "Done"
        default: return ""
        }
    }
}

// MARK: - Dynamic Island Views

@available(iOS 16.2, *)
struct CompactLeadingView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        ZStack {
            // Mini utopian progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.48, green: 0.12, blue: 0.74),
                            Color(red: 0.24, green: 0.56, blue: 0.98),
                            Color(red: 0.14, green: 0.82, blue: 0.94),
                            Color(red: 0.48, green: 0.12, blue: 0.74)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(-90))

            Image(systemName: context.state.state == .running ? "timer" : "pause.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var progress: Double {
        let total = Double(context.attributes.totalSeconds)
        let remaining = Double(context.state.remainingSeconds)
        guard total > 0 else { return 0 }
        return 1.0 - (remaining / total)
    }
}

@available(iOS 16.2, *)
struct CompactTrailingView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        Text(context.state.formattedTime)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .contentTransition(.numericText())
    }
}

@available(iOS 16.2, *)
struct MinimalView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.22, blue: 0.88),
                            Color(red: 0.24, green: 0.56, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(-90))

            Image(systemName: "timer")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var progress: Double {
        let total = Double(context.attributes.totalSeconds)
        let remaining = Double(context.state.remainingSeconds)
        guard total > 0 else { return 0 }
        return 1.0 - (remaining / total)
    }
}

// MARK: - Expanded Views

@available(iOS 16.2, *)
struct ExpandedLeadingView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(stateLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(stateColor)

            Text(context.attributes.taskTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }

    private var stateLabel: String {
        switch context.state.state {
        case .running: return "FOCUSING"
        case .paused: return "PAUSED"
        case .breakTime: return "BREAK TIME"
        case .completed: return "COMPLETED"
        default: return ""
        }
    }

    private var stateColor: Color {
        switch context.state.state {
        case .running: return Color(red: 0.58, green: 0.22, blue: 0.88)
        case .paused: return Color(red: 1.0, green: 0.76, blue: 0.28)
        case .breakTime: return Color(red: 0.20, green: 0.88, blue: 0.56)
        case .completed: return Color(red: 0.20, green: 0.88, blue: 0.56)
        default: return .gray
        }
    }
}

@available(iOS 16.2, *)
struct ExpandedTrailingView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Ends at")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Text(context.state.endTime, style: .time)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }
}

@available(iOS 16.2, *)
struct ExpandedCenterView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        ZStack {
            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.58, green: 0.22, blue: 0.88).opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 8)

            // Progress ring with utopian gradient
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 6)
                .frame(width: 70, height: 70)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: progressColors,
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color(red: 0.58, green: 0.22, blue: 0.88).opacity(0.4), radius: 4)

            // Time
            Text(context.state.formattedTime)
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    private var progress: Double {
        let total = Double(context.attributes.totalSeconds)
        let remaining = Double(context.state.remainingSeconds)
        guard total > 0 else { return 0 }
        return 1.0 - (remaining / total)
    }

    private var progressColors: [Color] {
        switch context.state.state {
        case .running:
            return [
                Color(red: 0.48, green: 0.12, blue: 0.74),
                Color(red: 0.58, green: 0.22, blue: 0.88),
                Color(red: 0.24, green: 0.56, blue: 0.98),
                Color(red: 0.14, green: 0.82, blue: 0.94),
                Color(red: 0.48, green: 0.12, blue: 0.74)
            ]
        case .breakTime:
            return [
                Color(red: 0.20, green: 0.88, blue: 0.56),
                Color(red: 0.14, green: 0.82, blue: 0.94),
                Color(red: 0.20, green: 0.88, blue: 0.56)
            ]
        default:
            return [.gray, .gray.opacity(0.5)]
        }
    }
}

@available(iOS 16.2, *)
struct ExpandedBottomView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Pause/Resume button with utopian styling
            Link(destination: URL(string: "veloce://pomodoro/toggle")!) {
                HStack(spacing: 5) {
                    Image(systemName: context.state.state == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(context.state.state == .running ? "Pause" : "Resume")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.48, green: 0.12, blue: 0.74).opacity(0.6),
                                    Color(red: 0.24, green: 0.56, blue: 0.98).opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                )
            }

            // Stop button with glass styling
            Link(destination: URL(string: "veloce://pomodoro/stop")!) {
                HStack(spacing: 5) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Stop")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color(red: 1.0, green: 0.36, blue: 0.36))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 1.0, green: 0.36, blue: 0.36).opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 1.0, green: 0.36, blue: 0.36).opacity(0.3), lineWidth: 0.5)
                        )
                )
            }
        }
    }
}

// MARK: - Activity Attributes

struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var state: PomodoroState
        var endTime: Date

        var formattedTime: String {
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var taskTitle: String
    var totalSeconds: Int
}

// MARK: - Pomodoro State

enum PomodoroState: String, Codable, Hashable {
    case idle
    case running
    case paused
    case breakTime
    case completed
}
