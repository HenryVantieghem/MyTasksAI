//
//  FocusMainView.swift
//  Veloce
//
//  Reimagined Focus Experience
//  Two main portals: Focus Timer & App Blocking
//  Cosmic Observatory aesthetic with stunning glass effects
//

import SwiftUI
import FamilyControls

// MARK: - Quick Focus Mode

enum QuickFocusMode: String, CaseIterable {
    case pomodoro = "Pomodoro"
    case deepWork = "Deep Work"
    case flow = "Flow"

    var duration: TimeInterval {
        switch self {
        case .pomodoro: return 25 * 60
        case .deepWork: return 90 * 60
        case .flow: return 0 // Counts up
        }
    }

    var icon: String {
        switch self {
        case .pomodoro: return "clock"
        case .deepWork: return "brain.head.profile"
        case .flow: return "bolt"
        }
    }

    var label: String {
        switch self {
        case .pomodoro: return "25m"
        case .deepWork: return "90m"
        case .flow: return "∞"
        }
    }

    var accentColor: Color {
        switch self {
        case .pomodoro: return Theme.Colors.aiAmber
        case .deepWork: return Theme.Colors.aiPurple
        case .flow: return Theme.Colors.aiCyan
        }
    }
}

enum QuickTimerState {
    case idle, running, paused
}

// MARK: - Flow Section (Unified Toggle)

enum FlowSection: String, CaseIterable {
    case timer = "Timer"
    case blocking = "Blocking"
    case insights = "Insights"

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .blocking: return "shield.lefthalf.filled"
        case .insights: return "chart.bar.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .timer: return Theme.Colors.aiAmber
        case .blocking: return Theme.Colors.aiCyan
        case .insights: return Theme.Colors.aiPurple
        }
    }
}

// MARK: - Focus Main View

struct FocusMainView: View {
    // Task context (when launched from a task)
    var taskContext: FocusTaskContext?
    var onSessionComplete: ((Bool) -> Void)?

    // Navigation state
    @State private var showFocusTimer = false
    @State private var showAppBlocking = false
    @State private var showActiveSession = false

    // Section state (unified toggle)
    @State private var activeSection: FlowSection = .timer

    // Quick timer state
    @State private var selectedMode: QuickFocusMode = .pomodoro
    @State private var timerState: QuickTimerState = .idle
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var totalTime: TimeInterval = 25 * 60
    @State private var timer: Timer?

    // Services
    private let blockingService = FocusBlockingService.shared
    private let gamificationService = GamificationService.shared

    // Animation states
    @State private var portalPulse: CGFloat = 0
    @State private var backgroundRotation: Double = 0
    @State private var starsOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Cosmic background with enhanced depth
            enhancedCosmicBackground

            ScrollView {
                VStack(spacing: 0) {
                    // Header area with subtle greeting
                    headerView
                        .padding(.top, Theme.Spacing.universalHeaderHeight)

                    // Quick Timer Section (above portal cards)
                    quickTimerSection
                        .padding(.top, Theme.Spacing.lg)

                    // Mode Selector
                    modeSelectorView
                        .padding(.top, Theme.Spacing.lg)

                    // Section Toggle (Timer | Blocking | Insights)
                    FlowSectionToggle(selected: $activeSection)
                        .padding(.top, Theme.Spacing.xl)

                    // Section Content
                    sectionContentView
                        .padding(.top, Theme.Spacing.lg)

                    // Quick stats bar
                    quickStatsBar
                        .padding(.top, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.floatingTabBarClearance)
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showFocusTimer) {
            FocusTimerSetupView(
                taskContext: taskContext,
                onStartSession: { session in
                    showFocusTimer = false
                    showActiveSession = true
                }
            )
        }
        .fullScreenCover(isPresented: $showAppBlocking) {
            AppBlockingMainView()
        }
        .fullScreenCover(isPresented: $showActiveSession) {
            ImmersiveFocusSessionView(
                onComplete: { completed in
                    showActiveSession = false
                    onSessionComplete?(completed)
                }
            )
        }
        .onAppear {
            startAmbientAnimations()

            // Check for active session
            if blockingService.isBlocking {
                showActiveSession = true
            }

            // Auto-show timer setup if launched from task
            if taskContext != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFocusTimer = true
                }
            }
        }
    }

    // MARK: - Enhanced Cosmic Background

    private var enhancedCosmicBackground: some View {
        ZStack {
            // Base void gradient
            LinearGradient(
                colors: [
                    Theme.CelestialColors.voidDeep,
                    Theme.CelestialColors.void,
                    Theme.CelestialColors.abyss
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Rotating nebula layers
            nebulaLayers

            // Central focus glow
            RadialGradient(
                colors: [
                    Theme.Colors.aiAmber.opacity(0.15),
                    Theme.Colors.aiOrange.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .scaleEffect(1 + portalPulse * 0.1)

            // Star field
            starFieldView
                .opacity(starsOpacity)
        }
    }

    private var nebulaLayers: some View {
        ZStack {
            // Purple nebula (top-right)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.12),
                            Theme.Colors.aiPurple.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 400)
                .rotationEffect(.degrees(backgroundRotation * 0.5))
                .offset(x: 150, y: -200)

            // Amber nebula (center-left)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiAmber.opacity(0.08),
                            Theme.Colors.aiOrange.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 350)
                .rotationEffect(.degrees(-backgroundRotation * 0.3))
                .offset(x: -100, y: 100)

            // Cyan nebula (bottom)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiCyan.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 300)
                .rotationEffect(.degrees(backgroundRotation * 0.2))
                .offset(x: 50, y: 300)
        }
        .blur(radius: 60)
        .ignoresSafeArea()
    }

    private var starFieldView: some View {
        Canvas { context, size in
            // Generate deterministic stars
            let stars = generateStars(count: 60, in: size)

            for star in stars {
                let rect = CGRect(
                    x: star.x - star.size / 2,
                    y: star.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(star.brightness))
                )
            }
        }
        .ignoresSafeArea()
    }

    private func generateStars(count: Int, in size: CGSize) -> [(x: CGFloat, y: CGFloat, size: CGFloat, brightness: Double)] {
        var stars: [(x: CGFloat, y: CGFloat, size: CGFloat, brightness: Double)] = []
        var generator = SeededRandomGenerator(seed: 42)

        for _ in 0..<count {
            let star = (
                x: CGFloat.random(in: 0...size.width, using: &generator),
                y: CGFloat.random(in: 0...size.height, using: &generator),
                size: CGFloat.random(in: 1...3, using: &generator),
                brightness: Double.random(in: 0.2...0.8, using: &generator)
            )
            stars.append(star)
        }
        return stars
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(headerGreeting)
                .font(.system(size: 28, weight: .thin))
                .foregroundStyle(.white)

            Text("Enter your focus sanctuary")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, Theme.Spacing.lg)
    }

    private var headerGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning Focus"
        case 12..<17: return "Afternoon Focus"
        case 17..<21: return "Evening Focus"
        default: return "Night Focus"
        }
    }

    // MARK: - Quick Timer Section (Tiimo-Inspired)

    private var quickTimerSection: some View {
        ZStack {
            // Tiimo-style visual timer
            TiimoTimerCircle(
                mode: selectedMode,
                isActive: timerState == .running,
                progress: timerProgress,
                timeRemaining: timeRemaining,
                totalTime: totalTime
            )

            // Play/Pause button overlay
            VStack {
                Spacer()
                    .frame(height: 170)

                Button {
                    toggleTimer()
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedMode.accentColor)
                            .frame(width: 52, height: 52)
                            .shadow(color: selectedMode.accentColor.opacity(0.5), radius: 16, y: 6)

                        Image(systemName: timerState == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .offset(x: timerState == .running ? 0 : 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 280)
    }

    // MARK: - Mode Selector

    private var modeSelectorView: some View {
        HStack(spacing: 12) {
            ForEach(QuickFocusMode.allCases, id: \.self) { mode in
                QuickModeButton(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    isDisabled: timerState != .idle
                ) {
                    selectMode(mode)
                }
            }
        }
    }

    // MARK: - Timer Computed Properties

    private var timerProgress: Double {
        guard totalTime > 0 else {
            return selectedMode == .flow ? 1 : 0
        }
        return timeRemaining / totalTime
    }

    private var timerDisplayString: String {
        let absTime = abs(timeRemaining)
        let minutes = Int(absTime) / 60
        let seconds = Int(absTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Timer Actions

    private func toggleTimer() {
        HapticsService.shared.impact(.medium)

        switch timerState {
        case .idle:
            startTimer()
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        }
    }

    private func startTimer() {
        timerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            if selectedMode == .flow {
                timeRemaining += 1
            } else if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeSession()
            }
        }
    }

    private func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        timer = nil
    }

    private func resumeTimer() {
        timerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            if selectedMode == .flow {
                timeRemaining += 1
            } else if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeSession()
            }
        }
    }

    private func completeSession() {
        timer?.invalidate()
        timer = nil
        timerState = .idle

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Reset to mode duration
        timeRemaining = selectedMode.duration
        totalTime = selectedMode.duration
    }

    private func selectMode(_ mode: QuickFocusMode) {
        guard timerState == .idle else { return }

        HapticsService.shared.selectionFeedback()
        selectedMode = mode
        timeRemaining = mode.duration
        totalTime = mode.duration
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContentView: some View {
        switch activeSection {
        case .timer:
            timerSectionContent
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))

        case .blocking:
            blockingSectionContent
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))

        case .insights:
            insightsSectionContent
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
        }
    }

    // MARK: - Timer Section Content

    private var timerSectionContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Configure Session Card
            FlowSectionCard(
                title: "Configure Session",
                subtitle: "Customize your focus time",
                icon: "slider.horizontal.3",
                accentColor: Theme.Colors.aiAmber
            ) {
                HapticsService.shared.impact()
                showFocusTimer = true
            }

            // Quick duration options
            HStack(spacing: 12) {
                ForEach([15, 30, 45, 60], id: \.self) { minutes in
                    durationChip(minutes: minutes)
                }
            }

            // Task linking hint
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.aiAmber.opacity(0.7))

                Text("Link a task to track progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }

    private func durationChip(minutes: Int) -> some View {
        Button {
            HapticsService.shared.selectionFeedback()
            timeRemaining = TimeInterval(minutes * 60)
            totalTime = TimeInterval(minutes * 60)
        } label: {
            Text("\(minutes)m")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .glassEffect(
                    .regular.tint(Theme.Colors.aiAmber.opacity(0.1)),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Blocking Section Content

    private var blockingSectionContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Quick Block Toggle
            FlowBlockToggleCard(isBlocking: blockingService.isBlocking) {
                // Toggle blocking
            }

            // App Groups Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FlowAppGroupCard(name: "Social", icon: "bubble.left.and.bubble.right.fill", appCount: 5, color: Theme.Colors.aiPink)
                FlowAppGroupCard(name: "Entertainment", icon: "play.rectangle.fill", appCount: 3, color: Theme.Colors.aiPurple)
                FlowAppGroupCard(name: "Games", icon: "gamecontroller.fill", appCount: 8, color: Theme.Colors.aiOrange)
                FlowAppGroupCard(name: "Custom", icon: "plus.circle.fill", appCount: 0, color: Theme.Colors.aiCyan)
            }

            // View All / Schedules Link
            Button {
                HapticsService.shared.impact()
                showAppBlocking = true
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                    Text("Manage Schedules")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .opacity(0.5)
                }
                .foregroundStyle(Theme.Colors.aiCyan)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(
                    .regular.tint(Theme.Colors.aiCyan.opacity(0.1)),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Insights Section Content

    private var insightsSectionContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Streak & Gems Hero
            StreakFlameView(
                currentStreak: gamificationService.currentStreak,
                bestStreak: gamificationService.longestStreak,
                hasStreakShield: gamificationService.hasActiveStreakShield
            )

            // Gem Collection
            GemCollectionView(gems: buildGemProgress()) { gemType in
                // Handle gem tap - could show details
                HapticsService.shared.selectionFeedback()
            }

            // Focus Score Hero
            FlowFocusScoreCard(score: focusScore, trend: focusScoreTrend)

            // Screen Time Summary
            FlowScreenTimeSummary(
                todayTime: formattedFocusTime,
                vsYesterday: focusTimeComparison,
                pickups: 67
            )

            // AI Insight
            FlowAIInsightCard(
                insight: gamificationService.latestInsight ?? "Complete a focus session to get personalized insights."
            )
        }
    }

    // MARK: - Gem Progress Calculation

    private func buildGemProgress() -> [GemProgress] {
        let totalMinutes = gamificationService.focusMinutesTotal
        let streak = gamificationService.currentStreak
        let totalHours = totalMinutes / 60
        let sessionsCompleted = gamificationService.tasksCompleted // Using as proxy for now

        return [
            GemProgress(
                gemType: .sapphire,
                isEarned: sessionsCompleted >= 1,
                progress: min(1.0, Double(sessionsCompleted) / 1.0),
                earnedDate: sessionsCompleted >= 1 ? Date() : nil
            ),
            GemProgress(
                gemType: .emerald,
                isEarned: totalMinutes >= 90,
                progress: min(1.0, Double(totalMinutes) / 90.0),
                earnedDate: totalMinutes >= 90 ? Date() : nil
            ),
            GemProgress(
                gemType: .ruby,
                isEarned: streak >= 7,
                progress: min(1.0, Double(streak) / 7.0),
                earnedDate: streak >= 7 ? Date() : nil
            ),
            GemProgress(
                gemType: .diamond,
                isEarned: streak >= 30,
                progress: min(1.0, Double(streak) / 30.0),
                earnedDate: streak >= 30 ? Date() : nil
            ),
            GemProgress(
                gemType: .amethyst,
                isEarned: totalHours >= 100,
                progress: min(1.0, Double(totalHours) / 100.0),
                earnedDate: totalHours >= 100 ? Date() : nil
            )
        ]
    }

    // MARK: - Focus Analytics Computed Properties

    private var focusScore: Int {
        // Calculate focus score based on streaks, consistency, and time
        let streakBonus = min(gamificationService.currentStreak * 5, 30)
        let timeBonus = min(gamificationService.focusMinutesTotal / 10, 50)
        let consistencyBonus = 20 // Base consistency
        return min(streakBonus + timeBonus + consistencyBonus, 100)
    }

    private var focusScoreTrend: ScoreTrend {
        // Compare this week vs last week activity
        let thisWeek = gamificationService.weeklyActivityData.reduce(0, +)
        let lastWeek = gamificationService.previousWeekData.reduce(0, +)
        if thisWeek > lastWeek { return .up }
        if thisWeek < lastWeek { return .down }
        return .stable
    }

    private var formattedFocusTime: String {
        let totalMinutes = gamificationService.focusMinutesTotal
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    private var focusTimeComparison: String {
        // Calculate vs yesterday comparison
        let today = gamificationService.weeklyActivityData.last ?? 0
        let yesterday = gamificationService.weeklyActivityData.dropLast().last ?? 0
        guard yesterday > 0 else { return "+\(today)" }
        let change = ((Double(today) - Double(yesterday)) / Double(yesterday)) * 100
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(Int(change))%"
    }

    // MARK: - Quick Stats Bar

    private var quickStatsBar: some View {
        HStack(spacing: Theme.Spacing.lg) {
            quickStatItem(value: "2h 45m", label: "Today's Focus", icon: "flame.fill", color: Theme.Colors.aiOrange)

            Divider()
                .frame(height: 30)
                .background(.white.opacity(0.2))

            quickStatItem(value: "5", label: "Sessions", icon: "checkmark.circle.fill", color: Theme.Colors.success)

            Divider()
                .frame(height: 30)
                .background(.white.opacity(0.2))

            quickStatItem(value: "85%", label: "Focus Score", icon: "star.fill", color: Theme.Colors.aiAmber)
        }
        .padding(Theme.Spacing.md)
        // 🌟 LIQUID GLASS: Interactive glass stats bar
        .glassEffect(
            .regular.interactive(true),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }

    private func quickStatItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Ambient Animations

    private func startAmbientAnimations() {
        guard !reduceMotion else {
            starsOpacity = 0.7
            return
        }

        // Fade in stars
        withAnimation(.easeOut(duration: 1.5)) {
            starsOpacity = 0.7
        }

        // Portal breathing
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            portalPulse = 1
        }

        // Slow background rotation
        withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
            backgroundRotation = 360
        }
    }
}

// MARK: - Focus Portal Card

struct FocusPortalCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let glowIntensity: Double
    let action: () -> Void

    @State private var isPressed = false
    @State private var orbRotation: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                // Portal glow background
                portalGlow

                // Glass container
                HStack(spacing: Theme.Spacing.lg) {
                    // Left: Animated orb icon
                    orbIconView

                    // Center: Title & subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    // Right: Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(Theme.Spacing.xl)
                // 🌟 LIQUID GLASS: Interactive glass with tint for portal effect
                .glassEffect(
                    .regular
                        .tint(accentColor.opacity(0.08))
                        .interactive(true),
                    in: RoundedRectangle(cornerRadius: 24)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.5),
                                    accentColor.opacity(0.3),
                                    .white.opacity(0.2),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: accentColor.opacity(0.2), radius: 16, y: 8)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    orbRotation = 360
                }
            }
        }
    }

    private var portalGlow: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(
                RadialGradient(
                    colors: [
                        accentColor.opacity(0.2 * glowIntensity),
                        accentColor.opacity(0.05 * glowIntensity),
                        Color.clear
                    ],
                    center: .leading,
                    startRadius: 0,
                    endRadius: 300
                )
            )
            .blur(radius: 20)
            .offset(x: -20)
    }

    private var orbIconView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(accentColor.opacity(0.3))
                .frame(width: 70, height: 70)
                .blur(radius: 15)

            // Rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            accentColor.opacity(0.6),
                            accentColor.opacity(0.2),
                            .clear,
                            accentColor.opacity(0.2),
                            accentColor.opacity(0.6)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(orbRotation))

            // Inner orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor,
                            accentColor.opacity(0.7)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 25
                    )
                )
                .frame(width: 44, height: 44)

            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Quick Mode Button

struct QuickModeButton: View {
    let mode: QuickFocusMode
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .medium))

                Text(mode.rawValue)
                    .font(.system(size: 12, weight: .medium))

                Text(mode.label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(
                .regular
                    .tint(isSelected ? mode.accentColor.opacity(0.15) : Color.clear)
                    .interactive(true),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .foregroundStyle(isSelected ? mode.accentColor : .white.opacity(0.7))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? mode.accentColor : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.4 : 1)
        .buttonStyle(.plain)
    }
}

// MARK: - Seeded Random Generator

struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Flow Section Card

struct FlowSectionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(Theme.Spacing.md)
            .glassEffect(
                .regular.tint(accentColor.opacity(0.08)),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Flow Block Toggle Card

struct FlowBlockToggleCard: View {
    let isBlocking: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Shield icon with status
            ZStack {
                Circle()
                    .fill(isBlocking ? Theme.Colors.aiCyan.opacity(0.3) : Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: isBlocking ? "shield.checkered" : "shield")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isBlocking ? Theme.Colors.aiCyan : .white.opacity(0.6))
                    .symbolEffect(.pulse, options: .repeating, isActive: isBlocking)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isBlocking ? "Blocking Active" : "App Blocking")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Text(isBlocking ? "Distractions are blocked" : "Enable to block apps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Toggle (visual only for now)
            Toggle("", isOn: .constant(isBlocking))
                .labelsHidden()
                .tint(Theme.Colors.aiCyan)
        }
        .padding(Theme.Spacing.md)
        .glassEffect(
            .regular.tint(isBlocking ? Theme.Colors.aiCyan.opacity(0.1) : Color.clear),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isBlocking ? Theme.Colors.aiCyan.opacity(0.4) : .white.opacity(0.15),
                    lineWidth: isBlocking ? 1.5 : 0.5
                )
        }
    }
}

// MARK: - Flow App Group Card

struct FlowAppGroupCard: View {
    let name: String
    let icon: String
    let appCount: Int
    let color: Color

    @State private var isSelected = false

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            isSelected.toggle()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }

                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text("\(appCount) apps")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassEffect(
                .regular.tint(isSelected ? color.opacity(0.12) : Color.clear),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : .white.opacity(0.1), lineWidth: isSelected ? 1.5 : 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Focus Score Card

enum ScoreTrend {
    case up, down, stable

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return Theme.Colors.success
        case .down: return Theme.Colors.error
        case .stable: return Theme.Colors.aiAmber
        }
    }

    var description: String {
        switch self {
        case .up: return "+12% from last week"
        case .down: return "-8% from last week"
        case .stable: return "Same as last week"
        }
    }
}

struct FlowFocusScoreCard: View {
    let score: Int
    let trend: ScoreTrend

    var body: some View {
        HStack(spacing: 20) {
            // Score Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Score")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .bold))
                    Text(trend.description)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(trend.color)
            }

            Spacer()
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple.opacity(0.4), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Flow Screen Time Summary

struct FlowScreenTimeSummary: View {
    let todayTime: String
    let vsYesterday: String
    let pickups: Int

    var body: some View {
        HStack(spacing: 0) {
            summaryItem(value: todayTime, label: "Today", icon: "clock.fill", color: Theme.Colors.aiCyan)

            Divider()
                .frame(height: 40)
                .background(.white.opacity(0.15))
                .padding(.horizontal, 12)

            summaryItem(value: vsYesterday, label: "vs Yesterday", icon: "arrow.down", color: Theme.Colors.success)

            Divider()
                .frame(height: 40)
                .background(.white.opacity(0.15))
                .padding(.horizontal, 12)

            summaryItem(value: "\(pickups)", label: "Pickups", icon: "hand.tap.fill", color: Theme.Colors.aiOrange)
        }
        .padding(Theme.Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        }
    }

    private func summaryItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Flow AI Insight Card

struct FlowAIInsightCard: View {
    let insight: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI sparkle icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Insight")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text(insight)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(2)
            }
        }
        .padding(Theme.Spacing.md)
        .glassEffect(
            .regular.tint(Theme.Colors.aiPurple.opacity(0.08)),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.Colors.aiCyan.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Preview

#Preview {
    FocusMainView()
}
