//
//  AppPickerView.swift
//  Veloce
//
//  FamilyActivityPicker wrapper with Celestial Void aesthetic
//  Allows users to select apps/categories to block during focus sessions
//

import SwiftUI
import FamilyControls

// MARK: - App Picker View

/// Beautiful wrapper around FamilyActivityPicker with Celestial styling
struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: FamilyActivitySelection

    @State private var showingPicker = false
    @State private var focusBlockingService = FocusBlockingService.shared
    @State private var screenTimeAuthService = ScreenTimeAuthService.shared

    var body: some View {
        ZStack {
            // Deep void background
            Theme.CelestialColors.void
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Authorization status card
                        if !screenTimeAuthService.isAuthorized {
                            authorizationCard
                        }

                        // Selection summary card
                        selectionSummaryCard

                        // Select apps button
                        selectAppsButton

                        // Quick presets section
                        presetsSection

                        // Info card
                        infoCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .familyActivityPicker(
            isPresented: $showingPicker,
            selection: $selection
        )
        .onChange(of: selection) { _, newValue in
            focusBlockingService.updateSelection(newValue)
        }
    }

    // MARK: - Header (Liquid Glass)

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
            }
            .glassEffect(.regular, in: SwiftUI.Circle())

            Spacer()

            Text("Block Apps")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                focusBlockingService.saveSelection()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: Capsule())
        }
    }

    // MARK: - Authorization Card

    private var authorizationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 40))
                .foregroundStyle(Theme.CelestialColors.warningNebula)

            Text("Screen Time Access Required")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Text("To block apps during focus sessions, you need to grant Screen Time access.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    try? await screenTimeAuthService.requestAuthorization()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield")
                    Text("Grant Access")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Theme.CelestialColors.nebulaCore, Theme.CelestialColors.nebulaGlow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.abyss)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.CelestialColors.warningNebula.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Selection Summary (Liquid Glass)

    private var selectionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("Selected Apps")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
                    Button("Clear") {
                        selection = FamilyActivitySelection()
                        focusBlockingService.clearSelection()
                        HapticsService.shared.selectionFeedback()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.errorNebula)
                }
            }

            // Selection counts
            HStack(spacing: 12) {
                selectionBadge(
                    count: selection.applicationTokens.count,
                    label: "Apps",
                    icon: "app.fill",
                    color: Theme.CelestialColors.nebulaCore
                )

                selectionBadge(
                    count: selection.categoryTokens.count,
                    label: "Categories",
                    icon: "square.grid.2x2.fill",
                    color: Theme.CelestialColors.nebulaGlow
                )

                selectionBadge(
                    count: selection.webDomainTokens.count,
                    label: "Websites",
                    icon: "globe",
                    color: Theme.CelestialColors.nebulaEdge
                )
            }

            // Empty state
            if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("No apps selected")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            }
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    private func selectionBadge(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundStyle(count > 0 ? color : Theme.CelestialColors.starGhost)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Select Apps Button (Liquid Glass)

    private var selectAppsButton: some View {
        Button {
            guard screenTimeAuthService.isAuthorized else {
                Task {
                    try? await screenTimeAuthService.requestAuthorization()
                }
                return
            }
            showingPicker = true
            HapticsService.shared.impact()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.nebulaCore.opacity(0.2))
                        .frame(width: 42, height: 42)

                    Image(systemName: "plus.app.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Apps to Block")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Choose apps, categories, or websites")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .disabled(!screenTimeAuthService.isAuthorized)
        .opacity(screenTimeAuthService.isAuthorized ? 1 : 0.5)
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK PRESETS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .tracking(1)

            VStack(spacing: 10) {
                presetRow(
                    icon: "briefcase.fill",
                    title: "Work Mode",
                    subtitle: "Block social & entertainment",
                    color: Color(hex: "#6B73F9")
                )

                presetRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Social Media Detox",
                    subtitle: "Block all social apps",
                    color: Color(hex: "#FF6B6B")
                )

                presetRow(
                    icon: "brain.head.profile",
                    title: "Deep Work",
                    subtitle: "Allow only essential apps",
                    color: Color(hex: "#14CC8C")
                )
            }
        }
    }

    private func presetRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        Button {
            // Load preset (in future, this would load saved selection)
            showingPicker = true
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(12)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        .disabled(!screenTimeAuthService.isAuthorized)
        .opacity(screenTimeAuthService.isAuthorized ? 1 : 0.5)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.CelestialColors.nebulaEdge)

            VStack(alignment: .leading, spacing: 4) {
                Text("How it works")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Selected apps will be blocked during your focus sessions. You can always edit this list later.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.CelestialColors.nebulaEdge.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    AppPickerView(selection: .constant(FamilyActivitySelection()))
}
