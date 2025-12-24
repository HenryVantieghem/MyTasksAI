//
//  JournalTabView.swift
//  Veloce
//
//  Journal Tab - Daily reflections with Brain Dump and Reminders toggles
//

import SwiftUI
import SwiftData

// MARK: - Journal Tab View

struct JournalTabView: View {
    var tasksViewModel: TasksViewModel
    @State private var journalViewModel = JournalViewModel()
    @State private var brainDumpViewModel = BrainDumpViewModel()
    @State private var selectedDate: Date = Date()

    // Toggle states
    @State private var showBrainDump: Bool = false
    @State private var showReminders: Bool = false

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Background - Living Cosmos journal variant
            VoidBackground.journal

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Date navigation
                    TodayPillView(selectedDate: $selectedDate)
                        .padding(.top, Theme.Spacing.universalHeaderHeight)
                        .padding(.horizontal, Theme.Spacing.screenPadding)

                    // Feature Toggles
                    featureToggles
                        .padding(.horizontal, Theme.Spacing.screenPadding)

                    // Brain Dump Section (when enabled)
                    if showBrainDump {
                        brainDumpSection
                            .padding(.horizontal, Theme.Spacing.screenPadding)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                    }

                    // Reminders Section (when enabled)
                    if showReminders {
                        remindersSection
                            .padding(.horizontal, Theme.Spacing.screenPadding)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                    }

                    // Journal entry area
                    JournalEntryCard(viewModel: journalViewModel, date: selectedDate)
                        .padding(.horizontal, Theme.Spacing.screenPadding)

                    // AI Reflection (if available)
                    if let reflection = journalViewModel.currentReflection {
                        AIReflectionCard(reflection: reflection)
                            .padding(.horizontal, Theme.Spacing.screenPadding)
                    }
                }
                .padding(.bottom, 120)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showBrainDump)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showReminders)
        .task {
            journalViewModel.setup(context: modelContext)
        }
        .onChange(of: selectedDate) { _, newDate in
            Task {
                await journalViewModel.loadEntry(for: newDate)
            }
        }
    }

    // MARK: - Feature Toggles

    private var featureToggles: some View {
        HStack(spacing: 12) {
            // Brain Dump Toggle
            FeatureToggleButton(
                icon: "brain.head.profile",
                label: "Brain Dump",
                isEnabled: showBrainDump,
                accentColor: Theme.Colors.aiPurple
            ) {
                HapticsService.shared.selectionFeedback()
                withAnimation {
                    showBrainDump.toggle()
                }
            }

            // Reminders Toggle
            FeatureToggleButton(
                icon: "bell.badge",
                label: "Reminders",
                isEnabled: showReminders,
                accentColor: Theme.Colors.aiBlue
            ) {
                HapticsService.shared.selectionFeedback()
                withAnimation {
                    showReminders.toggle()
                }
            }
        }
    }

    // MARK: - Brain Dump Section

    private var brainDumpSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("Brain Dump")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    HapticsService.shared.selectionFeedback()
                    withAnimation {
                        showBrainDump = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(8)
                        .background {
                            SwiftUI.Circle()
                                .fill(.white.opacity(0.1))
                        }
                }
                .buttonStyle(.plain)
            }

            // Brain dump input
            ZStack(alignment: .topLeading) {
                if brainDumpViewModel.inputText.isEmpty {
                    Text("What's on your mind? Let it all out...")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                }

                TextEditor(text: $brainDumpViewModel.inputText)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100, maxHeight: 150)
            }

            // Process button
            if !brainDumpViewModel.inputText.isEmpty {
                Button {
                    HapticsService.shared.impact()
                    Task {
                        await brainDumpViewModel.processBrainDump()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if brainDumpViewModel.isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(brainDumpViewModel.isProcessing ? "Processing..." : "Process Thoughts")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .buttonStyle(.plain)
                .disabled(brainDumpViewModel.isProcessing)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "bell.badge")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiBlue)

                Text("Reminders")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    HapticsService.shared.selectionFeedback()
                    withAnimation {
                        showReminders = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(8)
                        .background {
                            SwiftUI.Circle()
                                .fill(.white.opacity(0.1))
                        }
                }
                .buttonStyle(.plain)
            }

            // Reminders list
            RemindersListView()
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.aiBlue.opacity(0.3), lineWidth: 1)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Feature Toggle Button

struct FeatureToggleButton: View {
    let icon: String
    let label: String
    let isEnabled: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isEnabled ? .semibold : .regular))

                Text(label)
                    .font(.system(size: 13, weight: isEnabled ? .semibold : .medium))
            }
            .foregroundStyle(isEnabled ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isEnabled {
                    Capsule()
                        .fill(accentColor.opacity(0.4))
                } else {
                    Capsule()
                        .fill(.white.opacity(0.08))
                }
            }
            .overlay {
                if isEnabled {
                    Capsule()
                        .stroke(accentColor.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reminders List View

struct RemindersListView: View {
    @State private var reminders: [ReminderItem] = []
    @State private var newReminderText: String = ""
    @FocusState private var isAddingReminder: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Add reminder input
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.aiBlue)

                TextField("Add a reminder...", text: $newReminderText)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .focused($isAddingReminder)
                    .submitLabel(.done)
                    .onSubmit {
                        addReminder()
                    }

                if !newReminderText.isEmpty {
                    Button {
                        addReminder()
                    } label: {
                        Text("Add")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.Colors.aiBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.05))
            }

            // Reminders list
            if reminders.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 24, weight: .thin))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No reminders yet")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(reminders) { reminder in
                    ReminderRowView(reminder: reminder) {
                        toggleReminder(reminder)
                    } onDelete: {
                        deleteReminder(reminder)
                    }
                }
            }
        }
    }

    private func addReminder() {
        let text = newReminderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let reminder = ReminderItem(text: text)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            reminders.append(reminder)
        }
        newReminderText = ""
        HapticsService.shared.lightImpact()
    }

    private func toggleReminder(_ reminder: ReminderItem) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                reminders[index].isCompleted.toggle()
            }
            HapticsService.shared.selectionFeedback()
        }
    }

    private func deleteReminder(_ reminder: ReminderItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            reminders.removeAll { $0.id == reminder.id }
        }
        HapticsService.shared.lightImpact()
    }
}

// MARK: - Reminder Item

struct ReminderItem: Identifiable {
    let id = UUID()
    var text: String
    var isCompleted: Bool = false
    var dueDate: Date?
}

// MARK: - Reminder Row View

struct ReminderRowView: View {
    let reminder: ReminderItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(reminder.isCompleted ? Theme.Colors.success : .white.opacity(0.4))
            }
            .buttonStyle(.plain)

            Text(reminder.text)
                .font(.system(size: 15))
                .foregroundStyle(reminder.isCompleted ? .white.opacity(0.4) : .white)
                .strikethrough(reminder.isCompleted, color: .white.opacity(0.4))

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    JournalTabView(tasksViewModel: TasksViewModel())
        .modelContainer(for: [TaskItem.self, NotesLine.self, JournalEntry.self], inMemory: true)
}
