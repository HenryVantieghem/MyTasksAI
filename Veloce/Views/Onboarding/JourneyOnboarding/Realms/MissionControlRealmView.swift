//
//  MissionControlRealmView.swift
//  MyTasksAI
//
//  Step 2: "Your Mission Control"
//  Feature showcase with animated cards
//

import SwiftUI

struct MissionControlRealmView: View {
    @Bindable var viewModel: JourneyOnboardingViewModel
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showCards = [false, false, false]
    @State private var orbState: EtherealOrbState = .idle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let features: [(icon: String, title: String, description: String, color: Color)] = [
        ("sparkles", "AI Task Intelligence", "Smart suggestions that understand your workflow", Color(red: 0.75, green: 0.55, blue: 0.90)),
        ("flame.fill", "Deep Focus Sessions", "Block distractions, enter flow state", Color(red: 1.0, green: 0.70, blue: 0.30)),
        ("star.fill", "Progress & Achievements", "Track momentum, earn rewards", Color(red: 0.55, green: 0.85, blue: 0.95))
    ]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geometry.size.height * 0.04)

                // Ethereal Orb - Presenting state
                EtherealOrb(
                    size: .large,
                    state: orbState,
                    isAnimating: true,
                    intensity: viewModel.orbIntensity,
                    showGlow: true
                )
                .scaleEffect(showContent ? 1 : 0.85)
                .opacity(showContent ? 1 : 0)

                Spacer()
                    .frame(height: 28)

                // Header
                VStack(spacing: 10) {
                    Text("Your Mission Control")
                        .font(.system(size: 26, weight: .thin))
                        .tracking(2)
                        .foregroundStyle(.white)

                    Text("Everything you need to succeed")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

                Spacer()
                    .frame(height: 32)

                // Feature cards
                VStack(spacing: 14) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        FeatureCard(
                            icon: feature.icon,
                            title: feature.title,
                            description: feature.description,
                            accentColor: feature.color
                        )
                        .opacity(showCards[index] ? 1 : 0)
                        .offset(y: showCards[index] ? 0 : 20)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // CTA Button
                Button {
                    HapticsService.shared.impact()
                    onContinue()
                } label: {
                    HStack(spacing: 10) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.85, blue: 0.95),
                                        Color(red: 0.75, green: 0.55, blue: 0.90)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(
                        color: Color(red: 0.55, green: 0.85, blue: 0.95).opacity(0.35),
                        radius: 18,
                        y: 8
                    )
                }
                .opacity(showContent ? 1 : 0)
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 50)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        guard !reduceMotion else {
            showContent = true
            showCards = [true, true, true]
            return
        }

        // Main content
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }

        // Staggered card reveal
        for (index, _) in features.enumerated() {
            let delay = 0.4 + Double(index) * 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    showCards[index] = true
                }
            }
        }

        // Orb presenting state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            orbState = .active
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        MissionControlRealmView(viewModel: JourneyOnboardingViewModel()) {
            print("Continue tapped")
        }
    }
}
