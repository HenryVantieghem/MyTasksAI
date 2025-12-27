//
//  ImmersiveFocusOverlay.swift
//  Veloce
//
//  Immersive Full-Screen Focus Timer Overlay
//  Replaces tab navigation with in-context focus experience
//

import SwiftUI

// MARK: - Immersive Focus Overlay

/// Full-screen focus timer overlay that appears from TaskDetailSheet
/// Features: large timer, progress ring, ambient visuals, pause/end controls
struct ImmersiveFocusOverlay: View {
    let task: TaskItem
    let initialDuration: TimeInterval // in seconds
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @State private var timeRemaining: TimeInterval
    @State private var isRunning = true
    @State private var isPaused = false
    @State private var showEndConfirmation = false
    @State private var ambientPhase: CGFloat = 0
    @State private var ringProgress: CGFloat = 0
    @State private var breathingScale: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(task: TaskItem, duration: Int = 25, onComplete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.task = task
        self.initialDuration = TimeInterval(duration * 60)
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        self._timeRemaining = State(initialValue: TimeInterval(duration * 60))
    }

    private var progress: CGFloat {
        1 - (timeRemaining / initialDuration)
    }

    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // MARK: - Ambient Background
            ambientBackground

            // MARK: - Main Content
            VStack(spacing: 0) {
                // Top spacer
                Spacer()
                    .frame(height: 60)

                // Task title
                Text(task.title)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 40)

                Spacer()

                // Timer section
                timerSection

                Spacer()

                // Controls
                controlsSection
                    .padding(.bottom, 60)
            }
            .padding()
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            guard isRunning && !isPaused else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
                ringProgress = progress
            } else {
                // Timer completed
                HapticsService.shared.success()
                onComplete()
            }
        }
        .onAppear {
            startAmbientAnimations()
            HapticsService.shared.softImpact()
        }
        .confirmationDialog("End Focus Session?", isPresented: $showEndConfirmation) {
            Button("End Session", role: .destructive) {
                onDismiss()
            }
            Button("Continue Focusing", role: .cancel) { }
        } message: {
            Text("You still have \(Int(timeRemaining / 60)) minutes remaining.")
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.06),
                    Color(red: 0.04, green: 0.02, blue: 0.08),
                    Color(red: 0.02, green: 0.02, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ambient glow circles
            if !reduceMotion {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.AdaptiveColors.aiPrimary.opacity(0.15),
                                Theme.AdaptiveColors.aiPrimary.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 300
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: -200)
                    .scaleEffect(breathingScale)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.AdaptiveColors.aiSecondary.opacity(0.1),
                                Theme.AdaptiveColors.aiSecondary.opacity(0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 250
                        )
                    )
                    .frame(width: 350, height: 350)
                    .offset(x: 120, y: 300)
                    .scaleEffect(1.1 - (breathingScale - 1.0))
            }
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
                .frame(width: 240, height: 240)

            // Progress ring
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.AdaptiveColors.aiPrimary,
                            Theme.AdaptiveColors.aiSecondary,
                            Theme.AdaptiveColors.aiTertiary,
                            Theme.AdaptiveColors.aiPrimary
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: ringProgress)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.AdaptiveColors.aiPrimary.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: 220, height: 220)

            // Time display
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                if isPaused {
                    Text("PAUSED")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.AdaptiveColors.warning)
                        .tracking(2)
                } else {
                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 40) {
            // End button
            Button {
                HapticsService.shared.warning()
                showEndConfirmation = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())

                    Text("End")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            // Pause/Resume button (larger, primary)
            Button {
                HapticsService.shared.impact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPaused.toggle()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 28, weight: .medium))
                        .frame(width: 80, height: 80)
                        .background(
                            isPaused
                                ? Theme.AdaptiveColors.aiGradient
                                : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }

                    Text(isPaused ? "Resume" : "Pause")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            // Add 5 min button
            Button {
                HapticsService.shared.selectionFeedback()
                withAnimation {
                    timeRemaining += 5 * 60
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())

                    Text("+5 min")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
    }

    // MARK: - Animations

    private func startAmbientAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathingScale = 1.15
        }
    }
}

// MARK: - Preview

#Preview("Immersive Focus Overlay") {
    ImmersiveFocusOverlay(
        task: TaskItem(title: "Write quarterly report for Q4 2024"),
        duration: 25,
        onComplete: { },
        onDismiss: { }
    )
}

#Preview("Immersive Focus - Paused") {
    ImmersiveFocusOverlay(
        task: TaskItem(title: "Review design mockups"),
        duration: 15,
        onComplete: { },
        onDismiss: { }
    )
}
