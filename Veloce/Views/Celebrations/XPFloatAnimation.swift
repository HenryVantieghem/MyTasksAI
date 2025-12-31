//
//  XPFloatAnimation.swift
//  Veloce
//
//  XP Float Animation
//  Beautiful floating XP text that rises from completion point
//

import SwiftUI

// MARK: - XP Float Data

struct XPFloatData: Identifiable, Equatable {
    let id = UUID()
    let amount: Int
    let multiplier: Double
    let position: CGPoint
    let timestamp: Date = .now

    var displayAmount: Int {
        Int(Double(amount) * multiplier)
    }

    var hasMultiplier: Bool {
        multiplier > 1.0
    }

    static func == (lhs: XPFloatData, rhs: XPFloatData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - XP Float View

struct XPFloatView: View {
    let data: XPFloatData
    let onComplete: () -> Void

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var glowIntensity: Double = 0

    var body: some View {
        VStack(spacing: 2) {
            // Main XP amount
            HStack(spacing: 4) {
                Text("+")
                    .font(.system(size: 16, weight: .bold, design: .rounded))

                Text("\(data.displayAmount)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .contentTransition(.numericText())

                Text("XP")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Theme.Celebration.starGold,
                        Theme.Celebration.solarFlare
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Theme.Celebration.starGold.opacity(glowIntensity), radius: 8)

            // Multiplier badge (if applicable)
            if data.hasMultiplier {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .dynamicTypeFont(base: 10)

                    Text("×\(String(format: "%.1f", data.multiplier))")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Theme.Celebration.flameInner)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background {
                    Capsule()
                        .fill(Theme.Celebration.flameMid.opacity(0.3))
                }
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offsetY)
        .position(data.position)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Phase 1: Pop in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.2
            opacity = 1.0
            glowIntensity = 0.8
        }

        // Phase 2: Scale down to normal
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8).delay(0.15)) {
            scale = 1.0
        }

        // Phase 3: Float up and fade
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            offsetY = -80
            opacity = 0
            glowIntensity = 0
        }

        // Cleanup
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            onComplete()
        }
    }
}

// MARK: - XP Float Container

struct XPFloatContainer: View {
    @State private var floatingXP: [XPFloatData] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(floatingXP) { data in
                    XPFloatView(data: data) {
                        floatingXP.removeAll { $0.id == data.id }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onReceive(CelebrationEngine.shared.celebrationTriggered) { event in
            let data = XPFloatData(
                amount: event.xpEarned,
                multiplier: event.multiplier,
                position: event.position
            )
            floatingXP.append(data)
        }
    }
}

// MARK: - XP Counter Animation

struct XPCounterView: View {
    let currentXP: Int
    let previousXP: Int

    @State private var displayedXP: Int
    @State private var isAnimating = false

    init(currentXP: Int, previousXP: Int) {
        self.currentXP = currentXP
        self.previousXP = previousXP
        self._displayedXP = State(initialValue: previousXP)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(Theme.Celebration.starGold)
                .dynamicTypeFont(base: 14)

            Text("\(displayedXP)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text("XP")
                .dynamicTypeFont(base: 12, weight: .medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .onChange(of: currentXP) { oldValue, newValue in
            animateCounter(from: oldValue, to: newValue)
        }
    }

    private func animateCounter(from: Int, to: Int) {
        let difference = to - from
        let steps = min(abs(difference), 20)
        let stepValue = difference / max(steps, 1)
        let stepDuration = 0.5 / Double(steps)

        // Pulse animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            isAnimating = true
        }

        // Count up animation
        Task {
            for i in 1...steps {
                try? await Task.sleep(for: .seconds(stepDuration))
                withAnimation(.easeOut(duration: 0.1)) {
                    displayedXP = from + (stepValue * i)
                }
            }

            // Final value
            withAnimation(.easeOut(duration: 0.1)) {
                displayedXP = to
            }

            withAnimation(.spring(response: 0.3)) {
                isAnimating = false
            }
        }
    }
}

// MARK: - XP Earned Banner

struct XPEarnedBanner: View {
    let amount: Int
    let multiplier: Double
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    private var displayAmount: Int {
        Int(Double(amount) * multiplier)
    }

    var body: some View {
        if isShowing {
            HStack(spacing: 16) {
                // Star icon with glow
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Celebration.starGold.opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "star.fill")
                        .dynamicTypeFont(base: 28)
                        .foregroundStyle(Theme.Celebration.starGold)
                        .shadow(color: Theme.Celebration.starGold.opacity(0.8), radius: 10)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("+\(displayAmount) XP")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.Celebration.starGold,
                                    Theme.Celebration.solarFlare
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    if multiplier > 1.0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .dynamicTypeFont(base: 12)
                            Text("×\(String(format: "%.1f", multiplier)) Cosmic Flow bonus!")
                                .dynamicTypeFont(base: 12, weight: .medium)
                        }
                        .foregroundStyle(Theme.Celebration.flameInner)
                    }
                }

                Spacer()
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Theme.Celebration.starGold.opacity(0.4),
                                        Theme.Celebration.solarFlare.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: Theme.Celebration.starGold.opacity(0.2), radius: 20, y: 10)
            }
            .padding(.horizontal, 20)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }

                // Auto-dismiss
                Task {
                    try? await Task.sleep(for: .seconds(2.5))
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                        scale = 0.9
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - XP Sparkle Effect

struct XPSparkle: View {
    @State private var particles: [(id: UUID, offset: CGSize, opacity: Double)] = []

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Image(systemName: "sparkle")
                    .dynamicTypeFont(base: 8)
                    .foregroundStyle(Theme.Celebration.starGold)
                    .offset(particle.offset)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            startSparkles()
        }
    }

    private func startSparkles() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let id = UUID()
            let startOffset = CGSize(
                width: CGFloat.random(in: -20...20),
                height: CGFloat.random(in: -10...10)
            )

            particles.append((id: id, offset: startOffset, opacity: 1.0))

            withAnimation(.easeOut(duration: 0.8)) {
                if let index = particles.firstIndex(where: { $0.id == id }) {
                    particles[index].offset.height -= 30
                    particles[index].opacity = 0
                }
            }

            // Cleanup
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                particles.removeAll { $0.id == id }
            }
        }
    }
}

// MARK: - Preview

#Preview("XP Float") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            XPFloatView(
                data: XPFloatData(
                    amount: 50,
                    multiplier: 1.5,
                    position: CGPoint(x: 200, y: 400)
                )
            ) {}

            XPCounterView(currentXP: 1250, previousXP: 1200)
                .padding(.top, 100)
        }
    }
}

#Preview("XP Banner") {
    ZStack {
        Color.black.ignoresSafeArea()

        XPEarnedBanner(
            amount: 50,
            multiplier: 1.5,
            isShowing: .constant(true)
        )
    }
}
