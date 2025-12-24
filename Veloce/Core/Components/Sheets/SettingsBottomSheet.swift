//
//  SettingsBottomSheet.swift
//  Veloce
//
//  Settings Bottom Sheet
//  Profile, preferences, and account actions
//

import SwiftUI

// MARK: - Settings Bottom Sheet

struct SettingsBottomSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showContent = false
    @State private var showDeleteAccountAlert = false
    @State private var showSignOutAlert = false
    @State private var isDeleting = false

    private let gamification = GamificationService.shared

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    // Profile section
                    profileSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Quick preferences
                    preferencesSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Goals section
                    goalsSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Account actions
                    accountSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // App info
                    appInfoSection
                        .opacity(showContent ? 1 : 0)
                }
                .padding(Theme.Spacing.screenPadding)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.1)) {
                showContent = true
            }
        }
        .alert("Sign Out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await appViewModel.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await viewModel.deleteAccount()
                    } catch {
                        viewModel.error = error.localizedDescription
                    }
                    isDeleting = false
                }
            }
        } message: {
            Text("This will permanently delete your account and all your data. This action cannot be undone.")
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.accentGradient)
                    .frame(width: 80, height: 80)

                Text(viewModel.fullName.isEmpty ? "?" : String(viewModel.fullName.prefix(1)).uppercased())
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(.white)

                // Level badge
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.iridescentGradientLinear)
                        .frame(width: 28, height: 28)

                    Text("\(gamification.currentLevel)")
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                }
                .offset(x: 28, y: 28)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text(viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(viewModel.email)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Preferences")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)

            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "bell.fill",
                    iconColor: Theme.Colors.accent,
                    title: "Notifications",
                    isOn: $viewModel.notificationsEnabled
                )

                Divider().padding(.leading, 52)

                SettingsToggleRow(
                    icon: "hand.tap.fill",
                    iconColor: Theme.Colors.aiPurple,
                    title: "Haptic Feedback",
                    isOn: $viewModel.hapticsEnabled
                )

                Divider().padding(.leading, 52)

                // Theme picker
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.aiBlue.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.Colors.aiBlue)
                    }

                    Text("Theme")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Picker("", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.accent)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .glassCard()
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Daily Goals")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)

            VStack(spacing: 0) {
                SettingsStepperRow(
                    icon: "target",
                    iconColor: Theme.Colors.success,
                    title: "Daily Tasks",
                    value: $viewModel.dailyTaskGoal,
                    range: 1...20
                )

                Divider().padding(.leading, 52)

                SettingsStepperRow(
                    icon: "calendar",
                    iconColor: Theme.Colors.aiCyan,
                    title: "Weekly Tasks",
                    value: $viewModel.weeklyTaskGoal,
                    range: 5...100,
                    step: 5
                )
            }
            .glassCard()
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Account")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)

            VStack(spacing: 0) {
                // Subscription
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.xp.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.Colors.xp)
                    }

                    Text("Subscription")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Text(viewModel.isProUser ? "Pro" : "Free")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)

                Divider().padding(.leading, 52)

                // Sign out
                Button {
                    showSignOutAlert = true
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            SwiftUI.Circle()
                                .fill(Theme.Colors.warning.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.Colors.warning)
                        }

                        Text("Sign Out")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                }

                Divider().padding(.leading, 52)

                // Delete account
                Button {
                    showDeleteAccountAlert = true
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            SwiftUI.Circle()
                                .fill(Theme.Colors.error.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.Colors.error)
                        }

                        Text("Delete Account")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.error)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                }
                .disabled(isDeleting)
            }
            .glassCard()
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("MyTasksAI v1.0.0")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textTertiary)

            HStack(spacing: Theme.Spacing.md) {
                Button("Privacy Policy") { }
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.accent)

                Text("•")
                    .foregroundStyle(Theme.Colors.textTertiary)

                Button("Terms of Service") { }
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
        .padding(.top, Theme.Spacing.md)
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Settings Stepper Row

struct SettingsStepperRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    if value > range.lowerBound {
                        value -= step
                        HapticsService.shared.selectionFeedback()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(value > range.lowerBound ? Theme.Colors.accent : Theme.Colors.textTertiary)
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(minWidth: 40)

                Button {
                    if value < range.upperBound {
                        value += step
                        HapticsService.shared.selectionFeedback()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(value < range.upperBound ? Theme.Colors.accent : Theme.Colors.textTertiary)
                }
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    SettingsBottomSheet(viewModel: SettingsViewModel())
        .environment(AppViewModel())
}
