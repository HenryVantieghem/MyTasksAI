//
//  ProfileSheetView.swift
//  Veloce
//
//  Aurora Design System - Identity Nexus
//  Achievement rings orbit avatar, level up burst with confetti
//  Stats morph with scale bounce, prismatic profile card
//

import SwiftUI

// MARK: - Profile Sheet View

struct ProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.responsiveLayout) private var layout
    @Bindable var settingsViewModel: SettingsViewModel

    // Animation
    @State private var showContent = false
    @State private var cardScale: CGFloat = 0.9
    @State private var sectionsRevealed: [Bool] = Array(repeating: false, count: 6)
    @State private var orbitRotation: Double = 0
    @State private var glowPulse: CGFloat = 0.5

    // Avatar
    @StateObject private var profileImageService = ProfileImageService.shared
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false

    // Alerts
    @State private var showDeleteAccountAlert = false
    @State private var showClearCompletedAlert = false
    @State private var isDeleting = false

    // Services
    private let gamification = GamificationService.shared

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
                        .opacity(sectionsRevealed[0] ? 1 : 0)
                        .offset(y: sectionsRevealed[0] ? 0 : 20)

                    // Profile Section
                    profileSection
                        .sectionReveal(isVisible: sectionsRevealed[1])

                    // Appearance Section
                    appearanceSection
                        .sectionReveal(isVisible: sectionsRevealed[2])

                    // Notifications Section
                    notificationsSection
                        .sectionReveal(isVisible: sectionsRevealed[3])

                    // Focus Settings Section
                    focusSection
                        .sectionReveal(isVisible: sectionsRevealed[4])

                    // Data Section
                    dataSection
                        .sectionReveal(isVisible: sectionsRevealed[5])

                    // Sign Out
                    signOutButton
                        .opacity(sectionsRevealed[5] ? 1 : 0)
                        .offset(y: sectionsRevealed[5] ? 0 : 20)
                }
                .padding(.horizontal, layout.screenPadding)
                .padding(.top, layout.spacing * 1.5)
                .padding(.bottom, layout.spacing * 3)
            }
            .background {
                ProfileSheetBackground()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AuroraHaptics.light()
                        AuroraSoundEngine.shared.play(.buttonTap)
                        dismiss()
                    } label: {
                        ZStack {
                            // Glow behind close button
                            Image(systemName: "xmark.circle.fill")
                                .dynamicTypeFont(base: 28)
                                .foregroundStyle(Aurora.Colors.borealisViolet)
                                .blur(radius: 6)
                                .opacity(0.4)

                            Image(systemName: "xmark.circle.fill")
                                .dynamicTypeFont(base: 28)
                                .foregroundStyle(.white.opacity(0.6))
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
            }
        }
        .onAppear {
            startRevealAnimation()
            loadAvatar()
            startOrbitAnimation()
        }
        .sheet(isPresented: $showImagePicker) {
            ProfileImagePicker(image: $avatarImage)
        }
        .onChange(of: avatarImage) { _, newImage in
            if let image = newImage {
                Task {
                    await uploadAvatar(image)
                }
            }
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await settingsViewModel.deleteAccount()
                        await appViewModel.signOut()
                    } catch {
                        settingsViewModel.error = error.localizedDescription
                    }
                    isDeleting = false
                }
            }
        } message: {
            Text("This will permanently delete your account and all your data. This action cannot be undone.")
        }
        .alert("Clear Completed Tasks?", isPresented: $showClearCompletedAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                AuroraHaptics.medium()
                // TODO: Implement clear completed tasks
            }
        } message: {
            Text("This will remove all completed tasks. This cannot be undone.")
        }
    }

    // MARK: - Hero Profile Card

    private var profileHeroCard: some View {
        VStack(spacing: 20) {
            // Avatar with orbiting achievement rings
            Button {
                AuroraHaptics.light()
                AuroraSoundEngine.shared.play(.buttonTap)
                showImagePicker = true
            } label: {
                ZStack {
                    // Outer pulsing glow halo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Aurora.Colors.borealisViolet.opacity(0.3 * glowPulse),
                                    Aurora.Colors.electricCyan.opacity(0.15 * glowPulse),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: 25)

                    // Orbiting achievement particles
                    if !reduceMotion {
                        ForEach(0..<4, id: \.self) { i in
                            achievementOrbitParticle(index: i)
                        }
                    }

                    // Outer prismatic ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Aurora.Colors.electricCyan,
                                    Aurora.Colors.borealisViolet,
                                    Aurora.Colors.stellarMagenta,
                                    Aurora.Colors.electricCyan
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Aurora.Colors.electricCyan.opacity(0.4), radius: 8)

                    // Level progress ring
                    Circle()
                        .trim(from: 0, to: gamification.levelProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Aurora.Colors.borealisViolet, Aurora.Colors.electricCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Aurora.Colors.borealisViolet.opacity(0.5), radius: 6)

                    // Avatar circle
                    if let image = avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Aurora.Colors.voidNebula, lineWidth: 2)
                            }
                    } else {
                        // Initial letter avatar with aurora gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Aurora.Colors.borealisViolet.opacity(0.4),
                                        Aurora.Colors.electricCyan.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay {
                                // Glow text
                                ZStack {
                                    Text(userInitial)
                                        .dynamicTypeFont(base: 40, weight: .light)
                                        .foregroundStyle(Aurora.Colors.electricCyan)
                                        .blur(radius: 6)
                                        .opacity(0.5)

                                    Text(userInitial)
                                        .dynamicTypeFont(base: 40, weight: .light)
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle()
                                    .stroke(Aurora.Colors.voidNebula, lineWidth: 2)
                            }
                    }

                    // Edit badge with glow
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Aurora.Colors.borealisViolet)
                                    .frame(width: 28, height: 28)
                                    .shadow(color: Aurora.Colors.borealisViolet.opacity(0.6), radius: 6)

                                Image(systemName: "pencil")
                                    .dynamicTypeFont(base: 13, weight: .semibold)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(width: 114, height: 114)

                    // Level badge with glow
                    VStack {
                        Spacer()
                        HStack {
                            ZStack {
                                Text("Lv.\(gamification.currentLevel)")
                                    .dynamicTypeFont(base: 11, weight: .bold)
                                    .foregroundStyle(Aurora.Colors.electricCyan)
                                    .blur(radius: 4)
                                    .opacity(0.6)

                                Text("Lv.\(gamification.currentLevel)")
                                    .dynamicTypeFont(base: 11, weight: .bold)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background {
                                Capsule()
                                    .fill(Aurora.Colors.borealisViolet)
                                    .shadow(color: Aurora.Colors.borealisViolet.opacity(0.5), radius: 4)
                            }
                            Spacer()
                        }
                    }
                    .frame(width: 104, height: 104)
                }
            }
            .buttonStyle(AvatarButtonStyle())

            // Name and email with glow
            VStack(spacing: 8) {
                ZStack {
                    Text(userName)
                        .dynamicTypeFont(base: 26, weight: .semibold)
                        .foregroundStyle(Aurora.Colors.electricCyan)
                        .blur(radius: 8)
                        .opacity(0.4)

                    Text(userName)
                        .dynamicTypeFont(base: 26, weight: .semibold)
                        .foregroundStyle(Aurora.Colors.textPrimary)
                }

                Text(settingsViewModel.email.isEmpty ? "Welcome to Veloce" : settingsViewModel.email)
                    .font(Aurora.Typography.subheadline)
                    .foregroundStyle(Aurora.Colors.textTertiary)
            }
        }
        .padding(.vertical, Aurora.Spacing.xl)
        .padding(.horizontal, Aurora.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(Aurora.Colors.voidNebula.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Aurora.Colors.borealisViolet.opacity(0.4),
                                    Aurora.Colors.electricCyan.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
        }
        .auroraGlass(in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: Aurora.Colors.borealisViolet.opacity(0.2), radius: 20, y: 8)
    }

    // Orbiting achievement particle
    private func achievementOrbitParticle(index: Int) -> some View {
        let colors: [Color] = [
            Aurora.Colors.electricCyan,
            Aurora.Colors.borealisViolet,
            Aurora.Colors.stellarMagenta,
            Aurora.Colors.prismaticGreen
        ]
        let baseAngle = Double(index) * 90

        return Circle()
            .fill(colors[index % colors.count])
            .frame(width: 8, height: 8)
            .blur(radius: 1.5)
            .shadow(color: colors[index % colors.count].opacity(0.8), radius: 4)
            .offset(x: 70)
            .rotationEffect(.degrees(orbitRotation + baseAngle))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            AuroraStatCardProfile(
                value: "\(gamification.totalTasksCompleted)",
                label: "Tasks Done",
                icon: "checkmark.circle.fill",
                color: Aurora.Colors.prismaticGreen
            )

            AuroraStatCardProfile(
                value: "\(gamification.currentStreak)",
                label: "Day Streak",
                icon: "flame.fill",
                color: Aurora.Colors.stellarMagenta
            )

            AuroraStatCardProfile(
                value: "\(gamification.totalPoints)",
                label: "Power",
                icon: "bolt.fill",
                color: Aurora.Colors.cosmicGold
            )
        }
    }
    
    // MARK: - Section Header Helper
    
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .dynamicTypeFont(base: 16, weight: .semibold)
                .foregroundStyle(color)
            
            Text(title)
                .dynamicTypeFont(base: 17, weight: .semibold)
                .foregroundStyle(.white)
            
            Spacer()
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        SettingsSectionCard(title: "Profile", icon: "person.fill", iconColor: Aurora.Colors.borealisViolet) {
            VStack(spacing: 0) {
                // Name field
                SettingsTextField(
                    icon: "person.text.rectangle",
                    iconColor: Aurora.Colors.electricCyan,
                    title: "Name",
                    text: $settingsViewModel.fullName,
                    placeholder: "Your name"
                )
                .onChange(of: settingsViewModel.fullName) { _, _ in
                    Task {
                        await settingsViewModel.saveProfile()
                    }
                }

                SettingsDivider()

                // Email (read only)
                HStack(spacing: 14) {
                    SettingsIconContainer(icon: "envelope.fill", color: Aurora.Colors.electricCyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .dynamicTypeFont(base: 13)
                            .foregroundStyle(.white.opacity(0.5))
                        Text(settingsViewModel.email.isEmpty ? "Not set" : settingsViewModel.email)
                            .dynamicTypeFont(base: 16)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()
                }
                .padding(16)
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        SettingsSectionCard(title: "Appearance", icon: "paintbrush.fill", iconColor: Aurora.Colors.electricCyan) {
            VStack(spacing: 0) {
                // Theme picker
                HStack(spacing: 14) {
                    SettingsIconContainer(icon: "circle.lefthalf.filled", color: Aurora.Colors.borealisViolet)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme")
                            .dynamicTypeFont(base: 16, weight: .medium)
                            .foregroundStyle(.white)
                        Text("App appearance")
                            .dynamicTypeFont(base: 12)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Picker("", selection: $settingsViewModel.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Aurora.Colors.borealisViolet)
                    .onChange(of: settingsViewModel.theme) { _, _ in
                        AuroraHaptics.light()
                        Task {
                            await settingsViewModel.saveThemeSettings()
                        }
                    }
                }
                .padding(16)

                SettingsDivider()

                // App Icon (placeholder)
                HStack(spacing: 14) {
                    SettingsIconContainer(icon: "app.badge.fill", color: .orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("App Icon")
                            .dynamicTypeFont(base: 16, weight: .medium)
                            .foregroundStyle(.white)
                        Text("Default")
                            .dynamicTypeFont(base: 12)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .dynamicTypeFont(base: 12, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(16)
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Notifications", icon: "bell.fill", color: .orange)
            
            VStack(spacing: 12) {
                // Task Reminders
                LiquidGlassToggleRow(
                    title: "Task Reminders",
                    subtitle: "Get notified about upcoming tasks",
                    icon: "bell.badge.fill",
                    color: .orange,
                    isOn: $settingsViewModel.notificationsEnabled
                )
                .onChange(of: settingsViewModel.notificationsEnabled) { _, _ in
                    AuroraHaptics.light()
                    Task {
                        await settingsViewModel.saveNotificationSettings()
                    }
                }

                // Streak Alerts
                LiquidGlassToggleRow(
                    title: "Streak Alerts",
                    subtitle: "Remind you to keep your streak alive",
                    icon: "flame.fill",
                    color: Aurora.Colors.stellarMagenta,
                    isOn: .constant(true)
                )
                .onChange(of: settingsViewModel.notificationsEnabled) { _, _ in
                    AuroraHaptics.light()
                }
            }
        }
    }

    // MARK: - Focus Section

    private var focusSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Focus Settings", icon: "timer", color: Aurora.Colors.prismaticGreen)
            
            LiquidGlassCard(
                cornerRadius: 16
            ) {
                VStack(spacing: 16) {
                    // Default Timer Duration
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Aurora.Colors.prismaticGreen.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "clock.fill")
                                .dynamicTypeFont(base: 18, weight: .semibold)
                                .foregroundStyle(Aurora.Colors.prismaticGreen)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Default Timer")
                                .dynamicTypeFont(base: 16, weight: .semibold)
                                .foregroundStyle(.white)
                            Text("Focus session length")
                                .dynamicTypeFont(base: 14)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Text("25 min")
                            .dynamicTypeFont(base: 15, weight: .semibold)
                            .foregroundStyle(Aurora.Colors.prismaticGreen)
                    }
                    
                    Divider()
                        .background(.white.opacity(0.1))
                    
                    // Break Duration
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Aurora.Colors.electricCyan.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "cup.and.saucer.fill")
                                .dynamicTypeFont(base: 18, weight: .semibold)
                                .foregroundStyle(Aurora.Colors.electricCyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break Duration")
                                .dynamicTypeFont(base: 16, weight: .semibold)
                                .foregroundStyle(.white)
                            Text("Rest between sessions")
                                .dynamicTypeFont(base: 14)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Text("5 min")
                            .dynamicTypeFont(base: 15, weight: .semibold)
                            .foregroundStyle(Aurora.Colors.electricCyan)
                    }
                }
            }
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        SettingsSectionCard(title: "Data", icon: "square.and.arrow.up", iconColor: Aurora.Colors.electricCyan) {
            VStack(spacing: 0) {
                // Export data
                Button {
                    AuroraHaptics.light()
                    AuroraSoundEngine.shared.play(.buttonTap)
                    exportData()
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconContainer(icon: "square.and.arrow.up.fill", color: Aurora.Colors.electricCyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Data")
                                .dynamicTypeFont(base: 16, weight: .medium)
                                .foregroundStyle(.white)
                            Text("Download all your data")
                                .dynamicTypeFont(base: 12)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .dynamicTypeFont(base: 12, weight: .semibold)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                }
                .buttonStyle(SettingsRowButtonStyle())

                SettingsDivider()

                // Clear completed
                Button {
                    AuroraHaptics.medium()
                    showClearCompletedAlert = true
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconContainer(icon: "trash.fill", color: .orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Completed")
                                .dynamicTypeFont(base: 16, weight: .medium)
                                .foregroundStyle(.white)
                            Text("Remove all completed tasks")
                                .dynamicTypeFont(base: 12)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .dynamicTypeFont(base: 12, weight: .semibold)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                }
                .buttonStyle(SettingsRowButtonStyle())

                SettingsDivider()

                // Delete account
                Button {
                    AuroraHaptics.heavy()
                    showDeleteAccountAlert = true
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconContainer(icon: "person.crop.circle.badge.xmark", color: .red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Account")
                                .dynamicTypeFont(base: 16, weight: .medium)
                                .foregroundStyle(.red)
                            Text("Permanently remove your account")
                                .dynamicTypeFont(base: 12)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()
                    }
                    .padding(16)
                }
                .buttonStyle(SettingsRowButtonStyle())
                .disabled(isDeleting)
            }
        }
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button {
            AuroraHaptics.medium()
            AuroraSoundEngine.shared.play(.buttonTap)
            Task {
                await appViewModel.signOut()
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .dynamicTypeFont(base: 15, weight: .medium)
                Text("Sign Out")
                    .dynamicTypeFont(base: 16, weight: .medium)
            }
            .foregroundStyle(.red.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Aurora.Colors.voidNebula.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.red.opacity(0.2), lineWidth: 1)
                    }
            }
            .auroraGlass(in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ProfileButtonPressStyle())
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
        // Card entrance with aurora spring
        withAnimation(AuroraMotion.Spring.morph) {
            showContent = true
            cardScale = 1.0
        }

        // Staggered section reveals with aurora timing
        for index in 0..<sectionsRevealed.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(index) * 0.08) {
                withAnimation(AuroraMotion.Spring.ui) {
                    sectionsRevealed[index] = true
                }
            }
        }
    }

    private func startOrbitAnimation() {
        guard !reduceMotion else { return }

        // Slow orbital rotation for achievement particles
        withAnimation(
            .linear(duration: 25)
            .repeatForever(autoreverses: false)
        ) {
            orbitRotation = 360
        }

        // Glow pulse animation
        withAnimation(
            .easeInOut(duration: AuroraMotion.Duration.glowPulse)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = 1.0
        }
    }

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
            // Notify other views (like header) that avatar changed
            profileImageService.notifyAvatarChanged()
            AuroraHaptics.dopamineBurst()
            AuroraSoundEngine.shared.play(.taskComplete)
        } catch {
            settingsViewModel.error = error.localizedDescription
        }
    }

    private func exportData() {
        Task {
            do {
                _ = try await settingsViewModel.exportData()
                AuroraHaptics.dopamineBurst()
                AuroraSoundEngine.shared.play(.taskComplete)
            } catch {
                settingsViewModel.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Aurora Stat Card Profile

private struct AuroraStatCardProfile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    @State private var glowIntensity: CGFloat = 0.3

    var body: some View {
        VStack(spacing: 10) {
            // Icon with glow
            ZStack {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 20)
                    .foregroundStyle(color)
                    .blur(radius: 4)
                    .opacity(glowIntensity)

                Image(systemName: icon)
                    .dynamicTypeFont(base: 20)
                    .foregroundStyle(color)
            }

            // Value with glow
            ZStack {
                Text(value)
                    .font(Aurora.Typography.title2)
                    .foregroundStyle(color)
                    .blur(radius: 5)
                    .opacity(glowIntensity)

                Text(value)
                    .font(Aurora.Typography.title2)
                    .foregroundStyle(color)
            }

            Text(label)
                .font(Aurora.Typography.caption)
                .foregroundStyle(Aurora.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Aurora.Colors.voidNebula)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [color.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: color.opacity(0.25), radius: 10, y: 4)
        .onAppear {
            withAnimation(
                .easeInOut(duration: AuroraMotion.Duration.glowPulse)
                .repeatForever(autoreverses: true)
            ) {
                glowIntensity = 0.5
            }
        }
    }
}

// MARK: - Supporting Views

private struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with aurora glow
            HStack(spacing: 8) {
                ZStack {
                    Image(systemName: icon)
                        .dynamicTypeFont(base: 12, weight: .semibold)
                        .foregroundStyle(iconColor)
                        .blur(radius: 3)
                        .opacity(0.5)

                    Image(systemName: icon)
                        .dynamicTypeFont(base: 12, weight: .semibold)
                        .foregroundStyle(iconColor)
                }

                Text(title.uppercased())
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(Aurora.Colors.textTertiary)
                    .tracking(1.2)
            }
            .padding(.horizontal, 4)

            // Content card with aurora glass
            content()
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Aurora.Colors.voidNebula.opacity(0.6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [iconColor.opacity(0.2), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                }
                .auroraGlass(in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

private struct SettingsIconContainer: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            // Subtle glow behind
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 36, height: 36)
                .blur(radius: 3)

            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)

            Image(systemName: icon)
                .dynamicTypeFont(base: 15, weight: .medium)
                .foregroundStyle(color)
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Aurora.Colors.electricCyan.opacity(0.15),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.leading, 66)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            SettingsIconContainer(icon: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .dynamicTypeFont(base: 16, weight: .medium)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Aurora.Colors.borealisViolet)
                .onChange(of: isOn) { _, _ in
                    onChange()
                }
        }
        .padding(16)
    }
}

private struct SettingsTextField: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 14) {
            SettingsIconContainer(icon: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .dynamicTypeFont(base: 13)
                    .foregroundStyle(.white.opacity(0.5))
                TextField(placeholder, text: $text)
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(16)
    }
}

private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Aurora.Colors.electricCyan.opacity(0.05) : Color.clear)
            .animation(AuroraMotion.Spring.ui, value: configuration.isPressed)
    }
}

private struct ProfileButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AuroraMotion.Spring.ui, value: configuration.isPressed)
    }
}

private struct AvatarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AuroraMotion.Spring.morph, value: configuration.isPressed)
    }
}

// MARK: - Section Reveal Modifier

private struct SectionRevealModifier: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
    }
}

extension View {
    fileprivate func sectionReveal(isVisible: Bool) -> some View {
        modifier(SectionRevealModifier(isVisible: isVisible))
    }
}

// MARK: - Profile Sheet Background

private struct ProfileSheetBackground: View {
    var body: some View {
        ZStack {
            // Deep cosmic void base
            Aurora.Colors.voidCosmos
                .ignoresSafeArea()

            // Ambient glow
            RadialGradient(
                colors: [
                    Aurora.Colors.borealisViolet.opacity(0.15),
                    Aurora.Colors.electricCyan.opacity(0.08),
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

// MARK: - Profile Image Picker

struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProfileImagePicker

        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage {
                parent.image = image
            } else if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Aurora.Colors.voidCosmos.ignoresSafeArea()

        ProfileSheetView(settingsViewModel: SettingsViewModel())
            .environment(AppViewModel())
    }
    .preferredColorScheme(.dark)
}
