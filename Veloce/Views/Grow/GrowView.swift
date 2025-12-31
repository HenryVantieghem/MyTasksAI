//
//  GrowView.swift
//  Veloce
//
//  Utopian Design System - Growth Dashboard
//  Grow Tab - Contains 3 segments: Stats, Goals, Circles
//  Time-aware gradients with gold gamification theme
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

    var accentColor: Color {
        switch self {
        case .stats: return UtopianDesignFallback.Colors.focusActive      // Cyan for stats
        case .goals: return UtopianDesignFallback.Colors.completed        // Green for goals
        case .circles: return UtopianDesignFallback.Colors.aiPurple       // Purple for circles
        }
    }
}

// MARK: - Grow View

struct GrowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var tasks: [TaskItem]
    @Query(sort: \Goal.targetDate) private var goals: [Goal]

    @State private var selectedSegment: GrowSegment = .stats
    @State private var goalsVM = GoalsViewModel()

    private var gamification: GamificationService { GamificationService.shared }

    var body: some View {
        ZStack {
            // Utopian time-aware gradient background
            UtopianGradients.background(for: Date())
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Utopian Segmented Picker
                utopianSegmentPicker
                    .padding(.top, 80) // Below universal header
                    .padding(.horizontal, UtopianDesignFallback.Spacing.screenPadding)
                    .padding(.bottom, UtopianDesignFallback.Spacing.lg)

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

    // MARK: - Utopian Segment Picker

    private var utopianSegmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(GrowSegment.allCases, id: \.self) { segment in
                utopianSegmentTab(segment)
            }
        }
        .padding(UtopianDesignFallback.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    UtopianDesignFallback.Colors.focusActive.opacity(0.2),
                                    UtopianDesignFallback.Colors.aiPurple.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }

    private func utopianSegmentTab(_ segment: GrowSegment) -> some View {
        let isSelected = selectedSegment == segment

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedSegment = segment
            }
            HapticsService.shared.lightImpact()
        } label: {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                ZStack {
                    // Glow behind icon when selected
                    if isSelected {
                        Image(systemName: segment.icon)
                            .dynamicTypeFont(base: 12, weight: .semibold)
                            .foregroundStyle(segment.accentColor)
                            .blur(radius: 4)
                    }

                    Image(systemName: segment.icon)
                        .dynamicTypeFont(base: 12, weight: .semibold)
                }

                Text(segment.rawValue)
                    .font(UtopianDesignFallback.Typography.body)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, UtopianDesignFallback.Spacing.lg)
            .padding(.vertical, UtopianDesignFallback.Spacing.md)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(segment.accentColor.opacity(0.2))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            segment.accentColor.opacity(0.5),
                                            segment.accentColor.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: segment.accentColor.opacity(0.3), radius: 8, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GrowView()
        .preferredColorScheme(.dark)
}
