//
//  CreatePactSheet.swift
//  Veloce
//
//  Create Pact Sheet - Multi-step wizard to create a pact with a friend
//  Step 1: Select friend
//  Step 2: Choose commitment type
//  Step 3: Set target and confirm
//

import SwiftUI

// MARK: - Create Pact Sheet

struct CreatePactSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Step tracking
    @State private var currentStep = 0

    // Form state
    @State private var selectedFriend: FriendProfile?
    @State private var selectedType: PactCommitmentType = .dailyTasks
    @State private var targetValue: Int = 3
    @State private var customDescription: String = ""

    // UI state
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false

    // Services
    private let pactService = PactService.shared
    private let friendService = FriendService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.CelestialColors.void
                    .ignoresSafeArea()

                if showSuccess {
                    successView
                } else {
                    VStack(spacing: 0) {
                        // Progress indicator
                        progressIndicator
                            .padding(.top, 16)
                            .padding(.bottom, 24)

                        // Step content
                        TabView(selection: $currentStep) {
                            selectFriendStep
                                .tag(0)

                            selectTypeStep
                                .tag(1)

                            confirmStep
                                .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut, value: currentStep)
                    }
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                ToolbarItem(placement: .primaryAction) {
                    if !showSuccess {
                        nextButton
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { step in
                Capsule()
                    .fill(step <= currentStep ? Theme.Colors.aiPurple : .white.opacity(0.2))
                    .frame(height: 4)
                    .animation(.spring(), value: currentStep)
            }
        }
        .padding(.horizontal, 40)
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Select Friend"
        case 1: return "Choose Commitment"
        case 2: return "Confirm Pact"
        default: return "Create Pact"
        }
    }

    // MARK: - Step 1: Select Friend

    private var selectFriendStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.aiPurple)

                    Text("Who do you want to commit with?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Choose a friend to start your pact")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 20)

                // Friend list
                if friendService.friends.isEmpty {
                    emptyFriendsState
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(friendService.friends) { friendship in
                            if let friend = friendship.otherUser(currentUserId: getCurrentUserId()) {
                                FriendSelectRow(
                                    friend: friend,
                                    isSelected: selectedFriend?.id == friend.id,
                                    onSelect: {
                                        withAnimation(.spring()) {
                                            selectedFriend = friend
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
        }
        .task {
            try? await friendService.loadFriendships()
        }
    }

    private var emptyFriendsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))

            Text("No friends yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Text("Add some friends first to start a pact")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    // MARK: - Step 2: Select Type

    private var selectTypeStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.aiPurple)

                    Text("What will you commit to?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Both of you must complete this daily")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 20)

                // Type options
                VStack(spacing: 12) {
                    ForEach(PactCommitmentType.allCases, id: \.self) { type in
                        CommitmentTypeCard(
                            type: type,
                            isSelected: selectedType == type,
                            onSelect: {
                                withAnimation(.spring()) {
                                    selectedType = type
                                    targetValue = type.defaultTarget
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Step 3: Confirm

    private var confirmStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview
                pactPreview
                    .padding(.top, 20)

                // Target value slider
                targetSection

                // Custom description (for custom type)
                if selectedType == .custom {
                    customDescriptionSection
                }

                // Warning
                warningSection

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
    }

    private var pactPreview: some View {
        VStack(spacing: 16) {
            // Partner preview
            HStack(spacing: 16) {
                // You
                VStack(spacing: 4) {
                    Circle()
                        .fill(Theme.Colors.aiPurple)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("You")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        )

                    Text("You")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Connection
                VStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.aiPurple)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                }

                // Partner
                VStack(spacing: 4) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(selectedFriend?.displayName.prefix(2).uppercased() ?? "??")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        )

                    Text(selectedFriend?.displayName ?? "Partner")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }

            // Commitment summary
            VStack(spacing: 4) {
                Text(commitmentSummary)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Every day, together")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Target")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            HStack {
                Button {
                    if targetValue > 1 {
                        targetValue -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(targetValue > 1 ? Theme.Colors.aiPurple : .gray)
                }
                .disabled(targetValue <= 1)

                Spacer()

                VStack(spacing: 2) {
                    Text("\(targetValue)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text(selectedType.unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Button {
                    targetValue += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    private var customDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's your commitment?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            TextField("e.g., Read for 30 minutes", text: $customDescription)
                .textFieldStyle(.plain)
                .padding(14)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var warningSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.orange)

            Text("If either of you misses a day, **both** lose the streak. Choose wisely!")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var commitmentSummary: String {
        switch selectedType {
        case .dailyTasks:
            return "Complete \(targetValue) task\(targetValue == 1 ? "" : "s") every day"
        case .focusTime:
            return "Focus for \(targetValue) minutes every day"
        case .goalProgress:
            return "Make \(targetValue)% progress daily"
        case .custom:
            return customDescription.isEmpty ? "Custom commitment" : customDescription
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(Theme.Colors.completionMint.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Colors.completionMint)
                    .symbolEffect(.bounce)
            }

            VStack(spacing: 8) {
                Text("Pact Sent!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text("Waiting for \(selectedFriend?.displayName ?? "partner") to accept")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.aiPurple, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            if currentStep < 2 {
                withAnimation(.spring()) {
                    currentStep += 1
                }
            } else {
                createPact()
            }
        } label: {
            Text(currentStep < 2 ? "Next" : "Create Pact")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(canProceed ? Theme.Colors.aiPurple : .gray)
        }
        .disabled(!canProceed || isCreating)
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return selectedFriend != nil
        case 1: return true
        case 2: return selectedType != .custom || !customDescription.isEmpty
        default: return false
        }
    }

    // MARK: - Actions

    private func createPact() {
        guard let friend = selectedFriend else { return }

        isCreating = true

        Task {
            do {
                _ = try await pactService.createPact(
                    partnerId: friend.id,
                    commitmentType: selectedType,
                    targetValue: targetValue,
                    customDescription: selectedType == .custom ? customDescription : nil
                )

                await MainActor.run {
                    isCreating = false
                    withAnimation(.spring()) {
                        showSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func getCurrentUserId() -> UUID {
        SupabaseService.shared.currentUserId ?? UUID()
    }
}

// MARK: - Friend Select Row

struct FriendSelectRow: View {
    let friend: FriendProfile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(friend.displayName.prefix(2).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    if let username = friend.username {
                        Text("@\(username)")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Selection indicator
                Circle()
                    .stroke(isSelected ? Theme.Colors.aiPurple : .white.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(Theme.Colors.aiPurple)
                            .frame(width: 14, height: 14)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(12)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Theme.Colors.aiPurple.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Commitment Type Card

struct CommitmentTypeCard: View {
    let type: PactCommitmentType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.aiPurple : .white.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(typeDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
            .padding(14)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Theme.Colors.aiPurple.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var typeDescription: String {
        switch type {
        case .dailyTasks: return "Complete tasks together"
        case .focusTime: return "Focus for a set time"
        case .goalProgress: return "Progress on your goals"
        case .custom: return "Define your own commitment"
        }
    }
}

// MARK: - Preview

#Preview {
    CreatePactSheet()
}
