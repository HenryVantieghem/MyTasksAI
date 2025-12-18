//
//  DailyNotesView.swift
//  MyTasksAI
//
//  Apple Notes-style daily task pages
//  Free-form typing with lines that expand into task details
//

import SwiftUI
import SwiftData

// MARK: - Daily Notes View

struct DailyNotesView: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: State
    @State private var selectedDate: Date = Date()
    @State private var notesLines: [NotesLine] = []
    @State private var newLineText: String = ""
    @State private var selectedTaskForDetail: TaskItem?
    @State private var focusedLineId: UUID?
    @State private var isNewLineFocused: Bool = false

    // MARK: Keyboard
    @State private var keyboardObserver = KeyboardObserver()
    @State private var currentEditingLine: NotesLine?

    // MARK: Configuration
    private let maxLinesPerPage = 50

    var body: some View {
        VStack(spacing: 0) {
            // Header with date pill and stats
            headerSection

            // Notes content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Existing lines
                        ForEach(notesLines) { line in
                            NotesLineView(
                                line: line,
                                onTap: {
                                    handleLineTap(line)
                                },
                                onTextChange: { _ in
                                    saveLines()
                                },
                                onCheckToggle: {
                                    toggleLineCheckbox(line)
                                },
                                isFocused: Binding(
                                    get: { focusedLineId == line.id },
                                    set: { if $0 { focusedLineId = line.id; currentEditingLine = line } }
                                )
                            )
                            .id(line.id)
                        }

                        // New line input
                        EmptyNotesLineView(
                            placeholder: notesLines.isEmpty ? "Start typing..." : "New line...",
                            text: $newLineText,
                            isFocused: $isNewLineFocused,
                            onSubmit: {
                                createNewLine()
                            }
                        )
                        .id("newLine")
                    }
                    .padding(.bottom, keyboardObserver.isVisible ? 60 : 100)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: notesLines.count) { _, _ in
                    // Scroll to bottom when new line added
                    withAnimation(Theme.Animation.fast) {
                        proxy.scrollTo("newLine", anchor: .bottom)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if keyboardObserver.isVisible {
                keyboardToolbar
            }
        }
        .background(Theme.Colors.background)
        .onChange(of: selectedDate) { _, newDate in
            loadLinesForDate(newDate)
        }
        .task {
            loadLinesForDate(selectedDate)
        }
        .sheet(item: $selectedTaskForDetail) { task in
            taskDetailSheet(for: task)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Date pill
            DatePillView(selectedDate: $selectedDate)

            // Stats bar
            CompactStatsBar(
                completedCount: completedCount,
                totalCount: notesLines.filter { $0.hasCheckbox }.count,
                streakDays: viewModel.gamification.currentStreak,
                points: viewModel.gamification.totalPoints
            )
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Keyboard Toolbar

    private var keyboardToolbar: some View {
        NotesKeyboardToolbar(
            hasCheckbox: currentEditingLine?.hasCheckbox ?? false,
            starRating: currentEditingLine?.starRating ?? 0,
            onCheckboxToggle: {
                if let line = currentEditingLine {
                    line.toggleCheckbox()
                    saveLines()
                }
            },
            onStarsToggle: {
                if let line = currentEditingLine {
                    line.cycleStars()
                    saveLines()
                }
            },
            onDismiss: {
                dismissKeyboard()
            }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(Theme.Animation.fast, value: keyboardObserver.isVisible)
    }

    // MARK: - Task Detail Sheet

    @ViewBuilder
    private func taskDetailSheet(for task: TaskItem) -> some View {
        // Find the corresponding line for this task
        let line = notesLines.first(where: { $0.linkedTaskId == task.id })

        TaskDetailContentView(
            task: task,
            onToggleComplete: {
                viewModel.toggleCompletion(task)
                if let line = line {
                    line.isChecked = task.isCompleted
                    saveLines()
                }
            },
            onReprocessAI: {
                viewModel.reprocessAI(for: task)
            },
            onSchedule: { date in
                task.scheduledTime = date
                viewModel.updateTask(task)
            },
            onDuplicate: {
                viewModel.duplicateTask(task)
            },
            onSnooze: {
                viewModel.snoozeTask(task)
            },
            onDelete: {
                // Delete task and unlink from line
                viewModel.deleteTask(task)
                if let line = line {
                    line.linkedTaskId = nil
                    saveLines()
                }
                selectedTaskForDetail = nil
            },
            onDismiss: {
                selectedTaskForDetail = nil
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    // MARK: - Computed Properties

    private var completedCount: Int {
        notesLines.filter { $0.hasCheckbox && $0.isChecked }.count
    }

    private var gamification: GamificationService {
        GamificationService.shared
    }

    // MARK: - Methods

    private func loadLinesForDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        let descriptor = FetchDescriptor<NotesLine>(
            predicate: #Predicate<NotesLine> { line in
                line.date == normalizedDate
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        do {
            notesLines = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load notes lines: \(error)")
            notesLines = []
        }
    }

    private func createNewLine() {
        guard !newLineText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let line = NotesLine(
            text: newLineText,
            date: selectedDate,
            sortOrder: notesLines.count,
            userId: SupabaseService.shared.currentUserId
        )

        modelContext.insert(line)
        notesLines.append(line)

        // Clear input
        newLineText = ""

        // Focus the new line
        focusedLineId = line.id
        currentEditingLine = line

        saveLines()
        HapticsService.shared.lightImpact()
    }

    private func toggleLineCheckbox(_ line: NotesLine) {
        if line.hasCheckbox {
            line.toggleChecked()

            // Sync with linked task if exists
            if let taskId = line.linkedTaskId,
               let task = viewModel.tasks.first(where: { $0.id == taskId }) {
                task.isCompleted = line.isChecked
                if line.isChecked {
                    task.completedAt = Date()
                } else {
                    task.completedAt = nil
                }
                viewModel.updateTask(task)
            }
        }

        saveLines()
        HapticsService.shared.selectionFeedback()
    }

    private func handleLineTap(_ line: NotesLine) {
        guard line.hasContent else { return }

        // Get or create linked task
        let task: TaskItem
        if let taskId = line.linkedTaskId,
           let existingTask = viewModel.tasks.first(where: { $0.id == taskId }) {
            task = existingTask
        } else {
            // Create new task from line
            task = createTaskFromLine(line)
        }

        // Show task detail sheet
        selectedTaskForDetail = task
        HapticsService.shared.lightImpact()
    }

    private func createTaskFromLine(_ line: NotesLine) -> TaskItem {
        let task = TaskItem(
            title: line.text,
            userId: SupabaseService.shared.currentUserId ?? UUID()
        )

        task.starRating = line.starRating
        task.isCompleted = line.isChecked
        if line.isChecked {
            task.completedAt = Date()
        }

        // Link line to task
        line.linkedTaskId = task.id

        // Add to view model
        viewModel.addTaskItem(task)

        // Process with AI
        Task {
            await viewModel.processTaskWithAI(task)
        }

        saveLines()

        return task
    }

    private func saveLines() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save notes lines: \(error)")
        }
    }

    private func dismissKeyboard() {
        focusedLineId = nil
        isNewLineFocused = false
        currentEditingLine = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var vm = TasksViewModel()

        var body: some View {
            NavigationStack {
                DailyNotesView(viewModel: vm)
                    .navigationTitle("Tasks")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .modelContainer(for: [TaskItem.self, NotesLine.self], inMemory: true)
        }
    }
    return PreviewWrapper()
}
