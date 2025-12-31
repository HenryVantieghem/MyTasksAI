//
//  ResourcesModule.swift
//  MyTasksAI
//
//  AI-curated resources: YouTube tutorials, articles, templates
//  Thumbnail + title + duration + AI note
//  In-app viewing with WebViewSheet + external open option
//

import SwiftUI

// MARK: - Resources Module

struct ResourcesModule: View {
    let resources: [TaskResource]

    @State private var selectedResourceURL: URL?
    @State private var selectedResourceTitle: String = ""
    @State private var selectedResourceType: WebViewSheet.ResourceType = .article
    @State private var showWebView = false

    private let accentColor = Theme.TaskCardColors.resources

    var body: some View {
        ModuleCard(
            title: "RESOURCES",
            icon: "books.vertical.fill",
            accentColor: accentColor
        ) {
            if resources.isEmpty {
                emptyState
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(resources) { resource in
                        ResourceRow(
                            resource: resource,
                            accentColor: accentColor,
                            onOpenInApp: {
                                openInApp(resource)
                            },
                            onOpenExternal: {
                                openExternal(resource)
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showWebView) {
            if let url = selectedResourceURL {
                WebViewSheet(
                    url: url,
                    title: selectedResourceTitle,
                    resourceType: selectedResourceType,
                    isPresented: $showWebView
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Actions

    private func openInApp(_ resource: TaskResource) {
        guard let url = URL(string: resource.url) else { return }
        selectedResourceURL = url
        selectedResourceTitle = resource.title
        selectedResourceType = resource.type.webViewType
        showWebView = true
        HapticsService.shared.selectionFeedback()
    }

    private func openExternal(_ resource: TaskResource) {
        guard let url = URL(string: resource.url) else { return }

        // Try app-specific URL for YouTube
        if resource.type == .youtube {
            if let videoId = YouTubeThumbnail.extractVideoId(from: resource.url),
               let appURL = URL(string: "youtube://watch?v=\(videoId)"),
               UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
                return
            }
        }

        // Fall back to Safari
        UIApplication.shared.open(url)
        HapticsService.shared.selectionFeedback()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .dynamicTypeFont(base: 24)
                .foregroundStyle(accentColor.opacity(0.5))

            Text("No resources found")
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(.white.opacity(0.6))

            Text("AI will suggest helpful resources based on your task")
                .dynamicTypeFont(base: 11)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
    }
}

// MARK: - Resource Row

struct ResourceRow: View {
    let resource: TaskResource
    let accentColor: Color
    let onOpenInApp: () -> Void
    let onOpenExternal: () -> Void

    @State private var showActions = false

    private var thumbnailURL: URL? {
        if resource.type == .youtube {
            if let videoId = YouTubeThumbnail.extractVideoId(from: resource.url) {
                return YouTubeThumbnail.thumbnailURL(for: videoId, quality: .medium)
            }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main content - tap to expand
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showActions.toggle()
                }
                HapticsService.shared.selectionFeedback()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    // Thumbnail or type icon
                    thumbnailView

                    // Content
                    VStack(alignment: .leading, spacing: 3) {
                        Text(resource.title)
                            .dynamicTypeFont(base: 14, weight: .medium)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            // Type badge
                            HStack(spacing: 3) {
                                Image(systemName: resource.type.icon)
                                    .dynamicTypeFont(base: 9)
                                Text(resource.type.displayName)
                                    .dynamicTypeFont(base: 10, weight: .medium)
                            }
                            .foregroundStyle(resource.type.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(resource.type.color.opacity(0.15))
                            )

                            Text(resource.source)
                                .dynamicTypeFont(base: 11, weight: .regular)
                                .foregroundStyle(.white.opacity(0.6))

                            if let duration = resource.duration {
                                Text("•")
                                    .foregroundStyle(.white.opacity(0.4))
                                Text(duration)
                                    .dynamicTypeFont(base: 11, weight: .regular)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        // AI Reasoning
                        if let reasoning = resource.reasoning {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .dynamicTypeFont(base: 8)
                                Text(reasoning)
                                    .dynamicTypeFont(base: 10, weight: .medium)
                            }
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.1))
                            )
                        }
                    }

                    Spacer()

                    Image(systemName: showActions ? "chevron.up" : "chevron.down")
                        .dynamicTypeFont(base: 12, weight: .medium)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(Theme.Spacing.sm)
            }
            .buttonStyle(.plain)

            // Expandable actions
            if showActions {
                HStack(spacing: Theme.Spacing.sm) {
                    // Open in app (primary)
                    Button {
                        onOpenInApp()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.rectangle.fill")
                                .dynamicTypeFont(base: 12)
                            Text("Open in App")
                                .dynamicTypeFont(base: 12, weight: .semibold)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor)
                        )
                    }
                    .buttonStyle(.plain)

                    // Open external (secondary)
                    Button {
                        onOpenExternal()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: resource.type == .youtube ? "play.rectangle" : "safari")
                                .dynamicTypeFont(base: 12)
                            Text(resource.type == .youtube ? "YouTube" : "Safari")
                                .dynamicTypeFont(base: 12, weight: .medium)
                        }
                        .foregroundStyle(accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(accentColor.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.sm)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showActions ? accentColor.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Thumbnail View

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL {
            // YouTube thumbnail
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .empty:
                    thumbnailPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 45)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            // Play button overlay
                            ZStack {
                                SwiftUI.Circle()
                                    .fill(.black.opacity(0.5))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "play.fill")
                                    .dynamicTypeFont(base: 10)
                                    .foregroundStyle(.white)
                            }
                        )
                case .failure:
                    thumbnailPlaceholder
                @unknown default:
                    thumbnailPlaceholder
                }
            }
        } else {
            // Type icon for non-YouTube resources
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(resource.type.color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: resource.type.icon)
                    .dynamicTypeFont(base: 20, weight: .medium)
                    .foregroundStyle(resource.type.color)
            }
        }
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 45)

            Image(systemName: "play.rectangle.fill")
                .dynamicTypeFont(base: 18)
                .foregroundStyle(.white.opacity(0.4))
        }
        .shimmer()
    }
}

// MARK: - TaskResourceType Extension

extension TaskResourceType {
    var webViewType: WebViewSheet.ResourceType {
        switch self {
        case .youtube: return .youtube
        case .article: return .article
        case .documentation: return .documentation
        case .tool: return .tool
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ResourcesModule(
            resources: [
                TaskResource(
                    title: "How to Actually Start Working on Hard Tasks",
                    url: "https://youtube.com/watch?v=dQw4w9WgXcQ",
                    source: "YouTube",
                    type: .youtube,
                    duration: "8 min",
                    reasoning: "Perfect for procrastination"
                ),
                TaskResource(
                    title: "The 2-Minute Rule Explained",
                    url: "https://jamesclear.com/2-minute-rule",
                    source: "James Clear",
                    type: .article,
                    duration: nil,
                    reasoning: "Quick actionable read"
                ),
                TaskResource(
                    title: "SwiftUI Documentation",
                    url: "https://developer.apple.com/documentation/swiftui",
                    source: "Apple",
                    type: .documentation,
                    duration: nil,
                    reasoning: nil
                )
            ]
        )
        .padding()
    }
}
