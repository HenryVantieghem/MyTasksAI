//
//  PremiumTaskDetailSheet.swift
//  Veloce
//

import SwiftUI

struct PremiumTaskDetailSheet: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        if let category = task.category {
                            Text(category)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                    PriorityBadge(priority: task.priority.label)
                }
                .padding()

                // AI Advice
                AIAdviceSection(
                    icon: "lightbulb.fill",
                    iconColor: Theme.Colors.aiGold,
                    title: "AI Insight",
                    content: "This task pairs well with your morning energy. Consider breaking it into 25-minute focus blocks for optimal productivity."
                )

                // Time Estimate
                if let estimate = task.estimatedMinutes {
                    TimeEstimateCard(estimatedMinutes: estimate)
                }

                // AI Schedule
                AIScheduleSuggestionView(
                    suggestedTime: Date().addingTimeInterval(3600 * 2),
                    duration: task.estimatedMinutes ?? 30
                )


                // Pomodoro Timer
                PomodoroTimerWidget(taskId: task.id, taskTitle: task.title)

                // YouTube Learning
                if task.category != nil {
                    YouTubeLearningSection(query: task.title)
                }

                // Action Buttons
                HStack(spacing: 24) {
                    Button { } label: { Label("Edit", systemImage: "pencil") }
                    Button { showDeleteAlert = true } label: { Label("Delete", systemImage: "trash").foregroundStyle(.red) }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .background(VoidBackground())
        .alert("Delete Task?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dismiss() }
        }
    }
}

struct PriorityBadge: View {
    let priority: String?

    private var color: Color {
        switch priority?.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }

    var body: some View {
        if let priority = priority {
            Text(priority.capitalized)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .clipShape(Capsule())
        }
    }
}

struct YouTubeLearningSection: View {
    let query: String
    @State private var videos: [YouTubeVideo] = [
        YouTubeVideo(title: "Productivity Tips for Focus", thumbnail: "video1", duration: "12:34"),
        YouTubeVideo(title: "How to Stay Motivated", thumbnail: "video2", duration: "8:21"),
        YouTubeVideo(title: "Deep Work Strategies", thumbnail: "video3", duration: "15:45")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.red)
                Text("Learning Resources")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(videos) { video in
                        VideoCard(video: video)
                    }
                }
            }
        }
        .padding()
        .voidCard()
    }
}

struct YouTubeVideo: Identifiable {
    let id = UUID()
    let title: String
    let thumbnail: String
    let duration: String
}

struct VideoCard: View {
    let video: YouTubeVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 160, height: 90)
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.8))
                Text(video.duration)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(6)
            }
            Text(video.title)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
        }
    }
}
