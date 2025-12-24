//
//  FocusPresetsView.swift
//  Veloce
//
//  Block List Presets - Opal-style quick blocking profiles
//  Pre-built and custom app blocking configurations
//

import SwiftUI
import SwiftData
import FamilyControls

// MARK: - Focus Presets View

struct FocusPresetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusBlockList.useCount, order: .reverse) private var presets: [FocusBlockList]

    @State private var showCreateSheet = false
    @State private var selectedPreset: FocusBlockList?
    @State private var showAppPicker = false
    @State private var editingPreset: FocusBlockList?

    private let blockingService = FocusBlockingService.shared

    // Built-in presets (shown if not created yet)
    private var builtInPresets: [BuiltInPreset] {
        let existingNames = Set(presets.map { $0.name })
        return [
            BuiltInPreset(
                name: "Work Mode",
                description: "Block social media & entertainment during work",
                icon: "briefcase.fill",
                color: "#6B73F9"
            ),
            BuiltInPreset(
                name: "Social Media Detox",
                description: "Block all social media apps",
                icon: "bubble.left.and.bubble.right.fill",
                color: "#FF6B6B"
            ),
            BuiltInPreset(
                name: "Deep Work",
                description: "Block everything except essential apps",
                icon: "brain.head.profile",
                color: "#14CC8C"
            )
        ].filter { !existingNames.contains($0.name) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                headerSection

                // Authorization check
                if !blockingService.isAuthorized {
                    authorizationCard
                } else {
                    // Built-in presets (if not created)
                    if !builtInPresets.isEmpty {
                        builtInPresetsSection
                    }

                    // User presets
                    if !presets.isEmpty {
                        userPresetsSection
                    }

                    // Create custom button
                    createCustomButton
                }

                // Bottom padding
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.top, Theme.Spacing.md)
        }
        .sheet(isPresented: $showCreateSheet) {
            PresetCreationSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingPreset) { preset in
            PresetCreationSheet(editingPreset: preset)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .familyActivityPicker(
            isPresented: $showAppPicker,
            selection: Bindable(blockingService).selectedAppsToBlock
        )
        .onChange(of: blockingService.selectedAppsToBlock) { _, newSelection in
            if let preset = selectedPreset {
                saveSelectionToPreset(preset, selection: newSelection)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Block Presets")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text("Quick profiles for different focus scenarios")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Authorization Card

    private var authorizationCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.warning)

            Text("Screen Time Access Required")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Text("Enable Screen Time access to use app blocking presets")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    try? await blockingService.requestAuthorizationIfNeeded()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                    Text("Enable Access")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background {
                    Capsule()
                        .fill(Theme.Colors.aiAmber)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Built-in Presets

    private var builtInPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 10) {
                ForEach(builtInPresets, id: \.name) { preset in
                    BuiltInPresetCard(preset: preset) {
                        createPresetFromBuiltIn(preset)
                    }
                }
            }
        }
    }

    // MARK: - User Presets

    private var userPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Presets")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 10) {
                ForEach(presets) { preset in
                    PresetCard(
                        preset: preset,
                        onApply: {
                            applyPreset(preset)
                        },
                        onEdit: {
                            editingPreset = preset
                        },
                        onConfigureApps: {
                            selectedPreset = preset
                            loadPresetSelection(preset)
                            showAppPicker = true
                        },
                        onDelete: {
                            deletePreset(preset)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Create Custom Button

    private var createCustomButton: some View {
        Button {
            HapticsService.shared.impact()
            showCreateSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiAmber.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.Colors.aiAmber)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Custom Preset")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Build your own app blocking profile")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.Colors.aiAmber.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func createPresetFromBuiltIn(_ builtIn: BuiltInPreset) {
        let preset = FocusBlockList(
            name: builtIn.name,
            description: builtIn.description,
            iconName: builtIn.icon,
            colorHex: builtIn.color,
            isDefault: false,
            isAllowList: builtIn.name == "Deep Work"
        )
        modelContext.insert(preset)
        try? modelContext.save()

        // Show app picker immediately
        selectedPreset = preset
        showAppPicker = true

        HapticsService.shared.success()
    }

    private func applyPreset(_ preset: FocusBlockList) {
        if let data = preset.selectionData,
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            blockingService.updateSelection(selection)
            preset.markAsUsed()
            try? modelContext.save()
            HapticsService.shared.success()
        }
    }

    private func loadPresetSelection(_ preset: FocusBlockList) {
        if let data = preset.selectionData,
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            blockingService.selectedAppsToBlock = selection
        } else {
            blockingService.selectedAppsToBlock = FamilyActivitySelection()
        }
    }

    private func saveSelectionToPreset(_ preset: FocusBlockList, selection: FamilyActivitySelection) {
        if let data = try? PropertyListEncoder().encode(selection) {
            preset.updateSelection(data)
            try? modelContext.save()
        }
    }

    private func deletePreset(_ preset: FocusBlockList) {
        modelContext.delete(preset)
        try? modelContext.save()
        HapticsService.shared.impact()
    }
}

// MARK: - Built-in Preset Model

struct BuiltInPreset {
    let name: String
    let description: String
    let icon: String
    let color: String
}

// MARK: - Built-in Preset Card

struct BuiltInPresetCard: View {
    let preset: BuiltInPreset
    let onCreate: () -> Void

    private var presetColor: Color {
        Color(hex: preset.color)
    }

    var body: some View {
        Button(action: onCreate) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    SwiftUI.Circle()
                        .fill(presetColor.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: preset.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(presetColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(preset.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                // Add button
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(presetColor)
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preset Card

struct PresetCard: View {
    let preset: FocusBlockList
    let onApply: () -> Void
    let onEdit: () -> Void
    let onConfigureApps: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    private var presetColor: Color {
        Color(hex: preset.colorHex)
    }

    private var hasAppsConfigured: Bool {
        preset.selectionData != nil
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    SwiftUI.Circle()
                        .fill(presetColor.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: preset.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(presetColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(preset.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)

                        if preset.isAllowList {
                            Text("Allow List")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(presetColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule()
                                        .fill(presetColor.opacity(0.2))
                                }
                        }
                    }

                    if let description = preset.listDescription {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Use count
                if preset.useCount > 0 {
                    Text("Used \(preset.useCount)x")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Action buttons
            HStack(spacing: 8) {
                // Configure apps button
                Button {
                    HapticsService.shared.selectionFeedback()
                    onConfigureApps()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: hasAppsConfigured ? "checkmark.circle.fill" : "app.badge.fill")
                            .font(.system(size: 12))
                        Text(hasAppsConfigured ? "Apps Set" : "Select Apps")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(hasAppsConfigured ? Theme.Colors.success : .white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(hasAppsConfigured ? Theme.Colors.success.opacity(0.15) : .white.opacity(0.1))
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Delete
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.error.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background {
                            SwiftUI.Circle()
                                .fill(Theme.Colors.error.opacity(0.1))
                        }
                }
                .buttonStyle(.plain)

                // Apply button
                Button {
                    HapticsService.shared.impact()
                    onApply()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Apply")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(presetColor)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!hasAppsConfigured)
                .opacity(hasAppsConfigured ? 1 : 0.5)
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .confirmationDialog("Delete Preset?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete \"\(preset.name)\"")
        }
    }
}

// MARK: - Preset Creation Sheet

struct PresetCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var editingPreset: FocusBlockList?

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedIcon: String = "shield.lefthalf.filled"
    @State private var selectedColor: String = "#9440FA"
    @State private var isAllowList: Bool = false

    private let iconOptions = [
        "shield.lefthalf.filled",
        "briefcase.fill",
        "brain.head.profile",
        "bubble.left.and.bubble.right.fill",
        "gamecontroller.fill",
        "film.fill",
        "book.fill",
        "graduationcap.fill",
        "heart.fill",
        "moon.fill"
    ]

    private let colorOptions = [
        "#9440FA",  // Purple
        "#6B73F9",  // Indigo
        "#14CC8C",  // Green
        "#FF6B6B",  // Red
        "#F59E0B",  // Amber
        "#3B82F6",  // Blue
        "#EC4899",  // Pink
        "#10B981"   // Teal
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        TextField("e.g., Study Mode", text: $name)
                            .font(.system(size: 16))
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            }
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        TextField("What this preset blocks", text: $description)
                            .font(.system(size: 16))
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            }
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Icon Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    HapticsService.shared.selectionFeedback()
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(selectedIcon == icon ? .white : .white.opacity(0.5))
                                        .frame(width: 48, height: 48)
                                        .background {
                                            SwiftUI.Circle()
                                                .fill(selectedIcon == icon ? Color(hex: selectedColor) : .white.opacity(0.1))
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Color Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        HStack(spacing: 12) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button {
                                    HapticsService.shared.selectionFeedback()
                                    selectedColor = color
                                } label: {
                                    ZStack {
                                        SwiftUI.Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 36, height: 36)

                                        if selectedColor == color {
                                            SwiftUI.Circle()
                                                .stroke(.white, lineWidth: 3)
                                                .frame(width: 36, height: 36)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Allow List Toggle
                    Toggle(isOn: $isAllowList) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Allow List Mode")
                                .font(.system(size: 16, weight: .medium))
                            Text("Block everything EXCEPT selected apps")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.aiAmber))

                    Spacer()
                        .frame(height: 40)
                }
                .padding(Theme.Spacing.screenPadding)
            }
            .background(VoidBackground.focus)
            .navigationTitle(editingPreset != nil ? "Edit Preset" : "New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreset()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            if let preset = editingPreset {
                name = preset.name
                description = preset.listDescription ?? ""
                selectedIcon = preset.iconName
                selectedColor = preset.colorHex
                isAllowList = preset.isAllowList
            }
        }
    }

    private func savePreset() {
        if let preset = editingPreset {
            preset.name = name
            preset.listDescription = description.isEmpty ? nil : description
            preset.iconName = selectedIcon
            preset.colorHex = selectedColor
            preset.isAllowList = isAllowList
            preset.updatedAt = Date()
        } else {
            let preset = FocusBlockList(
                name: name,
                description: description.isEmpty ? nil : description,
                iconName: selectedIcon,
                colorHex: selectedColor,
                isDefault: false,
                isAllowList: isAllowList
            )
            modelContext.insert(preset)
        }

        try? modelContext.save()
        HapticsService.shared.success()
    }
}

// MARK: - Preview

#Preview {
    FocusPresetsView()
        .preferredColorScheme(.dark)
}
