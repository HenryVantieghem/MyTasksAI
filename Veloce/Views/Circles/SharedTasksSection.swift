//
//  SharedTasksSection.swift
//  Veloce
//
//  Shared Tasks Section - Display incoming task invitations and active collaborations
//  Part of the Circles social feature
//

import SwiftUI

// MARK: - Shared Tasks Section

struct SharedTasksSection: View {
    @State private var sharedTaskService = SharedTaskService.shared
    @State private var isExpanded = true
    @State private var showAllIncoming = false
    @State private var respondingTo: UUID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hasContent: Bool {
        !sharedTaskService.incomingInvitations.isEmpty || !sharedTaskService.sharedWithMe.isEmpty
    }

    var body: some View {
        if hasContent {
            VStack(spacing: 0) {
                // Section Header
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.badge.plus.fill")
                                .dynamicTypeFont(base: 14, weight: .semibold)
                                .foregroundStyle(Theme.Colors.aiPurple)

                            Text("SHARED WITH YOU")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(Color.white.opacity(0.4))

                            if !sharedTaskService.incomingInvitations.isEmpty {
                                Text("\(sharedTaskService.incomingInvitations.count)")
                                    .dynamicTypeFont(base: 10, weight: .bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.CelestialColors.errorNebula))
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .dynamicTypeFont(base: 12, weight: .semibold)
                            .foregroundStyle(Color.white.opacity(0.3))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                if isExpanded {
                    VStack(spacing: 12) {
                        // Pending Invitations
                        if !sharedTaskService.incomingInvitations.isEmpty {
                            pendingInvitationsSection
                        }

                        // Active Collaborations
                        if !sharedTaskService.sharedWithMe.isEmpty {
                            activeCollaborationsSection
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .task {
                do {
                    try await sharedTaskService.loadSharedTasks()
                } catch {
                    print("Error loading shared tasks: \(error)")
                }
            }
        }
    }

    // MARK: - Pending Invitations

    private var pendingInvitationsSection: some View {
        VStack(spacing: 8) {
            ForEach(Array(sharedTaskService.incomingInvitations.prefix(showAllIncoming ? 10 : 3)), id: \.id) { invitation in
                SharedTaskInvitationCard(
                    invitation: invitation,
                    isResponding: respondingTo == invitation.id,
                    onAccept: {
                        respondToInvitation(invitation, accept: true)
                    },
                    onDecline: {
                        respondToInvitation(invitation, accept: false)
                    }
                )
            }

            // Show more button
            if sharedTaskService.incomingInvitations.count > 3 && !showAllIncoming {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showAllIncoming = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Show \(sharedTaskService.incomingInvitations.count - 3) more")
                            .dynamicTypeFont(base: 13, weight: .semibold)
                        Image(systemName: "chevron.down")
                            .dynamicTypeFont(base: 10, weight: .bold)
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.aiPurple.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Active Collaborations

    private var activeCollaborationsSection: some View {
        VStack(spacing: 8) {
            // Subsection header
            HStack {
                Text("Active")
                    .dynamicTypeFont(base: 11, weight: .semibold)
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                Spacer()
            }
            .padding(.horizontal, 20)

            ForEach(sharedTaskService.sharedWithMe.prefix(5), id: \.id) { sharedTask in
                ActiveSharedTaskCard(sharedTask: sharedTask)
            }
        }
    }

    // MARK: - Actions

    private func respondToInvitation(_ invitation: SharedTask, accept: Bool) {
        respondingTo = invitation.id

        Task {
            do {
                try await sharedTaskService.respondToInvitation(invitation.id, accept: accept)
                UINotificationFeedbackGenerator().notificationOccurred(accept ? .success : .warning)
            } catch {
                print("Error responding to invitation: \(error)")
            }
            respondingTo = nil
        }
    }
}

// MARK: - Shared Task Invitation Card

private struct SharedTaskInvitationCard: View {
    let invitation: SharedTask
    let isResponding: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    @State private var isPressed = false
    @State private var pulsePhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // Inviter avatar with pulse
            ZStack {
                // Notification pulse
                if !reduceMotion {
                    Circle()
                        .stroke(Theme.Colors.aiPurple.opacity(0.3 * (1 - pulsePhase)), lineWidth: 2)
                        .frame(width: 50 + (pulsePhase * 10))
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.Colors.aiPurple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(invitation.inviter?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    )
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.aiPurple.opacity(0.4), lineWidth: 1.5)
                    )
            }

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.task?.title ?? "Shared Task")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("from \(invitation.inviter?.displayName ?? "Friend")")
                        .dynamicTypeFont(base: 12, weight: .medium)
                        .foregroundStyle(.white.opacity(0.5))

                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))

                    Text(invitation.timeSinceInvited)
                        .dynamicTypeFont(base: 11, weight: .medium)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            // Action buttons
            if isResponding {
                ProgressView()
                    .tint(Theme.Colors.aiPurple)
            } else {
                HStack(spacing: 8) {
                    // Decline
                    Button(action: onDecline) {
                        Image(systemName: "xmark")
                            .dynamicTypeFont(base: 12, weight: .bold)
                            .foregroundStyle(Theme.CelestialColors.errorNebula)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Theme.CelestialColors.errorNebula.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)

                    // Accept
                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                            .dynamicTypeFont(base: 12, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Theme.CelestialColors.auroraGreen)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.aiPurple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulsePhase = 1
            }
        }
    }
}

// MARK: - Active Shared Task Card

private struct ActiveSharedTaskCard: View {
    let sharedTask: SharedTask

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            // Task status indicator
            ZStack {
                Circle()
                    .fill(sharedTask.task?.isCompleted == true
                          ? Theme.CelestialColors.auroraGreen.opacity(0.2)
                          : Theme.Colors.aiPurple.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: sharedTask.task?.isCompleted == true
                      ? "checkmark.circle.fill"
                      : sharedTask.task?.displayIcon ?? "doc.fill")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(sharedTask.task?.isCompleted == true
                                    ? Theme.CelestialColors.auroraGreen
                                    : Theme.Colors.aiPurple)
            }

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(sharedTask.task?.title ?? "Shared Task")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(sharedTask.task?.isCompleted == true
                                    ? .white.opacity(0.5)
                                    : .white)
                    .strikethrough(sharedTask.task?.isCompleted == true)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    // Inviter
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .dynamicTypeFont(base: 9)
                        Text(sharedTask.inviter?.displayName ?? "Friend")
                            .dynamicTypeFont(base: 11, weight: .medium)
                    }
                    .foregroundStyle(.white.opacity(0.4))

                    // Priority stars
                    if let stars = sharedTask.task?.starRating, stars > 0 {
                        Text(String(repeating: "★", count: stars))
                            .dynamicTypeFont(base: 10)
                            .foregroundStyle(Theme.Colors.warning)
                    }

                    // Time estimate
                    if let time = sharedTask.task?.estimatedTimeFormatted {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .dynamicTypeFont(base: 9)
                            Text(time)
                                .dynamicTypeFont(base: 10, weight: .medium)
                        }
                        .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            // Completion status
            if sharedTask.task?.isCompleted == true {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .dynamicTypeFont(base: 10, weight: .bold)
                    Text("Done")
                        .dynamicTypeFont(base: 11, weight: .semibold)
                }
                .foregroundStyle(Theme.CelestialColors.auroraGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Theme.CelestialColors.auroraGreen.opacity(0.15))
                )
            } else {
                // Arrow to navigate
                Image(systemName: "chevron.right")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                SharedTasksSection()
            }
            .padding(.top, 40)
        }
    }
    .preferredColorScheme(.dark)
}
