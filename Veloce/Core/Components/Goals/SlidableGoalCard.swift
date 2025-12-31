//
//  SlidableGoalCard.swift
//  Veloce
//
//  Premium Slidable Goal Card with AI Integration
//  Ultra-premium design with swipe actions and AI generation status
//

import SwiftUI

// MARK: - Slidable Goal Card

struct SlidableGoalCard: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    var onTap: () -> Void
    var onGenerateAI: (() -> Void)?
    var onCheckIn: (() -> Void)?
    var onDelete: (() -> Void)?

    // MARK: - State
    @State private var offset: CGFloat = 0
    @State private var isPressed = false
    @State private var showActions = false
    @State private var glowIntensity: Double = 0.6
    @State private var aiPulse: Double = 0
    @State private var progressAnimated: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Swipe thresholds
    private let actionThreshold: CGFloat = 80
    private let maxOffset: CGFloat = 180

    // MARK: - AI State
    private var isGenerating: Bool {
        goalsVM.isRefiningGoal || goalsVM.isGeneratingRoadmap
    }

    private var hasError: Bool {
        goalsVM.error != nil && !goalsVM.hasAIContent(goal)
    }

    var body: some View {
        ZStack {
            // Swipe action background
            swipeActionsBackground

            // Main card
            mainCard
                .offset(x: offset)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Main Card

    private var mainCard: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Top section with status orb and info
                HStack(spacing: 16) {
                    // Animated status orb
                    statusOrb

                    // Goal info
                    VStack(alignment: .leading, spacing: 6) {
                        // Title
                        Text(goal.displayTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        // Metadata row
                        HStack(spacing: 10) {
                            if let timeframe = goal.timeframeEnum {
                                timeframeBadge(timeframe)
                            }

                            if let category = goal.categoryEnum {
                                categoryPill(category)
                            }

                            Spacer()

                            if let days = goal.daysRemaining {
                                daysIndicator(days)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Progress section
                progressSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // AI Status Banner (if generating or error)
                if isGenerating || hasError || !goalsVM.hasAIContent(goal) {
                    aiStatusBanner
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                // Quick insights row (if AI content exists)
                if let quote = goal.aiMotivationalQuote, goalsVM.hasAIContent(goal) {
                    quickInsightsRow(quote: quote)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .background(cardBackground)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(pressGesture)
    }

    // MARK: - Status Orb

    private var statusOrb: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(
                    RadialGradient(
                        colors: [
                            goal.themeColor.opacity(0.6 * glowIntensity),
                            goal.themeColor.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 50
                    ),
                    lineWidth: 3
                )
                .frame(width: 72, height: 72)

            // Progress ring
            Circle()
                .trim(from: 0, to: progressAnimated)
                .stroke(
                    LinearGradient(
                        colors: [goal.themeColor, goal.themeColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 2) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: goal.themeColor))
                        .scaleEffect(0.9)
                } else {
                    Text("\(Int(goal.progress * 100))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("%")
                        .dynamicTypeFont(base: 10, weight: .medium)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // AI sparkle indicator
            if goalsVM.hasAIContent(goal) {
                Image(systemName: "sparkle")
                    .dynamicTypeFont(base: 10, weight: .semibold)
                    .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple)
                    .offset(x: 24, y: -24)
                    .scaleEffect(1 + aiPulse * 0.2)
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 10) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [goal.themeColor, goal.themeColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressAnimated)
                        .shadow(color: goal.themeColor.opacity(0.5), radius: 8)

                    // Shine effect
                    if progressAnimated > 0.1 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.3), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 40)
                            .offset(x: geometry.size.width * progressAnimated - 50)
                            .blur(radius: 2)
                    }
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())

            // Milestone info
            if goal.milestoneCount > 0 {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered")
                            .dynamicTypeFont(base: 10)
                        Text("\(goal.completedMilestoneCount)/\(goal.milestoneCount) milestones")
                            .dynamicTypeFont(base: 11, weight: .medium)
                    }
                    .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    if goal.isCheckInDue {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(LiquidGlassDesignSystem.VibrantAccents.solarGold)
                                .frame(width: 6, height: 6)
                            Text("Check-in due")
                                .dynamicTypeFont(base: 11, weight: .medium)
                        }
                        .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.solarGold)
                    }
                }
            }
        }
    }

    // MARK: - AI Status Banner

    private var aiStatusBanner: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(aiStatusColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: aiStatusColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: aiStatusIcon)
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(aiStatusColor)
                }
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(aiStatusTitle)
                    .dynamicTypeFont(base: 13, weight: .semibold)
                    .foregroundStyle(.white)

                Text(aiStatusSubtitle)
                    .dynamicTypeFont(base: 11)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            // Action button
            if !isGenerating {
                Button {
                    onGenerateAI?()
                } label: {
                    Text(hasError ? "Retry" : "Generate")
                        .dynamicTypeFont(base: 12, weight: .semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(aiStatusColor)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(aiStatusColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(aiStatusColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var aiStatusColor: Color {
        if isGenerating {
            return LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
        } else if hasError {
            return LiquidGlassDesignSystem.VibrantAccents.solarGold
        } else {
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        }
    }

    private var aiStatusIcon: String {
        if hasError {
            return "exclamationmark.triangle"
        } else {
            return "sparkles"
        }
    }

    private var aiStatusTitle: String {
        if isGenerating {
            return "Generating AI Roadmap..."
        } else if hasError {
            return "Generation Failed"
        } else {
            return "Unlock AI Insights"
        }
    }

    private var aiStatusSubtitle: String {
        if isGenerating {
            return "Creating your personalized plan"
        } else if hasError {
            return goalsVM.error ?? "Please try again"
        } else {
            return "Get SMART analysis & milestones"
        }
    }

    // MARK: - Quick Insights Row

    private func quickInsightsRow(quote: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.opening")
                .dynamicTypeFont(base: 12)
                .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.6))

            Text(quote)
                .font(.system(size: 13, design: .serif).italic())
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.03))
        )
    }

    // MARK: - Badges & Pills

    private func timeframeBadge(_ timeframe: GoalTimeframe) -> some View {
        HStack(spacing: 4) {
            Image(systemName: timeframe.icon)
                .dynamicTypeFont(base: 9, weight: .semibold)
            Text(timeframe.displayName)
                .dynamicTypeFont(base: 10, weight: .semibold)
        }
        .foregroundStyle(timeframe.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(timeframe.color.opacity(0.12))
        )
    }

    private func categoryPill(_ category: GoalCategory) -> some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .dynamicTypeFont(base: 9)
            Text(category.displayName)
                .dynamicTypeFont(base: 10, weight: .medium)
        }
        .foregroundStyle(category.color.opacity(0.8))
    }

    private func daysIndicator(_ days: Int) -> some View {
        let isUrgent = days <= 3 && days >= 0
        let isOverdue = days < 0
        let color: Color = isOverdue ? Theme.Colors.error : (isUrgent ? LiquidGlassDesignSystem.VibrantAccents.solarGold : .white.opacity(0.5))

        return HStack(spacing: 4) {
            if isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .dynamicTypeFont(base: 9)
            }
            Text(isOverdue ? "Overdue" : (days == 0 ? "Today" : "\(days)d left"))
                .font(.system(size: 11, weight: isUrgent ? .semibold : .medium))
        }
        .foregroundStyle(color)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial.opacity(0.5))
            .overlay {
                // Gradient glow
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                goal.themeColor.opacity(0.12 * glowIntensity),
                                .clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
            }
            .overlay {
                // Border
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                goal.themeColor.opacity(0.4),
                                .white.opacity(0.08),
                                goal.themeColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: goal.themeColor.opacity(0.15 * glowIntensity), radius: 20, y: 8)
    }

    // MARK: - Swipe Actions Background

    private var swipeActionsBackground: some View {
        HStack(spacing: 0) {
            Spacer()

            HStack(spacing: 12) {
                // AI Generate action
                if !goalsVM.hasAIContent(goal) && goalsVM.isAIAvailable {
                    swipeActionButton(
                        icon: "sparkles",
                        label: "AI",
                        color: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                        action: { onGenerateAI?() }
                    )
                }

                // Check-in action
                if goal.isCheckInDue {
                    swipeActionButton(
                        icon: "bell.badge",
                        label: "Check-in",
                        color: LiquidGlassDesignSystem.VibrantAccents.solarGold,
                        action: { onCheckIn?() }
                    )
                }

                // Delete action
                swipeActionButton(
                    icon: "trash",
                    label: "Delete",
                    color: Theme.Colors.error,
                    action: { onDelete?() }
                )
            }
            .padding(.trailing, 16)
            .opacity(showActions ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.CelestialColors.voidDeep)
        )
    }

    private func swipeActionButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = 0
                showActions = false
            }
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .dynamicTypeFont(base: 18)
                        .foregroundStyle(color)
                }

                Text(label)
                    .dynamicTypeFont(base: 10, weight: .medium)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gestures

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let translation = value.translation.width

                // Only allow left swipe
                if translation < 0 {
                    offset = max(translation, -maxOffset)
                    showActions = abs(offset) > actionThreshold
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if abs(offset) > actionThreshold {
                        // Snap to show actions
                        offset = -maxOffset
                        showActions = true
                    } else {
                        // Snap back
                        offset = 0
                        showActions = false
                    }
                }
            }
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if offset == 0 {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Animate progress
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            progressAnimated = goal.progress
        }

        guard !reduceMotion else { return }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }

        // AI sparkle pulse
        if goalsVM.hasAIContent(goal) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                aiPulse = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("Slidable Goal Card") {
    ScrollView {
        VStack(spacing: 20) {
            let goal = Goal(
                title: "Get money",
                goalDescription: "Build wealth and financial freedom",
                targetDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                category: GoalCategory.financial.rawValue,
                timeframe: GoalTimeframe.milestone.rawValue
            )

            let vm = GoalsViewModel()

            SlidableGoalCard(
                goal: goal,
                goalsVM: vm,
                onTap: { print("Tapped") },
                onGenerateAI: { print("Generate AI") },
                onCheckIn: { print("Check in") },
                onDelete: { print("Delete") }
            )
        }
        .padding(20)
    }
    .background(Theme.CelestialColors.void)
}
