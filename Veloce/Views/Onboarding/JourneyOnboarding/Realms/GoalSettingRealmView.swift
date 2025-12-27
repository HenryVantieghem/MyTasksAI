//
//  GoalSettingRealmView.swift
//  MyTasksAI
//
//  Step 3: "Set Your Goals"
//  Daily and weekly goal selection
//

import SwiftUI

struct GoalSettingRealmView: View {
    @Bindable var viewModel: JourneyOnboardingViewModel
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var orbState: EtherealOrbState = .idle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dailyDescriptions: [Int: String] = [
        3: "A gentle start",
        5: "Balanced • Recommended",
        7: "Ambitious! You've got this",
        10: "Power mode activated"
    ]

    private let weeklyDescriptions: [Int: String] = [
        15: "Steady pace",
        25: "Consistent • Recommended",
        35: "High achiever",
        50: "Maximum momentum"
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.03)

                    // Ethereal Orb - Encouraging state
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
                        .frame(height: 24)

                    // Header
                    VStack(spacing: 10) {
                        Text("Set Your Goals")
                            .font(.system(size: 26, weight: .thin))
                            .tracking(2)
                            .foregroundStyle(.white)

                        Text("What do you want to achieve?")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)

                    Spacer()
                        .frame(height: 32)

                    // Daily Goal Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("DAILY TASKS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.leading, 4)

                        HStack(spacing: 10) {
                            ForEach(JourneyOnboardingViewModel.dailyGoalOptions, id: \.self) { goal in
                                JourneyGoalOptionButton(
                                    value: goal,
                                    isSelected: viewModel.dailyTaskGoal == goal,
                                    description: dailyDescriptions[goal] ?? ""
                                ) {
                                    viewModel.selectDailyGoal(goal)
                                }
                            }
                        }

                        // Current selection description
                        if let description = dailyDescriptions[viewModel.dailyTaskGoal] {
                            Text(description)
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 0.95))
                                .padding(.leading, 4)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Spacer()
                        .frame(height: 32)

                    // Weekly Goal Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("WEEKLY TASKS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.leading, 4)

                        HStack(spacing: 10) {
                            ForEach(JourneyOnboardingViewModel.weeklyGoalOptions, id: \.self) { goal in
                                JourneyGoalOptionButton(
                                    value: goal,
                                    isSelected: viewModel.weeklyTaskGoal == goal,
                                    description: weeklyDescriptions[goal] ?? ""
                                ) {
                                    viewModel.selectWeeklyGoal(goal)
                                }
                            }
                        }

                        // Current selection description
                        if let description = weeklyDescriptions[viewModel.weeklyTaskGoal] {
                            Text(description)
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 0.90))
                                .padding(.leading, 4)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Spacer()
                        .frame(height: 40)

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
        }
        .onAppear {
            startAnimations()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.dailyTaskGoal)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.weeklyTaskGoal)
    }

    private func startAnimations() {
        guard !reduceMotion else {
            showContent = true
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            orbState = .active
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            orbState = .idle
        }
    }
}

// MARK: - Journey Goal Option Button

private struct JourneyGoalOptionButton: View {
    let value: Int
    let isSelected: Bool
    let description: String
    let action: () -> Void

    private let selectedGradient = LinearGradient(
        colors: [
            Color(red: 0.55, green: 0.85, blue: 0.95).opacity(0.2),
            Color(red: 0.75, green: 0.55, blue: 0.90).opacity(0.15)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(selectedGradient) : AnyShapeStyle(.ultraThinMaterial.opacity(0.5)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isSelected ?
                                AnyShapeStyle(LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.85, blue: 0.95).opacity(0.6),
                                        Color(red: 0.75, green: 0.55, blue: 0.90).opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )) :
                                AnyShapeStyle(Color.white.opacity(0.12)),
                            lineWidth: isSelected ? 1.5 : 0.75
                        )
                )
                .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        GoalSettingRealmView(viewModel: JourneyOnboardingViewModel()) {
            print("Continue tapped")
        }
    }
}
