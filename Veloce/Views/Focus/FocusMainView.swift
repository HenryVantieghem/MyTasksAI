//
//  FocusMainView.swift
//  Veloce
//
//  Reimagined Focus Experience - Two Pillars: Timer & App Blocking
//  Full-screen immersive timer with Tiimo-style customization
//  App blocking with Opal-style screen time visualization
//

import SwiftUI
import FamilyControls

// MARK: - Focus Section

enum FocusSection: String, CaseIterable {
    case timer = "Timer"
    case blocking = "Blocking"

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .blocking: return "shield.lefthalf.filled"
        }
    }
}

// MARK: - Quick Focus Mode

enum QuickFocusMode: String, CaseIterable {
    case pomodoro = "Pomodoro"
    case deepWork = "Deep Work"
    case flow = "Flow"
    case custom = "Custom"

    var duration: TimeInterval {
        switch self {
        case .pomodoro: return 25 * 60
        case .deepWork: return 90 * 60
        case .flow: return 0 // Counts up
        case .custom: return 0 // User defined
        }
    }

    var icon: String {
        switch self {
        case .pomodoro: return "clock"
        case .deepWork: return "brain.head.profile"
        case .flow: return "infinity"
        case .custom: return "slider.horizontal.3"
        }
    }

    var label: String {
        switch self {
        case .pomodoro: return "25m"
        case .deepWork: return "90m"
        case .flow: return "∞"
        case .custom: return "Set"
        }
    }

    var description: String {
        switch self {
        case .pomodoro: return "Classic 25 min focus blocks"
        case .deepWork: return "Extended 90 min deep work"
        case .flow: return "Unlimited flow state"
        case .custom: return "Set your own duration"
        }
    }

    var accentColor: Color {
        switch self {
        case .pomodoro: return Theme.Colors.aiAmber
        case .deepWork: return Theme.Colors.aiPurple
        case .flow: return Theme.Colors.aiCyan
        case .custom: return Theme.Colors.success
        }
    }
}

enum QuickTimerState {
    case idle, running, paused
}

// MARK: - Focus Main View

struct FocusMainView: View {
    // Task context (when launched from a task)
    var taskContext: FocusTaskContext?
    var onSessionComplete: ((Bool) -> Void)?

    // Section selection
    @State private var selectedSection: FocusSection = .timer

    // Navigation state
    @State private var showFocusTimer = false
    @State private var showAppBlocking = false
    @State private var showActiveSession = false
    @State private var showCustomTimerPicker = false

    // Quick timer state - Default to Custom for Tiimo-style experience
    @State private var selectedMode: QuickFocusMode = .custom
    @State private var timerState: QuickTimerState = .idle
    @State private var timeRemaining: TimeInterval = 30 * 60  // Default custom: 30 min
    @State private var totalTime: TimeInterval = 30 * 60
    @AppStorage("lastCustomDuration") private var customMinutes: Int = 30
    @State private var timer: Timer?

    // Services
    private let blockingService = FocusBlockingService.shared
    private let gamificationService = GamificationService.shared

    // Animation states
    @State private var portalPulse: CGFloat = 0
    @State private var backgroundRotation: Double = 0
    @State private var starsOpacity: Double = 0
    @State private var timerBreathing: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Cosmic background with enhanced depth
            enhancedCosmicBackground

            VStack(spacing: 0) {
                // Section Selector - Compact Liquid Glass Pill
                CompactFlowPill(selected: $selectedSection)
                    .padding(.top, Theme.Spacing.universalHeaderHeight + 8)
                    .padding(.horizontal, 24)  // Proper margin from edges

                // Content based on section
                if selectedSection == .timer {
                    timerSectionContent
                } else {
                    appBlockingSectionContent
                }
            }
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
        .sheet(isPresented: $showCustomTimerPicker) {
            EnhancedCustomTimerView(
                selectedMinutes: $customMinutes,
                accentColor: Theme.Colors.success,
                onStart: {
                    showCustomTimerPicker = false
                    timeRemaining = TimeInterval(customMinutes * 60)
                    totalTime = TimeInterval(customMinutes * 60)
                    startTimer()
                },
                onDismiss: {
                    showCustomTimerPicker = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
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

    // MARK: - Section Selector

    private var sectionSelector: some View {
        HStack(spacing: 0) {
            ForEach(FocusSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedSection = section
                        HapticsService.shared.selectionFeedback()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .font(.system(size: 14, weight: .medium))

                        Text(section.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(selectedSection == section ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if selectedSection == section {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            section == .timer ? Theme.Colors.aiAmber : Theme.Colors.aiCyan,
                                            section == .timer ? Theme.Colors.aiOrange : Theme.Colors.aiBlue
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .matchedGeometryEffect(id: "sectionTab", in: sectionNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.5))
        )
    }

    @Namespace private var sectionNamespace

    // MARK: - Timer Section Content

    private var timerSectionContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Immersive Timer Display
                immersiveTimerDisplay
                    .padding(.top, Theme.Spacing.xl)

                // Mode Cards (Tiimo-style)
                modeCardsSection
                    .padding(.top, Theme.Spacing.xl)
                    .padding(.horizontal, Theme.Spacing.screenPadding)

                // Today's Focus Stats
                todayFocusStats
                    .padding(.top, Theme.Spacing.xl)
                    .padding(.horizontal, Theme.Spacing.screenPadding)

                // Streak Section
                streakFlameSection
                    .padding(.top, Theme.Spacing.xl)
                    .padding(.horizontal, Theme.Spacing.screenPadding)

                Spacer()
                    .frame(height: Theme.Spacing.floatingTabBarClearance)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Immersive Timer Display

    private var immersiveTimerDisplay: some View {
        GeometryReader { geometry in
            // Calculate responsive sizes based on available width
            // Use 60% of available width as base, capped at 220px max
            let availableWidth = geometry.size.width
            let baseRingSize = min(availableWidth * 0.55, 220)
            let outerRingBase = baseRingSize * 1.09 // ~240 when base is 220
            let ringGrowth = baseRingSize * 0.18 // ~40 when base is 220
            let innerGlowSize = baseRingSize * 0.91 // ~200 when base is 220
            let orbitOffset = baseRingSize / 2 // Half of ring size
            let strokeWidth: CGFloat = baseRingSize * 0.055 // ~12 when base is 220
            let fontSizeMain = min(baseRingSize * 0.24, 52) // Timer font

            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            selectedMode.accentColor.opacity(0.1 - Double(index) * 0.03),
                            lineWidth: 2
                        )
                        .frame(width: outerRingBase + CGFloat(index) * ringGrowth, height: outerRingBase + CGFloat(index) * ringGrowth)
                        .scaleEffect(timerBreathing + CGFloat(index) * 0.02)
                }

                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: strokeWidth)
                    .frame(width: baseRingSize, height: baseRingSize)

                // Progress ring
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                selectedMode.accentColor,
                                selectedMode.accentColor.opacity(0.8),
                                selectedMode.accentColor.opacity(0.5),
                                selectedMode.accentColor.opacity(0.3),
                                selectedMode.accentColor.opacity(0.1)
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: baseRingSize, height: baseRingSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerProgress)

                // Orbiting indicator dot
                if timerState == .running {
                    Circle()
                        .fill(selectedMode.accentColor)
                        .frame(width: 16, height: 16)
                        .shadow(color: selectedMode.accentColor.opacity(0.6), radius: 8)
                        .offset(y: -orbitOffset)
                        .rotationEffect(.degrees(-90 + 360 * timerProgress))
                        .animation(.linear(duration: 0.5), value: timerProgress)
                }

                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                selectedMode.accentColor.opacity(0.15),
                                selectedMode.accentColor.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: innerGlowSize / 2
                        )
                    )
                    .frame(width: innerGlowSize, height: innerGlowSize)
                    .scaleEffect(timerBreathing)

                // Center content
                VStack(spacing: 12) {
                    // Time display
                    Text(timerDisplayString)
                        .font(.system(size: fontSizeMain, weight: .thin, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: timeRemaining)
                        .minimumScaleFactor(0.7)

                    // Mode label
                    HStack(spacing: 6) {
                        Image(systemName: selectedMode.icon)
                            .font(.system(size: 12))
                        Text(selectedMode.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(selectedMode.accentColor)

                    // Control buttons
                    HStack(spacing: 20) {
                        // Reset button (visible when not idle)
                        if timerState != .idle {
                            Button {
                                resetTimer()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(.white.opacity(0.1)))
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Play/Pause button
                        Button {
                            toggleTimer()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedMode.accentColor)
                                    .frame(width: 52, height: 52)
                                    .shadow(color: selectedMode.accentColor.opacity(0.5), radius: 16, y: 4)

                                Image(systemName: timerState == .running ? "pause.fill" : "play.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .offset(x: timerState == .running ? 0 : 2)
                            }
                        }
                        .buttonStyle(.plain)

                        // Full screen button
                        if timerState != .idle {
                            Button {
                                showActiveSession = true
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(.white.opacity(0.1)))
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: timerState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: min(UIScreen.main.bounds.width * 0.85, 340))
    }

    // MARK: - Mode Cards Section (Tiimo-style)

    private var modeCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Modes")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(QuickFocusMode.allCases, id: \.self) { mode in
                    FocusModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        isDisabled: timerState != .idle
                    ) {
                        if mode == .custom {
                            showCustomTimerPicker = true
                        } else {
                            selectMode(mode)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Today's Focus Stats

    private var todayFocusStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Focus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 12) {
                FocusStatCard(
                    value: "2h 45m",
                    label: "Total Focus",
                    icon: "flame.fill",
                    color: Theme.Colors.aiOrange
                )

                FocusStatCard(
                    value: "5",
                    label: "Sessions",
                    icon: "checkmark.circle.fill",
                    color: Theme.Colors.success
                )

                FocusStatCard(
                    value: "85%",
                    label: "Score",
                    icon: "star.fill",
                    color: Theme.Colors.aiAmber
                )
            }
        }
    }

    // MARK: - App Blocking Section Content

    private var appBlockingSectionContent: some View {
        // Inline blocking with Overview/Schedules/Groups tabs
        InlineBlockingSection()
            .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Screen Time Overview (Opal-style)

    private var screenTimeOverview: some View {
        VStack(spacing: 16) {
            // Main stat card
            VStack(spacing: 8) {
                Text("Today's Screen Time")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("4")
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)

                    Text("h")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("23")
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)

                    Text("m")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Comparison
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.success)

                    Text("32min less than yesterday")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.success)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Theme.Colors.aiCyan.opacity(0.2), lineWidth: 1)
                    )
            )

            // Hourly breakdown chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Usage by Hour")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<12, id: \.self) { hour in
                        let height = screenTimeBarHeight(for: hour)
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.Colors.aiCyan, Theme.Colors.aiBlue],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 20, height: height)

                            Text("\(hour + 8)")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.4))
            )
        }
    }

    private func screenTimeBarHeight(for hour: Int) -> CGFloat {
        // Simulated data - in real app this would come from ScreenTime API
        let heights: [CGFloat] = [15, 25, 45, 60, 40, 30, 55, 70, 50, 35, 20, 10]
        return heights[hour % heights.count]
    }

    // MARK: - Quick Block Actions

    private var quickBlockActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 12) {
                QuickBlockButton(
                    title: "Focus Mode",
                    subtitle: "Block distractions",
                    icon: "moon.fill",
                    color: Theme.Colors.aiPurple,
                    isActive: blockingService.isBlocking
                ) {
                    showAppBlocking = true
                }

                QuickBlockButton(
                    title: "Deep Focus",
                    subtitle: "Unbreakable session",
                    icon: "lock.shield.fill",
                    color: Theme.Colors.aiCyan,
                    isActive: false
                ) {
                    showAppBlocking = true
                }
            }

            HStack(spacing: 12) {
                QuickBlockButton(
                    title: "Social Break",
                    subtitle: "Block social apps",
                    icon: "person.2.slash.fill",
                    color: Theme.Colors.warning,
                    isActive: false
                ) {
                    showAppBlocking = true
                }

                QuickBlockButton(
                    title: "Custom Block",
                    subtitle: "Choose apps",
                    icon: "square.grid.2x2.fill",
                    color: Theme.Colors.success,
                    isActive: false
                ) {
                    showAppBlocking = true
                }
            }
        }
    }

    // MARK: - App Categories Section

    private var appCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Categories")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Button {
                    showAppBlocking = true
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiCyan)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                CategoryUsageRow(
                    name: "Social",
                    time: "1h 45m",
                    percentage: 0.42,
                    color: .pink,
                    icon: "bubble.left.and.bubble.right.fill"
                )

                CategoryUsageRow(
                    name: "Entertainment",
                    time: "1h 12m",
                    percentage: 0.28,
                    color: .purple,
                    icon: "play.tv.fill"
                )

                CategoryUsageRow(
                    name: "Productivity",
                    time: "52m",
                    percentage: 0.20,
                    color: Theme.Colors.aiBlue,
                    icon: "doc.text.fill"
                )

                CategoryUsageRow(
                    name: "Other",
                    time: "34m",
                    percentage: 0.10,
                    color: .gray,
                    icon: "ellipsis.circle.fill"
                )
            }
        }
    }

    // MARK: - Blocking Schedule Section

    private var blockingScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled Blocks")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Button {
                    // Add schedule
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiCyan)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                ScheduleBlockRow(
                    name: "Morning Focus",
                    time: "6:00 AM - 9:00 AM",
                    days: "Mon-Fri",
                    isActive: true
                )

                ScheduleBlockRow(
                    name: "Work Hours",
                    time: "9:00 AM - 5:00 PM",
                    days: "Mon-Fri",
                    isActive: true
                )

                ScheduleBlockRow(
                    name: "Wind Down",
                    time: "9:00 PM - 11:00 PM",
                    days: "Every day",
                    isActive: false
                )
            }
        }
    }

    // MARK: - Reset Timer

    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .idle
        timeRemaining = selectedMode.duration
        totalTime = selectedMode.duration
        HapticsService.shared.impact(.medium)
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

    // MARK: - Quick Timer Section

    private var quickTimerSection: some View {
        GeometryReader { geometry in
            let ringSize = min(geometry.size.width * 0.5, 180)
            let strokeWidth: CGFloat = ringSize * 0.056 // ~10 when size is 180
            let fontSize = min(ringSize * 0.22, 40)

            VStack(spacing: Theme.Spacing.lg) {
                // Timer Circle
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: strokeWidth)
                        .frame(width: ringSize, height: ringSize)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: timerProgress)
                        .stroke(
                            LinearGradient(
                                colors: [selectedMode.accentColor, selectedMode.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                        )
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: timerProgress)

                    // Glow effect
                    Circle()
                        .stroke(selectedMode.accentColor.opacity(0.3), lineWidth: strokeWidth * 2)
                        .frame(width: ringSize, height: ringSize)
                        .blur(radius: 15)

                    // Time display + Play button
                    VStack(spacing: 12) {
                        Text(timerDisplayString)
                            .font(.system(size: fontSize, weight: .light, design: .monospaced))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .minimumScaleFactor(0.7)

                        // Play/Pause Button
                        Button {
                            toggleTimer()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedMode.accentColor)
                                    .frame(width: 48, height: 48)
                                    .shadow(color: selectedMode.accentColor.opacity(0.4), radius: 12, y: 4)

                                Image(systemName: timerState == .running ? "pause.fill" : "play.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .offset(x: timerState == .running ? 0 : 2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: min(UIScreen.main.bounds.width * 0.6, 220))
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
        let totalSeconds = Int(absTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        // For sessions >= 1 hour, show H:MM:SS format
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        // For sessions < 1 hour, show MM:SS format
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

    // MARK: - Portal Cards

    private var portalCardsView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Focus Timer Portal
            FocusPortalCard(
                title: "Focus Timer",
                subtitle: "Set duration & start session",
                icon: "timer",
                accentColor: Theme.Colors.aiAmber,
                glowIntensity: 0.7 + portalPulse * 0.2
            ) {
                HapticsService.shared.impact()
                showFocusTimer = true
            }

            // App Blocking Portal
            FocusPortalCard(
                title: "App Blocking",
                subtitle: "Control your digital space",
                icon: "shield.lefthalf.filled",
                accentColor: Theme.Colors.aiCyan,
                glowIntensity: 0.5 + portalPulse * 0.15
            ) {
                HapticsService.shared.impact()
                showAppBlocking = true
            }
        }
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

    // MARK: - Streak Flame Section (Gamification)

    private var streakFlameSection: some View {
        StreakFlameView(
            currentStreak: gamificationService.currentStreak,
            bestStreak: gamificationService.longestStreak,
            hasStreakShield: gamificationService.hasActiveStreakShield
        )
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

// MARK: - Focus Mode Card (Tiimo-style)

struct FocusModeCard: View {
    let mode: QuickFocusMode
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(mode.accentColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: mode.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(mode.accentColor)
                    }

                    Spacer()

                    // Selected indicator
                    if isSelected {
                        Circle()
                            .fill(mode.accentColor)
                            .frame(width: 8, height: 8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(mode.label)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(mode.accentColor)
                    }

                    Text(mode.description)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(isSelected ? 0.7 : 0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? mode.accentColor.opacity(0.5) : .white.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.5 : 1)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.2)) { isPressed = false } }
        )
    }
}

// MARK: - Focus Stat Card

struct FocusStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.4))
        )
    }
}

// MARK: - Quick Block Button

struct QuickBlockButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isActive: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isActive ? 0.3 : 0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                if isActive {
                    Text("Active")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(color))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial.opacity(isActive ? 0.6 : 0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isActive ? color.opacity(0.3) : .white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.2)) { isPressed = false } }
        )
    }
}

// MARK: - Category Usage Row

struct CategoryUsageRow: View {
    let name: String
    let time: String
    let percentage: Double
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(time)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .frame(height: 6)

                        Capsule()
                            .fill(color)
                            .frame(width: geometry.size.width * percentage, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.3))
        )
    }
}

// MARK: - Schedule Block Row

struct ScheduleBlockRow: View {
    let name: String
    let time: String
    let days: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text(time)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))

                    Text(days)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            Toggle("", isOn: .constant(isActive))
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.aiCyan))
                .labelsHidden()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.3))
        )
    }
}

// MARK: - Custom Timer Picker Sheet

struct CustomTimerPickerSheet: View {
    @Binding var minutes: Int
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let presets = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.focus

                VStack(spacing: 24) {
                    // Custom time display
                    VStack(spacing: 8) {
                        Text("\(minutes)")
                            .font(.system(size: 72, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)

                        Text("minutes")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 32)

                    // Slider
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { Double(minutes) },
                            set: { minutes = Int($0) }
                        ), in: 1...180, step: 1)
                        .tint(Theme.Colors.success)

                        HStack {
                            Text("1 min")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))

                            Spacer()

                            Text("3 hours")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 24)

                    // Presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Select")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                            ForEach(presets, id: \.self) { preset in
                                Button {
                                    minutes = preset
                                    HapticsService.shared.selectionFeedback()
                                } label: {
                                    Text("\(preset)m")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(minutes == preset ? .white : .white.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(minutes == preset ? Theme.Colors.success : .white.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Start button
                    Button {
                        HapticsService.shared.impact(.medium)
                        onStart()
                    } label: {
                        Text("Start Focus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Theme.Colors.success)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Custom Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }
}

// MARK: - Preview

#Preview {
    FocusMainView()
}
