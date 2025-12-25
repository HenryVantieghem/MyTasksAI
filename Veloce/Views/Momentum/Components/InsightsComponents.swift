//
//  InsightsComponents.swift
//  Veloce
//
//  AI Insights Section Components - Oracle Wisdom
//  Pattern recognition, predictions, mystical oracle aesthetic
//
//  Award-Winning Tier Visual Design
//

import SwiftUI

// MARK: - Oracle Header View

struct OracleHeaderView: View {
    @State private var orbPulse: Double = 0
    @State private var ringRotation: Double = 0
    @State private var particlePhase: Double = 0

    private let oracleColors: [Color] = [
        Theme.CelestialColors.nebulaCore,
        Theme.CelestialColors.nebulaGlow,
        Theme.CelestialColors.nebulaEdge
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Oracle orb
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                oracleColors[0].opacity(0.4 * orbPulse),
                                oracleColors[1].opacity(0.2 * orbPulse),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                // Rotating rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [oracleColors[i].opacity(0.5), .clear, oracleColors[i].opacity(0.3), .clear],
                                center: .center
                            ),
                            lineWidth: 1
                        )
                        .frame(width: CGFloat(70 + i * 20), height: CGFloat(70 + i * 20))
                        .rotationEffect(.degrees(ringRotation * (i % 2 == 0 ? 1 : -1)))
                }

                // Core orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(0.9),
                                    oracleColors[0].opacity(0.7),
                                    oracleColors[1].opacity(0.5),
                                    oracleColors[2].opacity(0.3)
                                ],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(1 + orbPulse * 0.1)

                    // Inner glow
                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 15, height: 15)
                        .blur(radius: 5)
                        .offset(x: -8, y: -8)
                }

                // Floating particles
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(oracleColors[i % 3].opacity(0.6))
                        .frame(width: 4, height: 4)
                        .offset(
                            x: cos(particlePhase + Double(i) * .pi / 3) * 45,
                            y: sin(particlePhase + Double(i) * .pi / 3) * 45
                        )
                        .blur(radius: 1)
                }
            }
            .frame(height: 160)

            // Title
            VStack(spacing: 8) {
                Text("Oracle Wisdom")
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(.white)

                Text("AI-powered insights into your productivity patterns")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                orbPulse = 1
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                particlePhase = .pi * 2
            }
        }
    }
}

// MARK: - Pattern Recognition Card

struct PatternRecognitionCard: View {
    let tasks: [TaskItem]
    let gamification: GamificationService

    private var patterns: [(title: String, description: String, icon: String, value: String)] {
        [
            ("Peak Hours", "You're most productive", "clock.fill", "9-11 AM"),
            ("Best Day", "Highest completion rate", "calendar", "Tuesday"),
            ("Optimal Focus", "Your ideal session length", "timer", "45 min"),
            ("Task Type", "You excel at", "star.fill", "Creative work")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("Your Patterns")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)

                Spacer()

                Text("This week")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Pattern grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(patterns, id: \.title) { pattern in
                    PatternItem(pattern: pattern)
                }
            }
        }
        .padding(20)
        .background {
            insightCardBackground
        }
    }

    private var insightCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.nebulaCore.opacity(0.3),
                                Theme.CelestialColors.nebulaEdge.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Theme.CelestialColors.nebulaCore.opacity(0.1), radius: 20, y: 8)
    }
}

struct PatternItem: View {
    let pattern: (title: String, description: String, icon: String, value: String)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: pattern.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.nebulaEdge)

                Text(pattern.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text(pattern.value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text(pattern.description)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.CelestialColors.nebulaCore.opacity(0.08))
        }
    }
}

// MARK: - AI Suggestions Card

struct AISuggestionsCard: View {
    let tasks: [TaskItem]
    let gamification: GamificationService

    @State private var visibleSuggestions: [AISuggestion] = []
    @State private var hasAnimated = false

    private var suggestions: [AISuggestion] {
        [
            AISuggestion(
                icon: "sunrise.fill",
                text: "Try scheduling creative tasks before 11 AM when your focus peaks",
                type: .timing
            ),
            AISuggestion(
                icon: "pause.circle.fill",
                text: "You've been skipping breaks - schedule a 5-min pause every 50 minutes",
                type: .wellness
            ),
            AISuggestion(
                icon: "arrow.triangle.branch",
                text: "Break down 'Project Alpha' into smaller tasks for better completion",
                type: .strategy
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("AI Recommendations")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    HapticsService.shared.impact(.light)
                } label: {
                    Text("Refresh")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.nebulaEdge)
                }
            }

            // Suggestions
            VStack(spacing: 12) {
                ForEach(Array(visibleSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                    SuggestionRow(suggestion: suggestion, delay: Double(index) * 0.15)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Theme.CelestialColors.nebulaCore.opacity(0.3),
                                    Theme.CelestialColors.nebulaEdge.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .onAppear {
            if !hasAnimated {
                animateSuggestions()
            }
        }
    }

    private func animateSuggestions() {
        hasAnimated = true
        for (index, suggestion) in suggestions.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    visibleSuggestions.append(suggestion)
                }
            }
        }
    }
}

struct AISuggestion: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let type: SuggestionType

    enum SuggestionType {
        case timing, wellness, strategy
    }
}

struct SuggestionRow: View {
    let suggestion: AISuggestion
    let delay: Double

    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.CelestialColors.nebulaCore.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: suggestion.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.nebulaEdge)
            }

            Text(suggestion.text)
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(4)

            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Weekly Reflection Card

struct WeeklyReflectionCard: View {
    let tasks: [TaskItem]
    let gamification: GamificationService
    let velocityScore: VelocityScore

    @State private var isExpanded = false

    private var wins: [String] {
        [
            "Completed 23 tasks this week",
            "Maintained a 5-day streak",
            "Beat your focus time goal by 2 hours"
        ]
    }

    private var improvements: [String] {
        [
            "Try starting earlier on Mondays",
            "Consider batching similar tasks together"
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerButton
            expandedContent
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

    private var headerButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("Weekly Reflection")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)

                Spacer()

                Text("Auto-generated")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.05)))

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var expandedContent: some View {
        if isExpanded {
            VStack(alignment: .leading, spacing: 20) {
                winsSection
                Divider().background(Color.white.opacity(0.1))
                improvementsSection
                shareButton
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var winsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)

                Text("Wins & Accomplishments")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
            }

            ForEach(wins, id: \.self) { win in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Theme.CelestialColors.auroraGreen)
                        .frame(width: 6, height: 6)
                        .offset(y: 6)

                    Text(win)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    private var improvementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.solarFlare)

                Text("Areas for Growth")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.solarFlare)
            }

            ForEach(improvements, id: \.self) { improvement in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Theme.CelestialColors.solarFlare)
                        .frame(width: 6, height: 6)
                        .offset(y: 6)

                    Text(improvement)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    private var shareButton: some View {
        Button {
            HapticsService.shared.impact(.medium)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12))

                Text("Share Reflection")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Theme.CelestialColors.nebulaEdge)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(Theme.CelestialColors.nebulaCore.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Theme.CelestialColors.nebulaCore.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Predictions Card

struct PredictionsCard: View {
    let goals: [Goal]
    let tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("Forecasts")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)

                Spacer()
            }

            // Predictions
            VStack(spacing: 12) {
                if goals.isEmpty {
                    Text("Set goals to see completion predictions")
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(goals.prefix(3)) { goal in
                        PredictionRow(goal: goal)
                    }
                }

                // Trend prediction
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.CelestialColors.plasmaCore.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.CelestialColors.plasmaCore)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Velocity Trend")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))

                        Text("On track to increase 12% by next week")
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(.white)
                    }

                    Spacer()
                }
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.CelestialColors.plasmaCore.opacity(0.08))
                }
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
}

struct PredictionRow: View {
    let goal: Goal

    private var predictedDate: String {
        let calendar = Calendar.current
        let daysToComplete = Int((1 - goal.progress) * 30) // Simulated
        if let date = calendar.date(byAdding: .day, value: daysToComplete, to: Date()) {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
        return "Soon"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: goal.progress)
                    .stroke(Theme.CelestialColors.auroraGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(goal.progress * 100))")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("Predicted completion: \(predictedDate)")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
    }
}

// MARK: - Ask Oracle Card

struct AskOracleCard: View {
    let onAsk: () -> Void

    @State private var placeholderIndex = 0
    @State private var glowPhase: Double = 0

    private let placeholders = [
        "Why am I not hitting my goals?",
        "How can I be more consistent?",
        "What's blocking my productivity?",
        "When should I schedule deep work?"
    ]

    var body: some View {
        Button(action: {
            HapticsService.shared.impact(.medium)
            onAsk()
        }) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.CelestialColors.nebulaCore.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .scaleEffect(1 + glowPhase * 0.1)

                    Circle()
                        .stroke(Theme.CelestialColors.nebulaCore.opacity(0.4), lineWidth: 1)
                        .frame(width: 60, height: 60)
                        .scaleEffect(1 + glowPhase * 0.15)

                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.CelestialColors.nebulaEdge)
                }

                VStack(spacing: 8) {
                    Text("Ask the Oracle")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)

                    Text("\"\(placeholders[placeholderIndex])\"")
                        .font(.system(size: 14, design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .animation(.easeInOut, value: placeholderIndex)
                }

                // Input hint
                HStack {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("Tap to ask a question...")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Theme.CelestialColors.nebulaCore.opacity(0.4),
                                        Theme.CelestialColors.nebulaEdge.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
            .shadow(color: Theme.CelestialColors.nebulaCore.opacity(0.15), radius: 30, y: 10)
        }
        .buttonStyle(.plain)
        .onAppear {
            // Cycle through placeholders
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                withAnimation {
                    placeholderIndex = (placeholderIndex + 1) % placeholders.count
                }
            }

            // Glow animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }
}

// MARK: - Oracle Chat Sheet

struct OracleChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var question = ""
    @State private var isThinking = false
    @State private var response: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()

                Text("Ask the Oracle")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)

                Spacer()

                Circle()
                    .fill(.clear)
                    .frame(width: 28, height: 28)
            }
            .padding(20)

            ScrollView {
                VStack(spacing: 24) {
                    // Oracle visualization
                    OracleVisualization(isThinking: isThinking)
                        .frame(height: 200)

                    if let response = response {
                        // Response
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The Oracle speaks...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.CelestialColors.nebulaEdge)

                            Text(response)
                                .font(.system(size: 16, design: .serif))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(6)
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Theme.CelestialColors.nebulaCore.opacity(0.1))
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }

            // Input bar
            HStack(spacing: 12) {
                TextField("Ask about your productivity...", text: $question)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                Button {
                    askOracle()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            question.isEmpty ? .white.opacity(0.2) : Theme.CelestialColors.nebulaCore
                        )
                }
                .disabled(question.isEmpty || isThinking)
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
        .background {
            SimpleVoidBackground(glowColor: Theme.CelestialColors.nebulaCore)
        }
    }

    private func askOracle() {
        guard !question.isEmpty else { return }

        isThinking = true
        HapticsService.shared.impact(.medium)

        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                response = "Based on your patterns, I see that you're most productive in the mornings, particularly between 9-11 AM. Consider scheduling your most important tasks during this window. Your current streak shows great momentum - keep building on it by maintaining consistent daily habits."
                isThinking = false
            }
        }
    }
}

struct OracleVisualization: View {
    let isThinking: Bool

    @State private var rotation: Double = 0
    @State private var pulsePhase: Double = 0

    var body: some View {
        ZStack {
            // Rings
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(
                        Theme.CelestialColors.nebulaCore.opacity(0.15 - Double(i) * 0.03),
                        lineWidth: 1
                    )
                    .frame(width: CGFloat(80 + i * 30), height: CGFloat(80 + i * 30))
                    .rotationEffect(.degrees(rotation + Double(i * 20)))
            }

            // Core
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.CelestialColors.nebulaCore.opacity(0.4),
                                Theme.CelestialColors.nebulaGlow.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + pulsePhase * 0.1)

                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 30, height: 30)
                    .blur(radius: isThinking ? 5 : 0)
            }

            if isThinking {
                // Thinking particles
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(Theme.CelestialColors.nebulaEdge)
                        .frame(width: 6, height: 6)
                        .offset(y: -50)
                        .rotationEffect(.degrees(Double(i) * 45 + rotation * 2))
                        .opacity(0.6)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsePhase = 1
            }
        }
    }
}
