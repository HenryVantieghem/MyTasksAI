//
//  JournalTabView.swift
//  Veloce
//
//  Journal Tab - Beautiful journaling experience with rich text,
//  multiple entry types, media support, and AI features
//

import SwiftUI
import SwiftData

// MARK: - Journal Tab View

struct JournalTabView: View {
    var tasksViewModel: TasksViewModel

    var body: some View {
        // Use the new comprehensive JournalFeedView
        JournalFeedView()
    }
}

// MARK: - Preview

#Preview {
    JournalTabView(tasksViewModel: TasksViewModel())
        .modelContainer(for: [TaskItem.self, JournalEntry.self], inMemory: true)
}
