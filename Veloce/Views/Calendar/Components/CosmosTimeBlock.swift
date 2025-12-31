//
//  CosmosTimeBlock.swift
//  Veloce
//
//  Living Cosmos Task Block
//  Morphic glass task blocks with plasma energy cores,
//  urgency glow effects, and supernova completion animations
//

import SwiftUI

// MARK: - Urgency Level

enum CosmosUrgencyLevel {
    case calm       // Plenty of time
    case near       // 1-4 hours away
    case critical   // < 1 hour
    case overdue    // Past scheduled time

    var glowColor: Color {
        switch self {
        case .calm: return .clear
        case .near: return Theme.CelestialColors.solarFlare
        case .critical: return Theme.CelestialColors.urgencyCritical
        case .overdue: return Color(red: 0.98, green: 0.2, blue: 0.2)
        }
    }

    var pulseSpeed: Double {
        switch self {
        case .calm: return 0
        case .near: return 2.0
        case .critical: return 1.2
        case .overdue: return 0.8
        }
    }
}

// MARK: - Cosmos Time Block

struct CosmosTimeBlock: View {
    let task: TaskItem
    let hourHeight: CGFloat
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var isPressed = false
    @State private var plasmaPhase: CGFloat = 0
    @State private var showSupernova = false
    @State private var strikethroughProgress: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed Properties

    private var blockHeight: CGFloat {
        let minutes = task.estimatedMinutes ?? 30
        return max(CGFloat(minutes) / 60.0 * hourHeight, LivingCosmos.Calendar.minBlockHeight)
    }

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    private var urgencyLevel: CosmosUrgencyLevel {
        guard let scheduledTime = task.scheduledTime, !task.isCompleted else {
            return .calm
        }

        let now = Date()
        let timeUntil = scheduledTime.timeIntervalSince(now)

        if timeUntil < 0 {
            return .overdue
        } else if timeUntil < 3600 { // < 1 hour
            return .critical
        } else if timeUntil < 14400 { // < 4 hours
            return .near
        } else {
            return .calm
        }
    }

    private var isHighPriority: Bool {
        task.starRating == 3
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Plasma energy core (completion toggle)
                plasmaCore
                    .onTapGesture {
                        triggerCompletion()
                    }

                // Task content
                taskContent

                Spacer()

                // Points badge
                if !task.isCompleted {
                    pointsBadge
                }
            }
            .padding(LivingCosmos.Calendar.blockPadding)
            .frame(height: blockHeight)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .background(blockBackground)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LivingCosmos.Calendar.blockCornerRadius))
        .overlay(blockBorder)
        .overlay(urgencyGlow)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(
            color: taskColor.opacity(isPressed ? 0.25 : 0.15),
            radius: isPressed ? 8 : 4,
            y: isPressed ? 1 : 2
        )
        // Completion feedback via scale animation (native approach)
        .scaleEffect(showSupernova ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSupernova)
        .animation(LivingCosmos.Animations.quick, value: isPressed)
        .simultaneousGesture(pressGesture)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Plasma Core

    private var plasmaCore: some View {
        ZStack {
            // Outer glow
            SwiftUI.Circle()
                .fill(taskColor.opacity(0.2))
                .frame(width: 28 + (isHighPriority ? plasmaPhase * 4 : 0))
                .blur(radius: 4)

            // Core background
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            taskColor,
                            taskColor.opacity(0.7)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 24, height: 24)

            // Completion checkmark
            if task.isCompleted {
                Image(systemName: "checkmark")
                    .dynamicTypeFont(base: 12, weight: .bold)
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(LivingCosmos.Animations.stellarBounce, value: task.isCompleted)
    }

    // MARK: - Task Content

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title with animated strikethrough
            ZStack(alignment: .leading) {
                Text(task.title)
                    .font(Theme.Typography.cosmosTitle)
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.5) : .white)
                    .lineLimit(blockHeight > 60 ? 2 : 1)

                // Strikethrough overlay
                if task.isCompleted {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Theme.CelestialColors.auroraGreen)
                            .frame(height: 2)
                            .frame(width: geometry.size.width * strikethroughProgress)
                            .offset(y: geometry.size.height / 2 - 1)
                    }
                }
            }

            // Metadata row
            if blockHeight > 50 {
                HStack(spacing: 8) {
                    // Time
                    if let time = task.scheduledTime {
                        Label(time.formatted(.dateTime.hour().minute()), systemImage: "clock")
                            .font(Theme.Typography.cosmosMeta)
                            .foregroundStyle(
                                urgencyLevel == .overdue || urgencyLevel == .critical
                                    ? urgencyLevel.glowColor
                                    : Theme.CelestialColors.starDim
                            )
                    }

                    // Duration
                    if let duration = task.estimatedMinutes {
                        Text("\(duration)m")
                            .font(Theme.Typography.cosmosMeta)
                            .foregroundStyle(Theme.CelestialColors.starGhost)
                    }

                    // Task type label
                    Text(task.taskType.rawValue.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(taskColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(taskColor.opacity(0.15))
                        }
                }
            }
        }
    }

    // MARK: - Points Badge

    private var pointsBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
                .dynamicTypeFont(base: 10)

            Text("+\(task.potentialPoints)")
                .font(Theme.Typography.cosmosPoints)
        }
        .foregroundStyle(taskColor)
    }

    // MARK: - Block Background (Native Liquid Glass)

    private var blockBackground: some View {
        ZStack {
            // Task color accent bar on leading edge
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(taskColor)
                    .frame(width: 3)
                    .padding(.vertical, 6)
                Spacer()
            }

            // Subtle task color tint
            RoundedRectangle(cornerRadius: LivingCosmos.Calendar.blockCornerRadius)
                .fill(taskColor.opacity(0.05))

            // High priority breathing overlay
            if isHighPriority && !task.isCompleted && !reduceMotion {
                RoundedRectangle(cornerRadius: LivingCosmos.Calendar.blockCornerRadius)
                    .fill(taskColor.opacity(0.03 + plasmaPhase * 0.05))
            }
        }
    }

    // MARK: - Block Border (Minimal)

    private var blockBorder: some View {
        RoundedRectangle(cornerRadius: LivingCosmos.Calendar.blockCornerRadius)
            .stroke(.white.opacity(0.08), lineWidth: 0.5)
    }

    // MARK: - Urgency Glow

    @ViewBuilder
    private var urgencyGlow: some View {
        if urgencyLevel != .calm && !task.isCompleted {
            RoundedRectangle(cornerRadius: LivingCosmos.Calendar.blockCornerRadius)
                .stroke(urgencyLevel.glowColor.opacity(0.6 + plasmaPhase * 0.4), lineWidth: 2)
                .blur(radius: 2)
        }
    }

    // MARK: - Gestures

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    withAnimation(LivingCosmos.Animations.quick) {
                        isPressed = true
                    }
                }
            }
            .onEnded { _ in
                withAnimation(LivingCosmos.Animations.quick) {
                    isPressed = false
                }
            }
    }

    // MARK: - Actions

    private func triggerCompletion() {
        guard !task.isCompleted else { return }

        HapticsService.shared.success()
        showSupernova = true

        // Animate strikethrough
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            strikethroughProgress = 1.0
        }

        // Actually complete the task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // High priority breathing
        if isHighPriority {
            withAnimation(LivingCosmos.Animations.plasmaPulse) {
                plasmaPhase = 1
            }
        }

        // Urgency pulse
        if urgencyLevel != .calm {
            withAnimation(.easeInOut(duration: urgencyLevel.pulseSpeed).repeatForever(autoreverses: true)) {
                plasmaPhase = 1
            }
        }
    }
}

// MARK: - Compact Time Block (for Week View)

struct CosmosCompactTimeBlock: View {
    let task: TaskItem
    let onTap: () -> Void

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Color dot
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [taskColor, taskColor.opacity(0.6)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 4
                        )
                    )
                    .frame(width: 8, height: 8)
                    .shadow(color: taskColor.opacity(0.5), radius: 2)

                // Title
                Text(task.title)
                    .dynamicTypeFont(base: 10, weight: .medium)
                    .foregroundStyle(.white.opacity(task.isCompleted ? 0.5 : 0.9))
                    .lineLimit(1)
                    .strikethrough(task.isCompleted, color: .white.opacity(0.5))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .stroke(taskColor.opacity(0.3), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Time Block") {
    ZStack {
        VoidBackground.calendar

        VStack(spacing: 16) {
            CosmosTimeBlock(
                task: TaskItem(
                    title: "Review project proposal",
                    estimatedMinutes: 45,
                    scheduledTime: Date(),
                    taskTypeRaw: "create"
                ),
                hourHeight: 80,
                onTap: {},
                onComplete: {}
            )
            .padding(.horizontal)

            CosmosTimeBlock(
                task: TaskItem(
                    title: "Team standup meeting",
                    estimatedMinutes: 30,
                    scheduledTime: Date().addingTimeInterval(-3600),
                    taskTypeRaw: "communicate"
                ),
                hourHeight: 80,
                onTap: {},
                onComplete: {}
            )
            .padding(.horizontal)
        }
    }
}
