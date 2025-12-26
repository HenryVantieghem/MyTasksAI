//
//  DailyWinsView.swift
//  Veloce
//
//  Daily Wins Celebration Scroll
//  End-of-day celebration showing all completed tasks with beautiful animations
//

import SwiftUI

// MARK: - Daily Win Item

struct DailyWinItem: Identifiable {
    let id: UUID
    let title: String
    let completedAt: Date
    let xpEarned: Int
    let category: String?
    let wasImportant: Bool

    init(from task: TaskItem) {
        self.id = task.id
        self.title = task.title
        self.completedAt = task.completedAt ?? .now
        self.xpEarned = task.pointsEarned
        self.category = task.category
        self.wasImportant = task.priorityEnum == .high
    }
}

// MARK: - Daily Wins View

struct DailyWinsView: View {
    let wins: [DailyWinItem]
    let totalXP: Int
    let onDismiss: () -> Void
    let onShare: () -> Void

    @State private var displayedWins: [DailyWinItem] = []
    @State private var runningXP: Int = 0
    @State private var showingSummary = false
    @State private var checkmarkStates: [UUID: Bool] = [:]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            VoidBackground()

            VStack(spacing: 0) {
                // Header
                header

                // Wins list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(displayedWins) { win in
                                DailyWinRow(
                                    win: win,
                                    isChecked: checkmarkStates[win.id] ?? false
                                )
                                .id(win.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }

                            // Summary card (appears at end)
                            if showingSummary {
                                summaryCard
                                    .id("summary")
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    .onChange(of: displayedWins.count) { _, _ in
                        if let lastWin = displayedWins.last {
                            withAnimation {
                                proxy.scrollTo(lastWin.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: showingSummary) { _, showing in
                        if showing {
                            withAnimation {
                                proxy.scrollTo("summary", anchor: .center)
                            }
                        }
                    }
                }

                // Running XP counter
                runningXPCounter
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    dismiss()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .background(SwiftUI.Circle().fill(.ultraThinMaterial))
                }

                Spacer()

                Button {
                    onShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Celebration.plasmaCore)
                        .padding(12)
                        .background(SwiftUI.Circle().fill(.ultraThinMaterial))
                }
            }
            .padding(.horizontal, 20)

            Text("Your Wins Today")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(formattedDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Running XP Counter

    private var runningXPCounter: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(Theme.Celebration.starGold)

            Text("\(runningXP)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text("XP")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .strokeBorder(
                            Theme.Celebration.starGold.opacity(0.3),
                            lineWidth: 1
                        )
                }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 20) {
            // Trophy
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Celebration.starGold.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 56))
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
                    .shadow(color: Theme.Celebration.starGold.opacity(0.6), radius: 20)
            }

            VStack(spacing: 8) {
                Text("Amazing Day!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(wins.count) tasks completed")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // Stats row
            HStack(spacing: 32) {
                statItem(
                    value: "\(totalXP)",
                    label: "XP Earned",
                    icon: "star.fill",
                    color: Theme.Celebration.starGold
                )

                statItem(
                    value: "\(wins.filter { $0.wasImportant }.count)",
                    label: "Important",
                    icon: "exclamationmark.circle.fill",
                    color: Theme.Celebration.solarFlare
                )
            }

            // Share button
            Button {
                onShare()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Your Wins")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Celebration.nebulaCore,
                                    Theme.Celebration.plasmaCore
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .padding(.top, 8)
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
                                    Theme.Celebration.starGold.opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
        }
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        // Add wins one by one with animation
        Task {
            for (index, win) in wins.enumerated() {
                // Small delay between each win
                try? await Task.sleep(for: .milliseconds(400))

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    displayedWins.append(win)
                }

                // Animate checkmark after a brief delay
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.spring(response: 0.3)) {
                    checkmarkStates[win.id] = true
                }

                // Play sound
                CelebrationSounds.shared.playQuickPop()

                // Update running XP
                withAnimation(.easeOut(duration: 0.3)) {
                    runningXP += win.xpEarned
                }

                // Add slight haptic
                if index % 3 == 0 {
                    HapticsService.shared.impact(.light)
                }
            }

            // Show summary after all wins
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showingSummary = true
            }

            // Play celebration sound
            CelebrationSounds.shared.playCompletionDing()
            HapticsService.shared.celebration()
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Daily Win Row

struct DailyWinRow: View {
    let win: DailyWinItem
    let isChecked: Bool

    @State private var checkScale: CGFloat = 0

    var body: some View {
        HStack(spacing: 16) {
            // Checkmark
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Celebration.successGlow.opacity(0.2))
                    .frame(width: 44, height: 44)

                SwiftUI.Circle()
                    .fill(Theme.Celebration.successGlow)
                    .frame(width: 44, height: 44)
                    .scaleEffect(isChecked ? 1.0 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(checkScale)
            }
            .onChange(of: isChecked) { _, checked in
                if checked {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        checkScale = 1.2
                    }
                    withAnimation(.spring(response: 0.2).delay(0.1)) {
                        checkScale = 1.0
                    }
                }
            }

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(win.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let category = win.category {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(Theme.Celebration.plasmaCore)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(Theme.Celebration.plasmaCore.opacity(0.2))
                            }
                    }
                }
            }

            Spacer()

            // XP
            HStack(spacing: 2) {
                Text("+\(win.xpEarned)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Celebration.starGold)

                Text("XP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Celebration.starGold.opacity(0.7))
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    if win.wasImportant {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                Theme.Celebration.solarFlare.opacity(0.3),
                                lineWidth: 1
                            )
                    }
                }
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: win.completedAt)
    }
}

// MARK: - Void Background

private struct DailyWinsVoidBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.04)
                    .ignoresSafeArea()

                // Subtle nebula glow
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Celebration.nebulaCore.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .offset(y: -200)
                    .blur(radius: 60)

                // Stars
                ForEach(0..<30, id: \.self) { index in
                    SwiftUI.Circle()
                        .fill(Color.white.opacity(Double(index % 4 + 2) / 10))
                        .frame(width: CGFloat((index % 3) + 1))
                        .position(
                            x: CGFloat((index * 47 + 23) % Int(geometry.size.width.isZero ? 393 : geometry.size.width)),
                            y: CGFloat((index * 31 + 17) % Int(geometry.size.height.isZero ? 852 : geometry.size.height))
                        )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Daily Wins") {
    DailyWinsView(
        wins: [
            DailyWinItem(from: {
                let task = TaskItem(title: "Complete project proposal")
                return task
            }()),
            DailyWinItem(from: {
                let task = TaskItem(title: "Review team feedback")
                return task
            }()),
            DailyWinItem(from: {
                let task = TaskItem(title: "Update documentation")
                return task
            }()),
        ],
        totalXP: 150,
        onDismiss: {},
        onShare: {}
    )
}
