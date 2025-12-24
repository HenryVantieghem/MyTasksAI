//
//  ShareableWinCard.swift
//  Veloce
//
//  Shareable Win Cards
//  Beautiful, branded achievement cards optimized for social sharing
//

import SwiftUI

// MARK: - Shareable Card Type

enum ShareableCardType {
    case dailySummary(tasks: Int, xp: Int, date: Date)
    case milestone(title: String, value: Int, description: String)
    case personalBest(type: PersonalBestType, value: Int, previousValue: Int)
    case streak(days: Int)
    case levelUp(level: Int, totalXP: Int)
    case achievement(title: String, description: String)
}

// MARK: - Shareable Win Card

struct ShareableWinCard: View {
    let cardType: ShareableCardType

    // Card dimensions for social sharing (Instagram story ratio)
    private let cardWidth: CGFloat = 350
    private let cardHeight: CGFloat = 450

    var body: some View {
        cardContent
            .frame(width: cardWidth, height: cardHeight)
            .background {
                cardBackground
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .shadow(color: primaryColor.opacity(0.3), radius: 30, y: 15)
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        switch cardType {
        case .dailySummary(let tasks, let xp, let date):
            dailySummaryContent(tasks: tasks, xp: xp, date: date)

        case .milestone(let title, let value, let description):
            milestoneContent(title: title, value: value, description: description)

        case .personalBest(let type, let value, let previous):
            personalBestContent(type: type, value: value, previousValue: previous)

        case .streak(let days):
            streakContent(days: days)

        case .levelUp(let level, let totalXP):
            levelUpContent(level: level, totalXP: totalXP)

        case .achievement(let title, let description):
            achievementContent(title: title, description: description)
        }
    }

    // MARK: - Daily Summary

    private func dailySummaryContent(tasks: Int, xp: Int, date: Date) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Celebration.successGlow.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Celebration.successGlow)
            }

            VStack(spacing: 8) {
                Text("Daily Wins")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(tasks)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("tasks completed")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }

            // XP badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.Celebration.starGold)

                Text("+\(xp) XP")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.1))
            }

            Spacer()

            branding(date: date)
        }
        .padding(24)
    }

    // MARK: - Milestone

    private func milestoneContent(title: String, value: Int, description: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Trophy
            ZStack {
                Circle()
                    .fill(Theme.Celebration.starGold.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Celebration.starGold, Theme.Celebration.solarFlare],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("MILESTONE")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Celebration.starGold)
                    .tracking(2)

                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("\(value)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Celebration.starGold, Theme.Celebration.solarFlare],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(description)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            branding(date: Date())
        }
        .padding(24)
    }

    // MARK: - Personal Best

    private func personalBestContent(type: PersonalBestType, value: Int, previousValue: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: type.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(type.color)
            }

            VStack(spacing: 12) {
                Text("NEW RECORD")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Celebration.starGold)
                    .tracking(2)

                Text(type.rawValue)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    if previousValue > 0 {
                        Text("\(previousValue)")
                            .font(.system(size: 32, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }

                    Image(systemName: "arrow.right")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Celebration.auroraGreen)

                    Text("\(value)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.Celebration.auroraGreen)
                }
            }

            Spacer()

            branding(date: Date())
        }
        .padding(24)
    }

    // MARK: - Streak

    private func streakContent(days: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Flame
            ZStack {
                Circle()
                    .fill(Theme.Celebration.flameInner.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Celebration.flameCore,
                                Theme.Celebration.flameInner,
                                Theme.Celebration.flameMid
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .shadow(color: Theme.Celebration.flameInner.opacity(0.8), radius: 20)
            }

            VStack(spacing: 8) {
                Text("\(days)")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Celebration.flameInner,
                                Theme.Celebration.solarFlare
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("day streak")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            // Motivation text
            Text(streakMotivation(days: days))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            branding(date: Date())
        }
        .padding(24)
    }

    private func streakMotivation(days: Int) -> String {
        switch days {
        case 1..<7: return "Building momentum!"
        case 7..<14: return "One week strong!"
        case 14..<30: return "Unstoppable!"
        case 30..<60: return "Month of consistency!"
        case 60..<100: return "Legendary dedication!"
        default: return "Absolute beast mode!"
        }
    }

    // MARK: - Level Up

    private func levelUpContent(level: Int, totalXP: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Level badge
            ZStack {
                Circle()
                    .fill(Theme.Celebration.nebulaCore.opacity(0.2))
                    .frame(width: 120, height: 120)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Theme.Celebration.plasmaCore, Theme.Celebration.nebulaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)

                Text("\(level)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("LEVEL UP!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Celebration.plasmaCore, Theme.Celebration.nebulaCore],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Total: \(totalXP) XP")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            // Stars animation placeholder
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundStyle(Theme.Celebration.starGold)
                }
            }

            Spacer()

            branding(date: Date())
        }
        .padding(24)
    }

    // MARK: - Achievement

    private func achievementContent(title: String, description: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Badge
            ZStack {
                Circle()
                    .fill(Theme.Celebration.starGold.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "medal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Celebration.starGold)
            }

            VStack(spacing: 12) {
                Text("ACHIEVEMENT UNLOCKED")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Celebration.starGold)
                    .tracking(2)

                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            branding(date: Date())
        }
        .padding(24)
    }

    // MARK: - Branding

    private func branding(date: Date) -> some View {
        VStack(spacing: 4) {
            Text("Veloce")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Text(formattedDate(date))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Styling

    private var cardBackground: some View {
        ZStack {
            // Base color
            Color(red: 0.04, green: 0.04, blue: 0.08)

            // Gradient overlay based on type
            LinearGradient(
                colors: [
                    primaryColor.opacity(0.2),
                    Color.clear,
                    primaryColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle noise texture
            Rectangle()
                .fill(.white.opacity(0.02))
        }
    }

    private var primaryColor: Color {
        switch cardType {
        case .dailySummary: return Theme.Celebration.successGlow
        case .milestone: return Theme.Celebration.starGold
        case .personalBest(let type, _, _): return type.color
        case .streak: return Theme.Celebration.flameInner
        case .levelUp: return Theme.Celebration.nebulaCore
        case .achievement: return Theme.Celebration.starGold
        }
    }

    private var borderColors: [Color] {
        [
            primaryColor.opacity(0.5),
            primaryColor.opacity(0.2),
            Color.clear
        ]
    }
}

// MARK: - Share Card Generator

@MainActor
struct ShareCardGenerator {
    /// Generate a shareable image from a card type
    static func generateImage(for cardType: ShareableCardType) -> UIImage? {
        let view = ShareableWinCard(cardType: cardType)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0 // High resolution

        return renderer.uiImage
    }

    /// Share a card using the system share sheet
    static func share(cardType: ShareableCardType, from viewController: UIViewController? = nil) {
        guard let image = generateImage(for: cardType) else { return }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Present
        if let vc = viewController ?? UIApplication.shared.keyWindow?.rootViewController {
            vc.present(activityVC, animated: true)
        }
    }
}

// MARK: - Share Button

struct ShareWinButton: View {
    let cardType: ShareableCardType
    @State private var isGenerating = false

    var body: some View {
        Button {
            isGenerating = true

            Task {
                // Small delay for visual feedback
                try? await Task.sleep(for: .milliseconds(300))
                ShareCardGenerator.share(cardType: cardType)
                isGenerating = false
            }
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text("Share")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(Theme.Celebration.nebulaCore)
            }
        }
        .disabled(isGenerating)
    }
}

// MARK: - Preview

#Preview("Daily Summary Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        ShareableWinCard(cardType: .dailySummary(
            tasks: 12,
            xp: 450,
            date: Date()
        ))
    }
}

#Preview("Streak Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        ShareableWinCard(cardType: .streak(days: 30))
    }
}

#Preview("Level Up Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        ShareableWinCard(cardType: .levelUp(level: 10, totalXP: 5000))
    }
}

#Preview("Personal Best Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        ShareableWinCard(cardType: .personalBest(
            type: .mostTasksInDay,
            value: 23,
            previousValue: 18
        ))
    }
}
