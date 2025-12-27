//
//  JournalFeedView.swift
//  Veloce
//
//  Apple Notes-Inspired Journal - Clean, minimal, free-form writing
//  Beautiful typography, open canvas, and distraction-free experience
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

// MARK: - Notes Journal View

struct JournalFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = JournalFeedViewModel()
    @State private var showEditor = false
    @State private var showDetailSheet = false
    @State private var selectedEntry: JournalEntry?
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    // Filtered entries based on search
    private var displayedEntries: [JournalEntry] {
        if searchText.isEmpty {
            return viewModel.filteredEntries
        }
        return viewModel.filteredEntries.filter { entry in
            entry.plainText.localizedCaseInsensitiveContains(searchText) ||
            (entry.title ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    // Group entries by date
    private var groupedEntries: [(String, [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: displayedEntries) { entry -> String in
            if calendar.isDateInToday(entry.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(entry.createdAt) {
                return "Yesterday"
            } else if calendar.isDate(entry.createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(entry.createdAt, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: entry.createdAt)
            }
        }

        let order = ["Today", "Yesterday", "This Week", "This Month"]
        return grouped.sorted { first, second in
            let firstIndex = order.firstIndex(of: first.key) ?? Int.max
            let secondIndex = order.firstIndex(of: second.key) ?? Int.max
            if firstIndex != Int.max || secondIndex != Int.max {
                return firstIndex < secondIndex
            }
            return first.key > second.key
        }
    }

    var body: some View {
        ZStack {
            // Background - Warm paper-like void
            notesBackground

            VStack(spacing: 0) {
                // Header
                notesHeader

                // Search bar (when active)
                if isSearching {
                    searchBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Content
                if displayedEntries.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }

            // Floating Compose Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    composeButton
                        .padding(.trailing, 24)
                        .padding(.bottom, 120)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.setup(context: modelContext)
        }
        .fullScreenCover(isPresented: $showEditor) {
            NotesEditorView(
                viewModel: viewModel,
                entry: selectedEntry,
                onDismiss: {
                    showEditor = false
                    selectedEntry = nil
                }
            )
        }
        .sheet(isPresented: $showDetailSheet) {
            if let entry = selectedEntry {
                JournalDetailSheet(
                    entry: entry,
                    onConvertToTask: { entry in
                        convertToTask(entry)
                    },
                    onDelete: { entry in
                        deleteEntry(entry)
                    }
                )
            }
        }
    }

    // MARK: - Background

    private var notesBackground: some View {
        ZStack {
            // Base void color
            Color(red: 0.06, green: 0.06, blue: 0.08)
                .ignoresSafeArea()

            // Subtle warm gradient overlay (paper-like warmth)
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.10, blue: 0.08).opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var notesHeader: some View {
        HStack(alignment: .center) {
            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text("Journal")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                Text("\(displayedEntries.count) Notes")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Search button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSearching.toggle()
                    if isSearching {
                        isSearchFocused = true
                    } else {
                        searchText = ""
                        isSearchFocused = false
                    }
                }
            } label: {
                Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(.white.opacity(0.08))
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, Theme.Spacing.universalHeaderHeight + 8)
        .padding(.bottom, 16)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.4))

            TextField("Search notes...", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.06))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Notes List

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedEntries, id: \.0) { section, entries in
                    Section {
                        ForEach(entries) { entry in
                            NoteRowView(entry: entry)
                                .onTapGesture {
                                    HapticsService.shared.selectionFeedback()
                                    selectedEntry = entry
                                    showDetailSheet = true
                                }
                        }
                    } header: {
                        sectionHeader(section)
                    }
                }
            }
            .padding(.bottom, 160)
        }
    }

    // MARK: - Convert to Task

    private func convertToTask(_ entry: JournalEntry) {
        let title = entry.title ?? String(entry.plainText.prefix(50))
        let task = TaskItem(title: title)
        task.contextNotes = entry.plainText
        modelContext.insert(task)

        do {
            try modelContext.save()
            HapticsService.shared.success()
        } catch {
            print("Failed to save task: \(error)")
        }
    }

    private func deleteEntry(_ entry: JournalEntry) {
        modelContext.delete(entry)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background {
            Color(red: 0.06, green: 0.06, blue: 0.08).opacity(0.95)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            // Pencil icon
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.25))

            VStack(spacing: 8) {
                Text("No Notes Yet")
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundStyle(.white.opacity(0.8))

                Text("Tap the compose button to start writing")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Compose Button

    private var composeButton: some View {
        Button {
            HapticsService.shared.impact()
            selectedEntry = nil
            showEditor = true
        } label: {
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 8)

                // Button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.5),
                                Color(red: 0.95, green: 0.7, blue: 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.5), radius: 16, y: 8)

                // Icon
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color(red: 0.15, green: 0.1, blue: 0.05))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Note Row View

struct NoteRowView: View {
    let entry: JournalEntry

    private var displayTitle: String {
        if let title = entry.title, !title.isEmpty {
            return title
        }
        let firstLine = entry.plainText.split(separator: "\n").first ?? ""
        return String(firstLine.prefix(50))
    }

    private var previewText: String {
        let text = entry.plainText
        if let title = entry.title, !title.isEmpty {
            return String(text.prefix(100))
        }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        if lines.count > 1 {
            return String(lines.dropFirst().joined(separator: " ").prefix(100))
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row with optional reminder badge
            HStack(spacing: 8) {
                Text(displayTitle.isEmpty ? "New Note" : displayTitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Reminder badge
                if entry.entryType == .reminder {
                    HStack(spacing: 3) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Task")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(JournalColors.reminder)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background {
                        Capsule()
                            .fill(JournalColors.reminder.opacity(0.15))
                    }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                // Date
                Text(entry.formattedTime)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.4))

                // Preview
                if !previewText.isEmpty {
                    Text(previewText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background {
            Rectangle()
                .fill(Color.clear)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 0.5)
                .padding(.leading, 20)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Notes Editor View (Full Screen)

struct NotesEditorView: View {
    @Bindable var viewModel: JournalFeedViewModel
    var entry: JournalEntry?
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var content: String = ""
    @State private var isLoaded = false
    @State private var currentEntry: JournalEntry?
    @FocusState private var isFocused: Bool

    // Word and character count
    private var wordCount: Int {
        content.split(separator: " ").count
    }

    private var characterCount: Int {
        content.count
    }

    var body: some View {
        ZStack {
            // Background - Warm paper-like
            editorBackground

            VStack(spacing: 0) {
                // Header
                editorHeader

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 0.5)

                // Text Editor
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Date stamp
                        Text(Date().formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.top, 20)
                            .padding(.bottom, 16)

                        // Free-form text area
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Start writing...")
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(.top, 8)
                            }

                            TextEditor(text: $content)
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundStyle(.white.opacity(0.9))
                                .scrollContentBackground(.hidden)
                                .focused($isFocused)
                                .frame(minHeight: 400)
                                .lineSpacing(8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }

            // Word count footer
            VStack {
                Spacer()
                wordCountFooter
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupEntry()
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                isLoaded = true
                isFocused = true
            }
        }
        .onDisappear {
            saveEntry()
        }
    }

    // MARK: - Background

    private var editorBackground: some View {
        ZStack {
            // Warm dark paper
            Color(red: 0.07, green: 0.065, blue: 0.06)
                .ignoresSafeArea()

            // Subtle texture overlay
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.09, blue: 0.07).opacity(0.5),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack {
            // Back button
            Button {
                HapticsService.shared.selectionFeedback()
                saveEntry()
                onDismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Notes")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.4))
            }
            .buttonStyle(.plain)

            Spacer()

            // Action buttons
            HStack(spacing: 20) {
                Button {
                    // Share action
                    HapticsService.shared.selectionFeedback()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Button {
                    // More options
                    HapticsService.shared.selectionFeedback()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .padding(.top, 50)
    }

    // MARK: - Word Count Footer

    private var wordCountFooter: some View {
        HStack {
            Text("\(wordCount) words")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.35))

            Text("•")
                .foregroundStyle(.white.opacity(0.2))

            Text("\(characterCount) characters")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.35))

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background {
            Color(red: 0.06, green: 0.055, blue: 0.05)
                .ignoresSafeArea()
        }
    }

    // MARK: - Actions

    private func setupEntry() {
        if let existingEntry = entry {
            currentEntry = existingEntry
            content = existingEntry.plainText
        } else {
            // Create new entry
            currentEntry = viewModel.createEntry(type: .brainDump)
        }
    }

    private func saveEntry() {
        guard let entry = currentEntry else { return }

        // Don't save empty entries
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedContent.isEmpty {
            // Delete the entry if it's empty
            modelContext.delete(entry)
            return
        }

        // Extract title from first line if not set
        let lines = trimmedContent.split(separator: "\n", omittingEmptySubsequences: true)
        if let firstLine = lines.first {
            let titleText = String(firstLine.prefix(50))
            entry.title = titleText
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

        do {
            try modelContext.save()
        } catch {
            print("Failed to save entry: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    JournalFeedView()
        .modelContainer(for: [JournalEntry.self], inMemory: true)
}
