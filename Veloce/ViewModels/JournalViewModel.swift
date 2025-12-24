//
//  JournalViewModel.swift
//  Veloce
//
//  Journal View Model - Manages journal entries and rich content
//  Handles CRUD operations, photo attachments, and sync
//

import Foundation
import SwiftData
import PencilKit
import UIKit

// MARK: - Journal View Model

@Observable
@MainActor
class JournalViewModel {
    // MARK: State
    var currentEntry: JournalEntry?
    var selectedDate: Date = Date()
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: Editor State
    var richTextViewModel = RichTextEditorViewModel()
    var currentDrawing: PKDrawing = PKDrawing()
    var photoAttachments: [PhotoAttachment] = []

    // MARK: Mode
    var editorMode: JournalEditorMode = .text

    // MARK: Private
    private var modelContext: ModelContext?

    // MARK: Initialization

    init() {}

    // MARK: Setup

    func setup(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: Load Entry

    /// Load or create entry for the selected date
    func loadEntry(for date: Date) async {
        guard let context = modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        let normalizedDate = Calendar.current.startOfDay(for: date)

        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate<JournalEntry> { entry in
                entry.date == normalizedDate
            }
        )

        do {
            let entries = try context.fetch(descriptor)

            if let existingEntry = entries.first {
                currentEntry = existingEntry
                loadEntryContent(existingEntry)
            } else {
                // Create new entry for this date
                let newEntry = JournalEntry(
                    date: date,
                    userId: SupabaseService.shared.currentUserId
                )
                context.insert(newEntry)
                currentEntry = newEntry
                clearEditorState()
            }
        } catch {
            errorMessage = "Failed to load journal entry: \(error.localizedDescription)"
        }
    }

    private func loadEntryContent(_ entry: JournalEntry) {
        richTextViewModel.attributedText = entry.getAttributedString()
        currentDrawing = entry.getDrawing()
        photoAttachments = entry.getPhotoAttachments()
    }

    private func clearEditorState() {
        richTextViewModel.attributedText = NSAttributedString()
        richTextViewModel.selectedRange = NSRange(location: 0, length: 0)
        richTextViewModel.activeFormats = []
        currentDrawing = PKDrawing()
        photoAttachments = []
    }

    // MARK: Save Entry

    /// Save current entry state
    func saveEntry() {
        guard let entry = currentEntry else { return }

        entry.setAttributedString(richTextViewModel.attributedText)
        entry.setDrawing(currentDrawing)
        entry.setPhotoAttachments(photoAttachments)

        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Failed to save journal entry: \(error.localizedDescription)"
        }
    }

    /// Auto-save with debouncing
    func autoSave() {
        // Simple save - in production, add debouncing
        saveEntry()
    }

    // MARK: Photo Management

    /// Add a photo from image data
    func addPhoto(imageData: Data, size: CGSize) async {
        // Save to documents directory
        let id = UUID()
        let fileName = "\(id).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent("JournalPhotos/\(fileName)")

        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: documentsPath.appendingPathComponent("JournalPhotos"),
            withIntermediateDirectories: true
        )

        // Create thumbnail
        var thumbnailData: Data?
        if let image = UIImage(data: imageData) {
            let thumbnailSize = CGSize(width: 200, height: 200)
            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            let thumbnail = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
            }
            thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
        }

        // Save full image
        do {
            try imageData.write(to: filePath)

            let attachment = PhotoAttachment(
                id: id,
                localPath: filePath.path,
                thumbnailData: thumbnailData,
                insertionIndex: richTextViewModel.selectedRange.location,
                width: size.width,
                height: size.height
            )

            photoAttachments.append(attachment)
            autoSave()

            HapticsService.shared.success()
        } catch {
            errorMessage = "Failed to save photo: \(error.localizedDescription)"
        }
    }

    /// Remove a photo
    func removePhoto(_ attachment: PhotoAttachment) {
        // Delete file
        try? FileManager.default.removeItem(atPath: attachment.localPath)

        // Remove from array
        photoAttachments.removeAll { $0.id == attachment.id }
        autoSave()

        HapticsService.shared.lightImpact()
    }

    // MARK: Drawing Management

    /// Update the drawing
    func updateDrawing(_ drawing: PKDrawing) {
        currentDrawing = drawing
        autoSave()
    }

    // MARK: Text Formatting

    /// Apply a text format
    func applyFormat(_ format: TextFormattingStyle) {
        richTextViewModel.applyFormat(format)
        autoSave()
    }

    // MARK: Date Navigation

    /// Navigate to previous day
    func previousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = newDate
            Task {
                await loadEntry(for: newDate)
            }
        }
        HapticsService.shared.selectionFeedback()
    }

    /// Navigate to next day
    func nextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = newDate
            Task {
                await loadEntry(for: newDate)
            }
        }
        HapticsService.shared.selectionFeedback()
    }

    /// Navigate to today
    func goToToday() {
        selectedDate = Date()
        Task {
            await loadEntry(for: selectedDate)
        }
        HapticsService.shared.selectionFeedback()
    }

    // MARK: Migration

    /// Migrate NotesLines to JournalEntry for a specific date
    func migrateNotesLines(from lines: [NotesLine], context: ModelContext) async {
        guard !lines.isEmpty else { return }

        let date = lines.first?.date ?? Date()

        // Check if already migrated
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate<JournalEntry> { entry in
                entry.date == normalizedDate && entry.isMigrated
            }
        )

        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return // Already migrated
        }

        // Combine all lines into rich text
        let combinedText = lines
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { line -> String in
                var prefix = ""
                if line.hasCheckbox {
                    prefix = line.isChecked ? "\u{2611} " : "\u{2610} "
                }
                if line.starRating > 0 {
                    prefix += String(repeating: "\u{2605}", count: line.starRating) + " "
                }
                return prefix + line.text
            }
            .joined(separator: "\n")

        let attributedString = NSAttributedString(
            string: combinedText,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.white
            ]
        )

        let entry = JournalEntry(
            date: date,
            userId: lines.first?.userId,
            isMigrated: true
        )
        entry.setAttributedString(attributedString)

        context.insert(entry)

        do {
            try context.save()
        } catch {
            print("Failed to migrate notes: \(error)")
        }
    }
}

// MARK: - Journal Editor Mode

enum JournalEditorMode: String, CaseIterable, Sendable {
    case text = "Text"
    case draw = "Draw"
    case photo = "Photo"

    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .draw: return "pencil.tip"
        case .photo: return "photo"
        }
    }
}
