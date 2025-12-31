//
//  StartHereModule.swift
//  MyTasksAI
//
//  THE critical micro-step module
//  30-120 second challenge with countdown
//  Neuroscience-backed first action to break procrastination
//

import SwiftUI

// MARK: - Start Here Module

struct StartHereModule: View {
    let task: TaskItem
    @Bindable var viewModel: GeniusSheetViewModel

    @State private var countdownProgress: CGFloat = 1

    private let accentColor = Theme.TaskCardColors.startHere

    var body: some View {
        ModuleCard(
            title: "START HERE",
            icon: "play.fill",
            accentColor: accentColor,
            trailingText: "\(viewModel.firstStepSeconds) seconds"
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // First step description
                Text(viewModel.firstStepTitle)
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)

                // Motivation text
                Text("This tiny step gets your brain engaged. Once you start, momentum takes over.")
                    .dynamicTypeFont(base: 13, weight: .regular)
                    .foregroundStyle(.white.opacity(0.7))

                // Challenge button or countdown
                if viewModel.challengeCompleted {
                    completedView
                } else if viewModel.isChallengeActive {
                    countdownView
                } else {
                    startButton
                }
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            viewModel.startMicroChallenge()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                Text("START \(viewModel.firstStepSeconds)s CHALLENGE")
                    .dynamicTypeFont(base: 14, weight: .bold)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: accentColor.opacity(0.4), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Countdown View

    private var countdownView: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Countdown circle
            ZStack {
                // Background circle
                SwiftUI.Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 4)

                // Progress circle
                SwiftUI.Circle()
                    .trim(from: 0, to: CGFloat(viewModel.countdown) / CGFloat(viewModel.firstStepSeconds))
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.countdown)

                // Countdown number
                Text("\(viewModel.countdown)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("Challenge in progress...")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(.white)

                Text("You're doing it! Keep going.")
                    .dynamicTypeFont(base: 12, weight: .regular)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Completed View

    private var completedView: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                SwiftUI.Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "checkmark")
                    .dynamicTypeFont(base: 20, weight: .bold)
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Challenge completed!")
                    .dynamicTypeFont(base: 14, weight: .bold)
                    .foregroundStyle(.white)

                Text("+10 points earned 🔥")
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(Theme.TaskCardColors.pointsGlow)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        StartHereModule(
            task: TaskItem(title: "Write quarterly report"),
            viewModel: GeniusSheetViewModel()
        )
        .padding()
    }
}
