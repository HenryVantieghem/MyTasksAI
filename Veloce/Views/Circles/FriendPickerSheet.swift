//
//  FriendPickerSheet.swift
//  Veloce
//
//  Friend Picker for Task Sharing
//  Allows selecting friends to invite to collaborate on a task
//

import SwiftUI

// MARK: - Friend Picker Sheet

struct FriendPickerSheet: View {
    // MARK: Properties
    let taskId: UUID
    let taskTitle: String
    let onInvite: ([UUID]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var friendService = FriendService.shared
    @State private var sharedTaskService = SharedTaskService.shared
    @State private var selectedFriends: Set<UUID> = []
    @State private var isLoading = false
    @State private var isSending = false
    @State private var error: String?
    @State private var alreadySharedWith: Set<UUID> = []
    @State private var showSuccess = false
    @State private var searchText = ""

    // MARK: Computed
    private var filteredFriends: [Friendship] {
        guard !searchText.isEmpty else { return friendService.friends }
        let search = searchText.lowercased()
        return friendService.friends.filter { friendship in
            let friend = friendship.otherUser(currentUserId: currentUserId)
            return friend?.displayName.lowercased().contains(search) == true ||
                   friend?.username?.lowercased().contains(search) == true
        }
    }

    private var currentUserId: UUID {
        UUID() // Will be replaced by actual user ID check
    }

    // MARK: Body
    var body: some View {
        ZStack {
            // Background
            Theme.CelestialColors.void
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                if isLoading {
                    loadingState
                } else if friendService.friends.isEmpty {
                    emptyState
                } else {
                    // Search
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Friend Grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredFriends) { friendship in
                                if let friend = friendship.otherUser(currentUserId: currentUserId) {
                                    FriendGridItem(
                                        friend: friend,
                                        isSelected: selectedFriends.contains(friend.id),
                                        isAlreadyShared: alreadySharedWith.contains(friend.id)
                                    ) {
                                        toggleSelection(friend.id)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }

                    // Bottom Action
                    if !selectedFriends.isEmpty {
                        inviteButton
                    }
                }
            }

            // Success Overlay
            if showSuccess {
                InviteSentOverlay {
                    showSuccess = false
                    dismiss()
                }
            }
        }
        .task {
            await loadData()
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 16) {
            // Drag Indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Title Section
            VStack(spacing: 8) {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.CelestialColors.nebulaGradient)

                Text("Invite Friends")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Share \"\(taskTitle)\" with friends")
                    .font(.subheadline)
                    .foregroundColor(Theme.CelestialColors.starDim)
                    .lineLimit(1)
                    .padding(.horizontal, 40)
            }

            // Selected Count
            if !selectedFriends.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.CelestialColors.auroraGreen)
                    Text("\(selectedFriends.count) friend\(selectedFriends.count == 1 ? "" : "s") selected")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.CelestialColors.auroraGreen)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Theme.CelestialColors.auroraGreen.opacity(0.15))
                .cornerRadius(20)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.CelestialColors.starDim)

            TextField("Search friends...", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.CelestialColors.starDim)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.5))
        .background(Theme.CelestialColors.abyss)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.CelestialColors.nebulaCore.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .tint(Theme.Colors.aiPurple)
                .scaleEffect(1.2)
            Text("Loading friends...")
                .font(.subheadline)
                .foregroundColor(Theme.CelestialColors.starDim)
            Spacer()
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(Theme.CelestialColors.nebulaGradient)

            VStack(spacing: 8) {
                Text("No Friends Yet")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Add friends to share tasks and compete together")
                    .font(.subheadline)
                    .foregroundColor(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                dismiss()
            } label: {
                Text("Go to Friends")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.CelestialColors.nebulaGradient)
                    .cornerRadius(12)
            }

            Spacer()
        }
    }

    // MARK: - Invite Button
    private var inviteButton: some View {
        Button {
            Task {
                await sendInvitations()
            }
        } label: {
            HStack(spacing: 10) {
                if isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Invite \(selectedFriends.count) Friend\(selectedFriends.count == 1 ? "" : "s")")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.aiPurple, Theme.CelestialColors.nebulaGlow],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 6)
        }
        .disabled(isSending)
        .padding(20)
        .background(
            Rectangle()
                .fill(Theme.CelestialColors.void)
                .shadow(color: .black.opacity(0.5), radius: 20, y: -10)
        )
    }

    // MARK: - Methods

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await friendService.loadFriendships()
            try await loadAlreadyShared()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadAlreadyShared() async throws {
        // Check which friends already have this task shared with them
        var shared = Set<UUID>()
        for friendship in friendService.friends {
            if let friend = friendship.otherUser(currentUserId: currentUserId) {
                let isShared = try await sharedTaskService.isTaskSharedWith(
                    taskId: taskId,
                    friendId: friend.id
                )
                if isShared {
                    shared.insert(friend.id)
                }
            }
        }
        alreadySharedWith = shared
    }

    private func toggleSelection(_ friendId: UUID) {
        if alreadySharedWith.contains(friendId) {
            return // Can't select already shared
        }

        if selectedFriends.contains(friendId) {
            selectedFriends.remove(friendId)
        } else {
            selectedFriends.insert(friendId)
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func sendInvitations() async {
        isSending = true
        defer { isSending = false }

        var successCount = 0
        for friendId in selectedFriends {
            do {
                try await sharedTaskService.inviteFriendToTask(taskId: taskId, friendId: friendId)
                successCount += 1
            } catch {
                print("Failed to invite \(friendId): \(error)")
            }
        }

        if successCount > 0 {
            onInvite(Array(selectedFriends))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showSuccess = true
        } else {
            self.error = "Failed to send invitations"
        }
    }
}

// MARK: - Friend Grid Item

private struct FriendGridItem: View {
    let friend: FriendProfile
    let isSelected: Bool
    let isAlreadyShared: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Avatar
                ZStack {
                    // Orbital ring for selected
                    if isSelected {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple, Theme.CelestialColors.nebulaEdge],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 72, height: 72)
                    }

                    // Avatar circle
                    Circle()
                        .fill(Theme.CelestialColors.abyss)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Group {
                                if let avatarUrl = friend.avatarUrl, let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        avatarPlaceholder
                                    }
                                } else {
                                    avatarPlaceholder
                                }
                            }
                            .clipShape(Circle())
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.CelestialColors.nebulaCore.opacity(0.3), lineWidth: 1)
                        )

                    // Selection checkmark
                    if isSelected {
                        Circle()
                            .fill(Theme.CelestialColors.auroraGreen)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.black)
                            )
                            .offset(x: 22, y: 22)
                    }

                    // Already shared badge
                    if isAlreadyShared {
                        Circle()
                            .fill(Theme.CelestialColors.starDim)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "link")
                                    .font(.caption2.bold())
                                    .foregroundColor(.black)
                            )
                            .offset(x: 22, y: 22)
                    }
                }

                // Name
                VStack(spacing: 2) {
                    Text(friend.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isAlreadyShared ? Theme.CelestialColors.starDim : .white)
                        .lineLimit(1)

                    if let username = friend.username {
                        Text("@\(username)")
                            .font(.caption2)
                            .foregroundColor(Theme.CelestialColors.starGhost)
                            .lineLimit(1)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Theme.Colors.aiPurple.opacity(0.15) : Theme.CelestialColors.abyss.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Theme.Colors.aiPurple.opacity(0.4) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAlreadyShared)
        .opacity(isAlreadyShared ? 0.6 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var avatarPlaceholder: some View {
        Text(friend.displayName.prefix(1).uppercased())
            .font(.title2.bold())
            .foregroundColor(Theme.Colors.aiPurple)
    }
}

// MARK: - Invite Sent Overlay

private struct InviteSentOverlay: View {
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var pulseRing = false

    var body: some View {
        ZStack {
            // Backdrop
            Theme.CelestialColors.void.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Success Animation
                ZStack {
                    // Pulse rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Theme.CelestialColors.auroraGreen.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                            .frame(width: pulseRing ? 180 + CGFloat(index * 40) : 80, height: pulseRing ? 180 + CGFloat(index * 40) : 80)
                            .opacity(pulseRing ? 0 : 1)
                    }

                    // Success icon
                    Circle()
                        .fill(Theme.CelestialColors.auroraGreen)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.black)
                        )
                        .scaleEffect(showContent ? 1.0 : 0.5)
                }

                VStack(spacing: 12) {
                    Text("Invitations Sent!")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Your friends will be notified")
                        .font(.subheadline)
                        .foregroundColor(Theme.CelestialColors.starDim)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 1.0)) {
                pulseRing = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FriendPickerSheet(
        taskId: UUID(),
        taskTitle: "Complete project proposal"
    ) { friendIds in
        print("Invited: \(friendIds)")
    }
}
