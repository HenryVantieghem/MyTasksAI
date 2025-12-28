//
//  WeeklyCheckInSheet.swift
//  Veloce
//
//  Weekly Check-In Sheet - Premium AI Coaching Experience
//  Interactive goal progress check-in with AI guidance
//

import SwiftUI
import SwiftData

struct WeeklyCheckInSheet: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var currentStep: CheckInStep = .feeling
    @State private var animateStep = false

    // Form data
    @State private var selectedMood: CheckInMood = .neutral
    @State private var progressSinceLastWeek: ProgressLevel = .someProgress
    @State private var blockers: [String] = []
    @State private var newBlocker = ""
    @State private var wins: [String] = []
    @State private var newWin = ""
    @State private var updatedProgress: Double = 0
    @State private var notes = ""

    // UI State
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var aiCoachResponse: String?

    @FocusState private var isBlockerFocused: Bool
    @FocusState private var isWinFocused: Bool
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.standard

                VStack(spacing: 0) {
                    // Progress dots
                    progressDots
                        .padding(.top, 16)
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
                        if currentStep == .feeling {
                            dismiss()
                        } else {
                            goBack()
                        }
                    } label: {
                        if currentStep == .feeling || currentStep == .success {
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
                    .disabled(currentStep == .submitting)
                }
            }
            .onAppear {
                updatedProgress = goal.progress
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animateStep = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .interactiveDismissDisabled(currentStep == .submitting)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(CheckInStep.allCases.filter { $0.showsInProgress }, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Theme.Colors.aiPurple : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .feeling:
            feelingStep
        case .progress:
            progressStep
        case .blockers:
            blockersStep
        case .wins:
            winsStep
        case .notes:
            notesStep
        case .review:
            reviewStep
        case .submitting:
            submittingStep
        case .success:
            successStep
        }
    }

    // MARK: - Feeling Step

    private var feelingStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                checkInOrb

                Text("How are you feeling?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("About your progress on \(goal.displayTitle)")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Mood selection
            HStack(spacing: 16) {
                ForEach(CheckInMood.allCases, id: \.self) { mood in
                    MoodButton(mood: mood, isSelected: selectedMood == mood) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMood = mood
                        }
                    }
                }
            }

            Spacer()

            continueButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Progress Step

    private var progressStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.aiCyan.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Colors.aiCyan)
                }

                Text("Update Your Progress")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Progress slider
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: updatedProgress)
                        .stroke(
                            LinearGradient(
                                colors: [goal.themeColor, goal.themeColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.4), value: updatedProgress)

                    VStack(spacing: 4) {
                        Text("\(Int(updatedProgress * 100))%")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text("complete")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Slider(value: $updatedProgress, in: 0...1, step: 0.05)
                    .tint(goal.themeColor)
                    .padding(.horizontal, 40)

                // Quick presets
                HStack(spacing: 12) {
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { value in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                updatedProgress = value
                            }
                        } label: {
                            Text("\(Int(value * 100))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(updatedProgress == value ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(updatedProgress == value ? goal.themeColor.opacity(0.3) : .white.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            continueButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Blockers Step

    private var blockersStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.warning.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Colors.warning)
                }

                Text("Any Blockers?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("What's getting in your way?")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Add blocker input
            HStack(spacing: 12) {
                TextField("Add a blocker...", text: $newBlocker)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial.opacity(0.5))
                    )
                    .focused($isBlockerFocused)
                    .submitLabel(.done)
                    .onSubmit { addBlocker() }

                Button {
                    addBlocker()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(newBlocker.isEmpty ? .white.opacity(0.3) : Theme.Colors.warning)
                }
                .buttonStyle(.plain)
                .disabled(newBlocker.isEmpty)
            }
            .padding(.horizontal, 20)

            // Blockers list
            if !blockers.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(blockers, id: \.self) { blocker in
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Colors.warning)

                                Text(blocker)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))

                                Spacer()

                                Button {
                                    blockers.removeAll { $0 == blocker }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white.opacity(0.05))
                            )
                        }
                    }
                }
                .frame(maxHeight: 200)
                .padding(.horizontal, 20)
            }

            Spacer()

            // Skip or continue
            VStack(spacing: 12) {
                continueButton

                if blockers.isEmpty {
                    Button {
                        goToNext()
                    } label: {
                        Text("No blockers this week")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Wins Step

    private var winsStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.success.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Colors.success)
                }

                Text("Celebrate Wins!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("What progress are you proud of?")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Add win input
            HStack(spacing: 12) {
                TextField("Add a win...", text: $newWin)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial.opacity(0.5))
                    )
                    .focused($isWinFocused)
                    .submitLabel(.done)
                    .onSubmit { addWin() }

                Button {
                    addWin()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(newWin.isEmpty ? .white.opacity(0.3) : Theme.Colors.success)
                }
                .buttonStyle(.plain)
                .disabled(newWin.isEmpty)
            }
            .padding(.horizontal, 20)

            // Wins list
            if !wins.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(wins, id: \.self) { win in
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Colors.success)

                                Text(win)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))

                                Spacer()

                                Button {
                                    wins.removeAll { $0 == win }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white.opacity(0.05))
                            )
                        }
                    }
                }
                .frame(maxHeight: 200)
                .padding(.horizontal, 20)
            }

            Spacer()

            continueButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Notes Step

    private var notesStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.aiPurple.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "text.alignleft")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }

                Text("Any Other Notes?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Reflect on your journey this week")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Notes input
            TextEditor(text: $notes)
                .font(.system(size: 15))
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
                .focused($isNotesFocused)
                .padding(.horizontal, 20)

            Spacer()

            // Skip or continue
            VStack(spacing: 12) {
                continueButton

                if notes.isEmpty {
                    Button {
                        goToNext()
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Review Step

    private var reviewStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.success.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.Colors.success)
                    }

                    Text("Review Check-In")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

                // Summary cards
                VStack(spacing: 16) {
                    // Mood & Progress
                    HStack(spacing: 12) {
                        ReviewCard(icon: selectedMood.icon, label: "Mood", value: selectedMood.label, color: selectedMood.color)
                        ReviewCard(icon: "chart.line.uptrend.xyaxis", label: "Progress", value: "\(Int(updatedProgress * 100))%", color: goal.themeColor)
                    }

                    // Blockers
                    if !blockers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.warning)
                                Text("Blockers")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            ForEach(blockers, id: \.self) { blocker in
                                Text("• \(blocker)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial.opacity(0.5))
                        )
                    }

                    // Wins
                    if !wins.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.success)
                                Text("Wins")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            ForEach(wins, id: \.self) { win in
                                Text("• \(win)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial.opacity(0.5))
                        )
                    }

                    // Notes
                    if !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.aiPurple)
                                Text("Notes")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            Text(notes)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial.opacity(0.5))
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 20)

                // Submit button
                Button {
                    Task {
                        await submitCheckIn()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))

                        Text("Submit Check-In")
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

    // MARK: - Submitting Step

    private var submittingStep: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Theme.Colors.aiPurple.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index) * 40, height: 120 + CGFloat(index) * 40)
                }

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.Colors.aiPurple.opacity(0.4), Theme.Colors.aiPurple.opacity(0.1)],
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

            VStack(spacing: 12) {
                Text("Saving Check-In")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text("Getting AI coach feedback...")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
    }

    // MARK: - Success Step

    private var successStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success animation
            ZStack {
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

            VStack(spacing: 16) {
                Text("Check-In Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                // Streak badge
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)

                    Text("\(goal.checkInStreak + 1) week streak!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.2))
                )

                // AI Coach response
                if let response = aiCoachResponse {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text("AI Coach")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Theme.Colors.aiPurple)

                        Text(response)
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
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

    private var checkInOrb: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.Colors.aiPurple.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 10)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.aiPurple.opacity(0.4), Theme.CelestialColors.void],
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
                                colors: [Theme.Colors.aiPurple.opacity(0.6), Theme.Colors.aiPurple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 28))
                .foregroundStyle(Theme.Colors.aiPurple)
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

    private func addBlocker() {
        let trimmed = newBlocker.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        blockers.append(trimmed)
        newBlocker = ""
    }

    private func addWin() {
        let trimmed = newWin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        wins.append(trimmed)
        newWin = ""
    }

    private func submitCheckIn() async {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            animateStep = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep = .submitting
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateStep = true
            }
        }

        isSubmitting = true

        // Update progress
        goal.updateProgress(updatedProgress)
        goal.recordCheckIn()

        // Perform AI check-in (result intentionally discarded - check-in data stored in goal)
        _ = await goalsVM.performWeeklyCheckIn(
            for: goal,
            progressUpdate: updatedProgress,
            blockers: blockers,
            wins: wins,
            notes: notes.isEmpty ? nil : notes,
            context: modelContext
        )

        // Generate AI response
        aiCoachResponse = generateCoachResponse()

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isSubmitting = false

        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateStep = false
            }
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

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

    private func generateCoachResponse() -> String {
        // Generate contextual AI coach response based on check-in data
        if updatedProgress >= 0.9 {
            return "You're so close to the finish line! Keep up this incredible momentum."
        } else if !wins.isEmpty && blockers.isEmpty {
            return "Fantastic progress this week! Your wins show real dedication. Keep building on this momentum."
        } else if !blockers.isEmpty && wins.isEmpty {
            return "I see some challenges ahead. Remember, obstacles are opportunities in disguise. Break them down into smaller steps."
        } else if !blockers.isEmpty && !wins.isEmpty {
            return "You're making progress despite challenges - that's what growth looks like! Focus on your wins while addressing blockers one at a time."
        } else if selectedMood == .struggling || selectedMood == .frustrated {
            return "Tough weeks happen. What matters is that you showed up. Take a moment to rest, then come back stronger."
        } else {
            return "Consistency is key, and you're building it! Keep taking small steps forward."
        }
    }
}

// MARK: - Check-In Step

private enum CheckInStep: Int, CaseIterable {
    case feeling = 0
    case progress = 1
    case blockers = 2
    case wins = 3
    case notes = 4
    case review = 5
    case submitting = 6
    case success = 7

    var next: CheckInStep {
        CheckInStep(rawValue: rawValue + 1) ?? .success
    }

    var previous: CheckInStep {
        CheckInStep(rawValue: rawValue - 1) ?? .feeling
    }

    var showsInProgress: Bool {
        switch self {
        case .feeling, .progress, .blockers, .wins, .notes, .review:
            return true
        case .submitting, .success:
            return false
        }
    }
}

// MARK: - Check-In Mood

private enum CheckInMood: String, CaseIterable {
    case great
    case good
    case neutral
    case struggling
    case frustrated

    var icon: String {
        switch self {
        case .great: return "face.smiling.fill"
        case .good: return "face.smiling"
        case .neutral: return "minus.circle"
        case .struggling: return "cloud"
        case .frustrated: return "exclamationmark.triangle"
        }
    }

    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .neutral: return "Okay"
        case .struggling: return "Struggling"
        case .frustrated: return "Frustrated"
        }
    }

    var color: Color {
        switch self {
        case .great: return Theme.Colors.success
        case .good: return Theme.Colors.aiCyan
        case .neutral: return Theme.Colors.warning
        case .struggling: return .orange
        case .frustrated: return Theme.Colors.error
        }
    }
}

// MARK: - Progress Level

private enum ProgressLevel: String, CaseIterable {
    case majorProgress
    case someProgress
    case littleProgress
    case noProgress
    case setback

    var label: String {
        switch self {
        case .majorProgress: return "Major Progress"
        case .someProgress: return "Some Progress"
        case .littleProgress: return "A Little"
        case .noProgress: return "No Progress"
        case .setback: return "Setback"
        }
    }
}

// MARK: - Mood Button

private struct MoodButton: View {
    let mood: CheckInMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? mood.color : mood.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: mood.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : mood.color)
                }

                Text(mood.label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Review Card

private struct ReviewCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.5))
        )
    }
}

// MARK: - Preview

#Preview {
    let goal = Goal(
        title: "Launch my productivity app",
        goalDescription: "Ship the MVP",
        targetDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
        category: GoalCategory.career.rawValue,
        timeframe: GoalTimeframe.milestone.rawValue
    )

    WeeklyCheckInSheet(goal: goal, goalsVM: GoalsViewModel())
}
