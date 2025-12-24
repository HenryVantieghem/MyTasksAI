//
//  FocusAreasView.swift
//  MyTasksAI
//
//  Focus Areas Onboarding Step - Aurora Design System
//  Celestial cosmic design with constellation-style selection
//

import SwiftUI

// MARK: - Focus Areas View

struct FocusAreasView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var cardAppearance: [Bool] = Array(repeating: false, count: 12)
    @State private var iconPulse: CGFloat = 1.0

    private let columns = [
        GridItem(.flexible(), spacing: Aurora.Layout.spacing),
        GridItem(.flexible(), spacing: Aurora.Layout.spacing)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Aurora.Layout.spacingXL) {
                // Enhanced header
                enhancedHeaderSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Enhanced selection count
                enhancedSelectionCount
                    .opacity(showContent ? 1 : 0)

                // Focus area grid with staggered animation
                LazyVGrid(columns: columns, spacing: Aurora.Layout.spacing) {
                    ForEach(Array(FocusArea.allCases.enumerated()), id: \.element.id) { index, area in
                        EnhancedFocusAreaCard(
                            area: area,
                            isSelected: viewModel.selectedFocusAreas.contains(area),
                            onTap: { toggleArea(area) }
                        )
                        .opacity(index < cardAppearance.count && cardAppearance[index] ? 1 : 0)
                        .offset(y: index < cardAppearance.count && cardAppearance[index] ? 0 : 30)
                        .scaleEffect(index < cardAppearance.count && cardAppearance[index] ? 1 : 0.9)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(Aurora.Layout.screenPadding)
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Enhanced Header Section

    private var enhancedHeaderSection: some View {
        VStack(spacing: Aurora.Layout.spacing) {
            // Animated icon
            ZStack {
                // Glow
                SwiftUI.Circle()
                    .fill(Aurora.Colors.violet.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .blur(radius: 20)
                    .scaleEffect(iconPulse)

                SwiftUI.Circle()
                    .fill(Aurora.Colors.cosmicElevated)
                    .frame(width: 80, height: 80)

                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Aurora.Colors.violet, Aurora.Colors.electric],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Focus Areas")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Aurora.Colors.textPrimary)

            Text("Select what you want to focus on.\nThis helps organize your tasks.")
                .font(.system(size: 16))
                .foregroundStyle(Aurora.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Enhanced Selection Count

    private var enhancedSelectionCount: some View {
        HStack(spacing: Aurora.Layout.spacingSmall) {
            // Selection badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                Text("\(viewModel.selectedFocusAreas.count) selected")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(viewModel.selectedFocusAreas.isEmpty ? Aurora.Colors.textTertiary : Aurora.Colors.success)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(viewModel.selectedFocusAreas.isEmpty ? Aurora.Colors.glassBorder.opacity(0.3) : Aurora.Colors.success.opacity(0.15))
            )

            if viewModel.selectedFocusAreas.isEmpty {
                Text("Select at least one")
                    .font(.system(size: 13))
                    .foregroundStyle(Aurora.Colors.warning)
            }

            Spacer()
        }
    }

    // MARK: - Helper

    private func toggleArea(_ area: FocusArea) {
        if viewModel.selectedFocusAreas.contains(area) {
            viewModel.selectedFocusAreas.remove(area)
        } else {
            viewModel.selectedFocusAreas.insert(area)
        }
        HapticsService.shared.selectionFeedback()
    }

    private func startAnimations() {
        // Header fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            showContent = true
        }

        // Icon pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            iconPulse = 1.1
        }

        // Staggered card appearance
        let areaCount = FocusArea.allCases.count
        for index in 0..<min(areaCount, cardAppearance.count) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(index) * 0.06) {
                withAnimation(Aurora.Animation.spring) {
                    cardAppearance[index] = true
                }
            }
        }
    }
}

// MARK: - Enhanced Focus Area Card

struct EnhancedFocusAreaCard: View {
    let area: FocusArea
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: Aurora.Layout.spacingSmall) {
                // Icon with glow
                ZStack {
                    if isSelected {
                        SwiftUI.Circle()
                            .fill(area.color.opacity(0.2))
                            .frame(width: 70, height: 70)
                            .blur(radius: 10)
                    }

                    SwiftUI.Circle()
                        .fill(isSelected ? area.color.opacity(0.2) : Aurora.Colors.cosmicElevated)
                        .frame(width: 56, height: 56)

                    Image(systemName: area.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isSelected ? area.color : Aurora.Colors.textSecondary)
                }

                // Name
                Text(area.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Aurora.Colors.textPrimary : Aurora.Colors.textSecondary)

                // Selected indicator
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Selected")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(area.color)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: isSelected ? 140 : 120)
            .padding(Aurora.Layout.spacing)
            .background(
                RoundedRectangle(cornerRadius: Aurora.Radius.xl)
                    .fill(Aurora.Colors.cosmicSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Aurora.Radius.xl)
                            .stroke(
                                isSelected ? area.color.opacity(0.6) : Aurora.Colors.glassBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? area.color.opacity(0.25) : Color.clear,
                radius: 12,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(Aurora.Animation.spring, value: isSelected)
    }
}

// MARK: - Legacy Focus Area Card

struct FocusAreaCard: View {
    let area: FocusArea
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: Aurora.Layout.spacingSmall) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(isSelected ? area.color.opacity(0.2) : Aurora.Colors.glassBase)
                        .frame(width: 60, height: 60)

                    Image(systemName: area.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(isSelected ? area.color : Aurora.Colors.textSecondary)
                }

                Text(area.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? Aurora.Colors.textPrimary : Aurora.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Aurora.Layout.spacingLarge)
            .background(
                isSelected ?
                area.color.opacity(0.1) :
                Aurora.Colors.glassBase.opacity(0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Aurora.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Aurora.Radius.card)
                    .stroke(isSelected ? area.color.opacity(0.5) : Aurora.Colors.glassBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? area.color.opacity(0.2) : Color.clear,
                radius: 8,
                y: 4
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(Aurora.Animation.spring, value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    FocusAreasView(viewModel: OnboardingViewModel())
        .background(AuroraBackground.onboardingStep)
}
