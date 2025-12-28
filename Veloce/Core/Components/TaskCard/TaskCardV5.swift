//
//  TaskCardV5.swift
//  Veloce
//
//  Floating Glass Island Task Card - iOS 26 Ultra-Premium Edition
//  Features: 4-layer glass background, 3-layer shadow system, urgency glow,
//  always-visible AI insight, epic celebration integration, Liquid Glass styling
//

import SwiftUI

// MARK: - Task Card V5 (Floating Glass Island Edition)

struct TaskCardV5: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    var onStartFocus: ((TaskItem, Int) -> Void)?
    var onSnooze: ((TaskItem) -> Void)?
    var onDelete: ((TaskItem) -> Void)?

    // Interaction states
    @State private var isPressed = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showMoreMenu = false
    @State private var selectedFocusDuration: Int = 25

    // Celebration states
    @State private var showEpicCelebration = false
    @State private var celebrationOrigin: CGPoint = .zero

    // Urgency glow animation
    @State private var urgencyGlowPulse: CGFloat = 0

    @Environment(\.responsiveLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let swipeCompleteThreshold: CGFloat = 80
    private let swipeSnoozeThreshold: CGFloat = 80
    private let swipeDeleteThreshold: CGFloat = 150
    private let cornerRadius: CGFloat = 20

    // MARK: - Computed Properties

    private var taskTypeColor: Color {
        switch task.taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    private var urgencyLevel: UrgencyLevel {
        guard let scheduledTime = task.scheduledTime else {
            return .calm
        }

        let hoursUntil = scheduledTime.timeIntervalSince(Date()) / 3600
        if hoursUntil < 0 {
            return .overdue
        } else if hoursUntil < 2 {
            return .critical
        } else if hoursUntil < 24 {
            return .near
        }
        return .calm
    }

    /// Always-visible AI insight with smart fallback chain
    private var aiInsight: String {
        // Priority 1: Explicit AI advice
        if let advice = task.aiAdvice, !advice.isEmpty {
            return advice
        }
        // Priority 2: AI quick tip
        if let tip = task.aiQuickTip, !tip.isEmpty {
            return tip
        }
        // Priority 3: Context-aware fallback
        return generateContextualInsight()
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

            // Epic celebration overlay
            if showEpicCelebration {
                EpicCelebrationOverlay(
                    origin: celebrationOrigin,
                    taskTypeColor: taskTypeColor,
                    pointsEarned: task.pointsEarned > 0 ? task.pointsEarned : 25,
                    isActive: $showEpicCelebration
                )
            }
        }
        .opacity(task.isCompleted ? 0.65 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.isCompleted)
        .coordinateSpace(name: "cardSpace")
        .onAppear(perform: startUrgencyAnimation)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap()
        } label: {
            VStack(spacing: 0) {
                // Main row: Checkbox + Title + Stars
                mainRow
                    .padding(.horizontal, layout.cardPadding)
                    .padding(.top, layout.cardPadding)

                // AI insight whisper (ALWAYS visible)
                aiWhisperSection
                    .padding(.horizontal, layout.cardPadding)
                    .padding(.top, 6)

                // Gradient divider
                gradientDivider
                    .padding(.horizontal, layout.cardPadding)
                    .padding(.vertical, layout.spacing / 2)

                // Metadata row
                metadataRow
                    .padding(.horizontal, layout.cardPadding)

                // Action row: Focus button + More menu
                if !task.isCompleted {
                    actionRow
                        .padding(.horizontal, layout.cardPadding)
                        .padding(.top, layout.spacing * 0.75)
                }

                Spacer().frame(height: layout.cardPadding)
            }
            .background(floatingIslandBackground)
        }
        .buttonStyle(FloatingIslandButtonStyle(isPressed: $isPressed, reduceMotion: reduceMotion))
        .iPadHoverEffect(.lift)
    }

    // MARK: - Floating Island Background (4-Layer System)

    private var floatingIslandBackground: some View {
        ZStack {
            // Layer 1: Deep void foundation
            if reduceTransparency {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.CelestialColors.abyss)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.CelestialColors.voidDeep)
            }

            // Layer 2: Ultra-thin glass material
            if !reduceTransparency {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }

            // Layer 3: Task-type nebula tint (radial gradient)
            if !reduceTransparency {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                taskTypeColor.opacity(0.12),
                                taskTypeColor.opacity(0.04),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
            }

            // Layer 4: Inner highlight (lensing effect)
            if !reduceTransparency {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.08),
                                .white.opacity(0.02),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        }
        // Refraction border
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(isPressed ? 0.45 : 0.35),
                            taskTypeColor.opacity(0.4),
                            Theme.CelestialColors.nebulaEdge.opacity(0.25),
                            .white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isPressed ? 2 : 1.5
                )
        }
        // 3-Layer shadow system
        .shadow(
            color: taskTypeColor.opacity(urgencyLevel.glowIntensity + urgencyGlowPulse * 0.15),
            radius: 24,
            x: 0,
            y: 8
        )
        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    // MARK: - Main Row

    private var mainRow: some View {
        HStack(spacing: layout.spacing * 0.75) {
            // Glass checkbox with celebration trigger
            GeometryReader { geo in
                GlassCheckBubble(
                    taskTypeColor: taskTypeColor,
                    isCompleted: task.isCompleted,
                    onComplete: {
                        celebrationOrigin = CGPoint(
                            x: geo.frame(in: .named("cardSpace")).midX,
                            y: geo.frame(in: .named("cardSpace")).midY
                        )
                        onToggleComplete()
                    },
                    onTriggerCardCelebration: {
                        showEpicCelebration = true
                    }
                )
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .frame(width: 44, height: 44)

            // Title - SF Pro Rounded for premium feel
            Text(task.title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .dynamicTypeFont(base: 17, weight: .semibold, design: .rounded)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            // Priority stars
            if !task.isCompleted {
                priorityStars
            }
        }
    }

    // MARK: - Priority Stars

    private var priorityStars: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < task.starRating ? "star.fill" : "star")
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(
                        index < task.starRating
                            ? Theme.AdaptiveColors.warning
                            : Color(.tertiaryLabel)
                    )
            }
        }
    }

    // MARK: - AI Whisper Section (Always Visible)

    private var aiWhisperSection: some View {
        Text(aiInsight)
            .font(.system(size: 14, weight: .regular, design: .serif))
            .italic()
            .dynamicTypeFont(base: 14, weight: .regular, design: .serif)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Theme.CelestialColors.starDim,
                        Theme.CelestialColors.starDim.opacity(0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4) // Subtle indent for whisper effect
    }

    // MARK: - Gradient Divider

    private var gradientDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        taskTypeColor.opacity(0.4),
                        taskTypeColor.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: layout.spacing * 0.625) {
            // Duration estimate
            if let duration = task.estimatedMinutes, duration > 0 {
                GlassMetadataChip(
                    icon: "clock.fill",
                    text: "\(duration)m",
                    color: Theme.AdaptiveColors.aiSecondary
                )
            }

            // Scheduled time
            if let scheduledTime = task.scheduledTime {
                GlassMetadataChip(
                    icon: "calendar",
                    text: formatScheduledTime(scheduledTime),
                    color: urgencyLevel.color
                )
            }

            // Recurring indicator
            if task.isRecurring {
                GlassMetadataChip(
                    icon: "repeat",
                    text: task.recurringExtended.shortLabel,
                    color: Theme.AdaptiveColors.aiTertiary
                )
            }

            Spacer()

            // Points badge
            if task.pointsEarned > 0 || !task.isCompleted {
                glassPointsBadge
            }
        }
    }

    // MARK: - Glass Points Badge

    private var glassPointsBadge: some View {
        let points = task.pointsEarned > 0 ? task.pointsEarned : 25

        return HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
                .dynamicTypeFont(base: 9, weight: .bold)

            Text("+\(points)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .dynamicTypeFont(base: 12, weight: .bold, design: .rounded)
        }
        .foregroundStyle(Theme.Colors.xp)
        .padding(.horizontal, layout.spacing / 2)
        .padding(.vertical, layout.spacing / 4)
        .background {
            Capsule()
                .fill(Theme.Colors.xp.opacity(0.15))
        }
        .overlay {
            Capsule()
                .strokeBorder(Theme.Colors.xp.opacity(0.3), lineWidth: 0.5)
        }
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: layout.spacing * 0.75) {
            // Focus button (Liquid Glass)
            focusButton

            Spacer()

            // More menu button
            moreMenuButton
        }
    }

    // MARK: - Focus Button (iOS 26 Liquid Glass)

    private var focusButton: some View {
        Button {
            HapticsService.shared.impact()
            onStartFocus?(task, selectedFocusDuration)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .semibold))

                Text("Focus")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.AdaptiveColors.aiGradient)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .adaptiveGlassCapsule()
        .shadow(color: Theme.AdaptiveColors.aiPrimary.opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - More Menu Button

    private var moreMenuButton: some View {
        Menu {
            Section {
                Button {
                    HapticsService.shared.selectionFeedback()
                    onSnooze?(task)
                } label: {
                    Label("Snooze", systemImage: "moon.fill")
                }

                Button {
                    HapticsService.shared.selectionFeedback()
                    onTap()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            Section {
                Button(role: .destructive) {
                    HapticsService.shared.warning()
                    onDelete?(task)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Swipe Backgrounds

    private var swipeBackgrounds: some View {
        ZStack {
            // Right swipe background (Complete)
            HStack {
                ZStack {
                    Theme.AdaptiveColors.success.opacity(0.2)

                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.AdaptiveColors.success)
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
                    (isDelete ? Theme.AdaptiveColors.destructive : Theme.AdaptiveColors.warning).opacity(0.2)

                    Image(systemName: isDelete ? "trash.fill" : "moon.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(isDelete ? Theme.AdaptiveColors.destructive : Theme.AdaptiveColors.warning)
                        .opacity(-swipeOffset > swipeSnoozeThreshold * 0.5 ? 1 : 0)
                }
                .frame(width: max(0, -swipeOffset))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let translation = value.translation.width
                if translation > 0 {
                    swipeOffset = min(translation, swipeCompleteThreshold + 20)
                } else {
                    swipeOffset = max(translation, -(swipeDeleteThreshold + 20))
                }
            }
            .onEnded { value in
                let translation = value.translation.width

                if translation > swipeCompleteThreshold {
                    HapticsService.shared.success()
                    showEpicCelebration = true
                    onToggleComplete()
                } else if translation < -swipeDeleteThreshold {
                    HapticsService.shared.warning()
                    onDelete?(task)
                } else if translation < -swipeSnoozeThreshold {
                    HapticsService.shared.impact(.light)
                    onSnooze?(task)
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    swipeOffset = 0
                }
            }
    }

    // MARK: - Urgency Animation

    private func startUrgencyAnimation() {
        guard !reduceMotion, urgencyLevel.animationSpeed > 0 else { return }

        withAnimation(
            .easeInOut(duration: urgencyLevel.animationSpeed)
            .repeatForever(autoreverses: true)
        ) {
            urgencyGlowPulse = 1.0
        }
    }

    // MARK: - AI Insight Fallback Generation

    private func generateContextualInsight() -> String {
        if task.starRating == 3 {
            return "High priority \u{2014} consider tackling this first."
        }
        if let minutes = task.estimatedMinutes, minutes <= 15 {
            return "Quick win \u{2014} knock this out in \(minutes) minutes."
        }
        if task.isRecurring {
            return "Building consistency with this recurring task."
        }
        if task.taskType == .create {
            return "Creative work ahead \u{2014} find your flow state."
        }
        if task.taskType == .communicate {
            return "Clear communication drives progress."
        }
        return "Focus on one step at a time."
    }

    // MARK: - Helpers

    private func formatScheduledTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "h:mm a"
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Urgency Level

enum UrgencyLevel {
    case calm       // > 24 hours away
    case near       // 2-24 hours away
    case critical   // < 2 hours away
    case overdue    // Past due

    var glowIntensity: Double {
        switch self {
        case .calm: return 0.15
        case .near: return 0.25
        case .critical: return 0.4
        case .overdue: return 0.5
        }
    }

    var color: Color {
        switch self {
        case .calm: return Theme.CelestialColors.urgencyCalm
        case .near: return Theme.CelestialColors.urgencyNear
        case .critical, .overdue: return Theme.CelestialColors.urgencyCritical
        }
    }

    var animationSpeed: Double {
        switch self {
        case .calm: return 0 // No animation
        case .near: return 2.5
        case .critical: return 1.5
        case .overdue: return 0.8
        }
    }
}

// MARK: - Floating Island Button Style

struct FloatingIslandButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.6),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
                if newValue {
                    HapticsService.shared.cardPress()
                }
            }
    }
}

// MARK: - Glass Metadata Chip

struct GlassMetadataChip: View {
    let icon: String
    let text: String
    let color: Color

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))

            Text(text)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background {
            if reduceTransparency {
                Capsule()
                    .fill(color.opacity(0.15))
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .fill(color.opacity(0.08))
                    }
            }
        }
        .overlay {
            Capsule()
                .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
        }
    }
}

// MARK: - Epic Celebration Overlay (Full Premium Animation)

struct EpicCelebrationOverlay: View {
    let origin: CGPoint
    let taskTypeColor: Color
    let pointsEarned: Int
    @Binding var isActive: Bool

    // Ring shockwave states
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.3
    @State private var ring2Opacity: Double = 0

    // Glow pulse states
    @State private var glowScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0

    // Particle states
    @State private var particles: [CelebrationParticle] = []

    // XP animation states
    @State private var showXP = false
    @State private var xpOffset: CGFloat = 0
    @State private var xpOpacity: Double = 0
    @State private var xpScale: CGFloat = 0.3
    @State private var xpGlow: Double = 0

    // Shimmer
    @State private var shimmerOffset: CGFloat = -100

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let particleCount = 16

    var body: some View {
        ZStack {
            // Layer 1: Outer glow pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            taskTypeColor.opacity(0.6),
                            taskTypeColor.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .position(origin)

            // Layer 2: Ring shockwave 1 (inner)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.auroraGreen,
                            taskTypeColor,
                            Theme.CelestialColors.auroraGreen.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 40 * ringScale, height: 40 * ringScale)
                .opacity(ringOpacity)
                .position(origin)

            // Layer 3: Ring shockwave 2 (outer, delayed)
            Circle()
                .stroke(
                    Theme.CelestialColors.auroraGreen.opacity(0.6),
                    lineWidth: 2
                )
                .frame(width: 40 * ring2Scale, height: 40 * ring2Scale)
                .opacity(ring2Opacity)
                .position(origin)

            // Layer 4: Celebration particles
            ForEach(particles) { particle in
                CelebrationParticleView(particle: particle, baseColor: taskTypeColor)
            }

            // Layer 5: XP badge animation
            if showXP {
                ZStack {
                    // Glow background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.gold.opacity(0.2))
                        .blur(radius: 12)
                        .frame(width: 120, height: 50)
                        .opacity(xpGlow)

                    // Main XP badge
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18, weight: .bold))

                        Text("+\(pointsEarned)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Colors.gold,
                                Theme.Colors.xp,
                                Theme.Colors.gold.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Theme.Colors.gold.opacity(0.8), radius: 16)
                    .shadow(color: Theme.Colors.xp.opacity(0.6), radius: 8)
                    // Shimmer overlay
                    .overlay {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .offset(x: shimmerOffset)
                        .mask {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("+\(pointsEarned)")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                            }
                        }
                    }
                }
                .scaleEffect(xpScale)
                .offset(y: xpOffset)
                .opacity(xpOpacity)
                .position(x: origin.x + 60, y: origin.y)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { animateEpicCelebration() }
        }
    }

    // MARK: - Epic Celebration Animation Sequence

    private func animateEpicCelebration() {
        // Trigger epic haptic
        HapticsService.shared.epicTaskComplete()

        if reduceMotion {
            // Simplified celebration for reduced motion
            showXP = true
            xpOpacity = 1
            xpScale = 1
            glowOpacity = 0.5
            glowScale = 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                xpOpacity = 0
                glowOpacity = 0
                isActive = false
            }
            return
        }

        // Generate particles
        createCelebrationParticles()

        // T+0ms: Glow explosion
        withAnimation(.easeOut(duration: 0.25)) {
            glowOpacity = 0.8
            glowScale = 1.2
        }

        // T+50ms: First ring burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 4.0
                ringOpacity = 0.9
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                ringOpacity = 0
            }
        }

        // T+150ms: Second ring burst (delayed, larger)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.6)) {
                ring2Scale = 5.5
                ring2Opacity = 0.7
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.25)) {
                ring2Opacity = 0
            }
        }

        // T+200ms: Animate particles outward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animateParticles()
        }

        // T+250ms: XP badge appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showXP = true

            // Spring entrance with overshoot
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                xpOpacity = 1
                xpScale = 1.2
                xpGlow = 1.0
            }
        }

        // T+400ms: Settle scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                xpScale = 1.0
            }
        }

        // T+450ms: Shimmer sweep
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.4)) {
                shimmerOffset = 100
            }
        }

        // T+500ms: Glow fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                glowOpacity = 0.2
                glowScale = 1.5
            }
        }

        // T+600ms: Float upward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.7)) {
                xpOffset = -80
            }
            withAnimation(.easeOut(duration: 0.5)) {
                xpGlow = 0
            }
        }

        // T+1000ms: Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.35)) {
                xpOpacity = 0
                glowOpacity = 0
            }
        }

        // T+1500ms: Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isActive = false
            showXP = false
            xpOffset = 0
            shimmerOffset = -100
            particles = []
            ringScale = 0.3
            ring2Scale = 0.3
            glowScale = 0.5
        }
    }

    // MARK: - Particle Generation

    private func createCelebrationParticles() {
        var newParticles: [CelebrationParticle] = []

        for i in 0..<particleCount {
            let angle = (Double(i) / Double(particleCount)) * 2 * .pi + Double.random(in: -0.15...0.15)
            let distance = CGFloat.random(in: 50...90)
            let isGold = i % 3 == 0
            let isStar = i % 4 == 0

            let particle = CelebrationParticle(
                id: UUID(),
                shape: isStar ? .star : (i % 2 == 0 ? .circle : .sparkle),
                color: isGold ? .gold : .taskType,
                size: CGFloat.random(in: 6...14),
                startPosition: origin,
                targetOffset: CGSize(
                    width: CGFloat(cos(angle)) * distance,
                    height: CGFloat(sin(angle)) * distance
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 180...360) * (i % 2 == 0 ? 1 : -1),
                delay: Double(i) * 0.015
            )
            newParticles.append(particle)
        }

        particles = newParticles
    }

    private func animateParticles() {
        for i in particles.indices {
            let delay = particles[i].delay

            // Outward burst
            withAnimation(.easeOut(duration: 0.45).delay(delay)) {
                particles[i].currentOffset = particles[i].targetOffset
                particles[i].currentRotation = particles[i].rotation + particles[i].rotationSpeed
            }

            // Gravity curve (fall slightly)
            withAnimation(.easeIn(duration: 0.3).delay(delay + 0.35)) {
                particles[i].currentOffset.height += 30
            }

            // Fade out
            withAnimation(.easeOut(duration: 0.25).delay(delay + 0.4)) {
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Celebration Particle Model

struct CelebrationParticle: Identifiable {
    let id: UUID
    let shape: ParticleShape
    let color: ParticleColor
    let size: CGFloat
    let startPosition: CGPoint
    var targetOffset: CGSize
    var currentOffset: CGSize = .zero
    let rotation: Double
    let rotationSpeed: Double
    var currentRotation: Double = 0
    var opacity: Double = 1.0
    let delay: Double

    enum ParticleShape {
        case circle, star, sparkle
    }

    enum ParticleColor {
        case gold, taskType
    }
}

// MARK: - Celebration Particle View

struct CelebrationParticleView: View {
    let particle: CelebrationParticle
    let baseColor: Color

    private var particleColor: Color {
        switch particle.color {
        case .gold:
            return Theme.Colors.gold
        case .taskType:
            return baseColor
        }
    }

    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle()
                    .fill(particleColor)
            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: particle.size))
                    .foregroundStyle(particleColor)
            case .sparkle:
                Image(systemName: "sparkle")
                    .font(.system(size: particle.size))
                    .foregroundStyle(particleColor)
            }
        }
        .frame(width: particle.size, height: particle.size)
        .rotationEffect(.degrees(particle.currentRotation))
        .offset(particle.currentOffset)
        .opacity(particle.opacity)
        .shadow(color: particleColor.opacity(0.6), radius: 4)
        .position(particle.startPosition)
    }
}


// MARK: - Preview

#Preview("TaskCardV5 - Floating Glass Island") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Floating Glass Island Cards")
                .font(Theme.Typography.cosmosTitle)
                .foregroundStyle(.white)
                .padding(.top, 20)

            TaskCardV5(
                task: {
                    let t = TaskItem(title: "Design quarterly presentation with data visualizations")
                    t.aiAdvice = "Break into sections: data gathering, writing, review"
                    t.estimatedMinutes = 45
                    t.starRating = 3
                    t.scheduledTime = Date().addingTimeInterval(3600)
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            TaskCardV5(
                task: {
                    let t = TaskItem(title: "Review design mockups")
                    t.aiQuickTip = "Focus on mobile-first layouts"
                    t.estimatedMinutes = 20
                    t.starRating = 2
                    t.setRecurringExtended(type: .daily, customDays: nil, endDate: nil)
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            TaskCardV5(
                task: {
                    let t = TaskItem(title: "Quick 5-minute task")
                    t.estimatedMinutes = 5
                    t.starRating = 1
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            Text("Completed State")
                .font(Theme.Typography.cosmosSectionHeader)
                .foregroundStyle(.secondary)

            TaskCardV5(
                task: {
                    let t = TaskItem(title: "Team standup call")
                    t.estimatedMinutes = 15
                    t.starRating = 1
                    t.isCompleted = true
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
    .background(Theme.CelestialColors.void.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
