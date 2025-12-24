//
//  StatsComponents.swift
//  Veloce
//
//  Stats Section Components - Premium Analytics
//  WHOOP-inspired productivity score, heatmaps, charts
//
//  Award-Winning Tier Visual Design
//

import SwiftUI

// MARK: - Productivity Score Ring (WHOOP-Style)

struct ProductivityScoreRing: View {
    let score: VelocityScore

    @State private var animatedProgress: Double = 0
    @State private var displayedScore: Int = 0
    @State private var ringRotation: Double = 0
    @State private var glowPulse: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let ringColors: [Color] = [
        Color(hex: "06B6D4"), // Cyan
        Color(hex: "3B82F6"), // Blue
        Color(hex: "8B5CF6"), // Purple
        Color(hex: "EC4899"), // Pink
    ]

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                score.color.opacity(0.3 * glowPulse),
                                score.color.opacity(0.1 * glowPulse),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 20)

                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 14)
                    .frame(width: 200, height: 200)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            colors: ringColors + [ringColors[0]],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: score.color.opacity(0.5), radius: 10)

                // Rotating accent ring
                Circle()
                    .trim(from: 0, to: 0.15)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(ringRotation))

                // Center content
                VStack(spacing: 4) {
                    Text("\(displayedScore)")
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("PRODUCTIVITY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.5))

                    // Trend indicator
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("+5%")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                    .padding(.top, 4)
                }

                // Score breakdown dots around ring
                ForEach(Array(ScoreBreakdown.from(score).enumerated()), id: \.element.id) { index, breakdown in
                    ScoreBreakdownDot(
                        breakdown: breakdown,
                        angle: Double(index) * 90 - 45
                    )
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double(index) * 90 - 45))
                }
            }
            .frame(height: 280)

            // Tier badge
            HStack(spacing: 8) {
                Image(systemName: score.tier.icon)
                    .font(.system(size: 14))

                Text(score.tierLabel.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(2)
            }
            .foregroundStyle(score.gradient)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(score.color.opacity(0.3), lineWidth: 1)
                    )
            }

            // Motivational message
            Text(score.message)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(.white.opacity(0.7))
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        guard !reduceMotion else {
            animatedProgress = Double(score.total) / 100.0
            displayedScore = score.total
            glowPulse = 1
            return
        }

        // Animate progress ring
        withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2)) {
            animatedProgress = Double(score.total) / 100.0
        }

        // Animate score counter
        let steps = 30
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.03) {
                withAnimation(.spring(response: 0.2)) {
                    displayedScore = Int(Double(score.total) * Double(i + 1) / Double(steps))
                }
            }
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPulse = 1
        }

        // Ring rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }
}

// MARK: - Score Breakdown Dot

struct ScoreBreakdownDot: View {
    let breakdown: ScoreBreakdown
    let angle: Double

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(breakdown.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: breakdown.percentage)
                    .stroke(breakdown.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))

                Image(systemName: breakdown.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(breakdown.color)
            }

            Text(breakdown.displayScore)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
        .rotationEffect(.degrees(-angle))
    }
}

// MARK: - Quick Stats Row

struct QuickStatsRow: View {
    let tasksCompleted: Int
    let focusHours: Double
    let completionRate: Double
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            QuickStatItem(
                value: "\(tasksCompleted)",
                label: "Tasks",
                icon: "checkmark.circle.fill",
                color: Theme.CelestialColors.auroraGreen,
                trend: "+3"
            )

            QuickStatItem(
                value: String(format: "%.1f", focusHours),
                label: "Hours",
                icon: "clock.fill",
                color: Theme.CelestialColors.plasmaCore,
                trend: "+0.5"
            )

            QuickStatItem(
                value: "\(Int(completionRate * 100))%",
                label: "Rate",
                icon: "chart.line.uptrend.xyaxis",
                color: Color(hex: "3B82F6"),
                trend: "+8%"
            )

            QuickStatItem(
                value: "\(streak)",
                label: "Streak",
                icon: "flame.fill",
                color: Color(hex: "F59E0B"),
                trend: nil,
                showFlame: streak > 0
            )
        }
    }
}

struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let trend: String?
    var showFlame: Bool = false

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .scaleEffect(showFlame && isAnimating ? 1.1 : 1.0)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            if let trend = trend {
                Text(trend)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        }
        .onAppear {
            if showFlame {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Weekly Heatmap Card

struct WeeklyHeatmapCard: View {
    let tasks: [TaskItem]
    let selectedDate: Date

    private let hours = stride(from: 6, to: 24, by: 2).map { $0 }
    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity Heatmap")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(mostProductiveTime)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.plasmaCore)
            }

            // Heatmap grid
            VStack(spacing: 3) {
                // Hour labels
                HStack(spacing: 3) {
                    Text("")
                        .frame(width: 28)

                    ForEach(hours, id: \.self) { hour in
                        Text("\(hour)")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Grid rows
                ForEach(0..<7, id: \.self) { dayIndex in
                    HStack(spacing: 3) {
                        Text(days[dayIndex])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 28, alignment: .leading)

                        ForEach(hours, id: \.self) { hour in
                            let intensity = activityIntensity(day: dayIndex, hour: hour)
                            HeatmapCell(intensity: intensity)
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 8) {
                Text("Less")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))

                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(for: Double(level) / 4.0))
                        .frame(width: 12, height: 12)
                }

                Text("More")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
    }

    private var mostProductiveTime: String {
        "Peak: Tue 9-11 AM"
    }

    private func activityIntensity(day: Int, hour: Int) -> Double {
        // Calculate based on task completion times
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate

        let dayDate = calendar.date(byAdding: .day, value: day, to: weekStart) ?? selectedDate

        let count = tasks.filter { task in
            guard task.isCompleted, let completedAt = task.completedAt else { return false }
            let taskHour = calendar.component(.hour, from: completedAt)
            return calendar.isDate(completedAt, inSameDayAs: dayDate) &&
            taskHour >= hour && taskHour < hour + 2
        }.count

        return min(Double(count) / 3.0, 1.0)
    }

    private func heatmapColor(for intensity: Double) -> Color {
        if intensity < 0.1 {
            return Color.white.opacity(0.05)
        }
        return Theme.CelestialColors.plasmaCore.opacity(0.2 + intensity * 0.6)
    }
}

struct HeatmapCell: View {
    let intensity: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(cellColor)
            .frame(maxWidth: .infinity)
            .frame(height: 20)
    }

    private var cellColor: Color {
        if intensity < 0.1 {
            return Color.white.opacity(0.05)
        }
        return Theme.CelestialColors.plasmaCore.opacity(0.2 + intensity * 0.6)
    }
}

// MARK: - Focus Time Chart

struct FocusTimeChart: View {
    let tasks: [TaskItem]

    @State private var animatedBars = false

    private var weekData: [(day: String, hours: Double)] {
        let calendar = Calendar.current
        var data: [(String, Double)] = []

        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            // Simulated focus hours - in production, calculate from actual focus sessions
            let hours = Double.random(in: 0.5...4.0)
            data.append((dayName, hours))
        }
        return data
    }

    private var maxHours: Double {
        max(weekData.map { $0.hours }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus Time")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Last 7 days")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1fh", weekData.map { $0.hours }.reduce(0, +)))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("total")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weekData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 8) {
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.CelestialColors.plasmaCore,
                                        Theme.CelestialColors.plasmaCore.opacity(0.6)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: 32,
                                height: animatedBars ? CGFloat(data.hours / maxHours) * 100 : 0
                            )
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.7).delay(Double(index) * 0.08),
                                value: animatedBars
                            )

                        // Day label
                        Text(data.day)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130)

            // Goal line indicator
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Theme.CelestialColors.auroraGreen)
                    .frame(width: 20, height: 2)

                Text("Daily goal: 2h")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
        .onAppear {
            animatedBars = true
        }
    }
}

// MARK: - Completion Trend Chart

struct CompletionTrendChart: View {
    let tasks: [TaskItem]

    @State private var animatedLine = false

    private var trendData: [Double] {
        // Generate 30 days of completion rates
        let calendar = Calendar.current
        var rates: [Double] = []

        for i in (0..<30).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayTasks = tasks.filter { task in
                guard let created = task.createdAt else { return false }
                return calendar.isDate(created, inSameDayAs: date)
            }
            let completed = dayTasks.filter { $0.isCompleted }.count
            let rate = dayTasks.isEmpty ? 0.5 : Double(completed) / Double(dayTasks.count)
            rates.append(rate)
        }
        return rates
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completion Trend")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("30 day average")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    let average = trendData.reduce(0, +) / Double(trendData.count)
                    Text("\(Int(average * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                        Text("+12%")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                }
            }

            // Line chart
            GeometryReader { geometry in
                ZStack {
                    // Gradient fill under line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))

                        for (index, value) in trendData.enumerated() {
                            let x = CGFloat(index) / CGFloat(trendData.count - 1) * geometry.size.width
                            let y = geometry.size.height - (value * geometry.size.height * 0.8)
                            if index == 0 {
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.plasmaCore.opacity(0.3),
                                Theme.CelestialColors.plasmaCore.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(animatedLine ? 1 : 0)

                    // Line
                    Path { path in
                        for (index, value) in trendData.enumerated() {
                            let x = CGFloat(index) / CGFloat(trendData.count - 1) * geometry.size.width
                            let y = geometry.size.height - (value * geometry.size.height * 0.8)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .trim(from: 0, to: animatedLine ? 1 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.CelestialColors.plasmaCore, Theme.CelestialColors.nebulaEdge],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: Theme.CelestialColors.plasmaCore.opacity(0.5), radius: 8)
                }
            }
            .frame(height: 100)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                animatedLine = true
            }
        }
    }
}

// MARK: - Personal Bests Card

struct PersonalBestsCard: View {
    let gamification: GamificationService

    private var bests: [(title: String, value: String, icon: String, color: Color)] {
        [
            ("Most tasks in a day", "23", "trophy.fill", Color(hex: "FFD700")),
            ("Longest focus streak", "4 hours", "timer", Theme.CelestialColors.plasmaCore),
            ("Best week", "Jan 15-21", "calendar.badge.checkmark", Theme.CelestialColors.auroraGreen),
            ("Highest velocity", "94", "speedometer", Color(hex: "EC4899"))
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "FFD700"))

                Text("Personal Bests")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                ForEach(bests, id: \.title) { best in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(best.color.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: best.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(best.color)
                        }

                        Text(best.title)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        Text(best.value)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "FFD700").opacity(0.2), lineWidth: 0.5)
                )
        }
    }
}
