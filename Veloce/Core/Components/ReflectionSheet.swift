//
//  ReflectionSheet.swift
//  Veloce
//
//  Post-task completion reflection for learning and AI improvement
//  Captures user insights to build a feedback loop
//

import SwiftUI

struct ReflectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let taskTitle: String
    let estimatedMinutes: Int?
    let onSave: (TaskReflection) -> Void
    let onSkip: () -> Void

    @State private var difficultyRating: Int = 3
    @State private var wasEstimateAccurate: Bool? = nil
    @State private var actualMinutes: String = ""
    @State private var learnings: String = ""
    @State private var aiSuggestedTips: [String] = []
    @State private var selectedTips: Set<String> = []
    @State private var customTip: String = ""

    @State private var currentStep: ReflectionStep = .difficulty
    @State private var isLoading: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)

                    // Content
                    TabView(selection: $currentStep) {
                        difficultyStep
                            .tag(ReflectionStep.difficulty)

                        accuracyStep
                            .tag(ReflectionStep.accuracy)

                        learningsStep
                            .tag(ReflectionStep.learnings)

                        tipsStep
                            .tag(ReflectionStep.tips)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)

                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                }
            }
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onSkip()
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.tertiaryText)
                }
            }
            .onAppear {
                loadAISuggestions()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(ReflectionStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue
                          ? Theme.Colors.accent
                          : Theme.Colors.glassBackground.opacity(0.5))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step 1: Difficulty Rating

    private var difficultyStep: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Celebration icon
            Image(systemName: "checkmark.circle.fill")
                .dynamicTypeFont(base: 60)
                .foregroundStyle(Theme.Colors.success)
                .symbolEffect(.bounce, value: appeared)

            Text("Task Completed!")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.primaryText)

            Text("How difficult was this task?")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.secondaryText)

            // Star rating
            HStack(spacing: Theme.Spacing.md) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            difficultyRating = rating
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Image(systemName: rating <= difficultyRating ? "star.fill" : "star")
                            .dynamicTypeFont(base: 36)
                            .foregroundStyle(rating <= difficultyRating
                                             ? Theme.Colors.warning
                                             : Theme.Colors.tertiaryText)
                            .scaleEffect(rating == difficultyRating ? 1.2 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(difficultyLabel)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.tertiaryText)

            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    private var difficultyLabel: String {
        switch difficultyRating {
        case 1: return "Very Easy"
        case 2: return "Easy"
        case 3: return "Moderate"
        case 4: return "Challenging"
        case 5: return "Very Difficult"
        default: return ""
        }
    }

    // MARK: - Step 2: Estimate Accuracy

    private var accuracyStep: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            if let estimated = estimatedMinutes {
                VStack(spacing: Theme.Spacing.sm) {
                    Text("AI estimated")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)

                    Text(estimated.formattedDuration)
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundStyle(Theme.Colors.accent)
                }

                Text("Was this estimate accurate?")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)

                HStack(spacing: Theme.Spacing.lg) {
                    accuracyButton(true, label: "Yes", icon: "checkmark.circle.fill", color: Theme.Colors.success)
                    accuracyButton(false, label: "No", icon: "xmark.circle.fill", color: Theme.Colors.error)
                }

                // Actual time input (if not accurate)
                if wasEstimateAccurate == false {
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("How long did it actually take?")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)

                        HStack {
                            TextField("Minutes", text: $actualMinutes)
                                .keyboardType(.numberPad)
                                .font(Theme.Typography.title3)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .padding(Theme.Spacing.sm)
                                .background {
                                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                                        .fill(Theme.Colors.glassBackground.opacity(0.5))
                                }

                            Text("minutes")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.secondaryText)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            } else {
                Text("No time estimate was set")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: wasEstimateAccurate)
    }

    private func accuracyButton(_ isAccurate: Bool, label: String, icon: String, color: Color) -> some View {
        Button {
            withAnimation {
                wasEstimateAccurate = isAccurate
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 36)
                    .foregroundStyle(wasEstimateAccurate == isAccurate ? color : Theme.Colors.tertiaryText)

                Text(label)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(wasEstimateAccurate == isAccurate ? color : Theme.Colors.secondaryText)
            }
            .frame(width: 100, height: 100)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(wasEstimateAccurate == isAccurate
                          ? color.opacity(0.1)
                          : Theme.Colors.glassBackground.opacity(0.3))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .strokeBorder(wasEstimateAccurate == isAccurate
                                          ? color.opacity(0.3)
                                          : Theme.Colors.glassBorder.opacity(0.2))
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Learnings

    private var learningsStep: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .dynamicTypeFont(base: 36)
                    .foregroundStyle(Theme.Colors.warning)

                Text("What did you learn?")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)

                Text("Optional - helps improve future suggestions")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
            .padding(.top, Theme.Spacing.lg)

            ZStack(alignment: .topLeading) {
                if learnings.isEmpty {
                    Text("e.g., \"Should have started with research first\" or \"Breaking it into smaller chunks helped\"...")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.tertiaryText.opacity(0.5))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $learnings)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Theme.Colors.glassBackground.opacity(0.3))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .strokeBorder(Theme.Colors.glassBorder.opacity(0.2))
                    }
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Step 4: Tips for Next Time

    private var tipsStep: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .dynamicTypeFont(base: 36)
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("Tips for next time")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)

                Text("AI suggestions based on your reflection")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }

            if isLoading {
                ProgressView()
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(aiSuggestedTips, id: \.self) { tip in
                            tipRow(tip)
                        }

                        // Add custom tip
                        customTipInput
                    }
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    private func tipRow(_ tip: String) -> some View {
        Button {
            withAnimation {
                if selectedTips.contains(tip) {
                    selectedTips.remove(tip)
                } else {
                    selectedTips.insert(tip)
                }
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: selectedTips.contains(tip) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedTips.contains(tip)
                                     ? Theme.Colors.success
                                     : Theme.Colors.tertiaryText)

                Text(tip)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(selectedTips.contains(tip)
                          ? Theme.Colors.success.opacity(0.1)
                          : Theme.Colors.glassBackground.opacity(0.3))
            }
        }
        .buttonStyle(.plain)
    }

    private var customTipInput: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "plus.circle")
                .foregroundStyle(Theme.Colors.accent)

            TextField("Add your own tip...", text: $customTip)
                .font(Theme.Typography.subheadline)
                .onSubmit {
                    addCustomTip()
                }

            if !customTip.isEmpty {
                Button {
                    addCustomTip()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            if currentStep != .difficulty {
                Button {
                    withAnimation {
                        currentStep = currentStep.previous
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(Theme.Typography.subheadline)
                }
                .buttonStyle(.glass)
            }

            Spacer()

            if currentStep == .tips {
                Button {
                    saveReflection()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Save")
                    }
                    .font(Theme.Typography.headline)
                }
                .buttonStyle(.glassProminent)
            } else {
                Button {
                    withAnimation {
                        currentStep = currentStep.next
                    }
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(Theme.Typography.headline)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }

    // MARK: - Actions

    private func loadAISuggestions() {
        isLoading = true

        // Simulate AI generating tips
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            aiSuggestedTips = generateLocalTips()
            isLoading = false
        }
    }

    private func generateLocalTips() -> [String] {
        var tips: [String] = []

        // Based on difficulty
        if difficultyRating >= 4 {
            tips.append("Break this type of task into smaller sub-tasks next time")
            tips.append("Consider scheduling more buffer time for challenging tasks")
        } else if difficultyRating <= 2 {
            tips.append("You handled this well - trust your process")
        }

        // Based on accuracy
        if wasEstimateAccurate == false {
            tips.append("Track actual time more often to improve estimates")
        }

        // General tips
        tips.append("Review your approach before starting similar tasks")
        tips.append("Use the Pomodoro technique for better focus")

        return tips
    }

    private func addCustomTip() {
        guard !customTip.isEmpty else { return }
        aiSuggestedTips.append(customTip)
        selectedTips.insert(customTip)
        customTip = ""
    }

    private func saveReflection() {
        let reflection = TaskReflection(
            taskId: UUID(), // Will be set by parent
            difficultyRating: difficultyRating,
            wasEstimateAccurate: wasEstimateAccurate,
            learnings: learnings.isEmpty ? nil : learnings,
            tipsForNext: selectedTips.isEmpty ? nil : Array(selectedTips),
            actualMinutes: Int(actualMinutes)
        )

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onSave(reflection)
        dismiss()
    }
}

// MARK: - Reflection Step

enum ReflectionStep: Int, CaseIterable {
    case difficulty = 0
    case accuracy = 1
    case learnings = 2
    case tips = 3

    var next: ReflectionStep {
        ReflectionStep(rawValue: rawValue + 1) ?? .tips
    }

    var previous: ReflectionStep {
        ReflectionStep(rawValue: rawValue - 1) ?? .difficulty
    }
}

// MARK: - Preview

#Preview {
    ReflectionSheet(
        taskTitle: "Finish quarterly report",
        estimatedMinutes: 45,
        onSave: { _ in },
        onSkip: { }
    )
}
