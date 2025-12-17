//
//  FocusAreasView.swift
//  MyTasksAI
//
//  Focus Areas Onboarding Step
//  Select categories for task organization
//

import SwiftUI

// MARK: - Focus Areas View
struct FocusAreasView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showContent = false

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                headerSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Selection count
                selectionCount
                    .opacity(showContent ? 1 : 0)

                // Focus area grid
                LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                    ForEach(Array(FocusArea.allCases.enumerated()), id: \.element.id) { index, area in
                        FocusAreaCard(
                            area: area,
                            isSelected: viewModel.selectedFocusAreas.contains(area),
                            onTap: { toggleArea(area) }
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : CGFloat(20 + index * 5))
                        .animation(Theme.Animation.spring.delay(Double(index) * 0.05), value: showContent)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(Theme.Spacing.lg)
        }
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(Theme.Colors.accent)

            Text("Focus Areas")
                .font(Theme.Typography.title1)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Select the areas you want to focus on. This helps organize your tasks.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Selection Count
    private var selectionCount: some View {
        HStack {
            Text("\(viewModel.selectedFocusAreas.count) selected")
                .font(Theme.Typography.headline)
                .foregroundStyle(viewModel.selectedFocusAreas.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.accent)

            if viewModel.selectedFocusAreas.isEmpty {
                Text("• Select at least one")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.warning)
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
}

// MARK: - Focus Area Card
struct FocusAreaCard: View {
    let area: FocusArea
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? area.color.opacity(0.2) : Theme.Colors.glassBackground)
                        .frame(width: 60, height: 60)

                    Image(systemName: area.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(isSelected ? area.color : Theme.Colors.textSecondary)
                }

                // Name
                Text(area.displayName)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.lg)
            .background(
                isSelected ?
                area.color.opacity(0.1) :
                Theme.Colors.glassBackground.opacity(0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(isSelected ? area.color.opacity(0.5) : Theme.Colors.glassBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? area.color.opacity(0.2) : Color.clear,
                radius: 8,
                y: 4
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(Theme.Animation.quickSpring, value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    FocusAreasView(viewModel: OnboardingViewModel())
        .iridescentBackground()
}
