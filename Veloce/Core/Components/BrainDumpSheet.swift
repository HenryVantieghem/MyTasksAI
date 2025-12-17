//
//  BrainDumpSheet.swift
//  Veloce
//
//  Apple Notes-style multi-line input for rapid task capture
//  Inspired by Sam Altman's paper productivity system
//

import SwiftUI

struct BrainDumpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    @State private var inputText: String = ""
    @State private var parsedTasks: [BrainDumpParser.ParsedTask] = []
    @State private var isProcessing: Bool = false
    @State private var showingPreview: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    let onTasksCreated: ([BrainDumpParser.ParsedTask]) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Instructions card
                    instructionsCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)

                    // Main input area
                    inputArea
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)

                    // Preview of parsed tasks
                    if showingPreview && !parsedTasks.isEmpty {
                        previewSection
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.top, Theme.Spacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer()

                    // Action buttons
                    actionBar
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                }
            }
            .navigationTitle("Brain Dump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
            .onChange(of: inputText) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    parsedTasks = BrainDumpParser.parse(newValue)
                    showingPreview = !parsedTasks.isEmpty
                }
            }
        }
    }

    // MARK: - Instructions Card

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.Colors.accent)
                Text("Quick Capture")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
            }

            Text("Write one task per line. Use stars for priority:")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)

            HStack(spacing: Theme.Spacing.lg) {
                priorityHint("*", label: "Low")
                priorityHint("**", label: "Medium")
                priorityHint("***", label: "High")
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.glassBorder.opacity(0.2))
                }
        }
    }

    private func priorityHint(_ stars: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(stars)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.Colors.accent)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.tertiaryText)
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if inputText.isEmpty {
                    Text("Buy groceries\n** Call mom\n*** Finish project deadline\nRead chapter 3...")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.tertiaryText.opacity(0.5))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                // Text editor
                TextEditor(text: $inputText)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 200)
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.glassBorder.opacity(0.3))
                }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Preview")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                Spacer()
                Text("\(parsedTasks.count) task\(parsedTasks.count == 1 ? "" : "s")")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.accent)
            }

            ScrollView {
                VStack(spacing: Theme.Spacing.xs) {
                    ForEach(Array(parsedTasks.enumerated()), id: \.offset) { index, task in
                        previewRow(task: task)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
            }
            .frame(maxHeight: 150)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.accent.opacity(0.2))
                }
        }
    }

    private func previewRow(task: BrainDumpParser.ParsedTask) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Priority indicator
            Text(task.priority.displayStars)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(priorityColor(for: task.priority))
                .frame(width: 36, alignment: .leading)

            // Task title
            Text(task.title)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.primaryText)
                .lineLimit(1)

            Spacer()

            // Checkmark indicator
            Image(systemName: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(Theme.Colors.success.opacity(0.5))
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colors.glassBackground.opacity(0.2))
        }
    }

    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: return Theme.Colors.tertiaryText
        case .medium: return Theme.Colors.accent
        case .high: return Theme.Colors.warning
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Clear button
            Button {
                withAnimation {
                    inputText = ""
                    parsedTasks = []
                    showingPreview = false
                }
            } label: {
                Label("Clear", systemImage: "xmark.circle")
                    .font(Theme.Typography.subheadline)
            }
            .buttonStyle(.glass)
            .disabled(inputText.isEmpty)
            .opacity(inputText.isEmpty ? 0.5 : 1)

            Spacer()

            // Create tasks button
            Button {
                createTasks()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(parsedTasks.isEmpty ? "Add Tasks" : "Add \(parsedTasks.count) Task\(parsedTasks.count == 1 ? "" : "s")")
                }
                .font(Theme.Typography.headline)
            }
            .buttonStyle(.glassProminent)
            .disabled(parsedTasks.isEmpty || isProcessing)
            .opacity(parsedTasks.isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Actions

    private func createTasks() {
        guard !parsedTasks.isEmpty else { return }

        isProcessing = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onTasksCreated(parsedTasks)
            isProcessing = false
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    BrainDumpSheet(isPresented: .constant(true)) { tasks in
        print("Created \(tasks.count) tasks")
    }
}
