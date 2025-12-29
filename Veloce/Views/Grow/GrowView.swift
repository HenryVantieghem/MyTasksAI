//
//  GrowView.swift
//  Veloce
//
//  Aurora Design System - Energy Core Dashboard
//  Grow Tab - Contains 3 segments: Stats, Goals, Circles
//  Energy visualization with aurora particles and prismatic glass
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

    var auroraColor: Color {
        switch self {
        case .stats: return Aurora.Colors.electricCyan
        case .goals: return Aurora.Colors.prismaticGreen
        case .circles: return Aurora.Colors.stellarMagenta
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
            // Aurora cosmic void background
            Aurora.Colors.voidCosmos
                .ignoresSafeArea()

            // Subtle aurora waves responding to segment
            if !reduceMotion {
                AuroraAnimatedWaveBackground(
                    colors: [
                        selectedSegment.auroraColor.opacity(0.3),
                        Aurora.Colors.borealisViolet.opacity(0.2)
                    ]
                )
                .ignoresSafeArea()
                .opacity(0.4)
            }

            VStack(spacing: 0) {
                // Aurora Segmented Picker
                auroraSegmentPicker
                    .padding(.top, 80) // Below universal header
                    .padding(.horizontal, Aurora.Spacing.screenPadding)
                    .padding(.bottom, Aurora.Spacing.lg)

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

    // MARK: - Aurora Segment Picker

    private var auroraSegmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(GrowSegment.allCases, id: \.self) { segment in
                auroraSegmentTab(segment)
            }
        }
        .padding(Aurora.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Aurora.Colors.voidNebula.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Aurora.Colors.electricCyan.opacity(0.2),
                                    Aurora.Colors.borealisViolet.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .auroraGlass(in: RoundedRectangle(cornerRadius: 24))
    }

    private func auroraSegmentTab(_ segment: GrowSegment) -> some View {
        let isSelected = selectedSegment == segment

        return Button {
            withAnimation(AuroraMotion.Spring.ui) {
                selectedSegment = segment
            }
            AuroraHaptics.light()
            AuroraSoundEngine.shared.play(.tabSwitch)
        } label: {
            HStack(spacing: Aurora.Spacing.sm) {
                ZStack {
                    // Glow behind icon when selected
                    if isSelected {
                        Image(systemName: segment.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(segment.auroraColor)
                            .blur(radius: 4)
                    }

                    Image(systemName: segment.icon)
                        .font(.system(size: 12, weight: .semibold))
                }

                Text(segment.rawValue)
                    .font(Aurora.Typography.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? Aurora.Colors.textPrimary : Aurora.Colors.textTertiary)
            .padding(.horizontal, Aurora.Spacing.lg)
            .padding(.vertical, Aurora.Spacing.md)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(segment.auroraColor.opacity(0.2))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            segment.auroraColor.opacity(0.5),
                                            segment.auroraColor.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: segment.auroraColor.opacity(0.3), radius: 8, y: 2)
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
