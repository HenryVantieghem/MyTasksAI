//
//  CircleDetailView.swift
//  Veloce
//
//  Circle Detail View - Shows circle members and activity feed
//

import SwiftUI

struct CircleDetailView: View {
    let circle: SocialCircle
    @Environment(\.dismiss) private var dismiss
    @State private var circleService = CircleService.shared
    @State private var activity: [CircleActivity] = []
    @State private var showInviteCode = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection

                    // Members
                    membersSection

                    // Activity Feed
                    activitySection
                }
                .padding()
            }
            .navigationTitle(circle.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showInviteCode = true
                        } label: {
                            Label("Invite Code", systemImage: "link")
                        }
                        Button(role: .destructive) {
                            Task {
                                try? await circleService.leaveCircle(circle.id)
                                dismiss()
                            }
                        } label: {
                            Label("Leave Circle", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Invite Code", isPresented: $showInviteCode) {
                Button("Copy") {
                    UIPasteboard.general.string = circle.formattedInviteCode
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(circle.formattedInviteCode)
            }
            .task {
                await loadActivity()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                SwiftUI.Circle()
                    .fill(LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                Text(circle.name.prefix(2).uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            if let description = circle.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Theme.Spacing.lg) {
                statItem(value: "\(circle.memberCount)", label: "Members")
                statItem(value: "\(circle.circleStreak)", label: "Streak")
                statItem(value: "\(circle.circleXp)", label: "XP")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Members")
                .font(.system(size: 18, weight: .bold))

            if let members = circle.members {
                ForEach(members) { member in
                    if let user = member.user {
                        HStack {
                            ZStack {
                                SwiftUI.Circle()
                                    .fill(Theme.Colors.backgroundSecondary)
                                    .frame(width: 40, height: 40)
                                Text(user.displayName.prefix(1).uppercased())
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                Text(member.role.displayName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            Spacer()
                            if let streak = user.currentStreak, streak > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 12))
                                    Text("\(streak)")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Activity")
                .font(.system(size: 18, weight: .bold))

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if activity.isEmpty {
                Text("No activity yet")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(activity) { item in
                    activityRow(item)
                }
            }
        }
    }

    private func activityRow(_ item: CircleActivity) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: item.activityType.icon)
                .foregroundStyle(item.activityType.color)
                .frame(width: 32, height: 32)
                .background(item.activityType.color.opacity(0.15), in: SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.user?.displayName ?? "User")
                    .font(.system(size: 14, weight: .medium))
                if let message = item.message {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            Text(item.formattedTime)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.vertical, 4)
    }

    private func loadActivity() async {
        isLoading = true
        activity = (try? await circleService.loadActivity(for: circle.id)) ?? []
        isLoading = false
    }
}
