//
//  CosmicGoalSetupPage.swift
//  Veloce
//
//  Cosmic Goal Setup - Set Your First Goal
//  Interactive goal wizard with category selection, AI enhancement, and visualization
//

import SwiftUI

struct CosmicGoalSetupPage: View {
    @Bindable var viewModel: CosmicOnboardingViewModel
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showCategories = false
    @State private var showInput = false
    @State private var showDuration = false
    @State private var showAISection = false
    @State private var starConstellation: [CGPoint] = []
    @State private var constellationOpacity: Double = 0
    @FocusState private var isInputFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer(minLength: Theme.Spacing.xl)

                    // Header
                    headerSection
                        .padding(.horizontal, Theme.Spacing.lg)

                    // Category selection
                    categorySection
                        .padding(.horizontal, Theme.Spacing.lg)

                    // Goal input
                    if viewModel.selectedCategory != nil {
                        goalInputSection
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Duration selector
                    if !viewModel.goalDescription.isEmpty || viewModel.selectedCategory != nil {
                        durationSection
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // AI Enhancement section
                    if viewModel.aiEnhancedGoal != nil {
                        aiEnhancementSection
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Goal visualization (constellation)
                    if viewModel.selectedCategory != nil {
                        goalVisualization(in: geometry)
                            .frame(height: 200)
                    }

                    Spacer(minLength: 60)

                    // Continue button
                    continueButton
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl * 2)
                }
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
        .onAppear {
            startAnimations()
            generateConstellation()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("What do you want to achieve?")
                .font(.system(size: 28, weight: .thin, design: .default))
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .multilineTextAlignment(.center)

            Text("Set your first goal and let's make it happen")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("CHOOSE A CATEGORY")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .tracking(1.5)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.md) {
                ForEach(OnboardingGoalCategory.allCases) { category in
                    categoryButton(category)
                }
            }
        }
        .opacity(showCategories ? 1 : 0)
        .offset(y: showCategories ? 0 : 20)
    }

    private func categoryButton(_ category: OnboardingGoalCategory) -> some View {
        let isSelected = viewModel.selectedCategory == category

        return Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(LivingCosmos.Animations.spring) {
                viewModel.selectedCategory = category
                showInput = true
            }
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color.opacity(0.3) : Theme.CelestialColors.void.opacity(0.6))
                        .frame(width: 56, height: 56)

                    if isSelected {
                        Circle()
                            .stroke(category.color, lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }

                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isSelected ? category.color : Theme.CelestialColors.starDim)
                }

                Text(category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.CelestialColors.starWhite : Theme.CelestialColors.starDim)
            }
            .padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color.opacity(0.1) : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? category.color.opacity(0.4) : Theme.CelestialColors.starGhost.opacity(0.2),
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(LivingCosmos.Animations.spring, value: isSelected)
    }

    // MARK: - Goal Input Section

    private var goalInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("DESCRIBE YOUR GOAL")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .tracking(1.5)

            ZStack(alignment: .topLeading) {
                if viewModel.goalDescription.isEmpty {
                    Text("e.g., Learn Spanish, Run a marathon, Launch my startup...")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.CelestialColors.starGhost.opacity(0.6))
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.md + 2)
                }

                TextEditor(text: $viewModel.goalDescription)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.CelestialColors.starWhite)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.sm)
                    .focused($isInputFocused)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isInputFocused
                                    ? (viewModel.selectedCategory?.color ?? Theme.Colors.aiPurple)
                                    : Theme.CelestialColors.starGhost.opacity(0.3),
                                lineWidth: isInputFocused ? 2 : 1
                            )
                    }
            }

            // AI Enhance button
            if !viewModel.goalDescription.isEmpty && viewModel.aiEnhancedGoal == nil {
                Button {
                    HapticsService.shared.impact()
                    Task {
                        await viewModel.enhanceGoalWithAI()
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        if viewModel.isEnhancingGoal {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Theme.CelestialColors.plasmaCore)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 14, weight: .medium))
                        }

                        Text(viewModel.isEnhancingGoal ? "Enhancing..." : "Enhance with AI")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Theme.CelestialColors.plasmaCore)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background {
                        Capsule()
                            .fill(Theme.CelestialColors.plasmaCore.opacity(0.15))
                            .overlay {
                                Capsule()
                                    .stroke(Theme.CelestialColors.plasmaCore.opacity(0.4), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isEnhancingGoal)
            }
        }
        .opacity(showInput ? 1 : 0)
        .offset(y: showInput ? 0 : 20)
        .animation(LivingCosmos.Animations.spring, value: showInput)
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("TIMEFRAME")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .tracking(1.5)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(GoalDuration.allCases) { duration in
                    durationButton(duration)
                }
            }
        }
        .opacity(showDuration ? 1 : 0)
        .offset(y: showDuration ? 0 : 20)
        .animation(LivingCosmos.Animations.spring.delay(0.2), value: showDuration)
        .onAppear {
            withAnimation(LivingCosmos.Animations.spring.delay(0.3)) {
                showDuration = true
            }
        }
    }

    private func durationButton(_ duration: GoalDuration) -> some View {
        let isSelected = viewModel.selectedDuration == duration
        let color = viewModel.selectedCategory?.color ?? Theme.Colors.aiPurple

        return Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(LivingCosmos.Animations.spring) {
                viewModel.selectedDuration = duration
            }
        } label: {
            Text(duration.shortLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starDim)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color : Theme.CelestialColors.void.opacity(0.6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? color : Theme.CelestialColors.starGhost.opacity(0.3),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        }
                }
                .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Enhancement Section

    private var aiEnhancementSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.CelestialColors.plasmaCore)

                Text("AI-ENHANCED GOAL")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
                    .tracking(1.5)
            }

            // Enhanced goal text
            Text(viewModel.aiEnhancedGoal ?? "")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.CelestialColors.plasmaCore.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.CelestialColors.plasmaCore.opacity(0.3), lineWidth: 1)
                        }
                }

            // Action items
            if !viewModel.generatedActionItems.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("First Steps")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    ForEach(viewModel.generatedActionItems, id: \.self) { item in
                        HStack(spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(Theme.CelestialColors.auroraGreen)
                                .frame(width: 6, height: 6)

                            Text(item)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.CelestialColors.starWhite)
                        }
                    }
                }
            }
        }
        .opacity(showAISection ? 1 : 0)
        .offset(y: showAISection ? 0 : 20)
        .onAppear {
            withAnimation(LivingCosmos.Animations.spring) {
                showAISection = true
            }
        }
    }

    // MARK: - Goal Visualization

    private func goalVisualization(in geometry: GeometryProxy) -> some View {
        let color = viewModel.selectedCategory?.color ?? Theme.Colors.aiPurple

        return ZStack {
            // Connection lines
            ForEach(0..<starConstellation.count, id: \.self) { i in
                if i < starConstellation.count - 1 {
                    Path { path in
                        path.move(to: starConstellation[i])
                        path.addLine(to: starConstellation[i + 1])
                    }
                    .stroke(color.opacity(0.3 * constellationOpacity), lineWidth: 1)
                }
            }

            // Stars
            ForEach(0..<starConstellation.count, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: i == 0 ? 12 : (i == starConstellation.count - 1 ? 16 : 8))
                    .position(starConstellation[i])
                    .opacity(constellationOpacity)
                    .shadow(color: color.opacity(0.5), radius: 8)
            }

            // Goal star (end point)
            if let last = starConstellation.last {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .blur(radius: 10)

                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.xp)
                }
                .position(last)
                .opacity(constellationOpacity)
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        let color = viewModel.selectedCategory?.color ?? Theme.Colors.aiPurple

        return Button {
            HapticsService.shared.impact()
            onContinue()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(
                        viewModel.canProceedFromGoal
                            ? LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Theme.CelestialColors.starGhost, Theme.CelestialColors.starGhost.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .shadow(color: viewModel.canProceedFromGoal ? color.opacity(0.4) : .clear, radius: 15, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canProceedFromGoal)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Animations

    private func startAnimations() {
        if reduceMotion {
            showContent = true
            showCategories = true
            constellationOpacity = 1
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showContent = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showCategories = true
        }

        withAnimation(.easeOut(duration: 1).delay(0.5)) {
            constellationOpacity = 1
        }
    }

    private func generateConstellation() {
        let height: CGFloat = 150

        starConstellation = [
            CGPoint(x: 50, y: height - 30),
            CGPoint(x: 100, y: height - 60),
            CGPoint(x: 150, y: height - 40),
            CGPoint(x: 200, y: height - 80),
            CGPoint(x: 250, y: height - 50),
            CGPoint(x: 300, y: height - 100)
        ]
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.onboarding
        CosmicGoalSetupPage(viewModel: CosmicOnboardingViewModel()) { }
    }
}
