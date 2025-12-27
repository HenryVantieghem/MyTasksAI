//
//  GrowView.swift
//  Veloce
//
//  Grow Tab - Contains 3 segments: Stats, Goals, Circles
//  Replaces MomentumDataArtView and absorbs Circles functionality
//

import SwiftUI
import SwiftData

// MARK: - Grow Segment Enum

enum GrowSegment: String, CaseIterable {
    case stats = "Stats"
    case goals = "Goals"
    case circles = "Circles"

    var icon: String {
        switch self {
        case .stats: return "chart.bar.fill"
        case .goals: return "leaf.fill"
        case .circles: return "person.2.fill"
        }
    }
}

// MARK: - Grow View

struct GrowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query(sort: \Goal.targetDate) private var goals: [Goal]

    @State private var selectedSegment: GrowSegment = .stats
    @State private var goalsVM = GoalsViewModel()

    private var gamification: GamificationService { GamificationService.shared }

    var body: some View {
        ZStack {
            // Cosmic void background
            VoidBackground.calendar

            VStack(spacing: 0) {
                // Segmented Picker
                segmentPicker
                    .padding(.top, 80) // Below universal header
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // Content
                TabView(selection: $selectedSegment) {
                    StatsContentView(
                        velocityScore: gamification.velocityScore,
                        streak: gamification.currentStreak,
                        longestStreak: gamification.longestStreak,
                        tasksCompleted: gamification.totalTasksCompleted,
                        tasksCompletedToday: gamification.tasksCompletedToday,
                        dailyGoal: gamification.dailyGoal,
                        focusHours: gamification.focusHours,
                        completionRate: gamification.completionRate,
                        level: gamification.currentLevel,
                        totalPoints: gamification.totalPoints,
                        levelProgress: gamification.levelProgress
                    )
                    .tag(GrowSegment.stats)

                    GoalsContentView(
                        goals: goals,
                        goalsVM: goalsVM
                    )
                    .tag(GrowSegment.goals)

                    CirclesContentView()
                        .tag(GrowSegment.circles)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .task {
            await goalsVM.loadGoals(context: modelContext)
        }
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(GrowSegment.allCases, id: \.self) { segment in
                segmentTab(segment)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.04, green: 0.05, blue: 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func segmentTab(_ segment: GrowSegment) -> some View {
        let isSelected = selectedSegment == segment

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedSegment = segment
            }
            HapticsService.shared.impact(.light)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: segment.icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(segment.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.Colors.aiPurple.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.Colors.aiPurple.opacity(0.5), lineWidth: 1)
                        )
                    : nil
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GrowView()
        .preferredColorScheme(.dark)
}
