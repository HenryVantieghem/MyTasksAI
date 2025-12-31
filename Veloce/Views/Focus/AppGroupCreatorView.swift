//
//  AppGroupCreatorView.swift
//  Veloce
//
//  Create and manage app groups for blocking
//  Group apps by category for easier schedule management
//

import SwiftUI
import FamilyControls

// MARK: - App Group Creator View

struct AppGroupCreatorView: View {
    @State private var groupName = ""
    @State private var selectedColor: GroupColor = .blue
    @State private var selectedIcon = "folder.fill"
    @State private var showAppPicker = false
    @State private var selectedApps = FamilyActivitySelection()

    @Environment(\.dismiss) private var dismiss

    private let iconOptions = [
        "folder.fill",
        "bubble.left.and.bubble.right.fill",
        "tv.fill",
        "gamecontroller.fill",
        "newspaper.fill",
        "cart.fill",
        "camera.fill",
        "music.note",
        "heart.fill",
        "star.fill",
        "bolt.fill",
        "flame.fill"
    ]

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                groupHeader

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Group preview
                        groupPreview

                        // Name input
                        nameSection

                        // Color selection
                        colorSection

                        // Icon selection
                        iconSection

                        // Apps selection
                        appsSection
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, 120)
                }

                // Save button
                saveButton
            }
        }
        .preferredColorScheme(.dark)
        .familyActivityPicker(isPresented: $showAppPicker, selection: $selectedApps)
    }

    // MARK: - Header

    private var groupHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .dynamicTypeFont(base: 16, weight: .medium)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Text("New Group")
                .dynamicTypeFont(base: 17, weight: .semibold)
                .foregroundStyle(.white)

            Spacer()

            // Invisible balance
            Text("Cancel")
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Group Preview

    private var groupPreview: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Icon preview
            ZStack {
                Circle()
                    .fill(selectedColor.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: selectedIcon)
                    .dynamicTypeFont(base: 32)
                    .foregroundStyle(selectedColor.color)
            }

            // Name preview
            Text(groupName.isEmpty ? "Group Name" : groupName)
                .dynamicTypeFont(base: 20, weight: .semibold)
                .foregroundStyle(groupName.isEmpty ? .white.opacity(0.3) : .white)

            // App count
            Text("\(selectedApps.applicationTokens.count) apps")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(selectedColor.color.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Group Name")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.7))

            TextField("e.g., Social Media", text: $groupName)
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(.white)
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        }
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Color")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.7))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(GroupColor.allCases, id: \.self) { color in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedColor = color
                        }
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 44, height: 44)
                            .overlay {
                                if selectedColor == color {
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                    Image(systemName: "checkmark")
                                        .dynamicTypeFont(base: 16, weight: .bold)
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Icon")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.7))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedIcon = icon
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedIcon == icon ? selectedColor.color.opacity(0.3) : Color.white.opacity(0.1))
                                .frame(width: 48, height: 48)

                            Image(systemName: icon)
                                .dynamicTypeFont(base: 20)
                                .foregroundStyle(selectedIcon == icon ? selectedColor.color : .white.opacity(0.6))
                        }
                        .overlay {
                            if selectedIcon == icon {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedColor.color, lineWidth: 2)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Apps Section

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Apps in Group")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.7))

            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .dynamicTypeFont(base: 20)
                        .foregroundStyle(selectedColor.color)

                    Text(selectedApps.applicationTokens.isEmpty ? "Add Apps" : "\(selectedApps.applicationTokens.count) apps selected")
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(Theme.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedColor.color.opacity(0.3), lineWidth: 1)
                }
            }

            // Suggestion
            if selectedApps.applicationTokens.isEmpty {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(Theme.Colors.aiAmber)

                    Text("Tip: Group similar apps together for easier blocking")
                        .dynamicTypeFont(base: 13, weight: .medium)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.aiAmber.opacity(0.1))
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(.white.opacity(0.1))

            Button {
                saveGroup()
            } label: {
                Text("Create Group")
                    .dynamicTypeFont(base: 17, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [selectedColor.color, selectedColor.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
            }
            .disabled(groupName.isEmpty)
            .opacity(groupName.isEmpty ? 0.5 : 1)
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func saveGroup() {
        // Would save to persistence
        HapticsService.shared.notification(.success)
        dismiss()
    }
}

// MARK: - Group Color

enum GroupColor: String, CaseIterable {
    case red, orange, yellow, green, teal, blue, indigo, purple, pink, brown

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        }
    }
}

// MARK: - Preview

#Preview {
    AppGroupCreatorView()
}
