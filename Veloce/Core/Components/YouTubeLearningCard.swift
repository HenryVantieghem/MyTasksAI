//
//  YouTubeLearningCard.swift
//  Veloce
//
//  AI-curated YouTube learning resources for tasks
//  Helps users learn how to complete their tasks effectively
//

import SwiftUI

struct YouTubeLearningCard: View {
    @Binding var resources: [YouTubeResource]
    let taskTitle: String
    let onRefresh: () -> Void

    @State private var isLoading: Bool = false
    @State private var appeared: Bool = false
    @State private var expandedVideoId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            headerView

            // Content
            if isLoading {
                loadingView
            } else if resources.isEmpty {
                emptyStateView
            } else {
                videoListView
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.glassBorder.opacity(0.2))
                }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "play.rectangle.fill")
                .foregroundStyle(.red)
                .dynamicTypeFont(base: 18)

            Text("Learn How")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.primaryText)

            Spacer()

            // Refresh button
            Button {
                refreshResources()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.5 : 1)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(0..<2, id: \.self) { index in
                HStack(spacing: Theme.Spacing.md) {
                    // Thumbnail skeleton
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .fill(Theme.Colors.glassBackground.opacity(0.5))
                        .frame(width: 80, height: 45)

                    // Text skeleton
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.glassBackground.opacity(0.5))
                            .frame(height: 14)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.glassBackground.opacity(0.3))
                            .frame(width: 100, height: 10)
                    }
                }
                .shimmer()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "play.rectangle")
                .dynamicTypeFont(base: 24)
                .foregroundStyle(Theme.Colors.tertiaryText)

            Text("No videos found yet")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)

            Button {
                refreshResources()
            } label: {
                Text("Find Resources")
                    .font(Theme.Typography.caption)
            }
            .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Video List

    private var videoListView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(resources.prefix(3)) { resource in
                YouTubeResourceRow(
                    resource: resource,
                    isExpanded: expandedVideoId == resource.id,
                    onTap: {
                        openVideo(resource)
                    },
                    onToggleExpand: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if expandedVideoId == resource.id {
                                expandedVideoId = nil
                            } else {
                                expandedVideoId = resource.id
                            }
                        }
                    }
                )
            }

            // See more button
            if resources.count > 3 {
                seeMoreButton
            }
        }
    }

    private var seeMoreButton: some View {
        Button {
            // Open full list
        } label: {
            HStack {
                Spacer()
                Text("See more resources")
                    .font(Theme.Typography.caption)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Spacer()
            }
            .foregroundStyle(Theme.Colors.accent)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func refreshResources() {
        isLoading = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        onRefresh()

        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }

    private func openVideo(_ resource: YouTubeResource) {
        // Try to open in YouTube app first
        if let appURL = resource.appURL,
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = resource.watchURL {
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: - YouTube Resource Row

struct YouTubeResourceRow: View {
    let resource: YouTubeResource
    let isExpanded: Bool
    let onTap: () -> Void
    let onToggleExpand: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            Button {
                onTap()
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    // Thumbnail
                    thumbnailView

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resource.title)
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.primaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: Theme.Spacing.sm) {
                            // Channel name
                            if let channel = resource.channelName {
                                Text(channel)
                                    .dynamicTypeFont(base: 10)
                                    .foregroundStyle(Theme.Colors.secondaryText)
                            }

                            // Duration
                            if let duration = resource.formattedDuration {
                                Text("• \(duration)")
                                    .dynamicTypeFont(base: 10)
                                    .foregroundStyle(Theme.Colors.tertiaryText)
                            }
                        }

                        // Views and relevance
                        HStack(spacing: Theme.Spacing.sm) {
                            if let views = resource.formattedViewCount {
                                Text(views)
                                    .dynamicTypeFont(base: 10)
                                    .foregroundStyle(Theme.Colors.tertiaryText)
                            }

                            if let relevance = resource.relevanceLabel {
                                Text("• \(relevance)")
                                    .dynamicTypeFont(base: 10)
                                    .foregroundStyle(Theme.Colors.success)
                            }
                        }
                    }

                    Spacer()

                    // Play indicator
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            }
            .buttonStyle(.plain)
            .padding(Theme.Spacing.sm)
        }
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(Theme.Colors.glassBorder.opacity(0.15))
        }
    }

    private var thumbnailView: some View {
        ZStack {
            // Thumbnail background
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
                .frame(width: 80, height: 45)

            // Thumbnail image (if available)
            if let urlString = resource.thumbnailURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        thumbnailPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 45)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    case .failure:
                        thumbnailPlaceholder
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }

            // Duration overlay
            if let duration = resource.formattedDuration {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(duration)
                            .dynamicTypeFont(base: 9, weight: .medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.black.opacity(0.8))
                            }
                            .padding(4)
                    }
                }
                .frame(width: 80, height: 45)
            }
        }
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colors.glassBackground.opacity(0.5))

            Image(systemName: "play.rectangle.fill")
                .foregroundStyle(.red.opacity(0.7))
        }
        .frame(width: 80, height: 45)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        YouTubeLearningCard(
            resources: .constant([
                YouTubeResource(
                    videoId: "abc123",
                    title: "How to Create Stunning Quarterly Reports",
                    channelName: "PowerPoint School",
                    durationSeconds: 720,
                    viewCount: 2_300_000,
                    relevanceScore: 0.92
                ),
                YouTubeResource(
                    videoId: "def456",
                    title: "Data Visualization Tips for Business Reports",
                    channelName: "Storytelling with Data",
                    durationSeconds: 480,
                    viewCount: 890_000,
                    relevanceScore: 0.78
                ),
                YouTubeResource(
                    videoId: "ghi789",
                    title: "Executive Summary Writing Masterclass",
                    channelName: "Business Writing Pro",
                    durationSeconds: 1200,
                    viewCount: 450_000,
                    relevanceScore: 0.65
                )
            ]),
            taskTitle: "Finish quarterly report",
            onRefresh: { }
        )
        .padding()
    }
    .background(Theme.Colors.background)
}
