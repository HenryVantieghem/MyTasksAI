//
//  SettingsBottomSheet.swift
//  Veloce
//
//  Settings Bottom Sheet - Living Cosmos Design
//  Profile with editable avatar, preferences, and account actions
//  with celestial glass styling and staggered reveal animations
//

import SwiftUI

// MARK: - Settings Bottom Sheet

struct SettingsBottomSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel

    @State private var showContent = false
    @State private var sectionVisibility: [Bool] = [false, false, false, false, false]
    @State private var showDeleteAccountAlert = false
    @State private var showSignOutAlert = false
    @State private var showProfileEditor = false
    @State private var isDeleting = false
    @State private var avatarImage: UIImage?

    private let gamification = GamificationService.shared
    @StateObject private var profileImageService = ProfileImageService.shared

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xl) {
                    // Profile section
                    profileSection
                        .staggeredReveal(index: 0, isVisible: sectionVisibility[0])

                    // Quick preferences
                    preferencesSection
                        .staggeredReveal(index: 1, isVisible: sectionVisibility[1])

                    // Goals section
                    goalsSection
                        .staggeredReveal(index: 2, isVisible: sectionVisibility[2])

                    // Account actions
                    accountSection
                        .staggeredReveal(index: 3, isVisible: sectionVisibility[3])

                    // App info
                    appInfoSection
                        .staggeredReveal(index: 4, isVisible: sectionVisibility[4])
                }
                .padding(Theme.Spacing.screenPadding)
                .padding(.bottom, Theme.Spacing.xxxl)
            }
            .background {
                VoidSheetBackground()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(Theme.Typography.cosmosTitle)
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    CosmicIconButton("xmark.circle.fill", color: Theme.CelestialColors.starDim, size: 36) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            startStaggeredReveal()
            loadAvatar()
        }
        .sheet(isPresented: $showProfileEditor) {
            ProfileEditSheet(
                viewModel: viewModel,
                avatarImage: $avatarImage,
                onSave: { image in
                    Task {
                        await uploadAvatar(image)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .voidPresentationBackground()
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

    // MARK: - Animation

    private func startStaggeredReveal() {
        for index in 0..<sectionVisibility.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + Double(index) * LivingCosmos.Animations.staggerDelay) {
                withAnimation(LivingCosmos.Animations.stellarBounce) {
                    sectionVisibility[index] = true
                }
            }
        }
    }

    // MARK: - Avatar

    private func loadAvatar() {
        Task {
            if let userId = appViewModel.currentUser?.id.uuidString {
                avatarImage = await profileImageService.fetchAvatar(for: userId)
            }
        }
    }

    private func uploadAvatar(_ image: UIImage) async {
        guard let userId = appViewModel.currentUser?.id.uuidString else { return }
        do {
            _ = try await profileImageService.uploadAvatar(image, for: userId)
            avatarImage = image
            HapticsService.shared.taskComplete()
        } catch {
            viewModel.error = error.localizedDescription
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Avatar with edit
            ProfileAvatarView(
                image: avatarImage,
                name: viewModel.fullName.isEmpty ? "User" : viewModel.fullName,
                size: .large,
                level: gamification.currentLevel,
                showEditButton: true
            ) {
                showProfileEditor = true
            }

            // Name and email
            VStack(spacing: Theme.Spacing.xs) {
                Text(viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if !viewModel.username.isEmpty {
                    Text("@\(viewModel.username)")
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.Colors.aiPurple)
                }

                Text(viewModel.email)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            // Stats row
            HStack(spacing: Theme.Spacing.xl) {
                statItem(value: "\(gamification.currentLevel)", label: "Level", icon: "star.fill", color: Theme.Colors.xp)
                statItem(value: "\(gamification.totalPoints)", label: "Points", icon: "sparkles", color: Theme.Colors.aiPurple)
                statItem(value: "\(gamification.currentStreak)", label: "Streak", icon: "flame.fill", color: Theme.CelestialColors.solarFlare)
            }

            // Edit profile button
            CosmicButton("Edit Profile", style: .ghost, icon: "pencil") {
                showProfileEditor = true
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .floatingIsland(accentColor: Theme.Colors.aiPurple)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        CosmicSectionCard(header: "Preferences", headerIcon: "gearshape.fill", headerIconColor: Theme.CelestialColors.starDim) {
            VStack(spacing: 0) {
                CosmicToggleRow(
                    icon: "bell.fill",
                    iconColor: Theme.Colors.accent,
                    title: "Notifications",
                    subtitle: "Task reminders & updates",
                    isOn: $viewModel.notificationsEnabled
                )

                CosmicDivider()

                CosmicToggleRow(
                    icon: "hand.tap.fill",
                    iconColor: Theme.Colors.aiPurple,
                    title: "Haptic Feedback",
                    subtitle: "Vibration for actions",
                    isOn: $viewModel.hapticsEnabled
                )

                CosmicDivider()

                CosmicToggleRow(
                    icon: "calendar.badge.clock",
                    iconColor: Theme.Colors.aiBlue,
                    title: "Calendar Sync",
                    subtitle: "Sync with Apple Calendar",
                    isOn: $viewModel.calendarSyncEnabled
                )

                CosmicDivider()

                // Theme picker row
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.CelestialColors.plasmaCore.opacity(0.15))
                            .frame(width: LivingCosmos.Controls.iconContainerSize, height: LivingCosmos.Controls.iconContainerSize)

                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: LivingCosmos.Controls.iconSize, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.plasmaCore)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.starWhite)

                        Text("App appearance")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }

                    Spacer()

                    Picker("", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.aiPurple)
                }
                .padding(.horizontal, LivingCosmos.Controls.rowPadding)
                .frame(minHeight: LivingCosmos.Controls.rowHeight)
            }
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        CosmicSectionCard(header: "Daily Goals", headerIcon: "target", headerIconColor: Theme.Colors.success) {
            VStack(spacing: 0) {
                CosmicStepperRow(
                    icon: "sun.max.fill",
                    iconColor: Theme.Colors.success,
                    title: "Daily Tasks",
                    subtitle: "Tasks to complete each day",
                    value: $viewModel.dailyTaskGoal,
                    range: 1...20
                )

                CosmicDivider()

                CosmicStepperRow(
                    icon: "calendar",
                    iconColor: Theme.Colors.aiCyan,
                    title: "Weekly Tasks",
                    subtitle: "Weekly target",
                    value: $viewModel.weeklyTaskGoal,
                    range: 5...100,
                    step: 5
                )
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        CosmicSectionCard(header: "Account", headerIcon: "person.fill", headerIconColor: Theme.Colors.aiPurple) {
            VStack(spacing: 0) {
                // Subscription
                CosmicNavigationRow(
                    icon: "crown.fill",
                    iconColor: Theme.Colors.xp,
                    title: "Subscription",
                    subtitle: viewModel.isProUser ? "Pro Plan Active" : "Upgrade to Pro",
                    value: viewModel.isProUser ? "Pro" : "Free"
                ) {
                    // Open subscription management
                }

                CosmicDivider()

                // Sign out
                CosmicNavigationRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: Theme.CelestialColors.warningNebula,
                    title: "Sign Out"
                ) {
                    showSignOutAlert = true
                }

                CosmicDivider()

                // Delete account
                Button {
                    showDeleteAccountAlert = true
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            SwiftUI.Circle()
                                .fill(Theme.CelestialColors.errorNebula.opacity(0.15))
                                .frame(width: LivingCosmos.Controls.iconContainerSize, height: LivingCosmos.Controls.iconContainerSize)

                            Image(systemName: "trash.fill")
                                .font(.system(size: LivingCosmos.Controls.iconSize, weight: .medium))
                                .foregroundStyle(Theme.CelestialColors.errorNebula)
                        }

                        Text("Delete Account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.errorNebula)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.starGhost)
                    }
                    .padding(.horizontal, LivingCosmos.Controls.rowPadding)
                    .frame(minHeight: LivingCosmos.Controls.rowHeight)
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // App logo mini
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("Veloce")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("v1.0.0")
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            HStack(spacing: Theme.Spacing.md) {
                CosmicLinkButton("Privacy Policy", color: Theme.Colors.aiPurple) {
                    // Open privacy policy
                }

                Text("•")
                    .foregroundStyle(Theme.CelestialColors.starGhost)

                CosmicLinkButton("Terms of Service", color: Theme.Colors.aiPurple) {
                    // Open terms
                }
            }

            Text("Made with AI in San Francisco")
                .font(.system(size: 11))
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .padding(.top, Theme.Spacing.xs)
        }
        .padding(.top, Theme.Spacing.lg)
    }
}

// MARK: - Profile Edit Sheet

struct ProfileEditSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Binding var avatarImage: UIImage?
    let onSave: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var editedName: String = ""
    @State private var editedUsername: String = ""
    @State private var isSaving = false

    private let gamification = GamificationService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Avatar picker
                    ProfileAvatarPicker(
                        selectedImage: $selectedImage,
                        currentImage: avatarImage,
                        name: viewModel.fullName.isEmpty ? "User" : viewModel.fullName,
                        level: gamification.currentLevel
                    ) { image in
                        selectedImage = image
                    }
                    .padding(.top, Theme.Spacing.xl)

                    // Name field
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("FULL NAME")
                            .font(Theme.Typography.cosmosSectionHeader)
                            .foregroundStyle(Theme.CelestialColors.starDim)
                            .tracking(1.5)

                        TextField("", text: $editedName)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.CelestialColors.starWhite)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.CelestialColors.void)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.CelestialColors.starGhost, lineWidth: 1)
                                    }
                            }
                    }

                    // Username field
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("USERNAME")
                            .font(Theme.Typography.cosmosSectionHeader)
                            .foregroundStyle(Theme.CelestialColors.starDim)
                            .tracking(1.5)

                        HStack {
                            Text("@")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.Colors.aiPurple)

                            TextField("", text: $editedUsername)
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.CelestialColors.starWhite)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.CelestialColors.void)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.CelestialColors.starGhost, lineWidth: 1)
                                }
                        }
                    }

                    Spacer(minLength: Theme.Spacing.xl)

                    // Save button
                    CosmicButton("Save Changes", style: .primary, isLoading: isSaving) {
                        saveChanges()
                    }
                }
                .padding(Theme.Spacing.screenPadding)
            }
            .background {
                SimpleVoidBackground()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Edit Profile")
                        .font(Theme.Typography.cosmosTitle)
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
        }
        .onAppear {
            editedName = viewModel.fullName
            editedUsername = viewModel.username
        }
    }

    private func saveChanges() {
        isSaving = true

        Task {
            // Update name and username
            viewModel.fullName = editedName
            viewModel.username = editedUsername

            // Save avatar if changed
            if let image = selectedImage {
                onSave(image)
            }

            // Save to backend
            do {
                try await viewModel.saveProfile()
                HapticsService.shared.taskComplete()
                dismiss()
            } catch {
                viewModel.error = error.localizedDescription
            }

            isSaving = false
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsBottomSheet(viewModel: SettingsViewModel())
        .environment(AppViewModel())
}
