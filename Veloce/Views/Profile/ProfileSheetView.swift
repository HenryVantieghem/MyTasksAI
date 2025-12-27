//
//  ProfileSheetView.swift
//  Veloce
//
//  Unified Profile Sheet - Premium Liquid Glass Design
//  User avatar (editable), stats summary, and inline settings
//  with iOS 26 glassEffect and stunning visual hierarchy
//

import SwiftUI

// MARK: - Profile Sheet View

struct ProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var settingsViewModel: SettingsViewModel

    // Animation
    @State private var showContent = false
    @State private var cardScale: CGFloat = 0.9
    @State private var sectionsRevealed: [Bool] = Array(repeating: false, count: 6)

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
        }
        .onAppear {
            startRevealAnimation()
            loadAvatar()
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
                HapticsService.shared.notification(.success)
                // TODO: Implement clear completed tasks
            }
        } message: {
            Text("This will remove all completed tasks. This cannot be undone.")
        }
    }

    // MARK: - Hero Profile Card

    private var profileHeroCard: some View {
        VStack(spacing: 20) {
            // Avatar with level ring - now tappable for editing
            Button {
                HapticsService.shared.selectionFeedback()
                showImagePicker = true
            } label: {
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

                    // Edit badge - bottom right
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.aiPurple)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .frame(width: 110, height: 110)

                    // Level badge
                    VStack {
                        Spacer()
                        HStack {
                            Text("Lv.\(gamification.currentLevel)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(Theme.Colors.aiPurple)
                                }
                            Spacer()
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            .buttonStyle(AvatarButtonStyle())

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

    // MARK: - Profile Section

    private var profileSection: some View {
        SettingsSectionCard(title: "Profile", icon: "person.fill", iconColor: Theme.Colors.aiPurple) {
            VStack(spacing: 0) {
                // Name field
                SettingsTextField(
                    icon: "person.text.rectangle",
                    iconColor: Theme.Colors.aiBlue,
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
                    SettingsIconContainer(icon: "envelope.fill", color: Theme.Colors.aiCyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(settingsViewModel.email.isEmpty ? "Not set" : settingsViewModel.email)
                            .font(.system(size: 16))
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
        SettingsSectionCard(title: "Appearance", icon: "paintbrush.fill", iconColor: Theme.Colors.aiCyan) {
            VStack(spacing: 0) {
                // Theme picker
                HStack(spacing: 14) {
                    SettingsIconContainer(icon: "circle.lefthalf.filled", color: Theme.Colors.aiPurple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                        Text("App appearance")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Picker("", selection: $settingsViewModel.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.aiPurple)
                    .onChange(of: settingsViewModel.theme) { _, _ in
                        HapticsService.shared.selectionFeedback()
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
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Default")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(16)
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        SettingsSectionCard(title: "Notifications", icon: "bell.fill", iconColor: .orange) {
            VStack(spacing: 0) {
                // Reminders toggle
                SettingsToggleRow(
                    icon: "bell.badge.fill",
                    iconColor: .orange,
                    title: "Task Reminders",
                    subtitle: "Get notified about upcoming tasks",
                    isOn: $settingsViewModel.notificationsEnabled
                ) {
                    HapticsService.shared.selectionFeedback()
                    Task {
                        await settingsViewModel.saveNotificationSettings()
                    }
                }

                SettingsDivider()

                // Streak reminders
                SettingsToggleRow(
                    icon: "flame.fill",
                    iconColor: .red,
                    title: "Streak Alerts",
                    subtitle: "Remind you to keep your streak",
                    isOn: .constant(true)
                ) {
                    HapticsService.shared.selectionFeedback()
                }
            }
        }
    }

    // MARK: - Focus Section

    private var focusSection: some View {
        SettingsSectionCard(title: "Focus Settings", icon: "timer", iconColor: Theme.Colors.success) {
            VStack(spacing: 0) {
                // Default timer duration
                HStack(spacing: 14) {
                    SettingsIconContainer(icon: "clock.fill", color: Theme.Colors.success)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Timer")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Focus session length")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Text("25 min")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.Colors.success)
                }
                .padding(16)

                SettingsDivider()

                // Break duration
                HStack(spacing: 14) {
                    SettingsIconContainer(icon: "cup.and.saucer.fill", color: Theme.Colors.aiBlue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Break Duration")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Rest between sessions")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Text("5 min")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiBlue)
                }
                .padding(16)

                SettingsDivider()

                // Haptic feedback
                SettingsToggleRow(
                    icon: "hand.tap.fill",
                    iconColor: Theme.Colors.aiPurple,
                    title: "Haptic Feedback",
                    subtitle: "Vibration for actions",
                    isOn: $settingsViewModel.hapticsEnabled
                ) {
                    settingsViewModel.saveHapticsSettings()
                }
            }
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        SettingsSectionCard(title: "Data", icon: "square.and.arrow.up", iconColor: Theme.Colors.aiBlue) {
            VStack(spacing: 0) {
                // Export data
                Button {
                    HapticsService.shared.selectionFeedback()
                    exportData()
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconContainer(icon: "square.and.arrow.up.fill", color: Theme.Colors.aiBlue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Data")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            Text("Download all your data")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                }
                .buttonStyle(SettingsRowButtonStyle())

                SettingsDivider()

                // Clear completed
                Button {
                    HapticsService.shared.impact(.medium)
                    showClearCompletedAlert = true
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconContainer(icon: "trash.fill", color: .orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Completed")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            Text("Remove all completed tasks")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                }
                .buttonStyle(SettingsRowButtonStyle())

                SettingsDivider()

                // Delete account
                Button {
                    HapticsService.shared.impact(.heavy)
                    showDeleteAccountAlert = true
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconContainer(icon: "person.crop.circle.badge.xmark", color: .red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.red)
                            Text("Permanently remove your account")
                                .font(.system(size: 12))
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
        // Card entrance
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showContent = true
            cardScale = 1.0
        }

        // Staggered section reveals
        for index in 0..<sectionsRevealed.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(index) * 0.08) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    sectionsRevealed[index] = true
                }
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

    private func uploadAvatar(_ image: UIImage) async {
        guard let userId = appViewModel.currentUser?.id.uuidString else { return }
        do {
            _ = try await profileImageService.uploadAvatar(image, for: userId)
            // Notify other views (like header) that avatar changed
            profileImageService.notifyAvatarChanged()
            HapticsService.shared.notification(.success)
        } catch {
            settingsViewModel.error = error.localizedDescription
        }
    }

    private func exportData() {
        Task {
            do {
                _ = try await settingsViewModel.exportData()
                HapticsService.shared.notification(.success)
            } catch {
                settingsViewModel.error = error.localizedDescription
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
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(title.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(1.2)
            }
            .padding(.horizontal, 4)

            // Content card
            content()
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

private struct SettingsIconContainer: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)

            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.Colors.aiPurple)
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
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
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
            .background(configuration.isPressed ? Color.white.opacity(0.05) : Color.clear)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct ProfileButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private struct AvatarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
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
    ProfileSheetView(settingsViewModel: SettingsViewModel())
        .environment(AppViewModel())
}
