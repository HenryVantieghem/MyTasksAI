//
//  TimeAwareGreeting.swift
//  MyTasksAI
//
//  Time-Aware Greeting - Dynamic Contextual Messages
//  Inspired by Claude Mobile's "How can I help you this late night?"
//  Acknowledges time, productivity context, and user momentum
//

import SwiftUI

// MARK: - Time Aware Greeting View

struct TimeAwareGreeting: View {
    let completedTasksToday: Int
    let currentStreak: Int
    let isFirstTaskOfDay: Bool

    @State private var currentGreeting: GreetingContent = .default
    @State private var opacity: Double = 1

    var body: some View {
        Text(currentGreeting.message)
            .dynamicTypeFont(base: 14, weight: .medium)
            .foregroundStyle(Theme.InputBarColors.greetingText)
            .multilineTextAlignment(.center)
            .opacity(opacity)
            .onAppear {
                updateGreeting()
            }
            .task {
                // Update greeting every 30 minutes
                await periodicGreetingUpdate()
            }
    }

    // MARK: - Greeting Logic

    private func updateGreeting() {
        withAnimation(.easeInOut(duration: DesignTokens.InputBar.greetingFadeDuration)) {
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.InputBar.greetingFadeDuration) {
            currentGreeting = generateGreeting()
            withAnimation(.easeInOut(duration: DesignTokens.InputBar.greetingFadeDuration)) {
                opacity = 1
            }
        }
    }

    private func generateGreeting() -> GreetingContent {
        // Priority: Context bonuses > Time-based

        // First task of day
        if isFirstTaskOfDay {
            return GreetingContent(message: "Let's start strong! What's first?")
        }

        // High productivity
        if completedTasksToday >= 10 {
            return GreetingContent(message: "You're on fire today! What else?")
        }

        if completedTasksToday >= 5 {
            return GreetingContent(message: "Great momentum! Keep it going.")
        }

        // Streak awareness
        if currentStreak >= 7 {
            return GreetingContent(message: "Week-long streak! What's next?")
        }

        // Weekend check
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 {
            return GreetingContent(message: "Weekend warrior mode? Let's go.")
        }

        // Time-based fallback
        return TimeAwareGreetingGenerator.generate()
    }

    private func periodicGreetingUpdate() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1800)) // 30 minutes
            await MainActor.run {
                updateGreeting()
            }
        }
    }
}

// MARK: - Greeting Content

struct GreetingContent {
    let message: String

    static let `default` = GreetingContent(message: "What needs to be done?")
}

// MARK: - Time Aware Greeting Generator

enum TimeAwareGreetingGenerator {
    static func generate() -> GreetingContent {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<7:
            return GreetingContent(message: earlyMorningGreetings.randomElement()!)
        case 7..<12:
            return GreetingContent(message: morningGreetings.randomElement()!)
        case 12..<14:
            return GreetingContent(message: middayGreetings.randomElement()!)
        case 14..<17:
            return GreetingContent(message: afternoonGreetings.randomElement()!)
        case 17..<21:
            return GreetingContent(message: eveningGreetings.randomElement()!)
        case 21..<24, 0..<5:
            return GreetingContent(message: lateNightGreetings.randomElement()!)
        default:
            return .default
        }
    }

    // MARK: - Greeting Pools

    private static let earlyMorningGreetings = [
        "Early bird! What's on your mind?",
        "Up before dawn? Let's make it count.",
        "Quiet morning energy. What's first?"
    ]

    private static let morningGreetings = [
        "Good morning! What's the plan?",
        "Fresh start. What matters today?",
        "Morning clarity. What needs doing?"
    ]

    private static let middayGreetings = [
        "Midday momentum. What's next?",
        "Lunch break productive? Add a task.",
        "Halfway through. Stay focused."
    ]

    private static let afternoonGreetings = [
        "Afternoon focus. What needs doing?",
        "Power through. What's on deck?",
        "Productive afternoon ahead."
    ]

    private static let eveningGreetings = [
        "Winding down? Any last tasks?",
        "Evening check-in. Capture it now.",
        "End the day strong. What's left?"
    ]

    private static let lateNightGreetings = [
        "Burning the midnight oil?",
        "Late night thoughts? Capture them.",
        "Night owl mode. What's brewing?"
    ]
}

// MARK: - Preview

#Preview("Time Aware Greeting") {
    VStack(spacing: 32) {
        Text("Time-Aware Greetings")
            .font(.headline)
            .foregroundStyle(.white)

        VStack(spacing: 16) {
            // Default state
            TimeAwareGreeting(
                completedTasksToday: 0,
                currentStreak: 0,
                isFirstTaskOfDay: false
            )

            // First task of day
            TimeAwareGreeting(
                completedTasksToday: 0,
                currentStreak: 3,
                isFirstTaskOfDay: true
            )

            // High productivity
            TimeAwareGreeting(
                completedTasksToday: 12,
                currentStreak: 5,
                isFirstTaskOfDay: false
            )

            // Week streak
            TimeAwareGreeting(
                completedTasksToday: 3,
                currentStreak: 7,
                isFirstTaskOfDay: false
            )
        }

        Divider()
            .background(.white.opacity(0.2))

        VStack(spacing: 8) {
            Text("Time-Based Samples")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(0..<6, id: \.self) { _ in
                Text(TimeAwareGreetingGenerator.generate().message)
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.InputBarColors.greetingText)
            }
        }
    }
    .padding(32)
    .background(Theme.CelestialColors.void)
}
