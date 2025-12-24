//
//  TaskCardV2.swift
//  Veloce
//
//  Living Cosmos Task Card - Apple Design Award Level
//  Bioluminescent deep sea meets cosmic nebula
//  Features: Morphic glass, parallax depth, plasma core, urgency glow, supernova completion
//

import SwiftUI

// MARK: - Task Card V2 (Living Cosmos Edition)

struct TaskCardV2: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    var onStartTimer: ((TaskItem) -> Void)?

    // Interaction states
    @State private var isPressed: Bool = false
    @State private var showCompletionBurst: Bool = false

    // Animation states
    @State private var breathePhase: CGFloat = 0
    @State private var showWhisper: Bool = true
    @State private var entryScale: CGFloat = 0.9
    @State private var entryOpacity: Double = 0

    // Parallax
    @ObservedObject private var parallax = ParallaxMotionManager.shared

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

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

    private var shouldShowWhisper: Bool {
        !task.isCompleted && showWhisper && hasGuidanceText
    }

    private var hasGuidanceText: Bool {
        (task.aiAdvice != nil && !task.aiAdvice!.isEmpty) ||
        (task.aiQuickTip != nil && !task.aiQuickTip!.isEmpty)
    }

    private var guidanceText: String {
        if let advice = task.aiAdvice, !advice.isEmpty {
            return advice
        }
        if let tip = task.aiQuickTip, !tip.isEmpty {
            return tip
        }
        return AIGuidanceGenerator.generateFallback(for: task.title, taskType: task.taskType)
    }

    private var urgencyLevel: UrgencyGlowModifier.UrgencyLevel {
        guard let scheduledTime = task.scheduledTime else { return .calm }
        let now = Date()

        if scheduledTime < now {
            return .overdue
        }

        let hoursUntil = scheduledTime.timeIntervalSince(now) / 3600
        if hoursUntil < 1 {
            return .critical
        } else if hoursUntil < 4 {
            return .near
        }
        return .calm
    }

    // MARK: - Body

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap()
        } label: {
            cardContent
        }
        .buttonStyle(LivingCosmosCardButtonStyle(isPressed: $isPressed))
        .onAppear {
            startEntryAnimation()
            if isHighPriority && !reduceMotion {
                startBreathingAnimation()
            }
            if !reduceMotion {
                parallax.startUpdates()
            }
        }
        .contextMenu {
            contextMenuContent
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        ZStack {
            // Cosmic amber glow behind the card
            if !task.isCompleted {
                CosmicAmberGlow(
                    taskTypeColor: taskTypeColor,
                    isHighPriority: isHighPriority
                )
                .allowsHitTesting(false)
            }

            // Main card with glass effect
            ZStack {
                // Parallax container with 3 depth layers
                parallaxLayers

                // Main content
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    // Top row: Plasma Core + Title + Points Badge
                    topRow

                    // AI Guidance Whisper (collapsible)
                    if shouldShowWhisper {
                        aiWhisperSection
                    }

                    // Metadata row
                    metadataRow

                    // Living Energy Bar
                    LivingEnergyBar(
                        energyLevel: energyLevel,
                        taskTypeColor: taskTypeColor,
                        isCompleted: task.isCompleted
                    )
                    .padding(.top, 4)
                }
                .padding(Theme.Spacing.md + 2)
                .parallax(depth: 0.6)  // Content floats in middle layer
            }
            // Morphic glass container
            .morphicGlass(
                cornerRadius: 20,
                taskTypeColor: taskTypeColor,
                isPressed: isPressed,
                isHighPriority: isHighPriority
            )
            // Urgency glow for time-sensitive tasks
            .urgencyGlow(level: urgencyLevel, isAnimated: !reduceMotion)
            // Supernova burst on completion
            .supernovaBurst(
                isTriggered: showCompletionBurst,
                color: Theme.CelestialColors.auroraGreen,
                particleCount: 32
            )
        }
        // Entry animation
        .scaleEffect(entryScale)
        .opacity(entryOpacity)
        // Completion state
        .opacity(task.isCompleted ? 0.7 : 1.0)
    }

    // MARK: - Parallax Layers

    private var parallaxLayers: some View {
        ZStack {
            // Background nebula layer (furthest)
            nebulaBackground
                .parallax(layer: .background)

            // Floating particles layer
            if hasGuidanceText && !reduceMotion {
                AISparkleParticles(color: taskTypeColor)
                    .parallax(layer: .floating)
                    .opacity(0.6)
            }
        }
    }

    private var nebulaBackground: some View {
        ZStack {
            // Deep void base
            Theme.CelestialColors.voidDeep

            // Task type nebula glow
            RadialGradient(
                colors: [
                    taskTypeColor.opacity(isHighPriority ? 0.15 : 0.08),
                    taskTypeColor.opacity(0.03),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 180
            )

            // Secondary accent glow
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaEdge.opacity(0.06),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 120
            )
        }
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm + 2) {
            // Plasma Energy Core (completion toggle)
            PlasmaEnergyCore(
                energyState: task.energyState,
                potentialPoints: task.potentialPoints,
                taskTypeColor: taskTypeColor,
                isCompleted: task.isCompleted,
                size: 28
            ) {
                triggerCompletion()
            }

            // Task title with Living Cosmos typography
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(Theme.Typography.cosmosTitle)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary.opacity(0.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Task type label (subtle monospace)
                if !task.isCompleted {
                    Text(task.taskType.rawValue.uppercased())
                        .font(Theme.Typography.cosmosMetaSmall)
                        .foregroundStyle(taskTypeColor.opacity(0.7))
                        .tracking(1.2)
                }
            }

            Spacer()

            // Play timer button (only for incomplete tasks)
            if !task.isCompleted, let onStartTimer = onStartTimer {
                PlayTimerButton(task: task, onStartTimer: onStartTimer)
                    .transition(.scale.combined(with: .opacity))
            }

            // Points Badge with cosmic styling
            CosmicPointsBadge(
                points: task.potentialPoints,
                energyState: task.energyState,
                isEarned: task.isCompleted
            )
        }
    }

    // MARK: - AI Whisper Section

    private var aiWhisperSection: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // AI indicator orb
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.nebulaCore.opacity(0.8),
                            Theme.CelestialColors.nebulaGlow.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            // Whisper text with serif italic (editorial feel)
            Text(guidanceText)
                .font(Theme.Typography.cosmosWhisperSmall)
                .foregroundStyle(Theme.CelestialColors.starDim)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.leading, 36) // Align with title
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Time estimate
            if let estimate = task.estimatedTimeFormatted {
                metadataChip(
                    icon: "clock",
                    text: estimate,
                    color: .secondary
                )
            }

            // AI indicator
            if task.hasAIProcessing {
                AIGuidanceChip(hasGuidance: hasGuidanceText)
            }

            Spacer()

            // Due date / Scheduled
            if let scheduledTime = task.scheduledTime {
                metadataChip(
                    icon: "calendar",
                    text: formatScheduledTime(scheduledTime),
                    color: urgencyLevel == .overdue ? Theme.CelestialColors.urgencyCritical : .secondary
                )
            }
        }
        .padding(.leading, 36) // Align with title
    }

    private func metadataChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(Theme.Typography.cosmosMeta)
        }
        .foregroundStyle(color)
    }

    private func formatScheduledTime(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    // MARK: - Energy Level

    private var energyLevel: Double {
        let baseEnergy = Double(task.potentialPoints) / 50.0
        let priorityBonus = Double(task.starRating) * 0.1
        return min(1.0, baseEnergy + priorityBonus)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            triggerCompletion()
        } label: {
            Label(
                task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                systemImage: task.isCompleted ? "circle" : "checkmark.circle"
            )
        }

        Divider()

        Button {
            // Future: Schedule action
        } label: {
            Label("Schedule", systemImage: "calendar")
        }

        Button {
            // Future: AI enhance action
        } label: {
            Label("AI Enhance", systemImage: "sparkles")
        }
    }

    // MARK: - Animations

    private func startEntryAnimation() {
        guard !reduceMotion else {
            entryScale = 1.0
            entryOpacity = 1.0
            return
        }

        withAnimation(Theme.Animation.portalOpen) {
            entryScale = 1.0
            entryOpacity = 1.0
        }
    }

    private func startBreathingAnimation() {
        withAnimation(Theme.Animation.plasmaPulse) {
            breathePhase = 1
        }
    }

    private func triggerCompletion() {
        HapticsService.shared.taskCompleteEnhanced()

        // Show supernova burst
        showCompletionBurst = true

        // Reset burst after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showCompletionBurst = false
        }

        onToggleComplete()
    }
}

// MARK: - Cosmic Amber Glow

/// Radial gradient glow that sits behind task cards
/// Creates a living, pulsing nebula effect
struct CosmicAmberGlow: View {
    let taskTypeColor: Color
    let isHighPriority: Bool

    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var primaryGlowColor: Color {
        // Blend task type color with cosmic amber for warmth
        Theme.Colors.aiAmber
    }

    private var glowIntensity: Double {
        isHighPriority ? 0.5 : 0.35
    }

    var body: some View {
        ZStack {
            // Outer soft nebula glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryGlowColor.opacity(glowIntensity),
                            primaryGlowColor.opacity(glowIntensity * 0.4),
                            taskTypeColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .scaleEffect(x: 1.4, y: 1.2)
                .scaleEffect(reduceMotion ? 1.0 : 1.0 + (pulsePhase * 0.06))
                .blur(radius: 40)

            // Inner bright core
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryGlowColor.opacity(glowIntensity * 0.8),
                            primaryGlowColor.opacity(glowIntensity * 0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .scaleEffect(0.6)
                .blur(radius: 20)

            // Secondary accent from task type
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            taskTypeColor.opacity(0.15),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.7, y: 0.3),
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .scaleEffect(0.8)
                .blur(radius: 25)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulsePhase = 1
            }
        }
    }
}

// MARK: - Play Timer Button

/// Amber play button that starts focus timer for a task
struct PlayTimerButton: View {
    let task: TaskItem
    let onStartTimer: (TaskItem) -> Void

    @State private var isPressed = false
    @State private var glowPulse: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            HapticsService.shared.impact()
            onStartTimer(task)
        } label: {
            ZStack {
                // Outer glow ring
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiAmber.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .blur(radius: 8 + (glowPulse * 4))
                    .scaleEffect(reduceMotion ? 1.0 : 1.0 + (glowPulse * 0.1))

                // Background circle
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.aiAmber.opacity(0.25),
                                Theme.Colors.aiAmber.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 18
                        )
                    )
                    .frame(width: 36, height: 36)

                // Border
                SwiftUI.Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiAmber.opacity(0.6),
                                Theme.Colors.aiAmber.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 36, height: 36)

                // Play icon
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiAmber)
                    .offset(x: 1)  // Optical centering for play icon
            }
        }
        .buttonStyle(PlayTimerButtonStyle())
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse = 1
            }
        }
    }
}

/// Button style for play timer button
private struct PlayTimerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .brightness(configuration.isPressed ? 0.1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Plasma Energy Core

/// Living energy core with plasma pulse animation
/// Enhanced with attention ring and tap hint for clarity
struct PlasmaEnergyCore: View {
    let energyState: EnergyState
    let potentialPoints: Int
    let taskTypeColor: Color
    let isCompleted: Bool
    let size: CGFloat
    let onTap: () -> Void

    @State private var pulsePhase: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var attentionRingPhase: CGFloat = 0
    @State private var completionScale: CGFloat = 1.0
    @State private var showCompletionFlash: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var coreColor: Color {
        if isCompleted {
            return Theme.CelestialColors.auroraGreen
        }
        return taskTypeColor
    }

    private var glowIntensity: Double {
        switch energyState {
        case .low: return 0.4
        case .medium: return 0.6
        case .high: return 0.8
        case .max: return 1.0
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Button {
                HapticsService.shared.impact()
                triggerCompletionAnimation()
                onTap()
            } label: {
                ZStack {
                    // Attention ring (pulsing border to draw eye)
                    if !isCompleted && !reduceMotion {
                        SwiftUI.Circle()
                            .strokeBorder(
                                coreColor.opacity(0.3 + (attentionRingPhase * 0.2)),
                                lineWidth: 2
                            )
                            .frame(width: size * 1.5, height: size * 1.5)
                            .scaleEffect(1.0 + (attentionRingPhase * 0.15))
                            .opacity(1 - (attentionRingPhase * 0.5))
                    }

                    // Outer glow ring
                    SwiftUI.Circle()
                        .fill(coreColor.opacity(0.2 + (Double(pulsePhase) * 0.15)))
                        .blur(radius: 8 + (pulsePhase * 4))
                        .frame(width: size * 1.8, height: size * 1.8)

                    // Plasma tendrils (for high energy)
                    if energyState == .max && !reduceMotion {
                        ForEach(0..<3, id: \.self) { i in
                            PlasmaRendril(
                                color: coreColor,
                                angle: rotationAngle + Double(i) * 120,
                                size: size
                            )
                        }
                    }

                    // Inner glow
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    coreColor.opacity(0.8),
                                    coreColor.opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.6
                            )
                        )
                        .frame(width: size * 1.2, height: size * 1.2)
                        .blur(radius: 4)

                    // Core orb
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(0.9),
                                    coreColor.opacity(0.9),
                                    coreColor.opacity(0.6)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                        .frame(width: size, height: size)

                    // Completion flash overlay
                    if showCompletionFlash {
                        SwiftUI.Circle()
                            .fill(.white)
                            .frame(width: size * 1.5, height: size * 1.5)
                            .blur(radius: 4)
                    }

                    // Completed checkmark
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.5, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(completionScale)
                    }
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(completionScale)

            // Tap hint (only for incomplete tasks)
            if !isCompleted {
                Text("tap")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
                    .opacity(reduceMotion ? 0.6 : 0.4 + (attentionRingPhase * 0.2))
            }
        }
        .onAppear {
            if !reduceMotion {
                // Core pulse animation
                withAnimation(Theme.Animation.plasmaPulse) {
                    pulsePhase = 1
                }

                // Attention ring animation (slower, draws eye to completion)
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    attentionRingPhase = 1
                }

                if energyState == .max {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            }
        }
    }

    private func triggerCompletionAnimation() {
        guard !isCompleted else { return }

        // Flash and scale burst
        withAnimation(.easeOut(duration: 0.15)) {
            showCompletionFlash = true
            completionScale = 1.3
        }

        // Settle back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showCompletionFlash = false
                completionScale = 1.0
            }
        }
    }
}

// MARK: - Plasma Tendril

struct PlasmaRendril: View {
    let color: Color
    let angle: Double
    let size: CGFloat

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.6),
                        color.opacity(0.2),
                        .clear
                    ],
                    startPoint: .center,
                    endPoint: .trailing
                )
            )
            .frame(width: size * 0.8, height: 2)
            .offset(x: size * 0.4)
            .rotationEffect(.degrees(angle))
            .blur(radius: 1)
    }
}

// MARK: - Cosmic Points Badge

struct CosmicPointsBadge: View {
    let points: Int
    let energyState: EnergyState
    let isEarned: Bool

    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var badgeColor: Color {
        if isEarned {
            return Theme.CelestialColors.auroraGreen
        }

        switch energyState {
        case .low: return Theme.CelestialColors.starGhost
        case .medium: return Theme.CelestialColors.nebulaCore
        case .high: return Theme.CelestialColors.solarFlare
        case .max: return Theme.CelestialColors.plasmaCore
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Text("+\(points)")
                .font(Theme.Typography.cosmosPoints)
                .foregroundStyle(badgeColor)

            Image(systemName: isEarned ? "bolt.fill" : "bolt")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(badgeColor.opacity(0.15))
                .overlay {
                    if !reduceMotion && energyState == .max {
                        Capsule()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.4),
                                        .clear
                                    ],
                                    center: .center,
                                    angle: .degrees(shimmerPhase)
                                ),
                                lineWidth: 1
                            )
                    }
                }
        }
        .onAppear {
            if !reduceMotion && energyState == .max {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerPhase = 360
                }
            }
        }
    }
}

// MARK: - Living Energy Bar

struct LivingEnergyBar: View {
    let energyLevel: Double
    let taskTypeColor: Color
    let isCompleted: Bool

    @State private var animatedLevel: Double = 0
    @State private var glowPulse: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let barHeight: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: barHeight)

                // Filled portion with gradient
                Capsule()
                    .fill(barGradient)
                    .frame(
                        width: max(0, geometry.size.width * animatedLevel),
                        height: barHeight
                    )

                // Glowing tip
                if !isCompleted && animatedLevel > 0.1 && !reduceMotion {
                    SwiftUI.Circle()
                        .fill(taskTypeColor)
                        .frame(width: 6, height: 6)
                        .blur(radius: 4 + (glowPulse * 2))
                        .offset(x: geometry.size.width * animatedLevel - 3)
                        .opacity(0.8)
                }
            }
        }
        .frame(height: barHeight)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedLevel = isCompleted ? 1.0 : energyLevel
            }

            if !reduceMotion {
                withAnimation(Theme.Animation.plasmaPulse) {
                    glowPulse = 1
                }
            }
        }
        .onChange(of: isCompleted) { _, completed in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animatedLevel = completed ? 1.0 : energyLevel
            }
        }
    }

    private var barGradient: LinearGradient {
        if isCompleted {
            return LinearGradient(
                colors: [
                    Theme.CelestialColors.auroraGreen.opacity(0.9),
                    Theme.CelestialColors.auroraGreen.opacity(0.6),
                    Theme.CelestialColors.plasmaCore.opacity(0.4)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [
                taskTypeColor.opacity(0.9),
                taskTypeColor.opacity(0.6),
                Theme.CelestialColors.nebulaEdge.opacity(0.4)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - AI Sparkle Particles

struct AISparkleParticles: View {
    let color: Color

    @State private var particles: [SparkleParticle] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                SwiftUI.Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .blur(radius: 1)
            }
            .onAppear {
                if !reduceMotion {
                    generateParticles(in: geometry.size)
                }
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [
            .white.opacity(0.8),
            color.opacity(0.6),
            Theme.CelestialColors.nebulaEdge.opacity(0.5)
        ]

        for i in 0..<8 {
            let particle = SparkleParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...4),
                color: colors.randomElement() ?? .white,
                opacity: 0
            )
            particles.append(particle)

            // Animate particle fade in/out
            let delay = Double(i) * 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                        particles[index].opacity = Double.random(in: 0.4...0.8)
                    }
                }
            }
        }
    }
}

struct SparkleParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
}

// MARK: - Button Style

private struct LivingCosmosCardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
                if pressed {
                    HapticsService.shared.cardPress()
                } else {
                    HapticsService.shared.cardRelease()
                }
            }
    }
}

// MARK: - Preview

#Preview("Living Cosmos Task Card") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Living Cosmos Cards")
                .font(Theme.Typography.cosmosTitleLarge)
                .foregroundStyle(.white)

            // High priority with AI
            TaskCardV2(
                task: {
                    let task = TaskItem(title: "Write quarterly report")
                    task.starRating = 3
                    task.aiAdvice = "Start with an outline of the three main sections. Your future self will thank you."
                    task.aiProcessedAt = .now
                    task.taskTypeRaw = TaskType.create.rawValue
                    task.estimatedMinutes = 60
                    task.scheduledTime = Calendar.current.date(byAdding: .hour, value: 2, to: .now)
                    return task
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartTimer: { _ in print("Start timer") }
            )

            // Medium priority
            TaskCardV2(
                task: {
                    let task = TaskItem(title: "Send email to Nicholas")
                    task.starRating = 2
                    task.taskTypeRaw = TaskType.communicate.rawValue
                    task.estimatedMinutes = 15
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )

            // Completed task
            TaskCardV2(
                task: {
                    let task = TaskItem(title: "Review meeting notes")
                    task.starRating = 1
                    task.isCompleted = true
                    task.taskTypeRaw = TaskType.consume.rawValue
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )

            // Overdue task
            TaskCardV2(
                task: {
                    let task = TaskItem(title: "Submit expense report")
                    task.starRating = 2
                    task.taskTypeRaw = TaskType.coordinate.rawValue
                    task.scheduledTime = Calendar.current.date(byAdding: .hour, value: -2, to: .now)
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )
        }
        .padding()
    }
    .background(Theme.CelestialColors.void)
}
