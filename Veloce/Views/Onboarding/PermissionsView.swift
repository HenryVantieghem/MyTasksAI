//
//  PermissionsView.swift
//  MyTasksAI
//
//  Permissions Onboarding Step
//  Request notification and calendar permissions
//

import SwiftUI
import EventKit
import UserNotifications

// MARK: - Permissions View
struct PermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                headerSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Notifications permission
                permissionCard(
                    icon: "bell.badge.fill",
                    iconColor: Theme.Colors.accent,
                    title: "Notifications",
                    subtitle: "Get reminders for your scheduled tasks and celebrate achievements",
                    isEnabled: viewModel.notificationsGranted,
                    status: notificationStatusText,
                    onRequest: {
                        Task {
                            await viewModel.requestNotifications()
                        }
                    }
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                // Calendar permission
                permissionCard(
                    icon: "calendar.badge.clock",
                    iconColor: Theme.Colors.success,
                    title: "Calendar",
                    subtitle: "Sync tasks with your calendar for seamless scheduling",
                    isEnabled: viewModel.calendarGranted,
                    status: calendarStatusText,
                    onRequest: {
                        Task {
                            await viewModel.requestCalendar()
                        }
                    }
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 40)

                // Privacy note
                privacyNote
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 50)

                Spacer(minLength: 100)
            }
            .padding(Theme.Spacing.lg)
        }
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "bell.badge")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(Theme.Colors.accent)

            Text("Stay on Track")
                .font(Theme.Typography.title1)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Enable permissions to get the most out of MyTasksAI")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Permission Card
    private func permissionCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isEnabled: Bool,
        status: String,
        onRequest: @escaping () -> Void
    ) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(subtitle)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            // Status and button
            HStack {
                // Status indicator
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(isEnabled ? Theme.Colors.success : Theme.Colors.textTertiary)
                        .frame(width: 8, height: 8)

                    Text(status)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(isEnabled ? Theme.Colors.success : Theme.Colors.textSecondary)
                }

                Spacer()

                // Action button
                if !isEnabled {
                    Button {
                        onRequest()
                    } label: {
                        Text("Enable")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(iconColor)
                            .clipShape(Capsule())
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Colors.success)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .glassCardStyle()
    }

    // MARK: - Privacy Note
    private var privacyNote: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.shield")
                .font(.system(size: Theme.Size.iconMedium))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("Your data stays on your device. We never sell your information.")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.md)
    }

    // MARK: - Status Text
    private var notificationStatusText: String {
        viewModel.notificationsGranted ? "Enabled" : "Not configured"
    }

    private var calendarStatusText: String {
        viewModel.calendarGranted ? "Enabled" : "Not configured"
    }
}

// MARK: - Preview
#Preview {
    PermissionsView(viewModel: OnboardingViewModel())
        .iridescentBackground()
}
