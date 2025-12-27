//
//  JournalFeedView.swift
//  Veloce
//
//  Free-Form Daily Journal - Amy-style open canvas experience
//  VoidBackground aesthetic matching Tasks page, TodayPillView navigation,
//  direct TextEditor for each day, auto-save with debounce
//

import SwiftUI
import SwiftData

// MARK: - Journal Colors

enum JournalColors {
    // Entry Type Colors (Living Cosmos palette)
    static let brainDump = Theme.CelestialColors.starDim
    static let reminder = Theme.CelestialColors.solarFlare
    static let gratitude = Color(red: 0.98, green: 0.45, blue: 0.65)  // Warm rose
    static let reflection = Theme.CelestialColors.nebulaCore

    // Mood Colors
    static let excellent = Theme.CelestialColors.auroraGreen
    static let good = Theme.CelestialColors.plasmaCore
    static let neutral = Theme.CelestialColors.starDim
    static let low = Theme.CelestialColors.nebulaGlow
    static let stressed = Theme.CelestialColors.solarFlare

    static func colorFor(entryType: JournalEntryType) -> Color {
        switch entryType {
        case .brainDump: return brainDump
        case .reminder: return reminder
        case .gratitude: return gratitude
        case .reflection: return reflection
        }
    }

    static func colorFor(mood: JournalMood) -> Color {
        switch mood {
        case .excellent: return excellent
        case .good: return good
        case .neutral: return neutral
        case .low: return low
        case .stressed: return stressed
        }
    }
}

// MARK: - Journal View (Free-Form Editor)

struct JournalFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = JournalFeedViewModel()

    // Date navigation
    @State private var selectedDate = Date()
    @State private var showDatePicker = false

    // Editor state
    @State private var currentText = ""
    @State private var currentEntry: JournalEntry?
    @State private var autoSaveTask: Task<Void, Never>?
    @FocusState private var isEditing: Bool

    // Word count
    private var wordCount: Int {
        currentText.split(separator: " ").count
    }

    var body: some View {
        ZStack {
            // Cosmic void background (matches Tasks page)
            VoidBackground.journal

            VStack(spacing: 0) {
                // Today pill with date navigation (matches ChatTasksView pattern)
                dateNavigationPill
                    .padding(.top, 48)
                    .padding(.bottom, 12)

                // Free-form editor
                editorArea

                // Minimal toolbar
                journalToolbar
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.setup(context: modelContext)
            loadEntry(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            saveCurrentEntry()
            loadEntry(for: newDate)
        }
        .onChange(of: currentText) { _, _ in
            scheduleAutoSave()
        }
        .sheet(isPresented: $showDatePicker) {
            JournalDatePickerSheet(selectedDate: $selectedDate)
        }
    }

    // MARK: - Date Navigation Pill

    private var dateNavigationPill: some View {
        TodayPillView(selectedDate: $selectedDate)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticsService.shared.selectionFeedback()
                showDatePicker = true
            }
    }

    // MARK: - Editor Area

    private var editorArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Date stamp
                Text(formattedDate)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                // Free-form text editor
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if currentText.isEmpty {
                        Text("What's on your mind?")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundStyle(.white.opacity(0.25))
                            .padding(.top, 8)
                    }

                    // Editor
                    TextEditor(text: $currentText)
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundStyle(.white.opacity(0.9))
                        .scrollContentBackground(.hidden)
                        .focused($isEditing)
                        .frame(minHeight: 400)
                        .lineSpacing(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Minimal Toolbar

    private var journalToolbar: some View {
        HStack(spacing: 16) {
            // Word count (left side)
            if wordCount > 0 {
                Text("\(wordCount) words")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // Voice input button
            Button {
                HapticsService.shared.selectionFeedback()
                // Voice input action (placeholder)
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(.white.opacity(0.08))
                    }
            }
            .buttonStyle(.plain)

            // Keyboard dismiss button
            Button {
                HapticsService.shared.selectionFeedback()
                isEditing = false
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(.white.opacity(0.08))
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Computed Properties

    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today, \(selectedDate.formatted(date: .abbreviated, time: .omitted))"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday, \(selectedDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            return selectedDate.formatted(date: .complete, time: .omitted)
        }
    }

    // MARK: - Data Management

    private func loadEntry(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Find existing entry for this day
        let entries = viewModel.filteredEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: startOfDay)
        }

        if let existingEntry = entries.first {
            currentEntry = existingEntry
            currentText = existingEntry.plainText
        } else {
            // No entry for this day - start fresh
            currentEntry = nil
            currentText = ""
        }
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                saveCurrentEntry()
            }
        }
    }

    private func saveCurrentEntry() {
        let trimmedContent = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Don't save empty content
        guard !trimmedContent.isEmpty else {
            // If we have an existing entry with no content, delete it
            if let entry = currentEntry, entry.plainText.isEmpty {
                modelContext.delete(entry)
            }
            return
        }

        if let entry = currentEntry {
            // Update existing entry
            updateEntry(entry, with: trimmedContent)
        } else {
            // Create new entry for this day
            let newEntry = viewModel.createEntry(type: .brainDump, for: selectedDate)
            updateEntry(newEntry, with: trimmedContent)
            currentEntry = newEntry
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save journal entry: \(error)")
        }
    }

    private func updateEntry(_ entry: JournalEntry, with content: String) {
        // Extract title from first line
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        if let firstLine = lines.first {
            entry.title = String(firstLine.prefix(50))
        }

        // Save content
        let attributedString = NSAttributedString(
            string: content,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.white
            ]
        )
        entry.setAttributedString(attributedString)
        entry.updatedAt = .now
    }
}

// MARK: - Journal Date Picker Sheet

struct JournalDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .tint(Theme.Colors.aiPurple)
                .padding(Theme.Spacing.md)

                Button {
                    HapticsService.shared.selectionFeedback()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .voidPresentationBackground()
    }
}

// MARK: - Preview

#Preview {
    JournalFeedView()
        .modelContainer(for: [JournalEntry.self], inMemory: true)
}
