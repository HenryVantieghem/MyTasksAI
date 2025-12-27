//
//  SendChallengeSheet.swift
//  Veloce
//
//  Send Challenge - Configure and launch competitive challenges
//  Beautiful step-by-step wizard with animated type selection
//

import SwiftUI

// MARK: - Send Challenge Sheet

struct SendChallengeSheet: View {
    var preselectedFriend: FriendProfile?

    @Environment(\.dismiss) private var dismiss
    @State private var friendService = FriendService.shared
    @State private var circleService = CircleService.shared
    @State private var challengeService = ChallengeService.shared

    // Form state
    @State private var currentStep = 0
    @State private var selectedType: ChallengeType = .taskCompletion
    @State private var selectedRecipients: [UUID] = []
    @State private var targetValue: Int = 10
    @State private var durationHours: Int = 24
    @State private var stakes: String = ""
    @State private var customTitle: String = ""

    // Loading/Error state
    @State private var isSending = false
    @State private var error: String?
    @State private var showSuccess = false

    // Animation
    @State private var showContent = false

    private let steps = ["Type", "Who", "Details", "Confirm"]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.CelestialColors.void.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    stepIndicator
                        .padding(.top, 8)

                    // Step content
                    TabView(selection: $currentStep) {
                        challengeTypeStep.tag(0)
                        recipientStep.tag(1)
                        detailsStep.tag(2)
                        confirmStep.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.4), value: currentStep)

                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
            .onAppear {
                if let friend = preselectedFriend {
                    selectedRecipients = [friend.id]
                }
                withAnimation(.spring(response: 0.5).delay(0.1)) {
                    showContent = true
                }
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack(spacing: 8) {
                    // Step circle
                    ZStack {
                        SwiftUI.Circle()
                            .fill(index <= currentStep ? selectedType.color : Color.white.opacity(0.1))
                            .frame(width: 28, height: 28)

                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(index <= currentStep ? .white : Theme.CelestialColors.starGhost)
                        }
                    }

                    // Step name (only for current)
                    if index == currentStep {
                        Text(steps[index])
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.CelestialColors.starWhite)
                    }

                    // Connector line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? selectedType.color : Color.white.opacity(0.1))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Step 1: Challenge Type

    private var challengeTypeStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 8) {
                    Text("Choose Challenge Type")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("What kind of challenge are you in the mood for?")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .padding(.top, 20)

                // Type grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(ChallengeType.allCases) { type in
                        ChallengeTypeSelectionCard(
                            type: type,
                            isSelected: selectedType == type,
                            onSelect: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedType = type
                                }
                            }
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.spring(response: 0.5).delay(Double(type.hashValue % 4) * 0.1), value: showContent)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Step 2: Recipients

    private var recipientStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Challenge Who?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("Select friends to challenge")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .padding(.top, 20)

                // Friends list
                VStack(spacing: 8) {
                    ForEach(friendService.friends) { friendship in
                        if let friend = friendship.otherUser(currentUserId: getCurrentUserId()) {
                            FriendSelectionRow(
                                friend: friend,
                                isSelected: selectedRecipients.contains(friend.id),
                                onToggle: {
                                    withAnimation(.spring(response: 0.3)) {
                                        if selectedRecipients.contains(friend.id) {
                                            selectedRecipients.removeAll { $0 == friend.id }
                                        } else {
                                            selectedRecipients.append(friend.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Circles section
                if !circleService.circles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or challenge a Circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(circleService.circles) { circle in
                                    CircleSelectionPill(circle: circle)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Step 3: Details

    private var detailsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Set the Terms")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("Define the challenge parameters")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .padding(.top, 20)

                // Target value
                VStack(alignment: .leading, spacing: 12) {
                    Text("Target")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    HStack {
                        // Decrease
                        Button {
                            withAnimation(.spring(response: 0.2)) {
                                targetValue = max(1, targetValue - targetStep)
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.CelestialColors.starWhite)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1), in: SwiftUI.Circle())
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("\(targetValue)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(selectedType.color)

                            Text(selectedType.unitLabel)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                        }

                        Spacer()

                        // Increase
                        Button {
                            withAnimation(.spring(response: 0.2)) {
                                targetValue += targetStep
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.CelestialColors.starWhite)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1), in: SwiftUI.Circle())
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                // Duration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(durationOptions, id: \.hours) { option in
                                DurationOption(
                                    label: option.label,
                                    isSelected: durationHours == option.hours,
                                    color: selectedType.color
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        durationHours = option.hours
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Stakes (optional)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Stakes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.CelestialColors.starDim)

                        Text("(optional)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starGhost)
                    }

                    TextField("e.g., Loser buys coffee", text: $stakes)
                        .font(.system(size: 15))
                        .padding(16)
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Step 4: Confirm

    private var confirmStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Challenge preview card
                VStack(spacing: 20) {
                    // Type header
                    ZStack {
                        SwiftUI.Circle()
                            .fill(selectedType.color.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: selectedType.icon)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(selectedType.color)
                    }

                    Text(challengeTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                        .multilineTextAlignment(.center)

                    // Details grid
                    HStack(spacing: 24) {
                        confirmDetail(icon: "target", value: "\(targetValue)", label: selectedType.unitLabel)
                        confirmDetail(icon: "clock", value: formattedDuration, label: "duration")
                        confirmDetail(icon: "star.fill", value: "+\(xpReward)", label: "XP")
                    }

                    // Recipients
                    VStack(spacing: 8) {
                        Text("Challenging")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.starGhost)

                        HStack(spacing: -8) {
                            ForEach(selectedRecipients.prefix(5), id: \.self) { id in
                                SwiftUI.Circle()
                                    .fill(Theme.CelestialColors.nebulaDust)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Text("?")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Theme.CelestialColors.starDim)
                                    }
                                    .overlay {
                                        SwiftUI.Circle()
                                            .stroke(Theme.CelestialColors.void, lineWidth: 2)
                                    }
                            }

                            if selectedRecipients.count > 5 {
                                SwiftUI.Circle()
                                    .fill(selectedType.color.opacity(0.3))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Text("+\(selectedRecipients.count - 5)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(selectedType.color)
                                    }
                            }
                        }
                    }

                    // Stakes
                    if !stakes.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text("Stakes: \(stakes)")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Theme.CelestialColors.solarFlare)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.CelestialColors.solarFlare.opacity(0.15), in: Capsule())
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(selectedType.color.opacity(0.3), lineWidth: 1)
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Ready text
                Text("Ready to send this challenge?")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            .padding(.bottom, 100)
        }
    }

    private func confirmDetail(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Theme.CelestialColors.starWhite)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.CelestialColors.starGhost)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Back button
            if currentStep > 0 {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .frame(width: 52, height: 52)
                        .background(Color.white.opacity(0.08), in: SwiftUI.Circle())
                }
            }

            Spacer()

            // Next/Send button
            Button {
                if currentStep < steps.count - 1 {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep += 1
                    }
                } else {
                    sendChallenge()
                }
            } label: {
                HStack(spacing: 8) {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep == steps.count - 1 ? "Send Challenge" : "Next")
                            .font(.system(size: 16, weight: .bold))

                        Image(systemName: currentStep == steps.count - 1 ? "paperplane.fill" : "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(canProceed && !isSending ? selectedType.color : Color.white.opacity(0.1), in: Capsule())
                .shadow(color: canProceed && !isSending ? selectedType.color.opacity(0.4) : Color.clear, radius: 12, y: 4)
            }
            .disabled(!canProceed || isSending)
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    // MARK: - Helpers

    private var challengeTitle: String {
        if !customTitle.isEmpty { return customTitle }
        switch selectedType {
        case .taskCompletion: return "\(targetValue) Task Sprint"
        case .focusTime: return "\(targetValue / 60)h Focus Marathon"
        case .streak: return "\(targetValue)-Day Streak Challenge"
        case .custom: return "Custom Challenge"
        }
    }

    private var targetStep: Int {
        switch selectedType {
        case .taskCompletion: return 1
        case .focusTime: return 15
        case .streak: return 1
        case .custom: return 10
        }
    }

    private var durationOptions: [(label: String, hours: Int)] {
        [
            ("1 hour", 1),
            ("6 hours", 6),
            ("24 hours", 24),
            ("3 days", 72),
            ("1 week", 168)
        ]
    }

    private var formattedDuration: String {
        if durationHours >= 168 { return "1 week" }
        if durationHours >= 72 { return "3 days" }
        if durationHours >= 24 { return "24h" }
        return "\(durationHours)h"
    }

    private var xpReward: Int {
        // Calculate based on difficulty
        let baseXP = 50
        let valueMultiplier = targetValue / 5
        let durationMultiplier = durationHours / 24
        return baseXP + (valueMultiplier * 10) + (durationMultiplier * 25)
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !selectedRecipients.isEmpty
        case 2: return targetValue > 0 && durationHours > 0
        case 3: return true
        default: return false
        }
    }

    private func getCurrentUserId() -> UUID {
        UUID() // Will be resolved by ChallengeService from auth
    }

    private func sendChallenge() {
        guard !selectedRecipients.isEmpty else { return }

        isSending = true
        error = nil

        Task {
            do {
                _ = try await challengeService.createChallenge(
                    type: selectedType,
                    title: challengeTitle,
                    description: nil,
                    targetValue: targetValue,
                    durationHours: durationHours,
                    stakes: stakes.isEmpty ? nil : stakes,
                    participantIds: selectedRecipients
                )

                // Success
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showSuccess = true

                // Dismiss after showing success
                try await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            } catch {
                self.error = error.localizedDescription
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }

            isSending = false
        }
    }
}

// MARK: - Challenge Type Selection Card

struct ChallengeTypeSelectionCard: View {
    let type: ChallengeType
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var glowPhase: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack {
                    if isSelected && !reduceMotion {
                        SwiftUI.Circle()
                            .fill(type.color.opacity(0.3 * glowPhase))
                            .frame(width: 60, height: 60)
                            .blur(radius: 10)
                    }

                    SwiftUI.Circle()
                        .fill(type.color.opacity(isSelected ? 0.3 : 0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: type.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(type.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text(type.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? type.color.opacity(0.1) : Color.white.opacity(0.03))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? type.color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1)
        .onAppear {
            guard !reduceMotion, isSelected else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
        .onChange(of: isSelected) { _, newValue in
            guard !reduceMotion, newValue else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }
}

// MARK: - Friend Selection Row

struct FriendSelectionRow: View {
    let friend: FriendProfile
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.nebulaDust)
                        .frame(width: 44, height: 44)

                    Text(friend.displayName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.displayName)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    if let streak = friend.currentStreak, streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(streak) day streak")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Theme.Colors.streakOrange)
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    SwiftUI.Circle()
                        .stroke(isSelected ? Theme.Colors.aiPurple : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.aiPurple)
                            .frame(width: 16, height: 16)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Theme.Colors.aiPurple.opacity(0.1) : Color.white.opacity(0.03))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Circle Selection Pill

struct CircleSelectionPill: View {
    let circle: SocialCircle

    var body: some View {
        HStack(spacing: 8) {
            // Circle avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Text(circle.name.prefix(2).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(circle.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("\(circle.memberCount) members")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05), in: Capsule())
    }
}

// MARK: - Duration Option

struct DurationOption: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starDim)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(isSelected ? color : Color.white.opacity(0.05))
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SendChallengeSheet()
}
