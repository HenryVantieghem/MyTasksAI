//
//  AIStrategyModule.swift
//  MyTasksAI
//
//  Expert AI advice module with source citation
//  2-3 sentence expert advice
//  Expandable "Read more"
//

import SwiftUI

// MARK: - AI Strategy Module

struct AIStrategyModule: View {
    let task: TaskItem
    @Bindable var viewModel: GeniusSheetViewModel

    private let accentColor = Theme.TaskCardColors.strategy

    var body: some View {
        ModuleCard(
            title: "AI STRATEGY",
            icon: "brain",
            accentColor: accentColor
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                if viewModel.isStrategyLoading {
                    loadingView
                } else if let strategy = viewModel.aiStrategy ?? task.aiAdvice {
                    strategyContent(strategy)
                } else {
                    noStrategyView
                }
            }
        }
    }

    // MARK: - Strategy Content

    private func strategyContent(_ strategy: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Strategy text
            Text(strategy)
                .dynamicTypeFont(base: 14, weight: .regular)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
                .lineLimit(viewModel.isStrategyExpanded ? nil : 3)

            // Source citation
            if let source = viewModel.strategySource {
                HStack(spacing: 4) {
                    Image(systemName: "quote.bubble.fill")
                        .dynamicTypeFont(base: 10)
                    Text("Based on: \(source)")
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .italic()
                }
                .foregroundStyle(accentColor.opacity(0.8))
                .padding(.top, 4)
            }

            // Read more button
            if !viewModel.isStrategyExpanded && strategy.count > 150 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.isStrategyExpanded = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Read more")
                        Image(systemName: "chevron.down")
                    }
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(accentColor)
                }
                .padding(.top, 4)
            }

            // Thought process (if available and expanded)
            if viewModel.isStrategyExpanded, let thoughtProcess = task.aiThoughtProcess {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(accentColor.opacity(0.3))

                    Text("Thought Process")
                        .dynamicTypeFont(base: 12, weight: .semibold)
                        .foregroundStyle(accentColor)

                    Text(thoughtProcess)
                        .dynamicTypeFont(base: 13, weight: .regular)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineSpacing(3)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            MiniThinkingOrb(isActive: true, size: 20)

            VStack(alignment: .leading, spacing: 4) {
                ShimmerLoadingText(text: "Analyzing task context...")
                    .dynamicTypeFont(base: 13)

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 12)
                    .frame(maxWidth: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    // MARK: - No Strategy View

    private var noStrategyView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .dynamicTypeFont(base: 24)
                .foregroundStyle(accentColor.opacity(0.5))

            Text("AI analysis not yet available")
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(.white.opacity(0.6))

            Button {
                // Trigger AI analysis
            } label: {
                Text("Generate Insights")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(accentColor.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        AIStrategyModule(
            task: {
                let task = TaskItem(title: "Write quarterly report")
                task.aiAdvice = "Break this task into smaller chunks. Focus on progress, not perfection. The hardest part is starting—once you begin, your brain's task-positive network activates and momentum builds naturally."
                task.aiThoughtProcess = "This is a creative task requiring sustained focus. Based on the task type and estimated duration, deep work sessions would be optimal."
                return task
            }(),
            viewModel: {
                let vm = GeniusSheetViewModel()
                vm.strategySource = "Dr. Timothy Pychyl's procrastination research"
                return vm
            }()
        )
        .padding()
    }
}
