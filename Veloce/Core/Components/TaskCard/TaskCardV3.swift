//
//  TaskCardV3.swift
//  Veloce
//
//  Simplified Task Card - Elegant & Scannable
//  Features: Things 3-style bubble, swipe gestures, minimal visual hierarchy
//  Target: ~88pt height, ~400 lines
//

import SwiftUI

// MARK: - Task Card V3 (Simplified Edition)

struct TaskCardV3: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    var onStartTimer: ((TaskItem) -> Void)?
    var onSnooze: ((TaskItem) -> Void)?
    var onDelete: ((TaskItem) -> Void)?

    // Interaction states
    @State private var isPressed = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showCompletionBurst = false
    @State private var floatingPoints: Bool = false
    @State private var pointsOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let cardHeight: CGFloat = 88
    private let swipeCompleteThreshold: CGFloat = 80
    private let swipeSnoozeThreshold: CGFloat = 80
    private let swipeDeleteThreshold: CGFloat = 150

    // MARK: - Computed Properties

    private var taskTypeColor: Color {
        switch task.taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    private var isHighPriority: Bool {
        task.starRating == 3
    }

    private var energyLevel: Int {
        task.pointsEarned > 0 ? task.pointsEarned : 25
    }

    private var guidanceText: String? {
        if let advice = task.aiAdvice, !advice.isEmpty {
            return advice
        }
        if let tip = task.aiQuickTip, !tip.isEmpty {
            return tip
        }
        return nil
    }

    private var urgencyColor: Color {
        guard let scheduledTime = task.scheduledTime else {
            return Theme.CelestialColors.starDim
        }

        let hoursUntil = scheduledTime.timeIntervalSince(Date()) / 3600
        if hoursUntil < 0 {
            return Theme.CelestialColors.urgencyCritical
        } else if hoursUntil < 1 {
            return Theme.CelestialColors.urgencyNear
        }
        return Theme.CelestialColors.urgencyCalm
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Swipe action backgrounds
            swipeBackgrounds

            // Main card content
            cardContent
                .offset(x: swipeOffset)
                .gesture(swipeGesture)
        }
        .frame(height: cardHeight)
        .opacity(task.isCompleted ? 0.7 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.isCompleted)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Left: Elegant Check Bubble
                ElegantCheckBubble(
                    taskTypeColor: taskTypeColor,
                    isCompleted: task.isCompleted,
                    onComplete: handleComplete
                )

                // Center: Task details
                VStack(alignment: .leading, spacing: 4) {
                    // Title + Points + Timer
                    HStack(alignment: .center) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.CelestialColors.starWhite)
                            .lineLimit(1)

                        Spacer()

                        // Points badge (with floating animation)
                        ZStack {
                            pointsBadge
                                .opacity(floatingPoints ? 0 : 1)

                            if floatingPoints {
                                floatingPointsView
                            }
                        }

                        // Timer button
                        if !task.isCompleted {
                            timerButton
                        }
                    }

                    // Task type label
                    Text(task.taskType.rawValue.uppercased())
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(taskTypeColor)
                        .tracking(1.2)

                    // AI whisper (1 line, italic)
                    if let guidance = guidanceText, !task.isCompleted {
                        Text(guidance)
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(Theme.CelestialColors.starDim)
                            .lineLimit(1)
                            .italic()
                    }

                    // Metadata row
                    metadataRow
                }

                // Right edge: Urgency indicator
                if !task.isCompleted && isHighPriority {
                    urgencyIndicator
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)
        }
        .buttonStyle(TaskCardV3ButtonStyle(isPressed: $isPressed, isHighPriority: isHighPriority, reduceMotion: reduceMotion))
    }

    // MARK: - Points Badge

    private var pointsBadge: some View {
        HStack(spacing: 2) {
            Text("+\(energyLevel)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.TaskCardColors.pointsGlow)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Theme.TaskCardColors.pointsGlow.opacity(0.15))
        )
    }

    private var floatingPointsView: some View {
        Text("+\(energyLevel)")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(Theme.TaskCardColors.pointsGlow)
            .offset(y: pointsOffset)
            .opacity(1 - Double(abs(pointsOffset)) / 40)
    }

    // MARK: - Timer Button

    private var timerButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onStartTimer?(task)
        } label: {
            Image(systemName: "play.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(taskTypeColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(taskTypeColor.opacity(0.15))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: 12) {
            // Duration estimate
            if let duration = task.estimatedMinutes, duration > 0 {
                Label {
                    Text("\(duration)m")
                        .font(.system(size: 11, weight: .medium))
                } icon: {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                }
                .foregroundColor(Theme.CelestialColors.starDim)
            }

            // Schedule time
            if let scheduledTime = task.scheduledTime {
                Label {
                    Text(formatTime(scheduledTime))
                        .font(.system(size: 11, weight: .medium))
                } icon: {
                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                }
                .foregroundColor(urgencyColor)
            }

            Spacer()

            // Compact energy bar
            CompactEnergyBar(
                energyLevel: energyLevel,
                taskTypeColor: taskTypeColor,
                isCompleted: task.isCompleted
            )
            .frame(width: 60)
        }
    }

    // MARK: - Urgency Indicator

    private var urgencyIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(urgencyColor)
            .frame(width: 3, height: 40)
            .opacity(isHighPriority ? 1.0 : 0.5)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.abyss)

            // Subtle border glow
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            taskTypeColor.opacity(0.3),
                            taskTypeColor.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // High priority breathing glow
            if isHighPriority && !task.isCompleted {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(taskTypeColor.opacity(0.4), lineWidth: 2)
                    .blur(radius: 4)
            }
        }
    }

    // MARK: - Swipe Backgrounds

    private var swipeBackgrounds: some View {
        ZStack {
            // Right swipe background (Complete)
            HStack {
                ZStack {
                    Theme.CelestialColors.auroraGreen.opacity(0.3)

                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.CelestialColors.auroraGreen)
                        .opacity(swipeOffset > swipeCompleteThreshold * 0.5 ? 1 : 0)
                }
                .frame(width: max(0, swipeOffset))

                Spacer()
            }

            // Left swipe background (Snooze / Delete)
            HStack {
                Spacer()

                ZStack {
                    let isDelete = -swipeOffset > swipeDeleteThreshold
                    (isDelete ? Theme.CelestialColors.errorNebula : Theme.CelestialColors.warningNebula).opacity(0.3)

                    Image(systemName: isDelete ? "trash.fill" : "moon.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isDelete ? Theme.CelestialColors.errorNebula : Theme.CelestialColors.warningNebula)
                        .opacity(-swipeOffset > swipeSnoozeThreshold * 0.5 ? 1 : 0)
                }
                .frame(width: max(0, -swipeOffset))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Limit swipe range
                let translation = value.translation.width
                if translation > 0 {
                    // Right swipe (complete)
                    swipeOffset = min(translation, swipeCompleteThreshold + 20)
                } else {
                    // Left swipe (snooze/delete)
                    swipeOffset = max(translation, -(swipeDeleteThreshold + 20))
                }
            }
            .onEnded { value in
                let translation = value.translation.width

                if translation > swipeCompleteThreshold {
                    // Complete
                    HapticsService.shared.impact(.medium)
                    handleComplete()
                } else if translation < -swipeDeleteThreshold {
                    // Delete
                    HapticsService.shared.notification(.warning)
                    onDelete?(task)
                } else if translation < -swipeSnoozeThreshold {
                    // Snooze
                    HapticsService.shared.impact(.light)
                    onSnooze?(task)
                }

                // Reset offset
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    swipeOffset = 0
                }
            }
    }

    // MARK: - Actions

    private func handleComplete() {
        guard !task.isCompleted else { return }

        // Animate floating points
        if !reduceMotion {
            floatingPoints = true
            withAnimation(.easeOut(duration: 0.4)) {
                pointsOffset = -40
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                floatingPoints = false
                pointsOffset = 0
            }
        }

        onToggleComplete()
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "h:mm a"
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Task Card V3 Button Style

struct TaskCardV3ButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let isHighPriority: Bool
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.15, dampingFraction: 0.8),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Compact Energy Bar

struct CompactEnergyBar: View {
    let energyLevel: Int
    let taskTypeColor: Color
    let isCompleted: Bool

    private var fillPercentage: CGFloat {
        CGFloat(min(energyLevel, 100)) / 100.0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Theme.CelestialColors.nebulaDust)

                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [taskTypeColor, taskTypeColor.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * fillPercentage)
                    .opacity(isCompleted ? 0.5 : 1.0)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 12) {
                // Sample tasks would go here
                Text("TaskCardV3 Preview")
                    .foregroundColor(.white)
            }
            .padding()
        }
    }
}
