//
//  ProfileSheetView.swift
//  Veloce
//
//  Profile Sheet - Premium Liquid Glass Design
//  User avatar, stats summary, and quick links to settings
//  with iOS 26 glassEffect and stunning visual hierarchy
//

import SwiftUI

// MARK: - Profile Sheet View

struct ProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var settingsViewModel: SettingsViewModel

    // Navigation
    @State private var showFullSettings = false
    @State private var navigateToSection: SettingsSection?

    // Animation
    @State private var showContent = false
    @State private var cardScale: CGFloat = 0.9
    @State private var statsRevealed = false

    // Services
    private let gamification = GamificationService.shared
    @StateObject private var profileImageService = ProfileImageService.shared
    @State private var avatarImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Hero Profile Card
                    profileHeroCard
                        .scaleEffect(cardScale)
                        .opacity(showContent ? 1 : 0)

                    // Stats Summary
                    statsGrid
                        .opacity(statsRevealed ? 1 : 0)
                        .offset(y: statsRevealed ? 0 : 20)

                    // Quick Links
                    quickLinksSection
                        .opacity(statsRevealed ? 1 : 0)
                        .offset(y: statsRevealed ? 0 : 30)

                    // Sign Out
                    signOutButton
                        .opacity(statsRevealed ? 1 : 0)
                        .offset(y: statsRevealed ? 0 : 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
            .background {
                ProfileSheetBackground()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsService.shared.selectionFeedback()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.6))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .navigationDestination(isPresented: $showFullSettings) {
                SettingsView(viewModel: settingsViewModel, initialSection: navigateToSection)
            }
        }
        .onAppear {
            startRevealAnimation()
            loadAvatar()
        }
    }

    // MARK: - Hero Profile Card

    private var profileHeroCard: some View {
        VStack(spacing: 20) {
            // Avatar with level ring
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(0.4),
                                Theme.Colors.aiPurple.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                // Level progress ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)

                // Avatar circle
                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    // Initial letter avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.aiPurple.opacity(0.3),
                                    Theme.Colors.aiBlue.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay {
                            Text(userInitial)
                                .font(.system(size: 40, weight: .light, design: .rounded))
                                .foregroundStyle(.white)
                        }
                }

                // Level badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Lv.\(gamification.currentLevel)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                Capsule()
                                    .fill(Theme.Colors.aiPurple)
                            }
                    }
                }
                .frame(width: 100, height: 100)
            }

            // Name and email
            VStack(spacing: 6) {
                Text(userName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)

                Text(settingsViewModel.email.isEmpty ? "Welcome to Veloce" : settingsViewModel.email)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(gamification.totalTasksCompleted)",
                label: "Tasks Done",
                icon: "checkmark.circle.fill",
                color: Theme.Colors.success
            )

            statCard(
                value: "\(gamification.currentStreak)",
                label: "Day Streak",
                icon: "flame.fill",
                color: .orange
            )

            statCard(
                value: "\(gamification.totalPoints)",
                label: "Power",
                icon: "bolt.fill",
                color: .yellow
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Quick Links Section

    private var quickLinksSection: some View {
        VStack(spacing: 2) {
            // Section header
            HStack {
                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            // Links
            VStack(spacing: 0) {
                quickLinkRow(
                    icon: "person.fill",
                    title: "Profile",
                    subtitle: "Name, avatar, account",
                    color: Theme.Colors.aiPurple,
                    section: .profile
                )

                Divider().background(.white.opacity(0.1))

                quickLinkRow(
                    icon: "paintbrush.fill",
                    title: "Appearance",
                    subtitle: "Theme, app icon",
                    color: Theme.Colors.aiCyan,
                    section: .appearance
                )

                Divider().background(.white.opacity(0.1))

                quickLinkRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Reminders, streaks",
                    color: .orange,
                    section: .notifications
                )

                Divider().background(.white.opacity(0.1))

                quickLinkRow(
                    icon: "timer",
                    title: "Focus Settings",
                    subtitle: "Timer, break duration",
                    color: Theme.Colors.success,
                    section: .focus
                )

                Divider().background(.white.opacity(0.1))

                quickLinkRow(
                    icon: "square.and.arrow.up",
                    title: "Data",
                    subtitle: "Export, clear completed",
                    color: Theme.Colors.aiBlue,
                    section: .data
                )

                Divider().background(.white.opacity(0.1))

                quickLinkRow(
                    icon: "info.circle.fill",
                    title: "About",
                    subtitle: "Version, privacy policy",
                    color: .gray,
                    section: .about,
                    showDivider: false
                )
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func quickLinkRow(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        section: SettingsSection,
        showDivider: Bool = true
    ) -> some View {
        Button {
            HapticsService.shared.selectionFeedback()
            navigateToSection = section
            showFullSettings = true
        } label: {
            HStack(spacing: 14) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuickLinkButtonStyle())
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button {
            HapticsService.shared.impact(.medium)
            Task {
                await appViewModel.signOut()
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .medium))
                Text("Sign Out")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(.red.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(QuickLinkButtonStyle())
    }

    // MARK: - Helpers

    private var userName: String {
        if !settingsViewModel.fullName.isEmpty {
            return settingsViewModel.fullName
        } else if let name = appViewModel.currentUser?.fullName, !name.isEmpty {
            return name
        }
        return "Welcome"
    }

    private var userInitial: String {
        if let first = userName.first, first != "W" {
            return String(first).uppercased()
        }
        return "V"
    }

    private func startRevealAnimation() {
        // Card entrance
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showContent = true
            cardScale = 1.0
        }

        // Stats reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                statsRevealed = true
            }
        }
    }

    private func loadAvatar() {
        Task {
            if let userId = appViewModel.currentUser?.id.uuidString {
                avatarImage = await profileImageService.fetchAvatar(for: userId)
            }
        }
    }
}

// MARK: - Quick Link Button Style

private struct QuickLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Profile Sheet Background

private struct ProfileSheetBackground: View {
    var body: some View {
        ZStack {
            // Deep void base
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            // Ambient glow
            RadialGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.15),
                    Theme.Colors.aiBlue.opacity(0.08),
                    .clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Subtle noise texture
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.02)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Settings Section Enum

enum SettingsSection: String, CaseIterable, Identifiable {
    case profile
    case appearance
    case notifications
    case focus
    case data
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile: return "Profile"
        case .appearance: return "Appearance"
        case .notifications: return "Notifications"
        case .focus: return "Focus Settings"
        case .data: return "Data"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .profile: return "person.fill"
        case .appearance: return "paintbrush.fill"
        case .notifications: return "bell.fill"
        case .focus: return "timer"
        case .data: return "square.and.arrow.up"
        case .about: return "info.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileSheetView(settingsViewModel: SettingsViewModel())
        .environment(AppViewModel())
}
