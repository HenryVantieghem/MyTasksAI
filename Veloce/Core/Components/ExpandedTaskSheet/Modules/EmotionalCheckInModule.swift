//
//  EmotionalCheckInModule.swift
//  MyTasksAI
//
//  "How are you feeling?" module with 4 emotions
//  Shows self-compassionate AI responses
//  Triggers when task rescheduled 2+ times
//

import SwiftUI

// MARK: - Emotional Check-In Module

struct EmotionalCheckInModule: View {
    let task: TaskItem
    @Bindable var viewModel: GeniusSheetViewModel

    @State private var selectedEmotion: Emotion?
    @State private var showResponse: Bool = false

    private let accentColor = Theme.TaskCardColors.emotional

    var body: some View {
        ModuleCard(
            title: "HOW ARE YOU FEELING?",
            icon: "heart.fill",
            accentColor: accentColor
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Intro text
                Text("This task has been waiting. That's okay—let's make it feel possible.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))

                // Emotion buttons
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Emotion.allCases, id: \.self) { emotion in
                        emotionButton(emotion)
                    }
                }

                // AI Response
                if let response = viewModel.emotionResponse, showResponse {
                    aiResponseView(response)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Emotion Button

    private func emotionButton(_ emotion: Emotion) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedEmotion = emotion
                viewModel.selectEmotion(emotion)
                showResponse = true
            }

            // Haptic
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        } label: {
            VStack(spacing: 4) {
                Text(emotion.emoji)
                    .font(.system(size: 24))
                Text(emotion.rawValue)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedEmotion == emotion
                        ? accentColor.opacity(0.2)
                        : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selectedEmotion == emotion
                                    ? accentColor.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .foregroundStyle(selectedEmotion == emotion ? .white : .white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Response View

    private func aiResponseView(_ response: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Quote mark
            Image(systemName: "quote.opening")
                .font(.system(size: 14))
                .foregroundStyle(accentColor.opacity(0.6))

            Text(response)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        EmotionalCheckInModule(
            task: {
                let task = TaskItem(title: "Write quarterly report")
                task.timesRescheduled = 3
                return task
            }(),
            viewModel: GeniusSheetViewModel()
        )
        .padding()
    }
}
