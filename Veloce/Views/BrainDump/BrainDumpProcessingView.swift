//
//  BrainDumpProcessingView.swift
//  Veloce
//
//  Brain Dump Processing View
//  Beautiful AI thinking animation while processing thoughts
//

import SwiftUI

// MARK: - Brain Dump Processing View

struct BrainDumpProcessingView: View {
    @State private var orbScale: CGFloat = 1.0
    @State private var orbRotation: Double = 0
    @State private var glowOpacity: Double = 0.5
    @State private var ringScale: CGFloat = 0.8
    @State private var particleOffset: CGFloat = 0
    @State private var statusIndex: Int = 0

    @Environment(\.colorScheme) private var colorScheme

    private let statusMessages = [
        "Reading your thoughts...",
        "Finding patterns...",
        "Extracting tasks...",
        "Understanding context...",
        "Almost there..."
    ]

    var body: some View {
        ZStack {
            // Background
            voidBackground

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                // Central orb with effects
                centralOrb

                // Status text
                statusText

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Central Orb

    private var centralOrb: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(0.3),
                                Theme.Colors.aiBlue.opacity(0.2),
                                Theme.Colors.aiCyan.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 140 + CGFloat(index * 40), height: 140 + CGFloat(index * 40))
                    .scaleEffect(ringScale + CGFloat(index) * 0.1)
                    .opacity(0.5 - Double(index) * 0.15)
                    .rotationEffect(.degrees(orbRotation + Double(index * 30)))
            }

            // Main glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.4),
                            Theme.Colors.aiBlue.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .opacity(glowOpacity)

            // Inner orb
            ZStack {
                // Gradient orb
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiPurple,
                                Theme.Colors.aiBlue,
                                Theme.Colors.aiCyan
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                // Shine overlay
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: 80, height: 80)

                // Sparkle icon
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
                    .opacity(0.9)
            }
            .scaleEffect(orbScale)
            .rotationEffect(.degrees(-orbRotation * 0.5))

            // Floating particles
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(particleColor(for: index))
                    .frame(width: CGFloat.random(in: 4...8))
                    .offset(
                        x: cos(Double(index) * .pi / 4 + particleOffset) * 70,
                        y: sin(Double(index) * .pi / 4 + particleOffset) * 70
                    )
                    .opacity(0.7)
            }
        }
    }

    private func particleColor(for index: Int) -> Color {
        let colors = [
            Theme.Colors.aiPurple,
            Theme.Colors.aiBlue,
            Theme.Colors.aiCyan,
            Theme.Colors.aiPink
        ]
        return colors[index % colors.count]
    }

    // MARK: - Status Text

    private var statusText: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(statusMessages[statusIndex])
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.9))
                .contentTransition(.numericText())
                .animation(.easeInOut, value: statusIndex)

            // Dots animation
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .scaleEffect(dotScale(for: index))
                }
            }
        }
    }

    private func dotScale(for index: Int) -> CGFloat {
        let phase = (orbRotation / 30).truncatingRemainder(dividingBy: 3)
        return Int(phase) == index ? 1.3 : 0.8
    }

    // MARK: - Void Background

    private var voidBackground: some View {
        ZStack {
            Color(white: 0.02)

            // Subtle radial glow
            RadialGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Animations

    private func startAnimations() {
        // Orb breathing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            orbScale = 1.1
        }

        // Orb rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            orbRotation = 360
        }

        // Glow pulsing
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }

        // Ring expansion
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            ringScale = 1.0
        }

        // Particles orbit
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            particleOffset = .pi * 2
        }

        // Status message cycling
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                statusIndex = (statusIndex + 1) % statusMessages.count
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BrainDumpProcessingView()
}
