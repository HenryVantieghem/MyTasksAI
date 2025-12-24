//
//  AddFriendSheet.swift
//  Veloce
//
//  Add Friend Sheet - Search and add friends by username
//  Part of Velocity Circles social feature
//

import SwiftUI

struct AddFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var friendService = FriendService.shared
    @State private var searchText = ""
    @State private var searchResults: [FriendProfile] = []
    @State private var isSearching = false
    @State private var sentRequests: Set<UUID> = []
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)

                // Results
                if isSearching {
                    loadingView
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    emptyResultsView
                } else if !searchResults.isEmpty {
                    resultsList
                } else {
                    searchPromptView
                }

                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: searchText) { _, newValue in
            Task {
                await search(query: newValue)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.textTertiary)

            TextField("Search by username", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.backgroundSecondary)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
            Text("Searching...")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "person.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No users found")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("Try a different username")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Search Prompt

    private var searchPromptView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "at")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("Search for friends")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("Enter a username to find friends")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(searchResults) { user in
                    userRow(user)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
        }
    }

    private func userRow(_ user: FriendProfile) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.backgroundSecondary)
                    .frame(width: 50, height: 50)

                Text(user.displayName.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                if let username = user.atUsername {
                    Text(username)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer()

            // Add button
            addButton(for: user)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func addButton(for user: FriendProfile) -> some View {
        if sentRequests.contains(user.id) {
            Text("Sent")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background {
                    Capsule()
                        .fill(Theme.Colors.backgroundSecondary)
                }
        } else {
            Button {
                Task {
                    await sendRequest(to: user)
                }
            } label: {
                Text("Add")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.aiPurple, in: Capsule())
            }
        }
    }

    // MARK: - Actions

    private func search(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true

        // Debounce
        try? await Task.sleep(for: .milliseconds(300))

        do {
            searchResults = try await friendService.searchByUsername(query)
        } catch {
            print("Search error: \(error)")
        }

        isSearching = false
    }

    private func sendRequest(to user: FriendProfile) async {
        do {
            try await friendService.sendFriendRequest(to: user.id)
            sentRequests.insert(user.id)
            HapticsService.shared.taskComplete()
        } catch {
            print("Failed to send request: \(error)")
            HapticsService.shared.error()
        }
    }
}

#Preview {
    AddFriendSheet()
}
