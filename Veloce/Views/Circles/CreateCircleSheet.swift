//
//  CreateCircleSheet.swift
//  Veloce
//
//  Create Circle - Beautiful wizard with icon/color pickers
//  Wired to CircleService for real circle creation
//

import SwiftUI

// MARK: - Circle Icon Options

enum CircleIcon: String, CaseIterable, Identifiable {
    case hexagon = "circle.hexagongrid.fill"
    case rocket = "paperplane.fill"
    case star = "star.fill"
    case flame = "flame.fill"
    case trophy = "trophy.fill"
    case target = "target"
    case book = "book.fill"
    case code = "chevron.left.forwardslash.chevron.right"
    case music = "music.note"
    case heart = "heart.fill"

    var id: String { rawValue }
}

// MARK: - Circle Color Options

enum CircleColor: String, CaseIterable, Identifiable {
    case purple
    case blue
    case cyan
    case green
    case orange
    case pink

    var id: String { rawValue }

    var value: Color {
        switch self {
        case .purple: return Theme.Colors.aiPurple
        case .blue: return Color(red: 0.30, green: 0.55, blue: 0.98)
        case .cyan: return Theme.CelestialColors.plasmaCore
        case .green: return Theme.CelestialColors.auroraGreen
        case .orange: return Theme.CelestialColors.solarFlare
        case .pink: return Color(red: 0.98, green: 0.45, blue: 0.65)
        }
    }
}

// MARK: - Create Circle Sheet

struct CreateCircleSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var circleName = ""
    @State private var circleDescription = ""
    @State private var selectedIcon: CircleIcon = .hexagon
    @State private var selectedColor: CircleColor = .purple
    @State private var maxMembers: Int = 5

    // UI state
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var createdCircle: SocialCircle?

    // Animation
    @State private var pulsePhase: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let circleService = CircleService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.CelestialColors.void
                    .ignoresSafeArea()

                if showSuccess, let circle = createdCircle {
                    CircleCreatedSuccess(circle: circle) {
                        dismiss()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 28) {
                            // Live preview
                            circlePreview
                                .padding(.top, 20)

                            // Circle name
                            nameSection

                            // Description
                            descriptionSection

                            // Icon picker
                            iconPickerSection

                            // Color picker
                            colorPickerSection

                            // Max members
                            memberLimitSection

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Create Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                ToolbarItem(placement: .primaryAction) {
                    if !showSuccess {
                        createButton
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
            .onAppear {
                startAnimations()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Circle Preview

    private var circlePreview: some View {
        ZStack {
            // Outer glow rings
            if !reduceMotion {
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .stroke(selectedColor.value.opacity(0.1 + Double(i) * 0.05), lineWidth: 1)
                        .frame(width: 100 + CGFloat(i) * 20)
                        .scaleEffect(1 + pulsePhase * 0.02)
                }
            }

            // Main circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [selectedColor.value, selectedColor.value.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: selectedColor.value.opacity(0.4), radius: 16)

            // Icon or initials
            if circleName.isEmpty {
                Image(systemName: selectedIcon.rawValue)
                    .dynamicTypeFont(base: 28, weight: .medium)
                    .foregroundStyle(.white)
            } else {
                Text(circleName.prefix(2).uppercased())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 140)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Circle Name")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starDim)

            TextField("e.g., Morning Warriors", text: $circleName)
                .dynamicTypeFont(base: 16)
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .tint(selectedColor.value)
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Description (optional)")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starDim)

            TextField("What's this circle about?", text: $circleDescription, axis: .vertical)
                .dynamicTypeFont(base: 16)
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .lineLimit(3...5)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .tint(selectedColor.value)
        }
    }

    // MARK: - Icon Picker

    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circle Icon")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starDim)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(CircleIcon.allCases) { icon in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedIcon = icon
                        }
                        hapticFeedback()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? selectedColor.value.opacity(0.2) : Color.white.opacity(0.05))
                                .frame(width: 50, height: 50)

                            Image(systemName: icon.rawValue)
                                .dynamicTypeFont(base: 18)
                                .foregroundStyle(selectedIcon == icon ? selectedColor.value : Theme.CelestialColors.starDim)

                            if selectedIcon == icon {
                                Circle()
                                    .stroke(selectedColor.value, lineWidth: 2)
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Color Picker

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circle Color")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starDim)

            HStack(spacing: 16) {
                ForEach(CircleColor.allCases) { color in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedColor = color
                        }
                        hapticFeedback()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.value)
                                .frame(width: 38, height: 38)
                                .shadow(color: color.value.opacity(selectedColor == color ? 0.5 : 0), radius: selectedColor == color ? 8 : 0)

                            if selectedColor == color {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .frame(width: 38, height: 38)

                                Image(systemName: "checkmark")
                                    .dynamicTypeFont(base: 14, weight: .bold)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Member Limit

    private var memberLimitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Maximum Members")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starDim)

            HStack(spacing: 12) {
                ForEach([3, 5, 10, 20], id: \.self) { limit in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            maxMembers = limit
                        }
                        hapticFeedback()
                    } label: {
                        Text("\(limit)")
                            .dynamicTypeFont(base: 15, weight: .semibold)
                            .foregroundStyle(maxMembers == limit ? .white : Theme.CelestialColors.starDim)
                            .frame(width: 50, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(maxMembers == limit ? selectedColor.value : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(maxMembers == limit ? selectedColor.value : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            createCircle()
        } label: {
            if isCreating {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Create")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)
            }
        }
        .disabled(circleName.isEmpty || isCreating)
        .opacity(circleName.isEmpty ? 0.5 : 1.0)
    }

    // MARK: - Actions

    private func createCircle() {
        guard !circleName.isEmpty, !isCreating else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                let circle = try await circleService.createCircle(
                    name: circleName,
                    description: circleDescription.isEmpty ? nil : circleDescription,
                    maxMembers: maxMembers
                )

                await MainActor.run {
                    createdCircle = circle
                    withAnimation(.spring(response: 0.5)) {
                        showSuccess = true
                    }

                    // Success haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }

            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                }
            }
        }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }
    }

    private func hapticFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Circle Created Success

struct CircleCreatedSuccess: View {
    let circle: SocialCircle
    var onDismiss: () -> Void

    @State private var phase: CGFloat = 0
    @State private var showInviteCode = false
    @State private var copied = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Celebration animation
            ZStack {
                // Expanding rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Theme.Colors.aiPurple.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 80 + CGFloat(phase) * CGFloat(i + 1) * 30)
                        .opacity(phase < 1 ? 1 : 0)
                }

                // Sparkles
                ForEach(0..<12, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(Theme.Colors.aiPurple)
                        .offset(y: -50 - phase * 30)
                        .rotationEffect(.degrees(Double(i) * 30))
                        .opacity(1 - phase)
                }

                // Circle avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 20)
                    .scaleEffect(phase > 0 ? 1 : 0.5)
                    .opacity(phase > 0 ? 1 : 0)

                Text(circle.name.prefix(2).uppercased())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(phase > 0 ? 1 : 0.5)
                    .opacity(phase > 0 ? 1 : 0)
            }
            .frame(height: 160)

            // Success text
            VStack(spacing: 8) {
                Text("Circle Created!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text(circle.name)
                    .dynamicTypeFont(base: 18, weight: .medium)
                    .foregroundStyle(Theme.Colors.aiPurple)
            }
            .opacity(phase > 0.3 ? 1 : 0)
            .offset(y: phase > 0.3 ? 0 : 20)

            // Invite code card
            if showInviteCode {
                VStack(spacing: 16) {
                    Text("Your Invite Code")
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Text(circle.formattedInviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.aiPurple)
                        .tracking(4)

                    Button {
                        UIPasteboard.general.string = circle.formattedInviteCode
                        withAnimation(.spring(response: 0.3)) {
                            copied = true
                        }

                        // Haptic
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)

                        // Reset after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy Code")
                        }
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(copied ? Theme.CelestialColors.auroraGreen : Theme.Colors.aiPurple, in: Capsule())
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Done button
            Button {
                onDismiss()
            } label: {
                Text("Start Inviting Friends")
                    .dynamicTypeFont(base: 17, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.aiPurple, in: RoundedRectangle(cornerRadius: 14))
            }
            .opacity(phase > 0.5 ? 1 : 0)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4)) {
                    showInviteCode = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreateCircleSheet()
}
