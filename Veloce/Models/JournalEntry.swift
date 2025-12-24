//
//  JournalEntry.swift
//  Veloce
//
//  Journal Entry Model - Apple Notes style rich content
//  Supports rich text, drawings, and photo attachments
//

import Foundation
import SwiftData
import PencilKit

// MARK: - Journal Entry Model

@Model
final class JournalEntry {
    // MARK: Core Properties
    var id: UUID
    var date: Date  // Which day this entry belongs to (normalized to midnight)
    var createdAt: Date
    var updatedAt: Date

    // MARK: Content
    /// Rich text content stored as attributed string data
    var richTextData: Data?

    /// PencilKit drawing data
    var drawingData: Data?

    /// Photo attachments as JSON-encoded array
    var photoAttachmentsData: Data?

    // MARK: Metadata
    var title: String?  // Optional title for the entry
    var wordCount: Int
    var hasDrawing: Bool
    var photoCount: Int

    // MARK: User Reference
    var userId: UUID?

    // MARK: Legacy Compatibility
    /// Migration flag - true when migrated from NotesLine
    var isMigrated: Bool

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        date: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        richTextData: Data? = nil,
        drawingData: Data? = nil,
        photoAttachmentsData: Data? = nil,
        title: String? = nil,
        wordCount: Int = 0,
        hasDrawing: Bool = false,
        photoCount: Int = 0,
        userId: UUID? = nil,
        isMigrated: Bool = false
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.richTextData = richTextData
        self.drawingData = drawingData
        self.photoAttachmentsData = photoAttachmentsData
        self.title = title
        self.wordCount = wordCount
        self.hasDrawing = hasDrawing
        self.photoCount = photoCount
        self.userId = userId
        self.isMigrated = isMigrated
    }

    // MARK: Computed Properties

    /// Whether this entry has any content
    var hasContent: Bool {
        (richTextData != nil && richTextData!.count > 0) ||
        (drawingData != nil && drawingData!.count > 0) ||
        photoCount > 0
    }

    /// Plain text content extracted from rich text (for search/preview)
    var plainText: String {
        guard let data = richTextData,
              let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
              ) else {
            return ""
        }
        return attributedString.string
    }

    /// Preview text for list display (first 100 characters)
    var previewText: String {
        let text = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 100 {
            return String(text.prefix(100)) + "..."
        }
        return text
    }

    // MARK: Rich Text Methods

    /// Get attributed string from stored data
    func getAttributedString() -> NSAttributedString {
        guard let data = richTextData,
              let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
              ) else {
            return NSAttributedString()
        }
        return attributedString
    }

    /// Set attributed string and update metadata
    func setAttributedString(_ attributedString: NSAttributedString) {
        if let data = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) {
            richTextData = data
            wordCount = countWords(in: attributedString.string)
            updatedAt = .now
        }
    }

    private func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    // MARK: Drawing Methods

    /// Get PKDrawing from stored data
    func getDrawing() -> PKDrawing {
        guard let data = drawingData,
              let drawing = try? PKDrawing(data: data) else {
            return PKDrawing()
        }
        return drawing
    }

    /// Set drawing and update metadata
    func setDrawing(_ drawing: PKDrawing) {
        drawingData = drawing.dataRepresentation()
        hasDrawing = !drawing.bounds.isEmpty
        updatedAt = .now
    }

    // MARK: Photo Methods

    /// Get photo attachments from stored data
    func getPhotoAttachments() -> [PhotoAttachment] {
        guard let data = photoAttachmentsData,
              let attachments = try? JSONDecoder().decode([PhotoAttachment].self, from: data) else {
            return []
        }
        return attachments
    }

    /// Set photo attachments and update metadata
    func setPhotoAttachments(_ attachments: [PhotoAttachment]) {
        if let data = try? JSONEncoder().encode(attachments) {
            photoAttachmentsData = data
            photoCount = attachments.count
            updatedAt = .now
        }
    }

    /// Add a new photo attachment
    func addPhotoAttachment(_ attachment: PhotoAttachment) {
        var attachments = getPhotoAttachments()
        attachments.append(attachment)
        setPhotoAttachments(attachments)
    }

    /// Remove a photo attachment by ID
    func removePhotoAttachment(id: UUID) {
        var attachments = getPhotoAttachments()
        attachments.removeAll { $0.id == id }
        setPhotoAttachments(attachments)
    }
}

// MARK: - Photo Attachment

struct PhotoAttachment: Codable, Sendable, Identifiable {
    let id: UUID
    let localPath: String
    let thumbnailData: Data?
    let insertionIndex: Int  // Position in the rich text where this photo is embedded
    let width: Double
    let height: Double
    let createdAt: Date

    init(
        id: UUID = UUID(),
        localPath: String,
        thumbnailData: Data? = nil,
        insertionIndex: Int = 0,
        width: Double = 0,
        height: Double = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.localPath = localPath
        self.thumbnailData = thumbnailData
        self.insertionIndex = insertionIndex
        self.width = width
        self.height = height
        self.createdAt = createdAt
    }
}

// MARK: - Date Helpers

extension JournalEntry {
    /// Check if this entry belongs to a specific date
    func belongsTo(date: Date) -> Bool {
        Calendar.current.isDate(self.date, inSameDayAs: date)
    }

    /// Format for display (Today, Yesterday, Tomorrow, or date)
    static func displayDate(for date: Date) -> String {
        NotesLine.displayDate(for: date)
    }
}

// MARK: - Supabase DTO

/// Data Transfer Object for Supabase sync
struct SupabaseJournalEntry: Codable, Sendable {
    let id: UUID
    let date: Date
    let createdAt: Date
    let updatedAt: Date
    let richTextData: Data?
    let drawingData: Data?
    let photoAttachmentsData: Data?
    let title: String?
    let wordCount: Int
    let hasDrawing: Bool
    let photoCount: Int
    let userId: UUID?
    let isMigrated: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case richTextData = "rich_text_data"
        case drawingData = "drawing_data"
        case photoAttachmentsData = "photo_attachments_data"
        case title
        case wordCount = "word_count"
        case hasDrawing = "has_drawing"
        case photoCount = "photo_count"
        case userId = "user_id"
        case isMigrated = "is_migrated"
    }

    init(from entry: JournalEntry) {
        self.id = entry.id
        self.date = entry.date
        self.createdAt = entry.createdAt
        self.updatedAt = entry.updatedAt
        self.richTextData = entry.richTextData
        self.drawingData = entry.drawingData
        self.photoAttachmentsData = entry.photoAttachmentsData
        self.title = entry.title
        self.wordCount = entry.wordCount
        self.hasDrawing = entry.hasDrawing
        self.photoCount = entry.photoCount
        self.userId = entry.userId
        self.isMigrated = entry.isMigrated
    }
}

// MARK: - Text Formatting Types

/// Text formatting options for rich text editor
enum TextFormattingStyle: String, CaseIterable, Sendable {
    case bold
    case italic
    case underline
    case strikethrough
    case header1
    case header2
    case header3
    case bulletList
    case numberedList
    case checklist

    var icon: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .header1: return "textformat.size.larger"
        case .header2: return "textformat.size"
        case .header3: return "textformat.size.smaller"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .checklist: return "checklist"
        }
    }

    var keyboardShortcutKey: String? {
        switch self {
        case .bold: return "b"
        case .italic: return "i"
        case .underline: return "u"
        default: return nil
        }
    }
}
