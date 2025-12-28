//
//  InlineBlockingSection.swift
//  Veloce
//
//  Inline App Blocking section with horizontal tab-style content
//  Overview, Schedules, and Groups accessible without leaving Flow page
//

import SwiftUI
import FamilyControls

// MARK: - Inline Blocking Section

struct InlineBlockingSection: View {
    @State private var selectedTab: BlockingTab = .overview
    @State private var showScheduleCreator = false
    @State private var showGroupCreator = false
    @State private var showAppPicker = false

    // Screen time sample data (would come from ScreenTime API)
    @State private var todayScreenTime: TimeInterval = 4.5 * 3600
    @State private var weeklyAverage: TimeInterval = 5.2 * 3600
    @State private var pickupsToday: Int = 67

    // Services
    private let blockingService = FocusBlockingService.shared

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            // Tab Bar
            BlockingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 24)

            // Content based on selected tab
            TabView(selection: $selectedTab) {
                overviewContent
                    .tag(BlockingTab.overview)

                schedulesContent
                    .tag(BlockingTab.schedules)

                groupsContent
                    .tag(BlockingTab.groups)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(minHeight: 500)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
        }
        .sheet(isPresented: $showScheduleCreator) {
            BlockingScheduleCreatorView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showGroupCreator) {
            AppGroupCreatorView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .familyActivityPicker(
            isPresented: $showAppPicker,
            selection: Bindable(blockingService).selectedAppsToBlock
        )
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Screen Time Hero Card
                screenTimeCard
                    .padding(.horizontal, 20)

                // Quick Stats Row
                quickStatsRow
                    .padding(.horizontal, 20)

                // Quick Block Actions
                quickBlockActions
                    .padding(.horizontal, 20)

                // AI Insight
                aiInsightCard
                    .padding(.horizontal, 20)

                // Active Blocks Status
                activeBlocksCard
                    .padding(.horizontal, 20)

                Spacer(minLength: Theme.Spacing.floatingTabBarClearance)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Screen Time Card

    private var screenTimeCard: some View {
        VStack(spacing: 12) {
            // Ring + Time
            HStack(spacing: 20) {
                // Usage ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: min(todayScreenTime / (8 * 3600), 1))
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.aiCyan, Theme.Colors.aiPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(todayScreenTime))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Today's Screen Time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    // Comparison
                    HStack(spacing: 4) {
                        Image(systemName: todayScreenTime < weeklyAverage ? "arrow.down" : "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                        Text(formatTimeDiff(todayScreenTime - weeklyAverage) + " vs avg")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(todayScreenTime < weeklyAverage ? Theme.Colors.success : Theme.Colors.aiOrange)
                }

                Spacer()
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.aiCyan.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "2h 45m", label: "Focus", icon: "flame.fill", color: Theme.Colors.aiOrange)
            statCard(value: "12", label: "Blocked", icon: "shield.fill", color: Theme.Colors.aiCyan)
            statCard(value: "\(pickupsToday)", label: "Pickups", icon: "hand.tap.fill", color: Theme.Colors.aiPurple)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.4))
        }
    }

    // MARK: - Quick Block Actions

    private var quickBlockActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 10) {
                quickActionButton(
                    title: "Block Now",
                    icon: "shield.lefthalf.filled",
                    color: Theme.Colors.aiCyan
                ) {
                    showAppPicker = true
                }

                quickActionButton(
                    title: "Focus Mode",
                    icon: "moon.fill",
                    color: Theme.Colors.aiPurple
                ) {
                    // Start focus mode
                }
            }
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.25))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Insight Card

    private var aiInsightCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Insight")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("Usage spikes after 9 PM. Consider blocking social apps then.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.4))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.Colors.aiPurple.opacity(0.25), lineWidth: 1)
                }
        }
    }

    // MARK: - Active Blocks Card

    private var activeBlocksCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(blockingService.isBlocking ? Theme.Colors.success : .white.opacity(0.3))
                        .frame(width: 8, height: 8)

                    Text(blockingService.isBlocking ? "Blocking Active" : "No Active Blocks")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                if blockingService.isBlocking {
                    Text("12 apps blocked")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            if blockingService.isBlocking {
                Button {
                    Task { await blockingService.endSession() }
                } label: {
                    Text("End")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background {
                            Capsule()
                                .fill(Theme.Colors.error.opacity(0.3))
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.4))
        }
    }

    // MARK: - Schedules Content

    private var schedulesContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Create Schedule Button
                Button {
                    showScheduleCreator = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))

                        Text("Create Schedule")
                            .font(.system(size: 15, weight: .semibold))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .foregroundStyle(.white)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.Colors.aiCyan.opacity(0.2))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.aiCyan.opacity(0.4), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // Sample Schedules
                scheduleRow(name: "Morning Focus", time: "6:00 AM - 9:00 AM", days: "Weekdays", isActive: true)
                scheduleRow(name: "Work Hours", time: "9:00 AM - 5:00 PM", days: "Weekdays", isActive: true)
                scheduleRow(name: "Wind Down", time: "9:00 PM - 11:00 PM", days: "Every day", isActive: false)

                Spacer(minLength: Theme.Spacing.floatingTabBarClearance)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    private func scheduleRow(name: String, time: String, days: String, isActive: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.Colors.success)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(Theme.Colors.success.opacity(0.2))
                            }
                    }
                }

                HStack(spacing: 6) {
                    Text(time)
                        .font(.system(size: 12))
                    Text("•")
                    Text(days)
                        .font(.system(size: 12))
                }
                .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: .constant(isActive))
                .labelsHidden()
                .tint(Theme.Colors.aiCyan)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.4))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Groups Content

    private var groupsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Create Group Button
                Button {
                    showGroupCreator = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))

                        Text("Create App Group")
                            .font(.system(size: 15, weight: .semibold))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .foregroundStyle(.white)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.Colors.aiPurple.opacity(0.2))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.aiPurple.opacity(0.4), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // Sample Groups
                groupRow(name: "Social Media", appCount: 5, color: .pink, icon: "bubble.left.and.bubble.right.fill")
                groupRow(name: "Entertainment", appCount: 8, color: .purple, icon: "tv.fill")
                groupRow(name: "Games", appCount: 12, color: .orange, icon: "gamecontroller.fill")
                groupRow(name: "News & Reading", appCount: 4, color: .blue, icon: "newspaper.fill")

                Spacer(minLength: Theme.Spacing.floatingTabBarClearance)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    private func groupRow(name: String, appCount: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text("\(appCount) apps")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.4))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func formatTimeDiff(_ diff: TimeInterval) -> String {
        let absDiff = abs(diff)
        let hours = Int(absDiff) / 3600
        let minutes = (Int(absDiff) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview("Inline Blocking Section") {
    ZStack {
        LinearGradient(
            colors: [
                Theme.CelestialColors.voidDeep,
                Theme.CelestialColors.void,
                Theme.CelestialColors.abyss
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        InlineBlockingSection()
    }
    .preferredColorScheme(.dark)
}
