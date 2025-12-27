//
//  WelcomeRealmView.swift
//  MyTasksAI
//
//  Step 1: "Welcome to Your Cosmos"
//  Personalized greeting with ethereal orb
//

import SwiftUI

struct WelcomeRealmView: View {
    @Bindable var viewModel: JourneyOnboardingViewModel
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var orbState: EtherealOrbState = .idle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geometry.size.height * 0.08)

                // Ethereal Orb - Hero
                EtherealOrb(
                    size: .hero,
                    state: orbState,
                    isAnimating: true,
                    intensity: viewModel.orbIntensity,
                    showGlow: true
                )
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)

                Spacer()
                    .frame(height: 40)

                // Welcome text
                VStack(spacing: 16) {
                    Text("Welcome to Your Cosmos")
                        .font(.system(size: 28, weight: .thin))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    Text(viewModel.userFirstName)
                        .font(.system(size: 42, weight: .thin))
                        .tracking(4)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.85, blue: 0.95),
                                    Color(red: 0.75, green: 0.55, blue: 0.90)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }

                Spacer()
                    .frame(height: 24)

                // Tagline
                Text("Your AI-powered journey to\npeak productivity begins here")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)

                Spacer()

                // CTA Button
                Button {
                    HapticsService.shared.impact()
                    onContinue()
                } label: {
                    HStack(spacing: 10) {
                        Text("Begin Your Journey")
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
                        color: Color(red: 0.55, green: 0.85, blue: 0.95).opacity(0.4),
                        radius: 20,
                        y: 8
                    )
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
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
            return
        }

        // Staggered reveal
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            showContent = true
        }

        // Orb becomes welcoming
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                orbState = .active
            }
        }

        // Return to idle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                orbState = .idle
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        WelcomeRealmView(viewModel: JourneyOnboardingViewModel()) {
            print("Continue tapped")
        }
    }
}
