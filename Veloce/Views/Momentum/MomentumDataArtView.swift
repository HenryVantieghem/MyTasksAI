//
//  MomentumDataArtView.swift
//  Veloce
//
//  LIVING DATA GARDEN - A Revolutionary Stats & Goals Experience
//
//  Your productivity visualized as a living, breathing ecosystem.
//  Part 1: FLOW - Stats as organic data streams and morphing organisms
//  Part 2: GROW - AI-cultivated goals as a growing network
//
//  Design Philosophy: Data Art / Generative
//  - Organic, biological forms over geometric/cosmic
//  - Everything breathes, flows, and grows
//  - Perlin noise-based motion fields
//  - Mycelium-inspired goal networks
//  - Bioluminescent color palette
//

import SwiftUI
import SwiftData

// MARK: - Living Data Color Palette

enum LivingDataColors {
    // Deep organic backgrounds
    static let substrate = Color(red: 0.02, green: 0.03, blue: 0.04)
    static let humus = Color(red: 0.04, green: 0.05, blue: 0.06)
    static let loam = Color(red: 0.06, green: 0.07, blue: 0.09)

    // Bioluminescent accents
    static let biolumCyan = Color(red: 0.2, green: 0.9, blue: 0.85)
    static let biolumGreen = Color(red: 0.3, green: 0.95, blue: 0.5)
    static let biolumPink = Color(red: 0.95, green: 0.4, blue: 0.7)
    static let biolumPurple = Color(red: 0.7, green: 0.4, blue: 0.95)
    static let biolumOrange = Color(red: 0.98, green: 0.6, blue: 0.3)
    static let biolumYellow = Color(red: 0.98, green: 0.9, blue: 0.4)

    // Velocity gradient (health indicator)
    static let velocityLow = Color(red: 0.3, green: 0.4, blue: 0.5)
    static let velocityMid = Color(red: 0.4, green: 0.8, blue: 0.7)
    static let velocityHigh = Color(red: 0.3, green: 0.95, blue: 0.5)
    static let velocityMax = Color(red: 0.95, green: 0.9, blue: 0.4)

    // Text hierarchy
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.4)
    static let textGhost = Color.white.opacity(0.2)

    // Gradients
    static var velocityGradient: [Color] {
        [velocityLow, velocityMid, velocityHigh, velocityMax]
    }

    static var biolumGradient: [Color] {
        [biolumCyan, biolumGreen, biolumYellow, biolumPink, biolumPurple, biolumCyan]
    }

    static var myceliumGradient: LinearGradient {
        LinearGradient(
            colors: [biolumCyan.opacity(0.8), biolumGreen.opacity(0.6), biolumPurple.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Realm Enum

enum MomentumRealm: String, CaseIterable {
    case flow = "Flow"
    case grow = "Grow"

    var icon: String {
        switch self {
        case .flow: return "waveform.path"
        case .grow: return "leaf.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .flow: return "Your living data"
        case .grow: return "Cultivate goals"
        }
    }
}

// MARK: - Main View

struct MomentumDataArtView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query(sort: \Goal.targetDate) private var goals: [Goal]

    @State private var selectedRealm: MomentumRealm = .flow
    @State private var showGoalCreation = false
    @State private var showGoalDetail = false
    @State private var selectedGoal: Goal?
    @State private var goalsVM = GoalsViewModel()

    // Animation states
    @State private var hasAppeared = false
    @State private var realmTransitionPhase: CGFloat = 0

    private var gamification: GamificationService { GamificationService.shared }

    var body: some View {
        ZStack {
            // Cosmic void background (matches calendar)
            VoidBackground.calendar

            VStack(spacing: 0) {
                // Realm selector
                realmSelector
                    .padding(.top, 60)
                    .padding(.horizontal, 24)

                // Content based on realm
                TabView(selection: $selectedRealm) {
                    FlowRealmView(
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
                        levelProgress: gamification.levelProgress,
                        tasks: tasks
                    )
                    .tag(MomentumRealm.flow)

                    GrowRealmView(
                        goals: goals,
                        goalsVM: goalsVM,
                        onGoalTap: { goal in
                            selectedGoal = goal
                            showGoalDetail = true
                        },
                        onAddGoal: { showGoalCreation = true }
                    )
                    .tag(MomentumRealm.grow)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .sheet(isPresented: $showGoalCreation) {
            GoalCreationSheet(goalsVM: goalsVM)
        }
        .sheet(isPresented: $showGoalDetail) {
            if let goal = selectedGoal {
                GoalDetailSheet(goal: goal, goalsVM: goalsVM)
            }
        }
        .task {
            await goalsVM.loadGoals(context: modelContext)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Realm Selector

    private var realmSelector: some View {
        HStack(spacing: 0) {
            ForEach(MomentumRealm.allCases, id: \.self) { realm in
                realmTab(realm)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LivingDataColors.humus)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func realmTab(_ realm: MomentumRealm) -> some View {
        let isSelected = selectedRealm == realm

        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedRealm = realm
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: realm.icon)
                    .font(.system(size: 14, weight: .medium))

                VStack(alignment: .leading, spacing: 1) {
                    Text(realm.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    Text(realm.subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .opacity(isSelected ? 0.7 : 0.5)
                }
            }
            .foregroundStyle(isSelected ? LivingDataColors.textPrimary : LivingDataColors.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: realm == .flow
                                        ? [LivingDataColors.biolumCyan.opacity(0.2), LivingDataColors.biolumGreen.opacity(0.1)]
                                        : [LivingDataColors.biolumPink.opacity(0.2), LivingDataColors.biolumPurple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        (realm == .flow ? LivingDataColors.biolumCyan : LivingDataColors.biolumPink).opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Living Substrate Background

struct LivingSubstrateBackground: View {
    let realm: MomentumRealm

    @State private var phase: CGFloat = 0
    @State private var noiseOffset: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            // Base substrate
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(LivingDataColors.substrate)
            )

            // Organic noise texture overlay
            let columns = 40
            let rows = 60
            let cellWidth = size.width / CGFloat(columns)
            let cellHeight = size.height / CGFloat(rows)

            for row in 0..<rows {
                for col in 0..<columns {
                    let x = CGFloat(col) * cellWidth
                    let y = CGFloat(row) * cellHeight

                    // Perlin-like noise simulation
                    let noise = sin(CGFloat(col) * 0.3 + noiseOffset) * cos(CGFloat(row) * 0.2 + noiseOffset * 0.7)
                    let alpha = (noise + 1) * 0.015

                    let color = realm == .flow
                        ? LivingDataColors.biolumCyan
                        : LivingDataColors.biolumPink

                    context.fill(
                        Path(CGRect(x: x, y: y, width: cellWidth + 1, height: cellHeight + 1)),
                        with: .color(color.opacity(alpha))
                    )
                }
            }

            // Radial glow from bottom
            let glowCenter = CGPoint(x: size.width / 2, y: size.height * 1.2)
            let glowColor = realm == .flow
                ? LivingDataColors.biolumCyan
                : LivingDataColors.biolumPink

            context.fill(
                Path(ellipseIn: CGRect(
                    x: glowCenter.x - size.width,
                    y: glowCenter.y - size.width * 0.8,
                    width: size.width * 2,
                    height: size.width * 1.2
                )),
                with: .radialGradient(
                    Gradient(colors: [
                        glowColor.opacity(0.15),
                        glowColor.opacity(0.05),
                        Color.clear
                    ]),
                    center: glowCenter,
                    startRadius: 0,
                    endRadius: size.width
                )
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                noiseOffset = .pi * 4
            }
        }
    }
}

// MARK: - Flow Realm View (Stats)

struct FlowRealmView: View {
    let velocityScore: Double
    let streak: Int
    let longestStreak: Int
    let tasksCompleted: Int
    let tasksCompletedToday: Int
    let dailyGoal: Int
    let focusHours: Double
    let completionRate: Double
    let level: Int
    let totalPoints: Int
    let levelProgress: Double
    let tasks: [TaskItem]

    @State private var hasAnimated = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Hero: Velocity Blob
                VelocityBlobVisualization(
                    score: velocityScore,
                    streak: streak
                )
                .frame(height: 320)
                .padding(.top, 20)

                // Stats Grid
                statsGrid

                // Streak Organism
                if streak > 0 {
                    StreakOrganismCard(
                        currentStreak: streak,
                        longestStreak: longestStreak
                    )
                }

                // Flow Field - Weekly Activity
                TaskFlowFieldCard(tasks: tasks)

                // Level & XP
                LevelProgressCard(
                    level: level,
                    totalPoints: totalPoints,
                    progress: levelProgress
                )

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                hasAnimated = true
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            OrganicStatCell(
                value: "\(tasksCompletedToday)/\(dailyGoal)",
                label: "Today",
                progress: Double(tasksCompletedToday) / Double(max(dailyGoal, 1)),
                color: LivingDataColors.biolumCyan
            )

            OrganicStatCell(
                value: "\(tasksCompleted)",
                label: "All Time",
                progress: min(Double(tasksCompleted) / 500, 1.0),
                color: LivingDataColors.biolumGreen
            )

            OrganicStatCell(
                value: String(format: "%.1fh", focusHours),
                label: "Focus",
                progress: min(focusHours / 40, 1.0),
                color: LivingDataColors.biolumPurple
            )

            OrganicStatCell(
                value: "\(Int(completionRate))%",
                label: "On Time",
                progress: completionRate / 100,
                color: LivingDataColors.biolumOrange
            )
        }
    }
}

// MARK: - Organic Stat Cell

struct OrganicStatCell: View {
    let value: String
    let label: String
    let progress: Double
    let color: Color

    @State private var animatedProgress: Double = 0
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Value
            Text(value)
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundStyle(LivingDataColors.textPrimary)

            // Label
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LivingDataColors.textSecondary)

            // Organic progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(color.opacity(0.15))

                    // Fill with organic wobble
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress)
                        .overlay(
                            // Bioluminescent glow at tip
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                                .blur(radius: 4)
                                .opacity(0.8 + Foundation.sin(pulsePhase) * 0.2)
                                .offset(x: geometry.size.width * animatedProgress - 4)
                                .opacity(animatedProgress > 0.05 ? 1 : 0),
                            alignment: .leading
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LivingDataColors.humus)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
                animatedProgress = progress
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulsePhase = .pi * 2
            }
        }
    }
}

// MARK: - Velocity Blob Visualization

struct VelocityBlobVisualization: View {
    let score: Double
    let streak: Int

    @State private var morphPhase: CGFloat = 0
    @State private var rotationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var particlePhase: CGFloat = 0

    private var normalizedScore: Double {
        min(max(score, 0), 100) / 100
    }

    private var blobColor: Color {
        let colors = LivingDataColors.velocityGradient
        let index = normalizedScore * Double(colors.count - 1)
        let lowerIndex = Int(floor(index))
        let upperIndex = min(lowerIndex + 1, colors.count - 1)
        let fraction = index - Double(lowerIndex)

        // Simple interpolation
        return colors[lowerIndex].opacity(1 - fraction)
    }

    // Helper functions to avoid type-check timeout
    private func ringWidth(_ ring: Int) -> CGFloat {
        200 + CGFloat(ring) * 40 + CGFloat(Foundation.sin(Double(morphPhase) + Double(ring))) * 10
    }

    private func ringHeight(_ ring: Int) -> CGFloat {
        200 + CGFloat(ring) * 40 + CGFloat(Foundation.cos(Double(morphPhase) + Double(ring))) * 10
    }

    private func particleOffset(_ i: Int) -> CGSize {
        let angle = Double(particlePhase) + Double(i) * .pi / 6
        let radius: Double = 80 + Foundation.sin(Double(particlePhase) * 0.5 + Double(i)) * 20
        return CGSize(
            width: Foundation.cos(angle) * radius,
            height: Foundation.sin(angle) * radius
        )
    }

    private func particleOpacity(_ i: Int) -> Double {
        0.6 + Foundation.sin(Double(particlePhase) + Double(i)) * 0.4
    }

    var body: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        blobColor.opacity(0.1 - Double(ring) * 0.03),
                        lineWidth: 1
                    )
                    .frame(
                        width: ringWidth(ring),
                        height: ringHeight(ring)
                    )
                    .scaleEffect(pulseScale + CGFloat(ring) * 0.02)
            }

            // Main blob with morphing shape
            MorphingBlob(
                phase: morphPhase,
                color: blobColor,
                intensity: normalizedScore
            )
            .frame(width: 180, height: 180)
            .scaleEffect(pulseScale)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            blobColor.opacity(0.4),
                            blobColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 20)

            // Floating particles
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(blobColor)
                    .frame(width: 4, height: 4)
                    .blur(radius: 1)
                    .offset(particleOffset(i))
                    .opacity(particleOpacity(i))
            }

            // Score display
            VStack(spacing: 4) {
                Text("\(Int(score))")
                    .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(LivingDataColors.textPrimary)

                Text("VELOCITY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(LivingDataColors.textSecondary)

                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(streak) day streak")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(LivingDataColors.biolumOrange)
                    .padding(.top, 4)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                morphPhase = .pi * 2
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                particlePhase = .pi * 2
            }
        }
    }
}

// MARK: - Morphing Blob Shape

struct MorphingBlob: View {
    let phase: CGFloat
    let color: Color
    let intensity: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) / 2 * 0.8

            var path = Path()
            let points = 64

            for i in 0...points {
                let angle = (CGFloat(i) / CGFloat(points)) * .pi * 2

                // Multiple frequency noise for organic shape
                let noise1 = sin(angle * 3 + phase) * 0.15
                let noise2 = sin(angle * 5 + phase * 1.3) * 0.08
                let noise3 = sin(angle * 7 + phase * 0.7) * 0.05
                let totalNoise = (noise1 + noise2 + noise3) * intensity

                let radius = baseRadius * (1 + totalNoise)
                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()

            // Fill with gradient
            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        color,
                        color.opacity(0.7),
                        color.opacity(0.5)
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            // Subtle inner shadow
            context.stroke(
                path,
                with: .color(color.opacity(0.3)),
                lineWidth: 2
            )
        }
    }
}

// MARK: - Streak Organism Card

struct StreakOrganismCard: View {
    let currentStreak: Int
    let longestStreak: Int

    @State private var growPhase: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(LivingDataColors.biolumOrange)

                Text("Streak Organism")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LivingDataColors.textPrimary)

                Spacer()

                Text("Best: \(longestStreak)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LivingDataColors.textSecondary)
            }

            // Organism visualization
            StreakOrganismVisualization(
                streak: currentStreak,
                phase: growPhase
            )
            .frame(height: 120)

            // Streak stats
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentStreak)")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundStyle(LivingDataColors.biolumOrange)
                    Text("days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LivingDataColors.textSecondary)
                }

                // Progress to milestone
                VStack(alignment: .leading, spacing: 4) {
                    let nextMilestone = nextStreakMilestone(currentStreak)
                    let progress = Double(currentStreak) / Double(nextMilestone)

                    Text("\(nextMilestone - currentStreak) days to \(nextMilestone)-day milestone")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LivingDataColors.textSecondary)

                    GeometryReader { geo in
                        Capsule()
                            .fill(LivingDataColors.biolumOrange.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .fill(LivingDataColors.biolumOrange)
                                    .frame(width: geo.size.width * progress),
                                alignment: .leading
                            )
                    }
                    .frame(height: 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LivingDataColors.humus)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(LivingDataColors.biolumOrange.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                growPhase = .pi * 2
            }
        }
    }

    private func nextStreakMilestone(_ current: Int) -> Int {
        let milestones = [3, 7, 14, 21, 30, 60, 90, 180, 365]
        return milestones.first { $0 > current } ?? current + 30
    }
}

// MARK: - Streak Organism Visualization

struct StreakOrganismVisualization: View {
    let streak: Int
    let phase: CGFloat

    var body: some View {
        Canvas { context, size in
            let branches = min(streak, 30)
            let startX = size.width * 0.1
            let endX = size.width * 0.9
            let midY = size.height / 2

            // Main stem
            var stemPath = Path()
            stemPath.move(to: CGPoint(x: startX, y: midY))

            for i in 0...20 {
                let progress = CGFloat(i) / 20
                let x = startX + (endX - startX) * progress
                let waveY = sin(progress * .pi * 3 + phase) * 8
                stemPath.addLine(to: CGPoint(x: x, y: midY + waveY))
            }

            context.stroke(
                stemPath,
                with: .color(LivingDataColors.biolumOrange),
                lineWidth: 3
            )

            // Branches
            for i in 0..<branches {
                let progress = CGFloat(i + 1) / CGFloat(branches + 1)
                let x = startX + (endX - startX) * progress
                let baseY = midY + sin(progress * .pi * 3 + phase) * 8

                let branchAngle = (i % 2 == 0 ? -1 : 1) * CGFloat.pi * 0.3
                let branchLength = 15 + sin(phase + CGFloat(i)) * 5

                let endX = x + cos(branchAngle + .pi / 2) * branchLength
                let endY = baseY + sin(branchAngle + .pi / 2) * branchLength

                var branchPath = Path()
                branchPath.move(to: CGPoint(x: x, y: baseY))
                branchPath.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    branchPath,
                    with: .color(LivingDataColors.biolumOrange.opacity(0.7)),
                    lineWidth: 2
                )

                // Leaf/node at branch end
                context.fill(
                    Path(ellipseIn: CGRect(x: endX - 4, y: endY - 4, width: 8, height: 8)),
                    with: .color(LivingDataColors.biolumYellow.opacity(0.8))
                )
            }
        }
    }
}

// MARK: - Task Flow Field Card

struct TaskFlowFieldCard: View {
    let tasks: [TaskItem]

    @State private var flowPhase: CGFloat = 0

    private var weeklyData: [Int] {
        let calendar = Calendar.current
        var data = [Int](repeating: 0, count: 7)

        for task in tasks where task.isCompleted {
            guard let completedAt = task.completedAt else { continue }
            let weekday = calendar.component(.weekday, from: completedAt)
            let index = (weekday + 5) % 7 // Monday = 0
            if calendar.isDate(completedAt, equalTo: Date(), toGranularity: .weekOfYear) {
                data[index] += 1
            }
        }
        return data
    }

    private var maxValue: Int {
        max(weeklyData.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path")
                    .font(.system(size: 16))
                    .foregroundStyle(LivingDataColors.biolumCyan)

                Text("Weekly Flow")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LivingDataColors.textPrimary)

                Spacer()

                Text("\(weeklyData.reduce(0, +)) tasks")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LivingDataColors.textSecondary)
            }

            // Flow field visualization
            FlowFieldVisualization(
                data: weeklyData,
                maxValue: maxValue,
                phase: flowPhase
            )
            .frame(height: 100)

            // Day labels
            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(LivingDataColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LivingDataColors.humus)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(LivingDataColors.biolumCyan.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                flowPhase = .pi * 2
            }
        }
    }
}

// MARK: - Flow Field Visualization

struct FlowFieldVisualization: View {
    let data: [Int]
    let maxValue: Int
    let phase: CGFloat

    var body: some View {
        Canvas { context, size in
            let columnWidth = size.width / CGFloat(data.count)

            // Draw flowing particles for each column
            for (index, value) in data.enumerated() {
                let normalizedValue = CGFloat(value) / CGFloat(maxValue)
                let particleCount = Int(normalizedValue * 8) + 2
                let x = columnWidth * (CGFloat(index) + 0.5)

                for p in 0..<particleCount {
                    let particlePhase = phase + CGFloat(p) * 0.5 + CGFloat(index) * 0.3
                    let y = size.height * (0.2 + 0.6 * (sin(particlePhase) + 1) / 2)
                    let wobbleX = sin(particlePhase * 2) * 10

                    let alpha = 0.3 + normalizedValue * 0.5
                    let particleSize = 4 + normalizedValue * 4

                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: x + wobbleX - particleSize / 2,
                            y: y - particleSize / 2,
                            width: particleSize,
                            height: particleSize
                        )),
                        with: .color(LivingDataColors.biolumCyan.opacity(alpha))
                    )
                }

                // Column value indicator at bottom
                let barHeight = normalizedValue * size.height * 0.3
                context.fill(
                    Path(CGRect(
                        x: x - 3,
                        y: size.height - barHeight,
                        width: 6,
                        height: barHeight
                    )),
                    with: .linearGradient(
                        Gradient(colors: [
                            LivingDataColors.biolumCyan,
                            LivingDataColors.biolumCyan.opacity(0.3)
                        ]),
                        startPoint: CGPoint(x: x, y: size.height),
                        endPoint: CGPoint(x: x, y: size.height - barHeight)
                    )
                )
            }
        }
    }
}

// MARK: - Level Progress Card

struct LevelProgressCard: View {
    let level: Int
    let totalPoints: Int
    let progress: Double

    @State private var animatedProgress: Double = 0
    @State private var glowPhase: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: LivingDataColors.biolumGradient,
                                center: .center,
                                angle: .degrees(Double(glowPhase) * 360 / (.pi * 2))
                            )
                        )
                        .frame(width: 48, height: 48)
                        .blur(radius: 1)

                    Circle()
                        .fill(LivingDataColors.substrate)
                        .frame(width: 42, height: 42)

                    Text("\(level)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(LivingDataColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Level \(level)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(LivingDataColors.textPrimary)

                    Text("\(totalPoints) XP total")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LivingDataColors.textSecondary)
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LivingDataColors.biolumPurple)
            }

            // Organic progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(LivingDataColors.biolumPurple.opacity(0.15))

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    LivingDataColors.biolumPurple,
                                    LivingDataColors.biolumCyan
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedProgress)

                    // Glow tip
                    Circle()
                        .fill(LivingDataColors.biolumCyan)
                        .frame(width: 12, height: 12)
                        .blur(radius: 4)
                        .offset(x: geo.size.width * animatedProgress - 6)
                        .opacity(animatedProgress > 0.02 ? 1 : 0)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LivingDataColors.humus)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(LivingDataColors.biolumPurple.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                animatedProgress = progress
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                glowPhase = .pi * 2
            }
        }
    }
}

// MARK: - Grow Realm View (Goals)

struct GrowRealmView: View {
    let goals: [Goal]
    let goalsVM: GoalsViewModel
    let onGoalTap: (Goal) -> Void
    let onAddGoal: () -> Void

    @State private var networkPhase: CGFloat = 0
    @State private var showAIAssistant = false

    private var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    private var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Mycelium Network Hero
                MyceliumNetworkVisualization(
                    goals: activeGoals,
                    phase: networkPhase
                )
                .frame(height: 280)
                .padding(.top, 20)

                // AI Goal Assistant Button
                aiAssistantButton

                // Active Goals
                if !activeGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Growing", count: activeGoals.count)

                        ForEach(activeGoals) { goal in
                            OrganicGoalCard(goal: goal)
                                .onTapGesture { onGoalTap(goal) }
                        }
                    }
                }

                // Add Goal Button
                addGoalButton

                // Completed Goals
                if !completedGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Harvested", count: completedGoals.count)

                        ForEach(completedGoals.prefix(3)) { goal in
                            CompletedGoalPill(goal: goal)
                        }
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showAIAssistant) {
            AIGoalAssistantSheet()
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                networkPhase = .pi * 2
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(LivingDataColors.textSecondary)

            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LivingDataColors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(LivingDataColors.loam)
                )

            Spacer()
        }
    }

    private var aiAssistantButton: some View {
        Button {
            showAIAssistant = true
        } label: {
            HStack(spacing: 12) {
                // AI orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    LivingDataColors.biolumPink,
                                    LivingDataColors.biolumPurple.opacity(0.5)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .blur(radius: 2)

                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Goal Assistant")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(LivingDataColors.textPrimary)

                    Text("Let's cultivate your next goal together")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LivingDataColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LivingDataColors.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                LivingDataColors.biolumPink.opacity(0.15),
                                LivingDataColors.biolumPurple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LivingDataColors.biolumPink.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var addGoalButton: some View {
        Button {
            onAddGoal()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))

                Text("Plant a New Goal")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(LivingDataColors.biolumGreen)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(LivingDataColors.biolumGreen.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(LivingDataColors.biolumGreen.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mycelium Network Visualization

struct MyceliumNetworkVisualization: View {
    let goals: [Goal]
    let phase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let nodePositions = calculateNodePositions(count: goals.count, in: size)

                // Draw connections (mycelium threads)
                for i in 0..<nodePositions.count {
                    for j in (i + 1)..<nodePositions.count {
                        let start = nodePositions[i]
                        let end = nodePositions[j]
                        let distance = hypot(end.x - start.x, end.y - start.y)

                        if distance < size.width * 0.5 {
                            var path = Path()
                            path.move(to: start)

                            // Curved connection with wave
                            let midX = (start.x + end.x) / 2 + sin(phase + CGFloat(i + j)) * 20
                            let midY = (start.y + end.y) / 2 + cos(phase + CGFloat(i + j)) * 20

                            path.addQuadCurve(
                                to: end,
                                control: CGPoint(x: midX, y: midY)
                            )

                            let opacity = 0.15 + (1 - distance / (size.width * 0.5)) * 0.15
                            context.stroke(
                                path,
                                with: .color(LivingDataColors.biolumGreen.opacity(opacity)),
                                lineWidth: 1.5
                            )
                        }
                    }
                }

                // Draw nodes (goals)
                for (index, position) in nodePositions.enumerated() {
                    let goal = goals[safe: index]
                    let progress = goal?.progress ?? 0
                    let nodeSize = 30 + progress * 20

                    // Outer glow
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: position.x - nodeSize - 5,
                            y: position.y - nodeSize - 5,
                            width: (nodeSize + 5) * 2,
                            height: (nodeSize + 5) * 2
                        )),
                        with: .radialGradient(
                            Gradient(colors: [
                                LivingDataColors.biolumPink.opacity(0.3),
                                Color.clear
                            ]),
                            center: position,
                            startRadius: nodeSize * 0.5,
                            endRadius: nodeSize + 10
                        )
                    )

                    // Node
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: position.x - nodeSize / 2,
                            y: position.y - nodeSize / 2,
                            width: nodeSize,
                            height: nodeSize
                        )),
                        with: .linearGradient(
                            Gradient(colors: [
                                LivingDataColors.biolumPink,
                                LivingDataColors.biolumPurple
                            ]),
                            startPoint: CGPoint(x: position.x, y: position.y - nodeSize / 2),
                            endPoint: CGPoint(x: position.x, y: position.y + nodeSize / 2)
                        )
                    )

                    // Inner highlight
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: position.x - nodeSize / 4,
                            y: position.y - nodeSize / 4,
                            width: nodeSize / 2,
                            height: nodeSize / 2
                        )),
                        with: .color(Color.white.opacity(0.2))
                    )
                }

                // Empty state
                if goals.isEmpty {
                    let centerX = size.width / 2
                    let centerY = size.height / 2

                    // Pulsing seed
                    let pulseSize = 40 + sin(phase * 2) * 5
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: centerX - pulseSize - 20,
                            y: centerY - pulseSize - 20,
                            width: (pulseSize + 20) * 2,
                            height: (pulseSize + 20) * 2
                        )),
                        with: .radialGradient(
                            Gradient(colors: [
                                LivingDataColors.biolumGreen.opacity(0.2),
                                Color.clear
                            ]),
                            center: CGPoint(x: centerX, y: centerY),
                            startRadius: 0,
                            endRadius: pulseSize + 30
                        )
                    )

                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: centerX - pulseSize / 2,
                            y: centerY - pulseSize / 2,
                            width: pulseSize,
                            height: pulseSize
                        )),
                        with: .color(LivingDataColors.biolumGreen.opacity(0.6))
                    )
                }
            }

            // Goal labels overlay
            ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                let positions = calculateNodePositions(count: goals.count, in: geometry.size)
                if let position = positions[safe: index] {
                    VStack(spacing: 2) {
                        Text("\(Int(goal.progress * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .position(position)
                }
            }

            // Empty state text
            if goals.isEmpty {
                VStack(spacing: 8) {
                    Text("Plant your first goal")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LivingDataColors.textSecondary)

                    Text("Watch your garden grow")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LivingDataColors.textTertiary)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 50)
            }
        }
    }

    private func calculateNodePositions(count: Int, in size: CGSize) -> [CGPoint] {
        guard count > 0 else { return [] }

        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius = min(size.width, size.height) * 0.35

        if count == 1 {
            return [CGPoint(x: centerX, y: centerY)]
        }

        return (0..<count).map { i in
            let angle = (CGFloat(i) / CGFloat(count)) * .pi * 2 - .pi / 2
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Organic Goal Card

struct OrganicGoalCard: View {
    let goal: Goal

    @State private var pulsePhase: CGFloat = 0

    private var categoryColor: Color {
        switch goal.category?.lowercased() {
        case "career": return LivingDataColors.biolumPurple
        case "health": return LivingDataColors.biolumGreen
        case "personal": return LivingDataColors.biolumCyan
        case "financial": return LivingDataColors.biolumYellow
        case "education": return LivingDataColors.biolumOrange
        case "relationships": return LivingDataColors.biolumPink
        default: return LivingDataColors.biolumCyan
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(categoryColor.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: goal.progress)
                    .stroke(categoryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(goal.progress * 100))")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LivingDataColors.textPrimary)
            }
            .frame(width: 50, height: 50)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(LivingDataColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Category
                    Text(goal.category ?? "Other")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(categoryColor)

                    // Days remaining
                    if let days = goal.daysRemaining {
                        Text("\(days)d left")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(LivingDataColors.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LivingDataColors.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LivingDataColors.humus)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(categoryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Completed Goal Pill

struct CompletedGoalPill: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(LivingDataColors.biolumGreen)

            Text(goal.title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(LivingDataColors.textSecondary)
                .lineLimit(1)

            Spacer()

            if let completedAt = goal.completedAt {
                Text(completedAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LivingDataColors.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(LivingDataColors.humus)
        )
    }
}

// MARK: - AI Goal Assistant Sheet

struct AIGoalAssistantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userInput = ""
    @State private var messages: [AIAssistantMessage] = []
    @State private var isThinking = false
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LivingDataColors.substrate
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeView
                                    .padding(.top, 40)
                            }

                            ForEach(messages) { message in
                                messageView(message)
                            }

                            if isThinking {
                                thinkingIndicator
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }

                    // Input
                    inputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(LivingDataColors.biolumPink)
                            .frame(width: 8, height: 8)
                            .blur(radius: 2)

                        Text("Goal Assistant")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(LivingDataColors.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(LivingDataColors.textSecondary)
                            .padding(8)
                            .background(Circle().fill(LivingDataColors.humus))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulsePhase = 1
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 24) {
            // Pulsing orb
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LivingDataColors.biolumPink.opacity(0.4),
                                LivingDataColors.biolumPurple.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + pulsePhase * 0.1)

                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(LivingDataColors.textPrimary)
            }

            VStack(spacing: 8) {
                Text("Let's cultivate a goal")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(LivingDataColors.textPrimary)

                Text("Tell me what you want to achieve, and I'll help you create a roadmap to get there.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LivingDataColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Suggestion chips
            VStack(spacing: 12) {
                suggestionChip("I want to read more books this year")
                suggestionChip("Help me get in shape")
                suggestionChip("I'd like to learn a new skill")
            }
        }
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            userInput = text
            sendMessage()
        } label: {
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(LivingDataColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(LivingDataColors.humus)
                        .overlay(
                            Capsule()
                                .stroke(LivingDataColors.biolumPink.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func messageView(_ message: AIAssistantMessage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isAI {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [LivingDataColors.biolumPink, LivingDataColors.biolumPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    )
            }

            VStack(alignment: message.isAI ? .leading : .trailing, spacing: 8) {
                Text(message.content)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LivingDataColors.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isAI ? LivingDataColors.humus : LivingDataColors.biolumPurple.opacity(0.3))
                    )
            }
            .frame(maxWidth: .infinity, alignment: message.isAI ? .leading : .trailing)

            if !message.isAI {
                Circle()
                    .fill(LivingDataColors.biolumCyan)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    )
            }
        }
    }

    private var thinkingIndicator: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [LivingDataColors.biolumPink, LivingDataColors.biolumPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                )

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(LivingDataColors.textSecondary)
                        .frame(width: 6, height: 6)
                        .opacity(0.5 + (pulsePhase * (i == 0 ? 1 : (i == 1 ? 0.5 : 0))))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LivingDataColors.humus)
            )

            Spacer()
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Describe your goal...", text: $userInput)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LivingDataColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(LivingDataColors.humus)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(LivingDataColors.biolumPink.opacity(0.2), lineWidth: 1)
                        )
                )

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [LivingDataColors.biolumPink, LivingDataColors.biolumPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .disabled(userInput.isEmpty)
            .opacity(userInput.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(LivingDataColors.substrate)
                .shadow(color: .black.opacity(0.3), radius: 20, y: -10)
        )
    }

    private func sendMessage() {
        guard !userInput.isEmpty else { return }

        let userMessage = AIAssistantMessage(content: userInput, isAI: false)
        messages.append(userMessage)
        let input = userInput
        userInput = ""

        isThinking = true

        // Simulate AI response (in real implementation, call AIService)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isThinking = false
            let aiResponse = AIAssistantMessage(
                content: "That's a great goal! Let me help you break it down into actionable steps. First, let's make it SMART - Specific, Measurable, Achievable, Relevant, and Time-bound.\n\nBased on \"\(input)\", I suggest we set a concrete target and timeline. What timeframe are you thinking - a sprint (1-2 weeks), milestone (1-3 months), or horizon goal (3-12 months)?",
                isAI: true
            )
            messages.append(aiResponse)
        }
    }
}

// MARK: - AI Assistant Message Model

struct AIAssistantMessage: Identifiable {
    let id = UUID()
    let content: String
    let isAI: Bool
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    MomentumDataArtView()
}
