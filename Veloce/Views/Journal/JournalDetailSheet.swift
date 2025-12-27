//
//  JournalDetailSheet.swift
//  Veloce
//
//  Read-only journal entry detail sheet with actions
//  Convert to Task, Copy, Delete functionality
//

import SwiftUI
import SwiftData

// MARK: - Journal Detail Sheet

struct JournalDetailSheet: View {
    let entry: JournalEntry
    let onConvertToTask: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var copiedToClipboard = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                detailBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Entry Type Badge
                        entryTypeBadge

                        // Content
                        contentSection

                        // Metadata
                        metadataSection

                        Divider()
                            .background(.white.opacity(0.1))

                        // Actions
                        actionsSection

                        // Reminder Suggestion (if applicable)
                        if entry.entryType == .reminder {
                            reminderSuggestionCard
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .confirmationDialog(
                "Delete Entry",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete(entry)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var detailBackground: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.08)
                .ignoresSafeArea()

            // Subtle gradient based on entry type
            LinearGradient(
                colors: [
                    JournalColors.colorFor(entryType: entry.entryType).opacity(0.1),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Entry Type Badge

    private var entryTypeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.entryType.icon)
                .font(.system(size: 12, weight: .medium))

            Text(entry.entryType.displayName)
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .foregroundStyle(JournalColors.colorFor(entryType: entry.entryType))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(JournalColors.colorFor(entryType: entry.entryType).opacity(0.15))
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title (if exists)
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
            }

            // Content
            Text(entry.plainText)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(6)
                .textSelection(.enabled)
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Created date
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))

                Text(entry.createdAt.formatted(date: .complete, time: .shortened))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Word count
            HStack(spacing: 6) {
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))

                Text("\(entry.wordCount) words")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Mood (if set)
            if let mood = entry.mood {
                HStack(spacing: 6) {
                    Text(mood.emoji)
                        .font(.system(size: 14))

                    Text(mood.displayName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Convert to Task
            Button {
                HapticsService.shared.impact()
                onConvertToTask(entry)
                dismiss()
            } label: {
                Label("Convert to Task", systemImage: "arrow.right.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.06))
                    }
            }
            .buttonStyle(.plain)

            // Copy Text
            Button {
                HapticsService.shared.selectionFeedback()
                UIPasteboard.general.string = entry.plainText
                withAnimation(.spring(response: 0.3)) {
                    copiedToClipboard = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.spring(response: 0.3)) {
                        copiedToClipboard = false
                    }
                }
            } label: {
                Label(
                    copiedToClipboard ? "Copied!" : "Copy Text",
                    systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc"
                )
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(copiedToClipboard ? Theme.Colors.success : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.06))
                    }
            }
            .buttonStyle(.plain)

            // Delete Entry
            Button {
                HapticsService.shared.impact(.light)
                showDeleteConfirmation = true
            } label: {
                Label("Delete Entry", systemImage: "trash")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.red.opacity(0.08))
                    }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Reminder Suggestion Card

    private var reminderSuggestionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("May contain a task", systemImage: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.aiAmber)

            Text("This entry looks actionable. Would you like to add it as a task?")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))

            Button {
                HapticsService.shared.impact()
                onConvertToTask(entry)
                dismiss()
            } label: {
                Text("Add to Tasks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.aiAmber)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.aiAmber.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.Colors.aiAmber.opacity(0.3), lineWidth: 0.5)
                }
        }
    }
}

// MARK: - Preview

#Preview {
    JournalDetailSheet(
        entry: {
            let entry = JournalEntry(entryType: .reminder, title: "Remember to buy groceries")
            return entry
        }(),
        onConvertToTask: { _ in },
        onDelete: { _ in }
    )
}
