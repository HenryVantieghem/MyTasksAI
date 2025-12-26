//
//  CelebrationIntegration.swift
//  Veloce
//
//  Celebration System Integration
//  View modifiers and helpers to integrate celebrations throughout the app
//

import SwiftUI
import Combine

// MARK: - Screen Bounds Helper

/// Helper to get screen bounds without using deprecated UIScreen.main
private extension UIApplication {
    static var screenBounds: CGRect {
        guard let windowScene = shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return CGRect(x: 0, y: 0, width: 393, height: 852) // iPhone 15 Pro fallback
        }
        return windowScene.screen.bounds
    }
}

// MARK: - Celebration Container Modifier

/// Adds celebration overlays to any view
struct CelebrationContainerModifier: ViewModifier {
    @State private var showingMomentumBanner = false
    @State private var lastMomentumCount = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                // Celebration overlays (particles, XP floats, etc.)
                CelebrationOverlayContainer()
            }
            .overlay(alignment: .top) {
                // Momentum activation banner
                if showingMomentumBanner {
                    MomentumActivationBanner(
                        isShowing: $showingMomentumBanner,
                        streakCount: lastMomentumCount
                    )
                    .padding(.top, 60)
                }
            }
            .onReceive(CelebrationEngine.shared.momentumChanged) { state in
                // Show banner when momentum first activates
                if state.isActive && !showingMomentumBanner && state.streakCount >= 3 && lastMomentumCount < 3 {
                    showingMomentumBanner = true
                }
                lastMomentumCount = state.streakCount
            }
    }
}

extension View {
    /// Adds celebration system overlays to this view
    func withCelebrations() -> some View {
        modifier(CelebrationContainerModifier())
    }
}

// MARK: - Task Completion Celebration Trigger

/// Extension to trigger celebrations when completing tasks
extension CelebrationEngine {
    /// Convenience method to celebrate task completion with automatic position detection
    @MainActor
    func celebrateTaskCompletion(
        task: TaskItem,
        at geometry: GeometryProxy? = nil,
        fallbackPosition: CGPoint? = nil
    ) {
        // Determine position for particle effects
        let position: CGPoint
        if let geo = geometry {
            // Use center of the geometry
            position = CGPoint(
                x: geo.frame(in: .global).midX,
                y: geo.frame(in: .global).midY
            )
        } else if let fallback = fallbackPosition {
            position = fallback
        } else {
            // Default to center of screen
            let screenBounds = UIApplication.screenBounds
            position = CGPoint(x: screenBounds.width / 2, y: screenBounds.height / 2)
        }

        // Calculate XP from gamification service
        let xp = GamificationService.shared.calculatePoints(
            for: task,
            completedOnTime: true,
            withStreak: true
        )

        // Trigger celebration
        celebrate(task: task, at: position, baseXP: xp)
    }
}

// MARK: - Celebratory Task Row Wrapper

/// Wraps a task row to automatically trigger celebrations on completion
struct CelebratoryTaskWrapper<Content: View>: View {
    let task: TaskItem
    let onComplete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var completionPosition: CGPoint = .zero

    var body: some View {
        content()
            .background {
                GeometryReader { geo in
                    Color.clear.onAppear {
                        completionPosition = CGPoint(
                            x: geo.frame(in: .global).midX,
                            y: geo.frame(in: .global).midY
                        )
                    }
                    .onChange(of: geo.frame(in: .global)) { _, frame in
                        completionPosition = CGPoint(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .onChange(of: task.isCompleted) { wasCompleted, isCompleted in
                // Only celebrate when transitioning to completed
                if !wasCompleted && isCompleted {
                    CelebrationEngine.shared.celebrateTaskCompletion(
                        task: task,
                        fallbackPosition: completionPosition
                    )
                }
            }
    }
}

// MARK: - Momentum Header Badge

/// Compact momentum indicator for navigation headers
struct HeaderMomentumBadge: View {
    @State private var momentumState = MomentumState()

    var body: some View {
        Group {
            if momentumState.streakCount > 0 {
                MomentumIndicator(state: momentumState)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: momentumState.streakCount)
        .onReceive(CelebrationEngine.shared.momentumChanged) { state in
            momentumState = state
        }
    }
}

// MARK: - Celebration Settings

struct CelebrationSettingsView: View {
    @AppStorage("celebrationSoundsEnabled") private var soundsEnabled = true
    @AppStorage("celebrationHapticsEnabled") private var hapticsEnabled = true
    @AppStorage("celebrationConfettiEnabled") private var confettiEnabled = true
    @AppStorage("celebrationIntensity") private var intensity: CelebrationIntensity = .medium

    var body: some View {
        Form {
            // Sounds section
            CelebrationSoundSettings()

            // Haptics section
            Section {
                Toggle("Haptic Feedback", isOn: $hapticsEnabled)

                if hapticsEnabled {
                    Button {
                        HapticsService.shared.celebration()
                    } label: {
                        Label("Preview Haptics", systemImage: "waveform")
                    }
                }
            } header: {
                Text("Haptics")
            }

            // Visual effects section
            Section {
                Toggle("Confetti Effects", isOn: $confettiEnabled)
                    .onChange(of: confettiEnabled) { _, enabled in
                        // Respect system reduce motion
                        if UIAccessibility.isReduceMotionEnabled && enabled {
                            confettiEnabled = false
                        }
                    }

                Picker("Celebration Intensity", selection: $intensity) {
                    ForEach(CelebrationIntensity.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            } header: {
                Text("Visual Effects")
            } footer: {
                if UIAccessibility.isReduceMotionEnabled {
                    Text("Some effects are reduced because \"Reduce Motion\" is enabled in system settings.")
                }
            }

            // Preview section
            Section {
                Button {
                    previewCelebration(.quick)
                } label: {
                    HStack {
                        Label("Quick Celebration", systemImage: "sparkle")
                        Spacer()
                        Text("+10 XP")
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    previewCelebration(.normal)
                } label: {
                    HStack {
                        Label("Normal Celebration", systemImage: "sparkles")
                        Spacer()
                        Text("+25 XP")
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    previewCelebration(.important)
                } label: {
                    HStack {
                        Label("Important Celebration", systemImage: "star.fill")
                        Spacer()
                        Text("+50 XP")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Celebrations")
    }

    private func previewCelebration(_ level: CelebrationLevel) {
        let screenBounds = UIApplication.screenBounds
        let center = CGPoint(
            x: screenBounds.width / 2,
            y: screenBounds.height / 2
        )

        CelebrationEngine.shared.celebrate(
            level: level,
            xp: level.xpAmount,
            at: center,
            message: level == .important ? "Great work!" : nil
        )
    }
}

// MARK: - Daily Wins Trigger

struct DailyWinsButton: View {
    @State private var showingDailyWins = false
    @State private var wins: [DailyWinItem] = []
    @State private var totalXP: Int = 0

    let completedTasks: [TaskItem]

    var body: some View {
        Button {
            prepareWins()
            showingDailyWins = true
        } label: {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.Celebration.starGold)

                Text("View Daily Wins")

                Spacer()

                Text("\(completedTasks.count) tasks")
                    .foregroundStyle(.secondary)
            }
        }
        .fullScreenCover(isPresented: $showingDailyWins) {
            DailyWinsView(
                wins: wins,
                totalXP: totalXP,
                onDismiss: {
                    showingDailyWins = false
                },
                onShare: {
                    ShareCardGenerator.share(
                        cardType: .dailySummary(
                            tasks: wins.count,
                            xp: totalXP,
                            date: Date()
                        )
                    )
                }
            )
        }
    }

    private func prepareWins() {
        wins = completedTasks
            .filter { $0.isCompleted && Calendar.current.isDateInToday($0.completedAt ?? Date()) }
            .sorted { ($0.completedAt ?? Date()) < ($1.completedAt ?? Date()) }
            .map { DailyWinItem(from: $0) }

        totalXP = wins.reduce(0) { $0 + $1.xpEarned }
    }
}

// MARK: - Quick Celebration Modifier

/// Modifier for simple celebration triggers on any view
struct CelebrateTapModifier: ViewModifier {
    let level: CelebrationLevel
    let xp: Int
    let message: String?

    @State private var tapLocation: CGPoint = .zero

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        tapLocation = value.location
                    }
            )
            .onTapGesture {
                CelebrationEngine.shared.celebrate(
                    level: level,
                    xp: xp,
                    at: tapLocation,
                    message: message
                )
            }
    }
}

extension View {
    /// Adds a celebration trigger when the view is tapped
    func celebrateOnTap(
        level: CelebrationLevel = .quick,
        xp: Int = 10,
        message: String? = nil
    ) -> some View {
        modifier(CelebrateTapModifier(level: level, xp: xp, message: message))
    }
}

// MARK: - Environment Values

private struct CelebrationEngineKey: EnvironmentKey {
    static let defaultValue = CelebrationEngine.shared
}

extension EnvironmentValues {
    var celebrationEngine: CelebrationEngine {
        get { self[CelebrationEngineKey.self] }
        set { self[CelebrationEngineKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview("Celebration Settings") {
    NavigationStack {
        CelebrationSettingsView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Header Badge") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            HStack {
                Text("Tasks")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Spacer()

                HeaderMomentumBadge()
            }
            .padding()

            Spacer()
        }
    }
}
