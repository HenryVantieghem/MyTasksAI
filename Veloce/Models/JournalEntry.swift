//
//  JournalEntry.swift
//  Veloce
//
//  Journal Entry Model - Apple Notes/Journal style rich content
//  Supports rich text, drawings, photo attachments, voice recordings, and AI features
//

import Foundation
import SwiftData
import PencilKit
#if canImport(PaperKit)
import PaperKit
#endif

// MARK: - Journal Entry Type

enum JournalEntryType: String, Codable, CaseIterable, Sendable {
    case brainDump = "brain_dump"
    case reminder = "reminder"
    case gratitude = "gratitude"
    case reflection = "reflection"

    var displayName: String {
        switch self {
        case .brainDump: return "Brain Dump"
        case .reminder: return "Reminder"
        case .gratitude: return "Gratitude"
        case .reflection: return "Reflection"
        }
    }

    var icon: String {
        switch self {
        case .brainDump: return "brain.head.profile"
        case .reminder: return "bell.badge"
        case .gratitude: return "heart.fill"
        case .reflection: return "sparkles"
        }
    }

    var color: String {
        switch self {
        case .brainDump: return "neutral"      // Gray
        case .reminder: return "amber"          // Amber/Yellow
        case .gratitude: return "rose"          // Soft pink/rose
        case .reflection: return "purple"       // Oracle purple
        }
    }

    var placeholder: String {
        switch self {
        case .brainDump: return "Get it all out of your head..."
        case .reminder: return "Remember to..."
        case .gratitude: return "Today I'm grateful for..."
        case .reflection: return "Reflecting on today..."
        }
    }

    var promptSuggestions: [String] {
        switch self {
        case .brainDump:
            return [
                "What's weighing on your mind?",
                "Dump all your thoughts here...",
                "No filter, just write..."
            ]
        case .reminder:
            return [
                "Don't forget to...",
                "Important: Remember...",
                "Note to self..."
            ]
        case .gratitude:
            return [
                "3 things you're grateful for today",
                "A small moment that made you smile",
                "Someone who helped you recently"
            ]
        case .reflection:
            return [
                "What did you learn today?",
                "What would you do differently?",
                "How did today align with your goals?"
            ]
        }
    }
}

// MARK: - Journal Mood

enum JournalMood: String, Codable, CaseIterable, Sendable {
    case excellent = "excellent"
    case good = "good"
    case neutral = "neutral"
    case low = "low"
    case stressed = "stressed"

    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .neutral: return "Neutral"
        case .low: return "Low"
        case .stressed: return "Stressed"
        }
    }

    var emoji: String {
        switch self {
        case .excellent: return "😄"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .low: return "😔"
        case .stressed: return "😰"
        }
    }

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "cyan"
        case .neutral: return "gray"
        case .low: return "blue"
        case .stressed: return "orange"
        }
    }

    var value: Double {
        switch self {
        case .excellent: return 1.0
        case .good: return 0.75
        case .neutral: return 0.5
        case .low: return 0.25
        case .stressed: return 0.15
        }
    }
}

// MARK: - Voice Recording

struct VoiceRecording: Codable, Sendable, Identifiable {
    let id: UUID
    let localPath: String
    let duration: TimeInterval
    let transcription: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        localPath: String,
        duration: TimeInterval,
        transcription: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.localPath = localPath
        self.duration = duration
        self.transcription = transcription
        self.createdAt = createdAt
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Journal Entry Model

@Model
final class JournalEntry {
    // MARK: Core Properties
    var id: UUID
    var date: Date  // Which day this entry belongs to (normalized to midnight)
    var createdAt: Date
    var updatedAt: Date

    // MARK: Entry Type & Mood (internal for SwiftData predicate access)
    var entryTypeRaw: String
    var moodRaw: String?

    var entryType: JournalEntryType {
        get { JournalEntryType(rawValue: entryTypeRaw) ?? .brainDump }
        set { entryTypeRaw = newValue.rawValue }
    }

    var mood: JournalMood? {
        get { moodRaw.flatMap { JournalMood(rawValue: $0) } }
        set { moodRaw = newValue?.rawValue }
    }

    // MARK: Content
    /// Rich text content stored as attributed string data
    var richTextData: Data?

    /// PencilKit drawing data
    var drawingData: Data?

    /// PaperKit markup data (iOS 26+) - replaces richTextData + drawingData when available
    var paperMarkupData: Data?

    /// Whether this entry uses PaperKit format (iOS 26+)
    var usesPaperKit: Bool

    /// Photo attachments as JSON-encoded array
    var photoAttachmentsData: Data?

    /// Voice recordings as JSON-encoded array
    var voiceRecordingsData: Data?

    // MARK: Metadata
    var title: String?  // Optional title for the entry
    var wordCount: Int
    var hasDrawing: Bool
    var photoCount: Int
    var recordingCount: Int

    // MARK: AI Features
    var aiPrompt: String?           // AI-generated daily prompt used
    var aiSummary: String?          // AI-generated summary of entry
    var aiSentiment: Double?        // Sentiment score (-1 to 1)
    var aiThemes: Data?             // JSON array of detected themes
    var aiProcessedAt: Date?        // When AI last analyzed this entry

    // MARK: Gratitude Specific
    var gratitudeItems: Data?       // JSON array of gratitude items
    var gratitudeStreak: Int        // Consecutive days of gratitude entries

    // MARK: User Reference
    var userId: UUID?

    // MARK: Legacy Compatibility
    /// Migration flag - true when migrated from NotesLine
    var isMigrated: Bool

    // MARK: Favorites & Pinned
    var isPinned: Bool
    var isFavorite: Bool

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        date: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        entryType: JournalEntryType = .brainDump,
        mood: JournalMood? = nil,
        richTextData: Data? = nil,
        drawingData: Data? = nil,
        paperMarkupData: Data? = nil,
        usesPaperKit: Bool = false,
        photoAttachmentsData: Data? = nil,
        voiceRecordingsData: Data? = nil,
        title: String? = nil,
        wordCount: Int = 0,
        hasDrawing: Bool = false,
        photoCount: Int = 0,
        recordingCount: Int = 0,
        aiPrompt: String? = nil,
        aiSummary: String? = nil,
        aiSentiment: Double? = nil,
        aiThemes: Data? = nil,
        aiProcessedAt: Date? = nil,
        gratitudeItems: Data? = nil,
        gratitudeStreak: Int = 0,
        userId: UUID? = nil,
        isMigrated: Bool = false,
        isPinned: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.entryTypeRaw = entryType.rawValue
        self.moodRaw = mood?.rawValue
        self.richTextData = richTextData
        self.drawingData = drawingData
        self.paperMarkupData = paperMarkupData
        self.usesPaperKit = usesPaperKit
        self.photoAttachmentsData = photoAttachmentsData
        self.voiceRecordingsData = voiceRecordingsData
        self.title = title
        self.wordCount = wordCount
        self.hasDrawing = hasDrawing
        self.photoCount = photoCount
        self.recordingCount = recordingCount
        self.aiPrompt = aiPrompt
        self.aiSummary = aiSummary
        self.aiSentiment = aiSentiment
        self.aiThemes = aiThemes
        self.aiProcessedAt = aiProcessedAt
        self.gratitudeItems = gratitudeItems
        self.gratitudeStreak = gratitudeStreak
        self.userId = userId
        self.isMigrated = isMigrated
        self.isPinned = isPinned
        self.isFavorite = isFavorite
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

    // MARK: PaperKit Methods (iOS 26+)

    #if canImport(PaperKit)
    /// Get PaperMarkup from stored data (iOS 26+)
    @available(iOS 26.0, *)
    func getPaperMarkup() -> PaperMarkup {
        guard let data = paperMarkupData,
              let markup = try? PaperMarkup(data: data) else {
            return PaperMarkup()
        }
        return markup
    }

    /// Set PaperMarkup and update metadata
    @available(iOS 26.0, *)
    func setPaperMarkup(_ markup: PaperMarkup) {
        paperMarkupData = try? markup.dataRepresentation()
        usesPaperKit = true
        hasDrawing = !markup.isEmpty
        updatedAt = .now
    }

    /// Extract plain text from PaperMarkup for search/preview
    @available(iOS 26.0, *)
    func getTextFromPaperMarkup() -> String {
        let markup = getPaperMarkup()
        // Extract text content from markup elements
        return markup.textContent ?? ""
    }
    #endif

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

    // MARK: Voice Recording Methods

    /// Get voice recordings from stored data
    func getVoiceRecordings() -> [VoiceRecording] {
        guard let data = voiceRecordingsData,
              let recordings = try? JSONDecoder().decode([VoiceRecording].self, from: data) else {
            return []
        }
        return recordings
    }

    /// Set voice recordings and update metadata
    func setVoiceRecordings(_ recordings: [VoiceRecording]) {
        if let data = try? JSONEncoder().encode(recordings) {
            voiceRecordingsData = data
            recordingCount = recordings.count
            updatedAt = .now
        }
    }

    /// Add a new voice recording
    func addVoiceRecording(_ recording: VoiceRecording) {
        var recordings = getVoiceRecordings()
        recordings.append(recording)
        setVoiceRecordings(recordings)
    }

    /// Remove a voice recording by ID
    func removeVoiceRecording(id: UUID) {
        var recordings = getVoiceRecordings()
        recordings.removeAll { $0.id == id }
        setVoiceRecordings(recordings)
    }

    /// Update transcription for a voice recording
    func updateTranscription(for recordingId: UUID, transcription: String) {
        var recordings = getVoiceRecordings()
        if let index = recordings.firstIndex(where: { $0.id == recordingId }) {
            let oldRecording = recordings[index]
            recordings[index] = VoiceRecording(
                id: oldRecording.id,
                localPath: oldRecording.localPath,
                duration: oldRecording.duration,
                transcription: transcription,
                createdAt: oldRecording.createdAt
            )
            setVoiceRecordings(recordings)
        }
    }

    // MARK: Gratitude Methods

    /// Get gratitude items from stored data
    func getGratitudeItems() -> [String] {
        guard let data = gratitudeItems,
              let items = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return items
    }

    /// Set gratitude items
    func setGratitudeItems(_ items: [String]) {
        if let data = try? JSONEncoder().encode(items) {
            gratitudeItems = data
            updatedAt = .now
        }
    }

    // MARK: AI Theme Methods

    /// Get AI-detected themes
    func getAIThemes() -> [String] {
        guard let data = aiThemes,
              let themes = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return themes
    }

    /// Set AI themes
    func setAIThemes(_ themes: [String]) {
        if let data = try? JSONEncoder().encode(themes) {
            aiThemes = data
        }
    }

    // MARK: Display Helpers

    /// Get the accent color for this entry type
    var accentColor: String {
        entryType.color
    }

    /// Formatted time for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    /// Total media count (photos + drawings + recordings)
    var mediaCount: Int {
        photoCount + (hasDrawing ? 1 : 0) + recordingCount
    }

    /// Check if entry has any media
    var hasMedia: Bool {
        mediaCount > 0
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
    let entryType: String
    let mood: String?
    let richTextData: Data?
    let drawingData: Data?
    let paperMarkupData: Data?
    let usesPaperKit: Bool
    let photoAttachmentsData: Data?
    let voiceRecordingsData: Data?
    let title: String?
    let wordCount: Int
    let hasDrawing: Bool
    let photoCount: Int
    let recordingCount: Int
    let aiPrompt: String?
    let aiSummary: String?
    let aiSentiment: Double?
    let aiThemes: Data?
    let aiProcessedAt: Date?
    let gratitudeItems: Data?
    let gratitudeStreak: Int
    let userId: UUID?
    let isMigrated: Bool
    let isPinned: Bool
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case entryType = "entry_type"
        case mood
        case richTextData = "rich_text_data"
        case drawingData = "drawing_data"
        case paperMarkupData = "paper_markup_data"
        case usesPaperKit = "uses_paper_kit"
        case photoAttachmentsData = "photo_attachments_data"
        case voiceRecordingsData = "voice_recordings_data"
        case title
        case wordCount = "word_count"
        case hasDrawing = "has_drawing"
        case photoCount = "photo_count"
        case recordingCount = "recording_count"
        case aiPrompt = "ai_prompt"
        case aiSummary = "ai_summary"
        case aiSentiment = "ai_sentiment"
        case aiThemes = "ai_themes"
        case aiProcessedAt = "ai_processed_at"
        case gratitudeItems = "gratitude_items"
        case gratitudeStreak = "gratitude_streak"
        case userId = "user_id"
        case isMigrated = "is_migrated"
        case isPinned = "is_pinned"
        case isFavorite = "is_favorite"
    }

    init(from entry: JournalEntry) {
        self.id = entry.id
        self.date = entry.date
        self.createdAt = entry.createdAt
        self.updatedAt = entry.updatedAt
        self.entryType = entry.entryType.rawValue
        self.mood = entry.mood?.rawValue
        self.richTextData = entry.richTextData
        self.drawingData = entry.drawingData
        self.paperMarkupData = entry.paperMarkupData
        self.usesPaperKit = entry.usesPaperKit
        self.photoAttachmentsData = entry.photoAttachmentsData
        self.voiceRecordingsData = entry.voiceRecordingsData
        self.title = entry.title
        self.wordCount = entry.wordCount
        self.hasDrawing = entry.hasDrawing
        self.photoCount = entry.photoCount
        self.recordingCount = entry.recordingCount
        self.aiPrompt = entry.aiPrompt
        self.aiSummary = entry.aiSummary
        self.aiSentiment = entry.aiSentiment
        self.aiThemes = entry.aiThemes
        self.aiProcessedAt = entry.aiProcessedAt
        self.gratitudeItems = entry.gratitudeItems
        self.gratitudeStreak = entry.gratitudeStreak
        self.userId = entry.userId
        self.isMigrated = entry.isMigrated
        self.isPinned = entry.isPinned
        self.isFavorite = entry.isFavorite
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
