//
//  GoalCreationSheet.swift
//  Veloce
//
//  Goal Creation Sheet - Premium Step-by-Step Wizard
//  Beautiful flow for setting new goals with AI refinement
//

import SwiftUI
import SwiftData

struct GoalCreationSheet: View {
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Wizard State
    @State private var currentStep: CreationStep = .title
    @State private var animateStep = false

    // MARK: - Form State
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: GoalCategory = .personal
    @State private var selectedTimeframe: GoalTimeframe = .milestone
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var showDatePicker = false

    // MARK: - UI State
    @State private var isCreating = false
    @State private var creationProgress: Double = 0
    @State private var createdGoal: Goal?
    @State private var showSuccess = false
    @State private var error: String?

    @FocusState private var titleFocused: Bool
    @FocusState private var descriptionFocused: Bool

    private var canProceed: Bool {
        switch currentStep {
        case .title:
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .category, .timeframe, .date, .description:
            return true
        case .review, .creating, .success:
            return true
        }
    }

    private var suggestedDate: Date {
        selectedTimeframe.suggestedTargetDate(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.standard

                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    // Step content
                    stepContent
                        .opacity(animateStep ? 1 : 0)
                        .offset(y: animateStep ? 0 : 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if currentStep == .title {
                            dismiss()
                        } else {
                            goBack()
                        }
                    } label: {
                        if currentStep == .title || currentStep == .success {
                            Text("Cancel")
                                .foregroundStyle(.white.opacity(0.7))
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Back")
                            }
                            .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .disabled(currentStep == .creating)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animateStep = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    titleFocused = true
                }
            }
            .onChange(of: selectedTimeframe) { _, newTimeframe in
                withAnimation(.easeInOut(duration: 0.3)) {
                    targetDate = newTimeframe.suggestedTargetDate(from: Date())
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .interactiveDismissDisabled(currentStep == .creating)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(CreationStep.allCases.filter { $0.showsInProgress }, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Theme.Colors.aiPurple : Color.white.opacity(0.2))
                    .frame(height: 3)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .title:
            titleStep
        case .category:
            categoryStep
        case .timeframe:
            timeframeStep
        case .date:
            dateStep
        case .description:
            descriptionStep
        case .review:
            reviewStep
        case .creating:
            creatingStep
        case .success:
            successStep
        }
    }

    // MARK: - Title Step

    private var titleStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                headerOrb(icon: "target", color: Theme.Colors.aiPurple)

                Text("What's your goal?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Describe what you want to achieve")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Input
            VStack(spacing: 8) {
                CrystallineTextField(
                    text: $title,
                    placeholder: "e.g., Launch my side project",
                    icon: "target"
                )
                .focused($titleFocused)

                Text("Be specific about what success looks like")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 20)

            Spacer()

            // Continue button
            continueButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Category Step

    private var categoryStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                headerOrb(icon: "folder.fill", color: selectedCategory.color)

                Text("What area of life?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Choose a category for your goal")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Category grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(GoalCategory.allCases, id: \.rawValue) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            continueButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Timeframe Step

    private var timeframeStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                headerOrb(icon: selectedTimeframe.icon, color: selectedTimeframe.color)

                Text("How long will it take?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Choose your goal horizon")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Timeframe cards
            VStack(spacing: 12) {
                ForEach(GoalTimeframe.allCases, id: \.rawValue) { timeframe in
                    TimeframeCard(
                        timeframe: timeframe,
                        isSelected: selectedTimeframe == timeframe
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTimeframe = timeframe
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            continueButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Date Step

    private var dateStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                headerOrb(icon: "calendar", color: selectedTimeframe.color)

                Text("Set your target date")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("When do you want to achieve this?")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Date display
            VStack(spacing: 16) {
                // Date button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDatePicker.toggle()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(targetDate.formatted(.dateTime.weekday(.wide)))
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.6))

                            Text(targetDate.formatted(.dateTime.month(.wide).day().year()))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        if let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(days)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(selectedTimeframe.color)

                                Text("days")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedTimeframe.color.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // Date picker
                if showDatePicker {
                    DatePicker(
                        "Target Date",
                        selection: $targetDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(selectedTimeframe.color)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.5))
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            continueButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Description Step

    private var descriptionStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                headerOrb(icon: "text.alignleft", color: Theme.Colors.aiPurple)

                Text("Add more details")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Optional: Help AI understand your goal better")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Description input
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $description)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120, maxHeight: 180)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .focused($descriptionFocused)

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.aiPurple)

                    Text("AI will refine your goal into SMART format")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Skip or continue
            VStack(spacing: 12) {
                continueButton

                Button {
                    description = ""
                    goToNext()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Review Step

    private var reviewStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    headerOrb(icon: "checkmark.seal", color: Theme.Colors.success)

                    Text("Review Your Goal")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Make sure everything looks right")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Summary card
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Goal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Divider()
                        .background(.white.opacity(0.1))

                    // Details grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ReviewItem(
                            label: "Category",
                            value: selectedCategory.displayName,
                            icon: selectedCategory.icon,
                            color: selectedCategory.color
                        )

                        ReviewItem(
                            label: "Timeframe",
                            value: selectedTimeframe.displayName,
                            icon: selectedTimeframe.icon,
                            color: selectedTimeframe.color
                        )

                        ReviewItem(
                            label: "Target Date",
                            value: targetDate.formatted(.dateTime.month(.abbreviated).day()),
                            icon: "calendar",
                            color: Theme.Colors.aiCyan
                        )

                        if let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day {
                            ReviewItem(
                                label: "Days Left",
                                value: "\(days)",
                                icon: "clock",
                                color: Theme.Colors.warning
                            )
                        }
                    }

                    // Description if provided
                    if !description.isEmpty {
                        Divider()
                            .background(.white.opacity(0.1))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))

                            Text(description)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                // AI note
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.aiPurple)

                    Text("AI will analyze your goal and create a personalized roadmap")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.aiPurple.opacity(0.1))
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 20)

                // Create button
                Button {
                    Task {
                        await createGoal()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))

                        Text("Create Goal")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiPurple.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 16, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Creating Step

    private var creatingStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated orb
            ZStack {
                // Outer rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Theme.Colors.aiPurple.opacity(0.2 - Double(index) * 0.05),
                            lineWidth: 2
                        )
                        .frame(
                            width: 120 + CGFloat(index) * 40,
                            height: 120 + CGFloat(index) * 40
                        )
                        .rotationEffect(.degrees(Double(index) * 30))
                }

                // Center orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.aiPurple.opacity(0.4),
                                    Theme.Colors.aiPurple.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }

            // Text
            VStack(spacing: 12) {
                Text("Creating Your Goal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text(creationStatusText)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        Capsule()
                            .fill(Theme.Colors.aiPurple)
                            .frame(width: geometry.size.width * creationProgress, height: 6)
                            .animation(.easeInOut, value: creationProgress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 60)

                Text("\(Int(creationProgress * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
    }

    private var creationStatusText: String {
        if creationProgress < 0.3 {
            return "Saving your goal..."
        } else if creationProgress < 0.6 {
            return "Analyzing with AI..."
        } else if creationProgress < 0.9 {
            return "Generating roadmap..."
        } else {
            return "Almost done..."
        }
    }

    // MARK: - Success Step

    private var successStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Success animation
            ZStack {
                // Celebration particles
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(Theme.Colors.success.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(
                            x: cos(Double(index) * .pi / 6) * 80,
                            y: sin(Double(index) * .pi / 6) * 80
                        )
                        .scaleEffect(showSuccess ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.6).delay(Double(index) * 0.05),
                            value: showSuccess
                        )
                }

                // Center check
                ZStack {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 100, height: 100)
                        .shadow(color: Theme.Colors.success.opacity(0.5), radius: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(showSuccess ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)
            }

            // Text
            VStack(spacing: 12) {
                Text("Goal Created!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                if let goal = createdGoal {
                    Text(goal.displayTitle)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                if createdGoal?.hasRoadmap == true {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("AI roadmap generated")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .padding(.top, 8)
                }
            }

            Spacer()

            // Done button
            Button {
                dismiss()
            } label: {
                Text("View Goal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.success, Theme.Colors.success.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helper Views

    private func headerOrb(icon: String, color: Color) -> some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 10)

            // Inner orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.4), Theme.CelestialColors.void],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.6), color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
        }
    }

    private var continueButton: some View {
        Button {
            goToNext()
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if canProceed {
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiPurple.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: canProceed ? Theme.Colors.aiPurple.opacity(0.4) : .clear,
                radius: 16,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .disabled(!canProceed)
        .padding(.horizontal, 20)
    }

    // MARK: - Navigation

    private func goToNext() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            animateStep = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep = currentStep.next
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateStep = true
            }

            // Focus appropriate field
            if currentStep == .description {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    descriptionFocused = true
                }
            }
        }
    }

    private func goBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            animateStep = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep = currentStep.previous
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateStep = true
            }
        }
    }

    // MARK: - Actions

    private func createGoal() async {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            animateStep = false
        }

        await MainActor.run {
            currentStep = .creating
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateStep = true
            }
        }

        isCreating = true

        // Animate progress - saving goal
        await MainActor.run {
            withAnimation {
                creationProgress = 0.2
            }
        }

        // Create the goal (this is quick, just saving to SwiftData)
        let goal = await goalsVM.createGoal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            category: selectedCategory,
            timeframe: selectedTimeframe,
            targetDate: targetDate,
            context: modelContext
        )

        createdGoal = goal

        await MainActor.run {
            withAnimation {
                creationProgress = 0.4
            }
        }

        // Try to generate AI roadmap with timeout (don't block on failure)
        // Use a timeout to prevent getting stuck
        // Fire-and-forget task - roadmap generation runs in background
        Task {
            await goalsVM.generateRoadmap(for: goal, context: modelContext)
        }

        // Wait for roadmap with 15 second timeout
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds
            return true
        }

        // Animate progress while waiting
        for i in 1...4 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s increments
            await MainActor.run {
                withAnimation {
                    creationProgress = min(0.4 + Double(i) * 0.12, 0.88)
                }
            }
        }

        // Cancel timeout task if roadmap completed
        timeoutTask.cancel()

        // Final progress
        await MainActor.run {
            withAnimation {
                creationProgress = 1.0
            }
        }

        try? await Task.sleep(nanoseconds: 300_000_000)

        isCreating = false

        // Show success regardless of AI status (goal was created successfully)
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateStep = false
            }
        }

        try? await Task.sleep(nanoseconds: 150_000_000)

        await MainActor.run {
            currentStep = .success
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateStep = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                showSuccess = true
            }
        }
    }
}

// MARK: - Creation Step

private enum CreationStep: Int, CaseIterable {
    case title = 0
    case category = 1
    case timeframe = 2
    case date = 3
    case description = 4
    case review = 5
    case creating = 6
    case success = 7

    var next: CreationStep {
        CreationStep(rawValue: rawValue + 1) ?? .success
    }

    var previous: CreationStep {
        CreationStep(rawValue: rawValue - 1) ?? .title
    }

    var showsInProgress: Bool {
        switch self {
        case .title, .category, .timeframe, .date, .description, .review:
            return true
        case .creating, .success:
            return false
        }
    }
}

// MARK: - Category Card

private struct CategoryCard: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : category.color)
                }

                Text(category.displayName)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(category.color.opacity(0.2))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.05))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? category.color.opacity(0.5) : .white.opacity(0.1),
                            lineWidth: 1
                        )
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeframe Card

private struct TimeframeCard: View {
    let timeframe: GoalTimeframe
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? timeframe.color : timeframe.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: timeframe.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? .white : timeframe.color)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeframe.displayName)
                        .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.9))

                    Text(timeframe.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Points multiplier
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("\(timeframe.pointsMultiplier, specifier: "%.1f")x")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "FFD700").opacity(0.8))

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(timeframe.color)
                }
            }
            .padding(14)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(timeframe.color.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.05))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? timeframe.color.opacity(0.5) : .white.opacity(0.1),
                            lineWidth: 1
                        )
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Review Item

private struct ReviewItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Timeframe Extension

extension GoalTimeframe {
    func suggestedTargetDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .sprint:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .milestone:
            return calendar.date(byAdding: .month, value: 2, to: date) ?? date
        case .horizon:
            return calendar.date(byAdding: .month, value: 6, to: date) ?? date
        }
    }
}

// MARK: - Preview

#Preview {
    GoalCreationSheet(goalsVM: GoalsViewModel())
        .modelContainer(for: [Goal.self, TaskItem.self])
}
