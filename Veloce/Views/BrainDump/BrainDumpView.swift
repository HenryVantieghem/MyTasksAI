//
//  BrainDumpView.swift
//  Veloce
//
//  Brain Dump View
//  Main container for the brain dump experience
//  Clear your mind, let AI organize your thoughts
//

import SwiftUI
import SwiftData

// MARK: - Brain Dump View

struct BrainDumpView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BrainDumpViewModel()
    @State private var showSuccessToast: Bool = false
    @State private var addedTaskCount: Int = 0

    var body: some View {
        ZStack {
            // Main content based on state
            Group {
                switch viewModel.state {
                case .input:
                    BrainDumpInputView(viewModel: viewModel)
                        .transition(.opacity)

                case .processing:
                    BrainDumpProcessingView()
                        .transition(.opacity)

                case .results:
                    BrainDumpResultsView(viewModel: viewModel) {
                        handleCompletion()
                    }
                    .transition(.opacity)

                case .error(let message):
                    errorView(message: message)
                        .transition(.opacity)
                }
            }
            .padding(.top, Theme.Spacing.universalHeaderHeight)
            .animation(.easeInOut(duration: 0.4), value: viewModel.state)

            // Success toast
            if showSuccessToast {
                VStack {
                    Spacer()

                    successToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            viewModel.setup(context: modelContext)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Error icon
            ZStack {
                SwiftUI.Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.red)
            }

            Text("Something went wrong")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white)

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Button {
                HapticsService.shared.impact()
                viewModel.reset()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    Capsule()
                        .fill(Theme.Colors.accentGradient)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, Theme.Spacing.md)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.02).ignoresSafeArea())
    }

    // MARK: - Success Toast

    private var successToast: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Theme.Colors.success)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(addedTaskCount) tasks added")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)

                Text("Go to Tasks to see them")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .stroke(Theme.Colors.success.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.Spacing.screenPadding)
    }

    // MARK: - Handle Completion

    private func handleCompletion() {
        addedTaskCount = viewModel.selectedCount
        HapticsService.shared.celebration()

        // Show success toast
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showSuccessToast = true
        }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showSuccessToast = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.reset()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BrainDumpView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
