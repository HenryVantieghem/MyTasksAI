//
//  FriendRequestsView.swift
//  Veloce
//
//  Friend Requests Management - Accept/Decline with Style
//  Design: Celestial theme with orbital animations, swipe gestures, celebration effects
//

import SwiftUI

// MARK: - Request Segment

enum RequestSegment: String, CaseIterable, Identifiable {
    case incoming = "Incoming"
    case sent = "Sent"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .incoming: return "arrow.down.circle.fill"
        case .sent: return "arrow.up.circle.fill"
        }
    }

    var emptyTitle: String {
        switch self {
        case .incoming: return "No Incoming Requests"
        case .sent: return "No Sent Requests"
        }
    }

    var emptySubtitle: String {
        switch self {
        case .incoming: return "When someone sends you a friend request,\nit will appear here"
        case .sent: return "Friend requests you've sent\nwill appear here"
        }
    }

    var emptyIcon: String {
        switch self {
        case .incoming: return "person.crop.circle.badge.plus"
        case .sent: return "paperplane.circle"
        }
    }
}

// MARK: - Friend Requests View

struct FriendRequestsView: View {
    @State private var friendService = FriendService.shared
    @State private var selectedSegment: RequestSegment = .incoming
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    // Celebration state
    @State private var celebratingFriendName: String?
    @State private var showCelebration = false

    // Animation states
    @State private var orbitPhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background
            Theme.CelestialColors.void
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Segment selector
                segmentSelector
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Content
                Group {
                    if isLoading && currentRequests.isEmpty {
                        loadingView
                    } else if currentRequests.isEmpty {
                        emptyStateView
                    } else {
                        requestsList
                    }
                }
            }

            // Celebration overlay
            if showCelebration, let name = celebratingFriendName {
                CelebrationOverlay(friendName: name, isActive: $showCelebration)
            }
        }
        .navigationTitle("Friend Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRequests()
            startAnimations()
        }
        .refreshable {
            await loadRequests()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "Something went wrong")
        }
    }

    // MARK: - Computed Properties

    private var currentRequests: [Friendship] {
        switch selectedSegment {
        case .incoming: return friendService.pendingRequests
        case .sent: return friendService.sentRequests
        }
    }

    // MARK: - Segment Selector

    private var segmentSelector: some View {
        HStack(spacing: 4) {
            ForEach(RequestSegment.allCases) { segment in
                segmentButton(for: segment)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private func segmentButton(for segment: RequestSegment) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedSegment = segment
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: segment.icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(segment.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                // Badge count
                if segment == .incoming && friendService.pendingCount > 0 {
                    Text("\(friendService.pendingCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.CelestialColors.errorNebula, in: Capsule())
                }
            }
            .foregroundStyle(selectedSegment == segment ? .white : Theme.CelestialColors.starDim)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if selectedSegment == segment {
                    Capsule()
                        .fill(Theme.Colors.aiPurple)
                        .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 8, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()

            ProgressView()
                .tint(Theme.Colors.aiPurple)
                .scaleEffect(1.5)

            Text("Loading requests...")
                .font(.system(size: 14))
                .foregroundStyle(Theme.CelestialColors.starDim)

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Animated orbital icon
            ZStack {
                // Orbital rings
                if !reduceMotion {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Theme.Colors.aiPurple.opacity(0.1 + Double(i) * 0.05), lineWidth: 1)
                            .frame(width: 80 + CGFloat(i) * 30)
                            .rotationEffect(.degrees(orbitPhase * (i % 2 == 0 ? 1 : -1) * 360))
                    }
                }

                Image(systemName: selectedSegment.emptyIcon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
            .frame(height: 160)

            Text(selectedSegment.emptyTitle)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Text(selectedSegment.emptySubtitle)
                .font(.system(size: 14))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .multilineTextAlignment(.center)

            // CTA for sent tab
            if selectedSegment == .sent {
                NavigationLink {
                    // Navigate to add friend
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                        Text("Add a Friend")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.aiPurple, in: Capsule())
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Requests List

    private var requestsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(currentRequests) { request in
                    switch selectedSegment {
                    case .incoming:
                        if let requester = request.requester {
                            IncomingRequestCard(
                                friendship: request,
                                profile: requester,
                                onAccept: {
                                    await acceptRequest(request, name: requester.displayName)
                                },
                                onDecline: {
                                    await declineRequest(request)
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }

                    case .sent:
                        if let addressee = request.addressee {
                            SentRequestCard(
                                friendship: request,
                                profile: addressee,
                                onCancel: {
                                    await cancelRequest(request)
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Actions

    private func loadRequests() async {
        isLoading = true
        do {
            try await friendService.loadFriendships()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    private func acceptRequest(_ request: Friendship, name: String) async {
        do {
            try await friendService.respondToRequest(request.id, accept: true)

            // Show celebration
            celebratingFriendName = name
            withAnimation(.spring(response: 0.4)) {
                showCelebration = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func declineRequest(_ request: Friendship) async {
        do {
            try await friendService.respondToRequest(request.id, accept: false)

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func cancelRequest(_ request: Friendship) async {
        do {
            try await friendService.cancelRequest(request.id)

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            orbitPhase = 1
        }
    }
}

// MARK: - Incoming Request Card

struct IncomingRequestCard: View {
    let friendship: Friendship
    let profile: FriendProfile
    var onAccept: () async -> Void
    var onDecline: () async -> Void

    @State private var isResponding = false
    @State private var swipeOffset: CGFloat = 0
    @State private var avatarGlow: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            // Swipe action backgrounds
            HStack {
                // Accept (right swipe)
                ZStack {
                    Theme.CelestialColors.auroraGreen.opacity(0.3)
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                }
                .frame(width: 80)
                .opacity(swipeOffset > 20 ? min(swipeOffset / swipeThreshold, 1) : 0)

                Spacer()

                // Decline (left swipe)
                ZStack {
                    Theme.CelestialColors.errorNebula.opacity(0.3)
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.CelestialColors.errorNebula)
                }
                .frame(width: 80)
                .opacity(swipeOffset < -20 ? min(abs(swipeOffset) / swipeThreshold, 1) : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Main card content
            HStack(spacing: 14) {
                // Avatar with orbital glow
                ZStack {
                    // Glow rings
                    if !reduceMotion {
                        Circle()
                            .stroke(Theme.CelestialColors.plasmaCore.opacity(0.2 * avatarGlow), lineWidth: 2)
                            .frame(width: 60, height: 60)
                            .scaleEffect(1 + avatarGlow * 0.05)
                    }

                    // Avatar circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    // Initials
                    Text(profile.displayName.prefix(1).uppercased())
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    if let username = profile.atUsername {
                        Text(username)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }

                    // Stats preview
                    HStack(spacing: 12) {
                        if let streak = profile.currentStreak, streak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.Colors.streakOrange)
                                Text("\(streak)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Theme.CelestialColors.starDim)
                            }
                        }

                        if let level = profile.currentLevel {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.Colors.xp)
                                Text("Lv \(level)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Theme.CelestialColors.starDim)
                            }
                        }
                    }
                }

                Spacer()

                // Action buttons
                if !isResponding {
                    HStack(spacing: 10) {
                        // Decline
                        Button {
                            respondToRequest(accept: false)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }

                        // Accept
                        Button {
                            respondToRequest(accept: true)
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Theme.CelestialColors.auroraGreen, Theme.CelestialColors.successNebula],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Theme.CelestialColors.auroraGreen.opacity(0.4), radius: 8, y: 2)
                                )
                        }
                    }
                } else {
                    ProgressView()
                        .tint(Theme.Colors.aiPurple)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.CelestialColors.plasmaCore.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .offset(x: swipeOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        swipeOffset = value.translation.width
                    }
                    .onEnded { value in
                        if value.translation.width > swipeThreshold {
                            // Swipe right - accept
                            withAnimation(.easeOut(duration: 0.3)) {
                                swipeOffset = 400
                            }
                            respondToRequest(accept: true)
                        } else if value.translation.width < -swipeThreshold {
                            // Swipe left - decline
                            withAnimation(.easeOut(duration: 0.3)) {
                                swipeOffset = -400
                            }
                            respondToRequest(accept: false)
                        } else {
                            // Spring back
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                swipeOffset = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    avatarGlow = 1
                }
            }
        }
    }

    private func respondToRequest(accept: Bool) {
        guard !isResponding else { return }
        isResponding = true

        Task {
            if accept {
                await onAccept()
            } else {
                await onDecline()
            }
            isResponding = false
        }
    }
}

// MARK: - Sent Request Card

struct SentRequestCard: View {
    let friendship: Friendship
    let profile: FriendProfile
    var onCancel: () async -> Void

    @State private var isCancelling = false
    @State private var pulsePhase: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 14) {
            // Avatar (dimmed for pending)
            ZStack {
                // Pulsing ring for pending
                if !reduceMotion {
                    Circle()
                        .stroke(Theme.CelestialColors.starGhost, lineWidth: 1)
                        .frame(width: 58, height: 58)
                        .scaleEffect(0.95 + pulsePhase * 0.1)
                        .opacity(0.5 + pulsePhase * 0.3)
                }

                // Avatar circle
                Circle()
                    .fill(Theme.CelestialColors.nebulaDust)
                    .frame(width: 52, height: 52)

                Text(profile.displayName.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite.opacity(0.8))

                if let username = profile.atUsername {
                    Text(username)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }

                // Pending badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.CelestialColors.warningNebula)
                        .frame(width: 6, height: 6)
                    Text("Pending")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }

            Spacer()

            // Cancel button
            if !isCancelling {
                Button {
                    cancelRequest()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.errorNebula)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Theme.CelestialColors.errorNebula.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Theme.CelestialColors.errorNebula.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            } else {
                ProgressView()
                    .tint(Theme.CelestialColors.errorNebula)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulsePhase = 1
                }
            }
        }
    }

    private func cancelRequest() {
        guard !isCancelling else { return }
        isCancelling = true

        Task {
            await onCancel()
            isCancelling = false
        }
    }
}

// MARK: - Celebration Overlay

struct CelebrationOverlay: View {
    let friendName: String
    @Binding var isActive: Bool

    @State private var phase: CGFloat = 0
    @State private var showContent = false
    @State private var confettiActive = false

    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 24) {
                // Celebration icon with burst
                ZStack {
                    // Expanding rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Theme.CelestialColors.auroraGreen.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                            .frame(width: 80 + CGFloat(phase) * CGFloat(i + 1) * 40)
                            .opacity(phase < 1 ? 1 : 0)
                    }

                    // Sparkles
                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.auroraGreen)
                            .offset(y: -60 - phase * 20)
                            .rotationEffect(.degrees(Double(i) * 45))
                            .opacity(1 - phase)
                    }

                    // Main icon
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

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)
                }

                VStack(spacing: 8) {
                    Text("You're Now Friends!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("with \(friendName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Theme.CelestialColors.auroraGreen, in: Capsule())
                }
                .opacity(showContent ? 1 : 0)
                .padding(.top, 8)
            }
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = 1
                showContent = true
            }

            // Haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isActive = false
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FriendRequestsView()
    }
    .preferredColorScheme(.dark)
}
