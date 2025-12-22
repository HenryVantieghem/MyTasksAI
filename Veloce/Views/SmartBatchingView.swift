//
//  SmartBatchingView.swift
//  Veloce
//

import SwiftUI

struct SmartBatchingView: View {
    let tasks: [TaskItem]
    @State private var selectedCluster: TaskCluster?

    private var clusters: [TaskCluster] {
        let categories = Dictionary(grouping: tasks) { $0.category ?? "Other" }
        return categories.map { TaskCluster(name: $0.key, tasks: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Smart Batching").font(.title2.bold()).foregroundStyle(.white)
                Text("Knock out similar tasks together").font(.subheadline).foregroundStyle(.white.opacity(0.7))

                ForEach(clusters) { cluster in
                    ClusterCard(cluster: cluster, isSelected: selectedCluster?.id == cluster.id)
                        .onTapGesture { withAnimation(.spring()) { selectedCluster = cluster } }
                }

                if let cluster = selectedCluster {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Power Hour: \(cluster.name)").font(.headline).foregroundStyle(.white)
                            Spacer()
                            Button("Start") {}.buttonStyle(.glassProminent)
                        }
                        ForEach(cluster.tasks) { task in
                            HStack {
                                Image(systemName: "circle").foregroundStyle(.white.opacity(0.5))
                                Text(task.title).foregroundStyle(.white)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .voidCard(borderColor: Theme.Colors.aiPurple)
                }
            }
            .padding()
        }
        .background(VoidBackground())
    }
}

struct TaskCluster: Identifiable {
    let id = UUID()
    let name: String
    let tasks: [TaskItem]
}

struct ClusterCard: View {
    let cluster: TaskCluster
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(cluster.name).font(.headline).foregroundStyle(.white)
                Text("\(cluster.tasks.count) tasks").font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            ZStack {
                ForEach(0..<min(3, cluster.tasks.count), id: \.self) { i in
                    Circle().fill(Theme.Colors.aiPurple.opacity(0.5)).frame(width: 24, height: 24).offset(x: CGFloat(i * 12))
                }
            }
        }
        .padding()
        .voidCard(borderColor: isSelected ? Theme.Colors.aiPurple : .white.opacity(0.1))
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}
