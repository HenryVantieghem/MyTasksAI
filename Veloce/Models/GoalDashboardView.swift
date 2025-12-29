//
//  GoalDashboardView.swift
//  MyTasksAI
//
//  Beautiful dashboard showcasing all the colorful components
//

import SwiftUI

struct GoalDashboardView: View {
    @State private var goals: [Goal] = []
    @State private var selectedTimeframe: GoalTimeframe = .horizon
    @Namespace private var glassNamespace
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with stats
                headerSection
                
                // Featured goal (Hero card)
                if let featuredGoal = goals.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Featured Goal")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        GoalCardHeroView(goal: featuredGoal)
                    }
                }
                
                // Timeframe selector
                timeframeSelector
                
                // Goals grid
                goalsGrid
                
                // Quick actions
                quickActionsSection
            }
            .padding()
        }
        .background {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05),
                    Color.pink.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Welcome message
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Goals")
                        .font(.largeTitle.weight(.bold))
                    
                    Text("Keep pushing forward! 🚀")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Stats row with glass containers
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    GoalStatCard(
                        icon: "target",
                        value: "\(goals.count)",
                        label: "Active Goals",
                        iconColor: .blue
                    )

                    GoalStatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "\(Int(averageProgress * 100))%",
                        label: "Avg Progress",
                        iconColor: .green
                    )

                    GoalStatCard(
                        icon: "flame.fill",
                        value: "\(longestStreak)",
                        label: "Best Streak",
                        iconColor: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Timeframe Selector
    
    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GoalTimeframe.allCases, id: \.self) { timeframe in
                    TimeframeChip(
                        timeframe: timeframe,
                        isSelected: selectedTimeframe == timeframe
                    ) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                            selectedTimeframe = timeframe
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Goals Grid
    
    private var goalsGrid: some View {
        VStack(spacing: 16) {
            ForEach(filteredGoals) { goal in
                GoalCardView(goal: goal)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3.weight(.semibold))
            
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    GoalQuickActionButton(
                        icon: "plus.circle.fill",
                        title: "New Goal",
                        color: .blue
                    ) {
                        // Add new goal
                    }

                    GoalQuickActionButton(
                        icon: "checkmark.circle.fill",
                        title: "Check In",
                        color: .green
                    ) {
                        // Check in
                    }

                    GoalQuickActionButton(
                        icon: "chart.bar.fill",
                        title: "Analytics",
                        color: .purple
                    ) {
                        // Show analytics
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredGoals: [Goal] {
        goals.filter { goal in
            goal.timeframeEnum == selectedTimeframe
        }
    }
    
    private var averageProgress: Double {
        guard !goals.isEmpty else { return 0 }
        return goals.map(\.progress).reduce(0, +) / Double(goals.count)
    }
    
    private var longestStreak: Int {
        goals.map(\.checkInStreak).max() ?? 0
    }
}

// MARK: - Supporting Views

struct GoalStatCard: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(iconColor.opacity(0.1))
        }
        .glassEffect(.regular.tint(iconColor), in: .rect(cornerRadius: 16))
    }
}

struct TimeframeChip: View {
    let timeframe: GoalTimeframe
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: timeframe.icon)
                    .font(.caption)
                
                Text(timeframe.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : timeframe.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    timeframe.color,
                                    timeframe.color.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .matchedGeometryEffect(id: "selector", in: glassNamespace)
                        .glassEffect(.regular.tint(timeframe.color), in: .capsule)
                } else {
                    Capsule()
                        .stroke(timeframe.color.opacity(0.3), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    @Namespace private var glassNamespace
}

struct GoalQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                .glassEffect(.regular.tint(color).interactive(), in: .circle)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.05))
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    GoalDashboardView()
}

#Preview("With Sample Data") {
    GoalDashboardView()
        .onAppear {
            // Add sample goals for preview
        }
}
