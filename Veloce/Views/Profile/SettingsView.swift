//
//  SettingsView.swift
//  Veloce
//
//  Full Settings View - Premium Liquid Glass Design
//  All settings sections with iOS 26 glassEffect
//  Profile, Appearance, Notifications, Focus, Data, About
//

import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var initialSection: SettingsSection?

    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel

    // State
    @State private var showDeleteAccountAlert = false
    @State private var isDeleting = false
    @State private var showExportSheet = false
    @State private var showClearCompletedAlert = false
    @State private var showRateAppAlert = false

    // Avatar
    @StateObject private var profileImageService = ProfileImageService.shared
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false

    // Animation
    @State private var sectionsRevealed: [Bool] = Array(repeating: false, count: 6)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Profile Section
                    profileSection
                        .id(SettingsSection.profile)
                        .settingsStaggeredReveal(index: 0, isVisible: sectionsRevealed[0])

                    // Appearance Section
                    appearanceSection
                        .id(SettingsSection.appearance)
                        .settingsStaggeredReveal(index: 1, isVisible: sectionsRevealed[1])

                    // Notifications Section
                    notificationsSection
                        .id(SettingsSection.notifications)
                        .settingsStaggeredReveal(index: 2, isVisible: sectionsRevealed[2])

                    // Focus Settings Section
                    focusSection
                        .id(SettingsSection.focus)
                        .settingsStaggeredReveal(index: 3, isVisible: sectionsRevealed[3])

                    // Data Section
                    dataSection
                        .id(SettingsSection.data)
                        .settingsStaggeredReveal(index: 4, isVisible: sectionsRevealed[4])

                    // About Section
                    aboutSection
                        .id(SettingsSection.about)
                        .settingsStaggeredReveal(index: 5, isVisible: sectionsRevealed[5])
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
            .background {
                SettingsBackground()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                startRevealAnimation()
                loadAvatar()

                // Scroll to initial section if provided
                if let section = initialSection {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            proxy.scrollTo(section, anchor: .top)
                        }
                    }
                }
            }
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await viewModel.deleteAccount()
                        await appViewModel.signOut()
                    } catch {
                        viewModel.error = error.localizedDescription
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
        .sheet(isPresented: $showImagePicker) {
            SettingsImagePicker(image: $avatarImage)
        }
        .onChange(of: avatarImage) { _, newImage in
            if let image = newImage {
                Task {
                    await uploadAvatar(image)
                }
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        SettingsSectionCard(title: "Profile", icon: "person.fill", iconColor: Theme.Colors.aiPurple) {
            VStack(spacing: 0) {
                // Avatar row
                Button {
                    HapticsService.shared.selectionFeedback()
                    showImagePicker = true
                } label: {
                    HStack(spacing: 14) {
                        // Avatar
                        ZStack {
                            if let image = avatarImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Theme.Colors.aiPurple.opacity(0.2))
                                    .frame(width: 56, height: 56)
                                    .overlay {
                                        Text(userInitial)
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundStyle(Theme.Colors.aiPurple)
                                    }
                            }

                            // Edit badge
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Theme.Colors.aiPurple).frame(width: 16, height: 16))
                                }
                            }
                            .frame(width: 56, height: 56)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.fullName.isEmpty ? "Add Name" : viewModel.fullName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)

                            Text("Tap to change avatar")
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

                // Name field
                SettingsTextField(
                    icon: "person.text.rectangle",
                    iconColor: Theme.Colors.aiBlue,
                    title: "Name",
                    text: $viewModel.fullName,
                    placeholder: "Your name"
                )

                SettingsDivider()

                // Email (read only)
                HStack(spacing: 14) {
                    SettingsIconContainer(icon: "envelope.fill", color: Theme.Colors.aiCyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(viewModel.email.isEmpty ? "Not set" : viewModel.email)
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

                    Picker("", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.aiPurple)
                    .onChange(of: viewModel.theme) { _, _ in
                        HapticsService.shared.selectionFeedback()
                        Task {
                            await viewModel.saveThemeSettings()
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
                    isOn: $viewModel.notificationsEnabled
                ) {
                    HapticsService.shared.selectionFeedback()
                    Task {
                        await viewModel.saveNotificationSettings()
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
                    isOn: $viewModel.hapticsEnabled
                ) {
                    viewModel.saveHapticsSettings()
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

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsSectionCard(title: "About", icon: "info.circle.fill", iconColor: .gray) {
            VStack(spacing: 0) {
                // Version
                HStack(spacing: 14) {
                    SettingsIconContainer(icon: "number", color: Theme.Colors.aiPurple)

                    Text("Version")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("1.0.0")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(16)

                SettingsDivider()

                // Rate app
                Button {
                    HapticsService.shared.selectionFeedback()
                    // TODO: Request app store review
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconContainer(icon: "star.fill", color: .yellow)

                        Text("Rate Veloce")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                }
                .buttonStyle(SettingsRowButtonStyle())

                SettingsDivider()

                // Privacy Policy
                Button {
                    HapticsService.shared.selectionFeedback()
                    // TODO: Open privacy policy URL
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconContainer(icon: "hand.raised.fill", color: Theme.Colors.aiCyan)

                        Text("Privacy Policy")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                }
                .buttonStyle(SettingsRowButtonStyle())
            }
        }
    }

    // MARK: - Helpers

    private var userInitial: String {
        if let first = viewModel.fullName.first {
            return String(first).uppercased()
        }
        return "V"
    }

    private func startRevealAnimation() {
        for index in 0..<sectionsRevealed.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + Double(index) * 0.08) {
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
            HapticsService.shared.notification(.success)
        } catch {
            viewModel.error = error.localizedDescription
        }
    }

    private func exportData() {
        Task {
            do {
                let data = try await viewModel.exportData()
                // TODO: Present share sheet with data
                HapticsService.shared.notification(.success)
            } catch {
                viewModel.error = error.localizedDescription
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

// MARK: - Settings Background

private struct SettingsBackground: View {
    var body: some View {
        Color(red: 0.02, green: 0.02, blue: 0.04)
            .ignoresSafeArea()
    }
}

// MARK: - Settings Staggered Reveal Modifier

private struct SettingsStaggeredRevealModifier: ViewModifier {
    let index: Int
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
    }
}

extension View {
    fileprivate func settingsStaggeredReveal(index: Int, isVisible: Bool) -> some View {
        modifier(SettingsStaggeredRevealModifier(index: index, isVisible: isVisible))
    }
}

// MARK: - Settings Image Picker

struct SettingsImagePicker: UIViewControllerRepresentable {
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
        let parent: SettingsImagePicker

        init(_ parent: SettingsImagePicker) {
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
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
    .environment(AppViewModel())
}
