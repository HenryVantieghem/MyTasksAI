//
//  PermissionsView.swift
//  MyTasksAI
//
//  Permissions Onboarding Step - Aurora Design System
//  Celestial cosmic design with power-up style cards
//

import SwiftUI
import EventKit
import UserNotifications

// MARK: - Permissions View

struct PermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.responsiveLayout) private var layout

    @State private var showContent = false
    @State private var notificationCardVisible = false
    @State private var calendarCardVisible = false
    @State private var privacyVisible = false
    @State private var iconPulse: CGFloat = 1.0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: layout.spacing * 1.5) {
                // Enhanced header
                enhancedHeaderSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Notifications permission
                EnhancedPermissionCard(
                    icon: "bell.badge.fill",
                    iconColor: Aurora.Colors.electric,
                    title: "Notifications",
                    subtitle: "Get reminders for scheduled tasks and celebrate achievements",
                    isEnabled: viewModel.notificationsGranted,
                    status: notificationStatusText,
                    onRequest: {
                        HapticsService.shared.impact()
                        Task {
                            await viewModel.requestNotifications()
                            if viewModel.notificationsGranted {
                                HapticsService.shared.taskComplete()
                            }
                        }
                    }
                )
                .opacity(notificationCardVisible ? 1 : 0)
                .offset(y: notificationCardVisible ? 0 : 30)

                // Calendar permission
                EnhancedPermissionCard(
                    icon: "calendar.badge.clock",
                    iconColor: Aurora.Colors.cyan,
                    title: "Calendar",
                    subtitle: "Sync tasks with your calendar for seamless scheduling",
                    isEnabled: viewModel.calendarGranted,
                    status: calendarStatusText,
                    onRequest: {
                        HapticsService.shared.impact()
                        Task {
                            await viewModel.requestCalendar()
                            if viewModel.calendarGranted {
                                HapticsService.shared.taskComplete()
                            }
                        }
                    }
                )
                .opacity(calendarCardVisible ? 1 : 0)
                .offset(y: calendarCardVisible ? 0 : 30)

                // Enhanced privacy note
                enhancedPrivacyNote
                    .opacity(privacyVisible ? 1 : 0)
                    .offset(y: privacyVisible ? 0 : 20)

                Spacer(minLength: layout.bottomSafeArea)
            }
            .padding(layout.screenPadding)
            .maxWidthConstrained()
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Enhanced Header Section

    // Responsive icon sizes
    private var headerIconSize: CGFloat {
        layout.deviceType.isTablet ? 100 : 80
    }

    private var headerGlowSize: CGFloat {
        layout.deviceType.isTablet ? 110 : 90
    }

    private var enhancedHeaderSection: some View {
        VStack(spacing: layout.spacing) {
            // Animated icon
            ZStack {
                // Glow
                SwiftUI.Circle()
                    .fill(Aurora.Colors.electric.opacity(0.2))
                    .frame(width: headerGlowSize, height: headerGlowSize)
                    .blur(radius: 20)
                    .scaleEffect(iconPulse)

                SwiftUI.Circle()
                    .fill(Aurora.Colors.cosmicElevated)
                    .frame(width: headerIconSize, height: headerIconSize)

                Image(systemName: "bell.badge")
                    .dynamicTypeFont(base: 40, weight: .light)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Aurora.Colors.electric, Aurora.Colors.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Stay on Track")
                .dynamicTypeFont(base: 28, weight: .bold)
                .foregroundStyle(Aurora.Colors.textPrimary)

            Text("Enable permissions to get the\nmost out of MyTasksAI")
                .dynamicTypeFont(base: 16, weight: .regular)
                .foregroundStyle(Aurora.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Enhanced Privacy Note

    private var enhancedPrivacyNote: some View {
        HStack(spacing: layout.spacing) {
            ZStack {
                SwiftUI.Circle()
                    .fill(Aurora.Colors.success.opacity(0.1))
                    .frame(width: layout.minTouchTarget, height: layout.minTouchTarget)

                Image(systemName: "lock.shield.fill")
                    .dynamicTypeFont(base: 18, weight: .medium)
                    .foregroundStyle(Aurora.Colors.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Privacy Matters")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Text("Your data stays on your device. We never sell your information.")
                    .dynamicTypeFont(base: 13, weight: .regular)
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }
        }
        .padding(layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Aurora.Colors.success.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Aurora.Colors.success.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Status Text

    private var notificationStatusText: String {
        viewModel.notificationsGranted ? "Enabled" : "Not configured"
    }

    private var calendarStatusText: String {
        viewModel.calendarGranted ? "Enabled" : "Not configured"
    }

    private func startAnimations() {
        // Header fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            showContent = true
        }

        // Icon pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            iconPulse = 1.1
        }

        // Staggered cards
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(Aurora.Animation.spring) {
                notificationCardVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Aurora.Animation.spring) {
                calendarCardVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(Aurora.Animation.spring) {
                privacyVisible = true
            }
        }
    }
}

// MARK: - Enhanced Permission Card

struct EnhancedPermissionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let status: String
    let onRequest: () -> Void

    @Environment(\.responsiveLayout) private var layout
    @State private var isPressed = false

    // Responsive icon sizes
    private var iconSize: CGFloat {
        layout.deviceType.isTablet ? 60 : 50
    }

    private var glowSize: CGFloat {
        layout.deviceType.isTablet ? 72 : 60
    }

    var body: some View {
        VStack(spacing: layout.cardPadding) {
            HStack(spacing: layout.spacing) {
                // Icon with glow
                ZStack {
                    if isEnabled {
                        SwiftUI.Circle()
                            .fill(iconColor.opacity(0.2))
                            .frame(width: glowSize, height: glowSize)
                            .blur(radius: 10)
                    }

                    SwiftUI.Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: iconSize, height: iconSize)

                    Image(systemName: icon)
                        .dynamicTypeFont(base: 22, weight: .medium)
                        .foregroundStyle(iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .dynamicTypeFont(base: 18, weight: .semibold)
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    Text(subtitle)
                        .dynamicTypeFont(base: 14, weight: .regular)
                        .foregroundStyle(Aurora.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            // Status and button
            HStack {
                // Status indicator
                HStack(spacing: 8) {
                    SwiftUI.Circle()
                        .fill(isEnabled ? Aurora.Colors.success : Aurora.Colors.glassBorder)
                        .frame(width: 10, height: 10)

                    Text(status)
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(isEnabled ? Aurora.Colors.success : Aurora.Colors.textSecondary)
                }

                Spacer()

                // Action button
                if !isEnabled {
                    Button {
                        onRequest()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Enable")
                                .dynamicTypeFont(base: 15, weight: .semibold)
                            Image(systemName: "arrow.right")
                                .dynamicTypeFont(base: 12, weight: .bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, layout.cardPadding)
                        .padding(.vertical, layout.spacing)
                        .background(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: iconColor.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .iPadHoverEffect(.lift)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .dynamicTypeFont(base: 22, weight: .medium)
                        Text("Done")
                            .dynamicTypeFont(base: 15, weight: .medium)
                    }
                    .foregroundStyle(Aurora.Colors.success)
                }
            }
        }
        .padding(layout.cardPadding * 1.25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Aurora.Colors.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isEnabled ? iconColor.opacity(0.4) : Aurora.Colors.glassBorder,
                            lineWidth: isEnabled ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isEnabled ? iconColor.opacity(0.2) : Color.clear,
            radius: 15,
            y: 8
        )
        .animation(Aurora.Animation.spring, value: isEnabled)
    }
}

// MARK: - Preview

#Preview {
    PermissionsView(viewModel: OnboardingViewModel())
        .background(AuroraBackground.onboardingStep)
}
