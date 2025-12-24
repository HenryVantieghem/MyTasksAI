//
//  JournalFeedViewModel.swift
//  Veloce
//
//  Journal Feed View Model - Manages journal entries, filtering, and AI features
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Journal Feed View Model

@Observable
@MainActor
class JournalFeedViewModel {
    // MARK: State
    var entries: [JournalEntry] = []
    var selectedDate: Date = Date()
    var selectedFilter: JournalEntryType?
    var isLoading: Bool = false
    var errorMessage: String?
    var showDatePicker: Bool = false

    // MARK: AI Features
    var dailyPrompt: String?
    var gratitudeStreak: Int = 0

    // MARK: Search
    var searchText: String = ""
    var searchResults: [JournalEntry] = []

    // MARK: Private
    private var modelContext: ModelContext?

    // MARK: Computed Properties

    var filteredEntries: [JournalEntry] {
        var result = entries

        if let filter = selectedFilter {
            result = result.filter { $0.entryType == filter }
        }

        // Sort: pinned first, then by creation date (newest first)
        return result.sorted { entry1, entry2 in
            if entry1.isPinned != entry2.isPinned {
                return entry1.isPinned
            }
            return entry1.createdAt > entry2.createdAt
        }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var formattedSelectedDate: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: Setup

    func setup(context: ModelContext) {
        self.modelContext = context
        Task {
            await loadEntries(for: selectedDate)
            await loadGratitudeStreak()
            await generateDailyPrompt()
        }
    }

    // MARK: Load Entries

    func loadEntries(for date: Date) async {
        guard let context = modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        let normalizedDate = Calendar.current.startOfDay(for: date)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: normalizedDate)!

        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate<JournalEntry> { entry in
                entry.date >= normalizedDate && entry.date < nextDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            entries = try context.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load entries: \(error.localizedDescription)"
            entries = []
        }
    }

    // MARK: Create Entry

    func createEntry(type: JournalEntryType) -> JournalEntry {
        let entry = JournalEntry(
            date: selectedDate,
            entryType: type,
            userId: SupabaseService.shared.currentUserId
        )

        modelContext?.insert(entry)

        do {
            try modelContext?.save()
            entries.insert(entry, at: 0)
        } catch {
            errorMessage = "Failed to create entry: \(error.localizedDescription)"
        }

        return entry
    }

    // MARK: Delete Entry

    func deleteEntry(_ entry: JournalEntry) {
        modelContext?.delete(entry)

        do {
            try modelContext?.save()
            entries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
        }
    }

    // MARK: Toggle Pin

    func togglePin(_ entry: JournalEntry) {
        entry.isPinned.toggle()
        entry.updatedAt = .now

        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Failed to update entry: \(error.localizedDescription)"
        }
    }

    // MARK: Toggle Favorite

    func toggleFavorite(_ entry: JournalEntry) {
        entry.isFavorite.toggle()
        entry.updatedAt = .now

        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Failed to update entry: \(error.localizedDescription)"
        }
    }

    // MARK: Date Navigation

    func previousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }

    func nextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }

    func goToToday() {
        selectedDate = Date()
    }

    // MARK: Gratitude Streak

    func loadGratitudeStreak() async {
        guard let context = modelContext else { return }

        // Count consecutive days with gratitude entries going backward from today
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        while true {
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!

            let descriptor = FetchDescriptor<JournalEntry>(
                predicate: #Predicate<JournalEntry> { entry in
                    entry.date >= currentDate &&
                    entry.date < nextDay &&
                    entry.entryTypeRaw == "gratitude"
                }
            )

            do {
                let entries = try context.fetch(descriptor)
                if entries.isEmpty {
                    break
                }
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } catch {
                break
            }
        }

        gratitudeStreak = streak
    }

    // MARK: AI Features

    func generateDailyPrompt() async {
        // Generate a personalized daily prompt based on user's goals and recent activity
        // For now, use a curated list of prompts

        let prompts = [
            "What's one thing you're looking forward to today?",
            "Describe a challenge you're facing and how you plan to overcome it.",
            "What made you smile recently?",
            "If you could change one thing about yesterday, what would it be?",
            "What are you most grateful for right now?",
            "What's a goal you're working towards?",
            "Describe your ideal day.",
            "What's something you've learned recently?",
            "Who has positively influenced your life lately?",
            "What's weighing on your mind?",
            "What accomplishment are you proud of?",
            "How are you taking care of yourself today?",
            "What's a habit you want to build or break?",
            "Describe a moment of peace you experienced recently.",
            "What would you tell your past self?"
        ]

        // Use date to consistently select a prompt for the day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let promptIndex = dayOfYear % prompts.count

        dailyPrompt = prompts[promptIndex]
    }

    // MARK: Search

    func searchEntries(query: String) async {
        guard let context = modelContext, !query.isEmpty else {
            searchResults = []
            return
        }

        let searchQuery = query.lowercased()

        // Fetch all entries and filter by content
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let allEntries = try context.fetch(descriptor)
            searchResults = allEntries.filter { entry in
                let plainText = entry.plainText.lowercased()
                let title = entry.title?.lowercased() ?? ""
                return plainText.contains(searchQuery) || title.contains(searchQuery)
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            searchResults = []
        }
    }

    // MARK: Analytics

    func getEntryCounts() async -> [JournalEntryType: Int] {
        guard let context = modelContext else { return [:] }

        var counts: [JournalEntryType: Int] = [:]

        for type in JournalEntryType.allCases {
            let typeRaw = type.rawValue
            let descriptor = FetchDescriptor<JournalEntry>(
                predicate: #Predicate<JournalEntry> { entry in
                    entry.entryTypeRaw == typeRaw
                }
            )

            do {
                let count = try context.fetchCount(descriptor)
                counts[type] = count
            } catch {
                counts[type] = 0
            }
        }

        return counts
    }

    func getMoodTrend(days: Int = 7) async -> [(Date, JournalMood?)] {
        guard let context = modelContext else { return [] }

        var trend: [(Date, JournalMood?)] = []
        let today = Calendar.current.startOfDay(for: Date())

        for dayOffset in (0..<days).reversed() {
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!

            let descriptor = FetchDescriptor<JournalEntry>(
                predicate: #Predicate<JournalEntry> { entry in
                    entry.date >= date && entry.date < nextDay
                }
            )

            do {
                let entries = try context.fetch(descriptor)
                // Get the most recent mood for the day
                let mood = entries.compactMap { $0.mood }.first
                trend.append((date, mood))
            } catch {
                trend.append((date, nil))
            }
        }

        return trend
    }
}
