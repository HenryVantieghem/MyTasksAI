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
    @State private var showContent = false
    @State private var notificationCardVisible = false
    @State private var calendarCardVisible = false
    @State private var privacyVisible = false
    @State private var iconPulse: CGFloat = 1.0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Aurora.Layout.spacingXL) {
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

                Spacer(minLength: 100)
            }
            .padding(Aurora.Layout.screenPadding)
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Enhanced Header Section

    private var enhancedHeaderSection: some View {
        VStack(spacing: Aurora.Layout.spacing) {
            // Animated icon
            ZStack {
                // Glow
                Circle()
                    .fill(Aurora.Colors.electric.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .blur(radius: 20)
                    .scaleEffect(iconPulse)

                Circle()
                    .fill(Aurora.Colors.cosmicElevated)
                    .frame(width: 80, height: 80)

                Image(systemName: "bell.badge")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Aurora.Colors.electric, Aurora.Colors.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Stay on Track")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Aurora.Colors.textPrimary)

            Text("Enable permissions to get the\nmost out of MyTasksAI")
                .font(.system(size: 16))
                .foregroundStyle(Aurora.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Enhanced Privacy Note

    private var enhancedPrivacyNote: some View {
        HStack(spacing: Aurora.Layout.spacing) {
            ZStack {
                Circle()
                    .fill(Aurora.Colors.success.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Aurora.Colors.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Privacy Matters")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Text("Your data stays on your device. We never sell your information.")
                    .font(.system(size: 13))
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }
        }
        .padding(Aurora.Layout.spacingLarge)
        .background(
            RoundedRectangle(cornerRadius: Aurora.Radius.large)
                .fill(Aurora.Colors.success.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Aurora.Radius.large)
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

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: Aurora.Layout.spacingLarge) {
            HStack(spacing: Aurora.Layout.spacing) {
                // Icon with glow
                ZStack {
                    if isEnabled {
                        Circle()
                            .fill(iconColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .blur(radius: 10)
                    }

                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Aurora.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            // Status and button
            HStack {
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(isEnabled ? Aurora.Colors.success : Aurora.Colors.glassBorder)
                        .frame(width: 10, height: 10)

                    Text(status)
                        .font(.system(size: 14, weight: .medium))
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
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
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
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                        Text("Done")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(Aurora.Colors.success)
                }
            }
        }
        .padding(Aurora.Layout.spacingXL)
        .background(
            RoundedRectangle(cornerRadius: Aurora.Radius.xl)
                .fill(Aurora.Colors.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Aurora.Radius.xl)
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
