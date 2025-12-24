//
//  FriendRequestsView.swift
//  Veloce
//
//  Placeholder view for friend requests
//

import SwiftUI

struct FriendRequestsView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Image(systemName: "person.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("Friend Requests")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("No pending friend requests")
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
        .navigationTitle("Friend Requests")
    }
}

#Preview {
    NavigationStack {
        FriendRequestsView()
    }
}
