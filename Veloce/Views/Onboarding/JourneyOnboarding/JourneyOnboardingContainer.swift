//
//  JourneyOnboardingContainer.swift
//  MyTasksAI
//
//  Journey Through the Cosmos - Main Container
//  Premium 5-step onboarding experience with ethereal orb guide
//

import SwiftUI

// MARK: - Journey Onboarding Container

struct JourneyOnboardingContainer: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var viewModel: JourneyOnboardingViewModel

    @State private var showContent = false
    @State private var orbState: EtherealOrbState = .idle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Ethereal color palette
    private let etherealColors: [Color] = [
        Color(red: 0.75, green: 0.55, blue: 0.90),
        Color(red: 0.55, green: 0.85, blue: 0.95),
        Color(red: 0.95, green: 0.65, blue: 0.80),
        Color(red: 0.70, green: 0.60, blue: 0.95),
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cosmic void background
                cosmicBackground

                // Ambient particles
                if !reduceMotion {
                    AmbientParticleField(
                        density: .sparse,
                        colors: etherealColors,
                        bounds: geometry.size
                    )
                    .opacity(showContent ? 0.5 : 0)
                }

                // Main content
                VStack(spacing: 0) {
                    // Constellation progress
                    ConstellationProgress(
                        totalSteps: OnboardingRealm.allCases.count,
                        currentStep: viewModel.currentRealm.rawValue
                    )
                    .padding(.top, topPadding(for: geometry))
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)

                    // Realm content
                    TabView(selection: $viewModel.currentRealm) {
                        WelcomeRealmView(viewModel: viewModel, onContinue: viewModel.nextRealm)
                            .tag(OnboardingRealm.welcome)

                        MissionControlRealmView(viewModel: viewModel, onContinue: viewModel.nextRealm)
                            .tag(OnboardingRealm.missionControl)

                        GoalSettingRealmView(viewModel: viewModel, onContinue: viewModel.nextRealm)
                            .tag(OnboardingRealm.goalSetting)

                        PowersRealmView(viewModel: viewModel, onContinue: viewModel.nextRealm)
                            .tag(OnboardingRealm.powers)

                        LaunchRealmView(viewModel: viewModel, onLaunch: viewModel.completeOnboarding)
                            .tag(OnboardingRealm.launch)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentRealm)
                }

                // Back button (if not on first step)
                if viewModel.canGoBack && showContent {
                    VStack {
                        HStack {
                            backButton
                            Spacer()
                        }
                        .padding(.top, topPadding(for: geometry) - 8)
                        .padding(.horizontal, 16)
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showContent = true
                }
            }
        }
        .task {
            viewModel.onComplete = {
                Task {
                    await appViewModel.checkAuthenticationState()
                }
            }
        }
    }

    // MARK: - Background

    private var cosmicBackground: some View {
        ZStack {
            // True void
            Color(red: 0.01, green: 0.01, blue: 0.02)
                .ignoresSafeArea()

            // Soft nebula hints
            RadialGradient(
                colors: [
                    etherealColors[0].opacity(0.08),
                    etherealColors[3].opacity(0.04),
                    Color.clear
                ],
                center: UnitPoint(x: 0.30, y: 0.25),
                startRadius: 0,
                endRadius: 350
            )
            .blur(radius: 50)

            RadialGradient(
                colors: [
                    etherealColors[1].opacity(0.06),
                    etherealColors[2].opacity(0.03),
                    Color.clear
                ],
                center: UnitPoint(x: 0.70, y: 0.70),
                startRadius: 0,
                endRadius: 300
            )
            .blur(radius: 45)
        }
        .ignoresSafeArea()
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button {
            viewModel.previousRealm()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                Text("Back")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
    }

    // MARK: - Layout

    private func topPadding(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        if height < 700 {
            return 50
        } else if height < 850 {
            return 60
        } else {
            return 70
        }
    }
}

// MARK: - Preview

#Preview {
    JourneyOnboardingContainer(viewModel: JourneyOnboardingViewModel())
        .environment(AppViewModel())
}
