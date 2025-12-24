//
//  BrainDumpInputView.swift
//  Veloce
//
//  Brain Dump Input View
//  The void - a minimal, calming space for unstructured thoughts
//

import SwiftUI

// MARK: - Brain Dump Input View

struct BrainDumpInputView: View {
    @Bindable var viewModel: BrainDumpViewModel
    @FocusState private var isFocused: Bool

    @State private var selectedDate: Date = Date()
    @State private var cursorOpacity: Double = 1
    @State private var placeholderOpacity: Double = 1
    @State private var showHint: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Tap to focus
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isFocused = true
                    }

                VStack(spacing: 0) {
                    // Date selector with Liquid Glass
                    TodayPillView(selectedDate: $selectedDate)
                        .padding(.top, 24)

                    Spacer()

                    // Input area
                    inputArea(geometry: geometry)

                    Spacer()

                    // Bottom hint
                    if showHint {
                        hintText
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Process button
                    if !viewModel.inputText.isEmpty {
                        processButton
                            .transition(.scale.combined(with: .opacity))
                            .padding(.bottom, Theme.Spacing.floatingTabBarClearance)
                    }
                }
            }
        }
        .background { VoidBackground.brainDump }
        .onAppear {
            startAnimations()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }

    // MARK: - Input Area

    private func inputArea(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if viewModel.inputText.isEmpty {
                placeholderText
            }

            // Text Editor
            TextEditor(text: $viewModel.inputText)
                .focused($isFocused)
                .font(.system(size: 20, weight: .regular, design: .default))
                .foregroundStyle(Color.white)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: 100, maxHeight: geometry.size.height * 0.6)
                .padding(.horizontal, Theme.Spacing.lg)
                .onChange(of: viewModel.inputText) { _, newValue in
                    if !newValue.isEmpty && !showHint {
                        withAnimation(.easeOut(duration: 0.3).delay(1)) {
                            showHint = true
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            HapticsService.shared.lightImpact()
                            isFocused = false
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Theme.Colors.accent)
                        }
                        .accessibilityLabel("Dismiss keyboard")
                    }
                }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Placeholder

    private var placeholderText: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What's on your mind?")
                .font(.system(size: 24, weight: .light, design: .default))
                .foregroundStyle(Color.white.opacity(0.4))

            Text("Just let it all out...")
                .font(.system(size: 16, weight: .light, design: .default))
                .foregroundStyle(Color.white.opacity(0.25))
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.sm)
        .opacity(placeholderOpacity)
        .animation(.easeOut(duration: 0.3), value: viewModel.inputText.isEmpty)
    }

    // MARK: - Hint Text

    private var hintText: some View {
        Text("Write freely. No structure needed. AI will organize it for you.")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color.white.opacity(0.3))
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Process Button

    private var processButton: some View {
        Button {
            HapticsService.shared.impact()
            Task {
                await viewModel.processBrainDump()
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))

                Text("Process Thoughts")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(processButtonBackground)
        }
        .buttonStyle(.plain)
    }

    private var processButtonBackground: some View {
        ZStack {
            // Glow
            Capsule()
                .fill(Theme.Colors.accentGradient)
                .blur(radius: 20)
                .opacity(0.5)

            // Button
            Capsule()
                .fill(Theme.Colors.accentGradient)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Cursor blink
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            cursorOpacity = 0.3
        }
    }
}

// MARK: - Preview

#Preview {
    BrainDumpInputView(viewModel: BrainDumpViewModel())
}
