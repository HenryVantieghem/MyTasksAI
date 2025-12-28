//
//  FocusHistoryView.swift
//  Veloce
//
//  Focus Session History & Analytics - Opal-style insights
//  Shows screen time saved, streaks, weekly progress, and session history
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Focus History View

struct FocusHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSessionRecord.startedAt, order: .reverse) private var sessions: [FocusSessionRecord]

    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedTimeRange: TimeRange = .week

    private var statistics: FocusStatistics {
        FocusStatistics.calculate(from: sessions)
    }

    private var filteredSessions: [FocusSessionRecord] {
        switch selectedFilter {
        case .all:
            return sessions
        case .completed:
            return sessions.filter { $0.wasCompleted }
        case .canceled:
            return sessions.filter { $0.wasCanceled }
        }
    }

    private var weeklyData: [DailyFocusData] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let daySessions = sessions.filter { session in
                session.startedAt >= dayStart && session.startedAt < dayEnd && session.wasCompleted
            }

            let totalMinutes = daySessions.reduce(0) { $0 + $1.durationMinutes }

            return DailyFocusData(
                date: date,
                minutes: totalMinutes,
                sessionCount: daySessions.count
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Stats Cards
                statsCardsSection

                // Weekly Chart
                weeklyChartSection

                // Streak Section
                streakSection

                // Session History
                sessionHistorySection

                // Bottom padding
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.top, Theme.Spacing.md)
        }
    }

    // MARK: - Stats Cards

    private var statsCardsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Total Focus Time
                HistoryStatCard(
                    title: "Total Focus",
                    value: formatDuration(statistics.totalMinutesFocused),
                    icon: "timer",
                    color: Theme.Colors.aiAmber
                )

                // Sessions Completed
                HistoryStatCard(
                    title: "Sessions",
                    value: "\(statistics.totalSessionsCompleted)",
                    icon: "checkmark.circle.fill",
                    color: Theme.Colors.success
                )
            }

            HStack(spacing: 12) {
                // Deep Focus Sessions
                HistoryStatCard(
                    title: "Deep Focus",
                    value: "\(statistics.deepFocusSessionsCompleted)",
                    icon: "lock.fill",
                    color: Theme.Colors.aiPurple
                )

                // Average Duration
                HistoryStatCard(
                    title: "Avg Duration",
                    value: "\(statistics.averageSessionDuration)m",
                    icon: "chart.bar.fill",
                    color: Theme.Colors.aiBlue
                )
            }
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(weeklyData.reduce(0) { $0 + $1.minutes }) min")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiAmber)
            }

            // Chart
            Chart(weeklyData) { data in
                BarMark(
                    x: .value("Day", data.date, unit: .day),
                    y: .value("Minutes", data.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.aiAmber, Theme.Colors.aiOrange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .chartYAxis {
                AxisMarks { mark in
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.4))
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.1))
                }
            }
            .frame(height: 160)
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: 16) {
            // Current Streak
            VStack(spacing: 8) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.fire.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.fire, Theme.Colors.streakOrange],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }

                Text("\(statistics.currentStreak)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Day Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

            // Longest Streak
            VStack(spacing: 8) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.gold.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Colors.gold)
                }

                Text("\(statistics.longestStreak)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Best Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Session History

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Session History")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                // Filter picker
                Menu {
                    ForEach(HistoryFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedFilter.rawValue)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(.white.opacity(0.1))
                    }
                }
            }

            if filteredSessions.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.white.opacity(0.4))

                    Text("No sessions yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredSessions.prefix(10)) { session in
                        SessionHistoryRow(session: session)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Supporting Types

enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case completed = "Completed"
    case canceled = "Canceled"
}

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct DailyFocusData: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
    let sessionCount: Int
}

// MARK: - History Stat Card

struct HistoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Session History Row

struct SessionHistoryRow: View {
    let session: FocusSessionRecord

    private var statusColor: Color {
        if session.wasCompleted {
            return Theme.Colors.success
        } else if session.wasCanceled {
            return Theme.Colors.error
        }
        return Theme.Colors.warning
    }

    private var statusIcon: String {
        if session.wasCompleted {
            return "checkmark.circle.fill"
        } else if session.wasCanceled {
            return "xmark.circle.fill"
        }
        return "clock.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: statusIcon)
                .font(.system(size: 16))
                .foregroundStyle(statusColor)

            // Session info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text(session.startedAt, format: .dateTime.month().day().hour().minute())
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))

                    Text(session.formattedDuration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            // Points earned
            if session.pointsEarned > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("+\(session.pointsEarned)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Theme.Colors.gold)
            }

            // Deep Focus badge
            if session.isDeepFocus {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.aiAmber)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        }
    }
}

// MARK: - Preview

#Preview {
    FocusHistoryView()
        .preferredColorScheme(.dark)
}
