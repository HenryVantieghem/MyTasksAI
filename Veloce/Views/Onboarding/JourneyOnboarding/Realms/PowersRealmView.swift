//
//  PowersRealmView.swift
//  MyTasksAI
//
//  Step 4: "Enable Your Powers"
//  Permission requests for notifications and calendar
//

import SwiftUI

struct PowersRealmView: View {
    @Bindable var viewModel: JourneyOnboardingViewModel
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var orbState: EtherealOrbState = .idle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.03)

                    // Ethereal Orb
                    EtherealOrb(
                        size: .large,
                        state: orbState,
                        isAnimating: true,
                        intensity: viewModel.orbIntensity,
                        showGlow: true
                    )
                    .scaleEffect(showContent ? 1 : 0.85)
                    .opacity(showContent ? 1 : 0)

                    Spacer()
                        .frame(height: 24)

                    // Header
                    VStack(spacing: 10) {
                        Text("Enable Your Powers")
                            .font(.system(size: 26, weight: .thin))
                            .tracking(2)
                            .foregroundStyle(.white)

                        Text("Unlock your full potential")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)

                    Spacer()
                        .frame(height: 32)

                    // Permission Cards
                    VStack(spacing: 16) {
                        // Notifications
                        PermissionCard(
                            icon: "bell.badge.fill",
                            title: "Notifications",
                            benefits: [
                                "Timely task reminders",
                                "Goal progress updates",
                                "Streak protection alerts"
                            ],
                            isGranted: viewModel.notificationsGranted,
                            isRequested: viewModel.notificationsRequested,
                            onAllow: {
                                Task {
                                    await viewModel.requestNotifications()
                                }
                            },
                            onSkip: {
                                viewModel.skipNotifications()
                            }
                        )

                        // Calendar
                        PermissionCard(
                            icon: "calendar.badge.clock",
                            title: "Calendar",
                            benefits: [
                                "Smart scheduling suggestions",
                                "View tasks alongside events",
                                "AI-powered time optimization"
                            ],
                            isGranted: viewModel.calendarGranted,
                            isRequested: viewModel.calendarRequested,
                            onAllow: {
                                Task {
                                    await viewModel.requestCalendar()
                                }
                            },
                            onSkip: {
                                viewModel.skipCalendar()
                            }
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Spacer()
                        .frame(height: 32)

                    // Note about settings
                    Text("You can change these anytime in Settings")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                        .opacity(showContent ? 1 : 0)

                    Spacer()
                        .frame(height: 24)

                    // CTA Button
                    Button {
                        HapticsService.shared.impact()
                        onContinue()
                    } label: {
                        HStack(spacing: 10) {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.55, green: 0.85, blue: 0.95),
                                            Color(red: 0.75, green: 0.55, blue: 0.90)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(
                            color: Color(red: 0.55, green: 0.85, blue: 0.95).opacity(0.35),
                            radius: 18,
                            y: 8
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)

                    Spacer()
                        .frame(height: 50)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        guard !reduceMotion else {
            showContent = true
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            orbState = .active
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            orbState = .idle
        }
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let icon: String
    let title: String
    let benefits: [String]
    let isGranted: Bool
    let isRequested: Bool
    let onAllow: () -> Void
    let onSkip: () -> Void

    private let accentCyan = Color(red: 0.55, green: 0.85, blue: 0.95)
    private let accentPurple = Color(red: 0.75, green: 0.55, blue: 0.90)
    private let successGreen = Color(red: 0.40, green: 0.85, blue: 0.65)

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isGranted ? successGreen.opacity(0.15) : accentCyan.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: isGranted ? "checkmark" : icon)
                        .font(.system(size: isGranted ? 18 : 20, weight: .medium))
                        .foregroundStyle(isGranted ? successGreen : accentCyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    if isGranted {
                        Text("Enabled")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(successGreen)
                    } else if isRequested {
                        Text("Skipped")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Spacer()
            }

            // Benefits (only show if not requested yet)
            if !isRequested {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(benefits, id: \.self) { benefit in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(accentCyan.opacity(0.6))

                            Text(benefit)
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                }
                .padding(.leading, 4)

                // Buttons
                HStack(spacing: 12) {
                    // Skip
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial.opacity(0.4))
                            )
                    }

                    // Allow
                    Button(action: onAllow) {
                        Text("Allow")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [accentCyan, accentPurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.55)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isGranted ?
                        AnyShapeStyle(successGreen.opacity(0.4)) :
                        AnyShapeStyle(LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.06), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )),
                    lineWidth: 0.75
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isGranted)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isRequested)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        PowersRealmView(viewModel: JourneyOnboardingViewModel()) {
            print("Continue tapped")
        }
    }
}
