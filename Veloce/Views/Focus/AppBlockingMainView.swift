//
//  AppBlockingMainView.swift
//  Veloce
//
//  Opal-inspired app blocking dashboard
//  Screen time analytics, AI insights, schedules, and app groups
//

import SwiftUI
import FamilyControls

// MARK: - App Blocking Main View

struct AppBlockingMainView: View {
    @State private var selectedTab: BlockingTab = .overview
    @State private var showScheduleCreator = false
    @State private var showGroupCreator = false
    @State private var showAppPicker = false

    // Sample data (would come from ScreenTime API)
    @State private var todayScreenTime: TimeInterval = 4.5 * 3600 // 4.5 hours
    @State private var weeklyAverage: TimeInterval = 5.2 * 3600
    @State private var pickupsToday: Int = 67
    @State private var mostUsedApps: [AppUsageData] = AppUsageData.sampleData

    // Services
    private let blockingService = FocusBlockingService.shared

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var headerScale: CGFloat = 0.95
    @State private var cardsAppeared = false

    var body: some View {
        ZStack {
            // Cosmic background
            cosmicBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                navigationHeader

                // Tab selector
                tabSelector
                    .padding(.top, Theme.Spacing.md)

                // Content based on selected tab
                ScrollView {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .schedules:
                        schedulesContent
                    case .groups:
                        groupsContent
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
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
            selection: .constant(FamilyActivitySelection())
        )
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Cosmic Background

    private var cosmicBackground: some View {
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

            // Subtle cyan accent glow
            RadialGradient(
                colors: [
                    Theme.Colors.aiCyan.opacity(0.08),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 400
            )

            // Purple accent
            RadialGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.06),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 350
            )
        }
    }

    // MARK: - Navigation Header

    private var navigationHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            Text("App Blocking")
                .dynamicTypeFont(base: 18, weight: .semibold)
                .foregroundStyle(.white)

            Spacer()

            // Quick block button
            Button {
                showAppPicker = true
            } label: {
                Image(systemName: "plus")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.Colors.aiCyan))
            }
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.top, 60)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(BlockingTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.title)
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(Theme.Colors.aiCyan.opacity(0.3))
                            }
                        }
                }
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Screen time hero card
            screenTimeHeroCard
                .scaleEffect(headerScale)
                .opacity(cardsAppeared ? 1 : 0)

            // AI Insight card
            aiInsightCard
                .opacity(cardsAppeared ? 1 : 0)
                .offset(y: cardsAppeared ? 0 : 20)

            // Quick stats row
            quickStatsRow
                .opacity(cardsAppeared ? 1 : 0)
                .offset(y: cardsAppeared ? 0 : 20)

            // Most used apps
            mostUsedAppsSection
                .opacity(cardsAppeared ? 1 : 0)
                .offset(y: cardsAppeared ? 0 : 20)

            // Active blocks
            activeBlocksSection
                .opacity(cardsAppeared ? 1 : 0)
                .offset(y: cardsAppeared ? 0 : 20)
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, 100)
    }

    private var screenTimeHeroCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Usage ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Progress ring
                Circle()
                    .trim(from: 0, to: min(todayScreenTime / (8 * 3600), 1)) // Cap at 8 hours
                    .stroke(
                        LinearGradient(
                            colors: [Theme.Colors.aiCyan, Theme.Colors.aiPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(formatTime(todayScreenTime))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("today")
                        .dynamicTypeFont(base: 13, weight: .medium)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Comparison
            HStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: todayScreenTime < weeklyAverage ? "arrow.down" : "arrow.up")
                            .dynamicTypeFont(base: 12, weight: .bold)
                        Text(formatTimeDifference(todayScreenTime - weeklyAverage))
                            .dynamicTypeFont(base: 14, weight: .semibold)
                    }
                    .foregroundStyle(todayScreenTime < weeklyAverage ? Theme.Colors.success : Theme.Colors.aiOrange)

                    Text("vs weekly avg")
                        .dynamicTypeFont(base: 11, weight: .medium)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 30)

                VStack(spacing: 2) {
                    Text("\(pickupsToday)")
                        .dynamicTypeFont(base: 18, weight: .bold)
                        .foregroundStyle(.white)

                    Text("pickups")
                        .dynamicTypeFont(base: 11, weight: .medium)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiCyan.opacity(0.4),
                            Theme.Colors.aiPurple.opacity(0.2),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
    }

    private var aiInsightCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            // AI avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .dynamicTypeFont(base: 18, weight: .medium)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Insight")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("Your social media usage spikes after 9 PM. Consider enabling blocking during that time for better sleep.")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
        }
    }

    private var quickStatsRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            quickStatCard(
                title: "Focus Time",
                value: "2h 45m",
                icon: "flame.fill",
                color: Theme.Colors.aiOrange
            )

            quickStatCard(
                title: "Apps Blocked",
                value: "12",
                icon: "shield.fill",
                color: Theme.Colors.aiCyan
            )

            quickStatCard(
                title: "Streak",
                value: "5 days",
                icon: "bolt.fill",
                color: Theme.Colors.aiAmber
            )
        }
    }

    private func quickStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .dynamicTypeFont(base: 20)
                .foregroundStyle(color)

            Text(value)
                .dynamicTypeFont(base: 16, weight: .bold)
                .foregroundStyle(.white)

            Text(title)
                .dynamicTypeFont(base: 11, weight: .medium)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }

    private var mostUsedAppsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Most Used Today")
                .dynamicTypeFont(base: 16, weight: .semibold)
                .foregroundStyle(.white)

            ForEach(mostUsedApps.prefix(5)) { app in
                appUsageRow(app: app)
            }
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
    }

    private func appUsageRow(app: AppUsageData) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(app.color.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: app.icon)
                        .dynamicTypeFont(base: 18)
                        .foregroundStyle(app.color)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(.white)

                Text(app.category)
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(app.duration))
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(.white)

                // Usage bar
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(app.color.opacity(0.3))
                        .frame(width: 60, height: 4)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(app.color)
                                .frame(width: 60 * app.percentOfTotal, height: 4)
                        }
                }
                .frame(width: 60, height: 4)
            }
        }
    }

    private var activeBlocksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Active Blocks")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                if blockingService.isBlocking {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .dynamicTypeFont(base: 12, weight: .medium)
                            .foregroundStyle(Theme.Colors.success)
                    }
                }
            }

            if blockingService.isBlocking {
                activeBlockCard
            } else {
                noActiveBlocksView
            }
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
    }

    private var activeBlockCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Session")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Text("12 apps blocked")
                    .dynamicTypeFont(base: 13, weight: .medium)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button {
                Task { await blockingService.endSession() }
            } label: {
                Text("End")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.error.opacity(0.3))
                    }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.success.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.success.opacity(0.3), lineWidth: 1)
                }
        }
    }

    private var noActiveBlocksView: some View {
        HStack {
            Image(systemName: "shield.slash")
                .dynamicTypeFont(base: 24)
                .foregroundStyle(.white.opacity(0.3))

            Text("No apps currently blocked")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            Button {
                showAppPicker = true
            } label: {
                Text("Block Apps")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.aiCyan)
                    }
            }
        }
    }

    // MARK: - Schedules Content

    private var schedulesContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Create schedule button
            Button {
                showScheduleCreator = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .dynamicTypeFont(base: 20)

                    Text("Create Schedule")
                        .dynamicTypeFont(base: 16, weight: .semibold)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .foregroundStyle(.white)
                .padding(Theme.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.aiCyan.opacity(0.2))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.Colors.aiCyan.opacity(0.4), lineWidth: 1)
                        }
                }
            }

            // Sample schedules
            scheduleCard(
                name: "Morning Focus",
                time: "6:00 AM - 9:00 AM",
                days: "Weekdays",
                isActive: true
            )

            scheduleCard(
                name: "Evening Wind Down",
                time: "9:00 PM - 11:00 PM",
                days: "Every day",
                isActive: false
            )

            scheduleCard(
                name: "Weekend Detox",
                time: "All day",
                days: "Sat, Sun",
                isActive: false
            )
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, 100)
    }

    private func scheduleCard(name: String, time: String, days: String, isActive: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(name)
                        .dynamicTypeFont(base: 16, weight: .semibold)
                        .foregroundStyle(.white)

                    if isActive {
                        Text("ACTIVE")
                            .dynamicTypeFont(base: 10, weight: .bold)
                            .foregroundStyle(Theme.Colors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(Theme.Colors.success.opacity(0.2))
                            }
                    }
                }

                HStack(spacing: Theme.Spacing.sm) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .dynamicTypeFont(base: 12)
                        Text(time)
                            .dynamicTypeFont(base: 13)
                    }

                    Text("•")

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .dynamicTypeFont(base: 12)
                        Text(days)
                            .dynamicTypeFont(base: 13)
                    }
                }
                .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Toggle("", isOn: .constant(isActive))
                .labelsHidden()
                .tint(Theme.Colors.aiCyan)
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Groups Content

    private var groupsContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Create group button
            Button {
                showGroupCreator = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .dynamicTypeFont(base: 20)

                    Text("Create App Group")
                        .dynamicTypeFont(base: 16, weight: .semibold)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .foregroundStyle(.white)
                .padding(Theme.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.aiPurple.opacity(0.2))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.Colors.aiPurple.opacity(0.4), lineWidth: 1)
                        }
                }
            }

            // Sample groups
            appGroupCard(
                name: "Social Media",
                appCount: 5,
                color: .pink,
                icon: "bubble.left.and.bubble.right.fill"
            )

            appGroupCard(
                name: "Entertainment",
                appCount: 8,
                color: .purple,
                icon: "tv.fill"
            )

            appGroupCard(
                name: "Games",
                appCount: 12,
                color: .orange,
                icon: "gamecontroller.fill"
            )

            appGroupCard(
                name: "News & Reading",
                appCount: 4,
                color: .blue,
                icon: "newspaper.fill"
            )
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, 100)
    }

    private func appGroupCard(name: String, appCount: Int, color: Color, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            // Group icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .dynamicTypeFont(base: 20)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)

                Text("\(appCount) apps")
                    .dynamicTypeFont(base: 13, weight: .medium)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatTimeDifference(_ diff: TimeInterval) -> String {
        let absDiff = abs(diff)
        let hours = Int(absDiff) / 3600
        let minutes = (Int(absDiff) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func animateIn() {
        guard !reduceMotion else {
            headerScale = 1
            cardsAppeared = true
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            headerScale = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            cardsAppeared = true
        }
    }
}

// MARK: - Supporting Types

enum BlockingTab: String, CaseIterable {
    case overview
    case schedules
    case groups

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .schedules: return "Schedules"
        case .groups: return "Groups"
        }
    }
}

struct AppUsageData: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let duration: TimeInterval
    let percentOfTotal: Double
    let color: Color
    let icon: String

    static let sampleData: [AppUsageData] = [
        AppUsageData(name: "Instagram", category: "Social", duration: 1.5 * 3600, percentOfTotal: 0.33, color: .pink, icon: "camera.fill"),
        AppUsageData(name: "YouTube", category: "Entertainment", duration: 1.2 * 3600, percentOfTotal: 0.27, color: .red, icon: "play.rectangle.fill"),
        AppUsageData(name: "Twitter", category: "Social", duration: 0.8 * 3600, percentOfTotal: 0.18, color: .blue, icon: "bubble.left.fill"),
        AppUsageData(name: "TikTok", category: "Entertainment", duration: 0.5 * 3600, percentOfTotal: 0.11, color: .purple, icon: "music.note"),
        AppUsageData(name: "Safari", category: "Productivity", duration: 0.5 * 3600, percentOfTotal: 0.11, color: .blue, icon: "safari.fill")
    ]
}

// MARK: - Preview

#Preview {
    AppBlockingMainView()
}
