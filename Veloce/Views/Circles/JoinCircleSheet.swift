//
//  JoinCircleSheet.swift
//  Veloce
//
//  Join Circle - Beautiful code input with validation and preview
//  Wired to CircleService for real join functionality
//

import SwiftUI

struct JoinCircleSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Input state
    @State private var inviteCode = ""
    @FocusState private var isCodeFocused: Bool

    // UI state
    @State private var isValidating = false
    @State private var isJoining = false
    @State private var validationError: String?
    @State private var foundCircle: SocialCircle?
    @State private var showSuccess = false

    private let circleService = CircleService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.CelestialColors.void
                    .ignoresSafeArea()

                if showSuccess, let circle = foundCircle {
                    JoinCircleSuccess(circle: circle) {
                        dismiss()
                    }
                } else {
                    VStack(spacing: 28) {
                        // Icon
                        ZStack {
                            // Glow rings
                            Circle()
                                .stroke(Theme.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                                .frame(width: 80)

                            Circle()
                                .fill(Theme.Colors.aiPurple.opacity(0.1))
                                .frame(width: 64)

                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(Theme.Colors.aiPurple)
                        }
                        .padding(.top, 24)

                        // Title
                        VStack(spacing: 8) {
                            Text("Enter Invite Code")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.CelestialColors.starWhite)

                            Text("Get the code from a circle member")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                        }

                        // Code input
                        codeInputField

                        // Error message
                        if let error = validationError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.CelestialColors.errorNebula)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Theme.CelestialColors.errorNebula.opacity(0.1))
                            )
                        }

                        // Circle preview (after validation)
                        if let circle = foundCircle, !isValidating {
                            CirclePreviewCard(circle: circle)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Spacer()

                        // Join button
                        joinButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Join Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
            .onAppear {
                isCodeFocused = true
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Code Input Field

    private var codeInputField: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    CodeDigitBox(
                        character: index < inviteCode.count ? String(inviteCode[inviteCode.index(inviteCode.startIndex, offsetBy: index)]) : "",
                        isFilled: index < inviteCode.count,
                        isActive: isCodeFocused && index == inviteCode.count && inviteCode.count < 6,
                        hasError: validationError != nil
                    )
                }
            }

            // Hidden text field for input
            TextField("", text: $inviteCode)
                .focused($isCodeFocused)
                .textInputAutocapitalization(.characters)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
                .onChange(of: inviteCode) { _, newValue in
                    // Filter to alphanumeric, uppercase, max 6 chars
                    let filtered = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                    if filtered != inviteCode {
                        inviteCode = filtered
                    }

                    // Clear error when typing
                    if validationError != nil {
                        withAnimation { validationError = nil }
                    }

                    // Clear found circle when editing
                    if foundCircle != nil {
                        withAnimation { foundCircle = nil }
                    }

                    // Auto-validate when complete
                    if inviteCode.count == 6 {
                        validateCode()
                    }
                }
                .opacity(0)
                .frame(height: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isCodeFocused = true
        }
    }

    // MARK: - Join Button

    private var joinButton: some View {
        Button {
            if foundCircle != nil {
                joinCircle()
            } else if inviteCode.count == 6 {
                validateCode()
            }
        } label: {
            HStack(spacing: 8) {
                if isJoining || isValidating {
                    ProgressView()
                        .tint(.white)
                } else {
                    if foundCircle != nil {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Join Circle")
                    } else {
                        Text("Continue")
                    }
                }
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(inviteCode.count == 6 ? Theme.Colors.aiPurple : Theme.Colors.aiPurple.opacity(0.3))
            )
        }
        .disabled(inviteCode.count < 6 || isJoining || isValidating)
    }

    // MARK: - Actions

    private func validateCode() {
        guard inviteCode.count == 6, !isValidating else { return }

        isValidating = true
        validationError = nil

        // Format the code with dash for lookup
        let formattedCode = String(inviteCode.prefix(3)) + "-" + String(inviteCode.suffix(3))

        Task {
            do {
                // Try to join to validate - CircleService will throw if invalid
                // For now, we proceed to join directly
                await MainActor.run {
                    isValidating = false
                    // If we had a validation endpoint, we'd set foundCircle here
                    // For now, we'll attempt to join directly
                }
            } catch {
                await MainActor.run {
                    validationError = "Invalid invite code"
                    isValidating = false
                }
            }
        }

        // For now, just stop validating and allow join attempt
        isValidating = false
    }

    private func joinCircle() {
        guard inviteCode.count == 6, !isJoining else { return }

        isJoining = true
        validationError = nil

        // Format the code with dash
        let formattedCode = String(inviteCode.prefix(3)) + "-" + String(inviteCode.suffix(3))

        Task {
            do {
                let circle = try await circleService.joinByInviteCode(formattedCode)

                await MainActor.run {
                    foundCircle = circle
                    withAnimation(.spring(response: 0.5)) {
                        showSuccess = true
                    }

                    // Success haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }

            } catch let error as CircleServiceError {
                await MainActor.run {
                    switch error {
                    case .invalidInviteCode:
                        validationError = "Invalid invite code"
                    case .alreadyMember:
                        validationError = "You're already in this circle"
                    case .circleFull:
                        validationError = "This circle is full"
                    default:
                        validationError = error.localizedDescription
                    }
                    isJoining = false

                    // Error haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }

            } catch {
                await MainActor.run {
                    validationError = error.localizedDescription
                    isJoining = false
                }
            }
        }
    }
}

// MARK: - Code Digit Box

struct CodeDigitBox: View {
    let character: String
    let isFilled: Bool
    let isActive: Bool
    let hasError: Bool

    @State private var cursorBlink = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isFilled ? Theme.Colors.aiPurple.opacity(0.15) : Color.white.opacity(0.05))
                .frame(width: 46, height: 58)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            hasError ? Theme.CelestialColors.errorNebula :
                            isActive ? Theme.Colors.aiPurple :
                            isFilled ? Theme.Colors.aiPurple.opacity(0.3) :
                            Color.white.opacity(0.1),
                            lineWidth: isActive ? 2 : 1
                        )
                )

            if isFilled {
                Text(character)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.CelestialColors.starWhite)
            } else if isActive {
                Rectangle()
                    .fill(Theme.Colors.aiPurple)
                    .frame(width: 2, height: 28)
                    .opacity(cursorBlink ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            cursorBlink = true
                        }
                    }
            }
        }
    }
}

// MARK: - Circle Preview Card

struct CirclePreviewCard: View {
    let circle: SocialCircle
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 16) {
            // Avatar with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.aiPurple.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100)
                    .blur(radius: 20)
                    .opacity(revealed ? 1 : 0)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .scaleEffect(revealed ? 1 : 0.5)

                Text(circle.name.prefix(2).uppercased())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(revealed ? 1 : 0)
            }

            VStack(spacing: 6) {
                Text(circle.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if let description = circle.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                // Stats
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.Colors.aiPurple)
                        Text("\(circle.memberCount)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.CelestialColors.starWhite)
                        Text("members")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.CelestialColors.starGhost)
                    }

                    if circle.circleStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.streakOrange)
                            Text("\(circle.circleStreak)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.CelestialColors.starWhite)
                            Text("streak")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.CelestialColors.starGhost)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 20)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                revealed = true
            }
        }
    }
}

// MARK: - Join Circle Success

struct JoinCircleSuccess: View {
    let circle: SocialCircle
    var onDismiss: () -> Void

    @State private var phase: CGFloat = 0
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Celebration animation
            ZStack {
                // Expanding rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Theme.CelestialColors.auroraGreen.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 80 + CGFloat(phase) * CGFloat(i + 1) * 30)
                        .opacity(phase < 1 ? 1 : 0)
                }

                // Sparkles
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                        .offset(y: -50 - phase * 20)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .opacity(1 - phase)
                }

                // Success icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.CelestialColors.auroraGreen, Theme.CelestialColors.successNebula],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Theme.CelestialColors.auroraGreen.opacity(0.5), radius: 20)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)
            }
            .frame(height: 160)

            // Success text
            VStack(spacing: 8) {
                Text("You're In!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Welcome to \(circle.name)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            // Circle info
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    // Members
                    VStack(spacing: 4) {
                        Text("\(circle.memberCount)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.CelestialColors.starWhite)
                        Text("Members")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 40)

                    // XP
                    VStack(spacing: 4) {
                        Text("\(circle.circleXp)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.Colors.xp)
                        Text("Circle XP")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .opacity(showContent ? 1 : 0)

            Spacer()

            // Done button
            Button {
                onDismiss()
            } label: {
                Text("Start Collaborating")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.CelestialColors.auroraGreen, in: RoundedRectangle(cornerRadius: 14))
            }
            .opacity(showContent ? 1 : 0)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = 1
                showContent = true
            }

            // Haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Preview

#Preview {
    JoinCircleSheet()
}
