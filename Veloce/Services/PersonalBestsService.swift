//
//  PersonalBestsService.swift
//  Veloce
//
//  Personal Bests Tracking Service
//  Tracks and detects personal records for gamification celebrations
//

import Foundation
import SwiftUI

// MARK: - Personal Best Record

struct PersonalBestRecord: Codable, Identifiable {
    let id: UUID
    let type: String // PersonalBestType.rawValue
    let value: Int
    let achievedAt: Date

    init(type: PersonalBestType, value: Int, achievedAt: Date = .now) {
        self.id = UUID()
        self.type = type.rawValue
        self.value = value
        self.achievedAt = achievedAt
    }

    var bestType: PersonalBestType? {
        PersonalBestType(rawValue: type)
    }
}

// MARK: - Personal Bests Service

@MainActor
@Observable
final class PersonalBestsService {
    // MARK: Singleton
    static let shared = PersonalBestsService()

    // MARK: Storage Keys
    private let storageKey = "veloce_personal_bests"
    private let dailyStatsKey = "veloce_daily_stats"

    // MARK: State
    private(set) var records: [PersonalBestType: PersonalBestRecord] = [:]
    private(set) var todayStats: DailyStats

    // MARK: Daily Stats Struct
    struct DailyStats: Codable {
        var date: Date
        var tasksCompleted: Int
        var xpEarned: Int
        var focusMinutes: Int
        var longestStreak: Int

        static var empty: DailyStats {
            DailyStats(
                date: .now,
                tasksCompleted: 0,
                xpEarned: 0,
                focusMinutes: 0,
                longestStreak: 0
            )
        }

        var isToday: Bool {
            Calendar.current.isDateInToday(date)
        }
    }

    // MARK: Initialization
    private init() {
        todayStats = .empty
        loadRecords()
        loadDailyStats()
    }

    // MARK: - Record Checking

    /// Check for new personal bests after task completion
    func checkForNewRecords(
        tasksToday: Int,
        xpToday: Int,
        currentStreak: Int,
        focusMinutes: Int
    ) -> PersonalBest? {
        // Update today's stats
        updateDailyStats(
            tasks: tasksToday,
            xp: xpToday,
            streak: currentStreak,
            focus: focusMinutes
        )

        // Check each record type
        var newBest: PersonalBest?

        // Most tasks in a day
        if let best = checkRecord(.mostTasksInDay, value: tasksToday) {
            newBest = best
        }

        // Most XP in a day
        if let best = checkRecord(.mostXPInDay, value: xpToday) {
            // Only override if this is higher priority
            if newBest == nil || xpToday > tasksToday * 20 {
                newBest = best
            }
        }

        // Longest task streak
        if let best = checkRecord(.longestTaskStreak, value: currentStreak) {
            newBest = best
        }

        // Longest focus streak (in minutes)
        if let best = checkRecord(.longestFocusStreak, value: focusMinutes) {
            newBest = best
        }

        return newBest
    }

    /// Check and update a specific record
    private func checkRecord(_ type: PersonalBestType, value: Int) -> PersonalBest? {
        let currentRecord = records[type]?.value ?? 0

        // Must beat the record, not tie it
        guard value > currentRecord else { return nil }

        // Create new record
        let newRecord = PersonalBestRecord(type: type, value: value)
        records[type] = newRecord
        saveRecords()

        // Create personal best for celebration
        return PersonalBest(
            type: type,
            value: value,
            previousValue: currentRecord
        )
    }

    /// Check best week (called at end of week)
    func checkBestWeek(weeklyTasks: Int) -> PersonalBest? {
        return checkRecord(.bestWeek, value: weeklyTasks)
    }

    // MARK: - Daily Stats

    private func updateDailyStats(
        tasks: Int,
        xp: Int,
        streak: Int,
        focus: Int
    ) {
        // Reset if new day
        if !todayStats.isToday {
            todayStats = .empty
        }

        todayStats.tasksCompleted = tasks
        todayStats.xpEarned = xp
        todayStats.longestStreak = max(todayStats.longestStreak, streak)
        todayStats.focusMinutes = focus

        saveDailyStats()
    }

    // MARK: - Public Accessors

    /// Get record for a specific type
    func record(for type: PersonalBestType) -> PersonalBestRecord? {
        records[type]
    }

    /// Get all records sorted by type
    var allRecords: [PersonalBestRecord] {
        PersonalBestType.allCases.compactMap { records[$0] }
    }

    /// Check if a value beats the current record
    func wouldBeatRecord(_ type: PersonalBestType, value: Int) -> Bool {
        let current = records[type]?.value ?? 0
        return value > current
    }

    /// Get formatted record value
    func formattedValue(for type: PersonalBestType) -> String {
        guard let record = records[type] else { return "—" }

        switch type {
        case .longestFocusStreak:
            let hours = record.value / 60
            let minutes = record.value % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(minutes)m"

        default:
            return "\(record.value)"
        }
    }

    // MARK: - Persistence

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PersonalBestRecord].self, from: data)
        else { return }

        for record in decoded {
            if let type = record.bestType {
                records[type] = record
            }
        }
    }

    private func saveRecords() {
        let recordsArray = Array(records.values)
        if let encoded = try? JSONEncoder().encode(recordsArray) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadDailyStats() {
        guard let data = UserDefaults.standard.data(forKey: dailyStatsKey),
              let decoded = try? JSONDecoder().decode(DailyStats.self, from: data)
        else { return }

        todayStats = decoded.isToday ? decoded : .empty
    }

    private func saveDailyStats() {
        if let encoded = try? JSONEncoder().encode(todayStats) {
            UserDefaults.standard.set(encoded, forKey: dailyStatsKey)
        }
    }

    // MARK: - Reset (for testing)

    func resetAllRecords() {
        records.removeAll()
        todayStats = .empty
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: dailyStatsKey)
    }
}

// MARK: - Personal Bests Display View

struct PersonalBestsView: View {
    let service = PersonalBestsService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.Celebration.starGold)

                Text("Personal Bests")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Records grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PersonalBestType.allCases, id: \.self) { type in
                    PersonalBestCard(
                        type: type,
                        record: service.record(for: type)
                    )
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

struct PersonalBestCard: View {
    let type: PersonalBestType
    let record: PersonalBestRecord?

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: type.icon)
                .font(.system(size: 24))
                .foregroundStyle(type.color)

            // Value
            Text(formattedValue)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Type label
            Text(type.rawValue)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay {
                    if record != nil {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(type.color.opacity(0.3), lineWidth: 1)
                    }
                }
        }
    }

    private var formattedValue: String {
        guard let record = record else { return "—" }

        switch type {
        case .longestFocusStreak:
            let hours = record.value / 60
            let minutes = record.value % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(minutes)m"

        default:
            return "\(record.value)"
        }
    }
}

// MARK: - New Record Banner

struct NewRecordBanner: View {
    let personalBest: PersonalBest
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        if isShowing {
            VStack(spacing: 16) {
                // Trophy with glow
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Celebration.starGold.opacity(0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.Celebration.starGold,
                                    Theme.Celebration.solarFlare
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Theme.Celebration.starGold.opacity(0.8), radius: 20)
                }

                VStack(spacing: 8) {
                    Text("NEW RECORD!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.Celebration.starGold,
                                    Theme.Celebration.solarFlare,
                                    Theme.Celebration.starGold
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay {
                            // Shimmer effect
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset)
                                .mask {
                                    Text("NEW RECORD!")
                                        .font(.system(size: 24, weight: .black, design: .rounded))
                                }
                        }

                    Text(personalBest.type.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        // Old value
                        if personalBest.previousValue > 0 {
                            Text("\(personalBest.previousValue)")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                                .strikethrough()
                        }

                        // Arrow
                        Image(systemName: "arrow.right")
                            .foregroundStyle(Theme.Celebration.auroraGreen)

                        // New value
                        Text("\(personalBest.value)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Celebration.auroraGreen)
                    }
                }
            }
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Theme.Celebration.starGold.opacity(0.5),
                                        Theme.Celebration.solarFlare.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: Theme.Celebration.starGold.opacity(0.3), radius: 30, y: 10)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }

                // Shimmer animation
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }

                // Auto-dismiss
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                        scale = 0.9
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Personal Bests") {
    ZStack {
        Color.black.ignoresSafeArea()

        PersonalBestsView()
            .padding()
    }
}

#Preview("New Record") {
    ZStack {
        Color.black.ignoresSafeArea()

        NewRecordBanner(
            personalBest: PersonalBest(
                type: .mostTasksInDay,
                value: 15,
                previousValue: 12
            ),
            isShowing: .constant(true)
        )
    }
}
