//
//  JournalAIService.swift
//  Veloce
//
//  Journal AI Service - AI-powered features for journaling
//  Daily prompts, sentiment analysis, summaries, and pattern recognition
//

import Foundation
import NaturalLanguage

// MARK: - Journal AI Service

@MainActor
@Observable
final class JournalAIService {
    static let shared = JournalAIService()

    // MARK: State
    private(set) var isProcessing = false
    var errorMessage: String?

    // MARK: Private
    private let sentimentPredictor = NLModel()

    private init() {}

    // MARK: - Daily Prompts

    /// Generate a personalized daily prompt based on user's goals and recent activity
    func generateDailyPrompt(recentEntries: [JournalEntry] = [], userGoals: [String] = []) -> String {
        // Curated prompts organized by theme
        let reflectionPrompts = [
            "What did you learn about yourself today?",
            "If you could relive one moment from today, which would it be?",
            "What's something you're proud of accomplishing recently?",
            "How did today challenge you to grow?",
            "What would you tell your past self from a year ago?"
        ]

        let gratitudePrompts = [
            "What unexpected blessing did you experience today?",
            "Who made a positive impact on your life this week?",
            "What simple pleasure brought you joy today?",
            "What challenge are you grateful for because it helped you grow?",
            "What's something about your daily life you often take for granted?"
        ]

        let goalPrompts = [
            "What progress did you make toward your goals today?",
            "What's one small step you can take tomorrow toward your dreams?",
            "How are you balancing ambition with self-care?",
            "What obstacle is standing between you and your goal? How might you overcome it?",
            "Visualize yourself achieving your biggest goal. How does it feel?"
        ]

        let emotionalPrompts = [
            "How are you really feeling right now? Be honest.",
            "What emotion have you been avoiding lately?",
            "When did you last feel truly at peace? What were you doing?",
            "What would you say to a friend feeling the way you feel now?",
            "What does your ideal self handle stress differently?"
        ]

        let creativePrompts = [
            "If today were a color, what would it be and why?",
            "Write a letter to your future self.",
            "Describe your perfect day in vivid detail.",
            "What would you create if you had unlimited time and resources?",
            "If you could have dinner with anyone, living or dead, who and why?"
        ]

        // Select prompt category based on day of week and recent activity
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        let allPrompts: [String]

        switch dayOfWeek {
        case 1: // Sunday - Reflection
            allPrompts = reflectionPrompts
        case 2: // Monday - Goals
            allPrompts = goalPrompts
        case 3: // Tuesday - Emotional
            allPrompts = emotionalPrompts
        case 4: // Wednesday - Creative
            allPrompts = creativePrompts
        case 5: // Thursday - Gratitude
            allPrompts = gratitudePrompts
        case 6: // Friday - Reflection
            allPrompts = reflectionPrompts
        case 7: // Saturday - Creative
            allPrompts = creativePrompts
        default:
            allPrompts = reflectionPrompts
        }

        // Use date hash to consistently select prompt for the day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let promptIndex = dayOfYear % allPrompts.count

        return allPrompts[promptIndex]
    }

    // MARK: - Sentiment Analysis

    /// Analyze the sentiment of journal entry text
    func analyzeSentiment(text: String) -> SentimentResult {
        guard !text.isEmpty else {
            return SentimentResult(score: 0, label: .neutral, confidence: 0)
        }

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var totalScore: Double = 0
        var wordCount: Double = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                wordCount += 1
            }
            return true
        }

        let averageScore = wordCount > 0 ? totalScore / wordCount : 0

        let label: SentimentLabel
        let confidence: Double

        if averageScore > 0.3 {
            label = .positive
            confidence = min(averageScore, 1.0)
        } else if averageScore < -0.3 {
            label = .negative
            confidence = min(abs(averageScore), 1.0)
        } else {
            label = .neutral
            confidence = 1.0 - abs(averageScore)
        }

        return SentimentResult(score: averageScore, label: label, confidence: confidence)
    }

    /// Map sentiment to suggested mood
    func suggestMood(from sentiment: SentimentResult) -> JournalMood? {
        switch sentiment.label {
        case .positive:
            return sentiment.score > 0.6 ? .excellent : .good
        case .negative:
            return sentiment.score < -0.6 ? .stressed : .low
        case .neutral:
            return .neutral
        }
    }

    // MARK: - Theme Detection

    /// Extract key themes from journal entry text
    func detectThemes(text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        var themes: Set<String> = []
        var nouns: [String: Int] = [:]

        // Extract named entities and nouns
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag {
                let word = String(text[range]).lowercased()

                // Skip common words and short words
                guard word.count > 3, !commonWords.contains(word) else {
                    return true
                }

                switch tag {
                case .noun:
                    nouns[word, default: 0] += 1
                case .verb:
                    // Track significant verbs
                    if significantVerbs.contains(word) {
                        themes.insert(word)
                    }
                default:
                    break
                }
            }
            return true
        }

        // Add most frequent nouns as themes
        let topNouns = nouns.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }

        themes.formUnion(topNouns)

        // Detect emotional themes
        let emotionalThemes = detectEmotionalThemes(in: text)
        themes.formUnion(emotionalThemes)

        return Array(themes).prefix(5).map { $0 }
    }

    private func detectEmotionalThemes(in text: String) -> Set<String> {
        let lowercased = text.lowercased()
        var themes: Set<String> = []

        let emotionKeywords: [String: [String]] = [
            "growth": ["learn", "improve", "progress", "develop", "grow", "better"],
            "gratitude": ["thankful", "grateful", "appreciate", "blessed", "fortune"],
            "anxiety": ["worry", "anxious", "nervous", "stress", "overwhelm"],
            "joy": ["happy", "joy", "excited", "wonderful", "amazing", "great"],
            "reflection": ["think", "reflect", "consider", "realize", "understand"],
            "connection": ["friend", "family", "love", "together", "relationship"],
            "achievement": ["accomplish", "achieve", "success", "complete", "finish"],
            "challenge": ["difficult", "hard", "struggle", "challenge", "tough"]
        ]

        for (theme, keywords) in emotionKeywords {
            if keywords.contains(where: { lowercased.contains($0) }) {
                themes.insert(theme)
            }
        }

        return themes
    }

    // MARK: - Summary Generation

    /// Generate a concise summary of a journal entry
    func generateSummary(text: String, maxSentences: Int = 2) -> String {
        guard !text.isEmpty else { return "" }

        // Split into sentences
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var sentences: [String] = []
        var currentSentence = ""

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .lexicalClass) { _, range in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }

        // If no sentences detected, split by periods
        if sentences.isEmpty {
            sentences = text.components(separatedBy: ". ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        // Return first N sentences
        let summary = sentences.prefix(maxSentences).joined(separator: ". ")
        return summary.hasSuffix(".") ? summary : summary + "."
    }

    // MARK: - Pattern Recognition

    /// Analyze patterns across multiple entries
    func analyzePatterns(entries: [JournalEntry]) -> PatternAnalysis {
        guard !entries.isEmpty else {
            return PatternAnalysis(
                dominantMood: nil,
                frequentThemes: [],
                writingStreak: 0,
                averageWordCount: 0,
                insights: []
            )
        }

        // Mood analysis
        let moods = entries.compactMap { $0.mood }
        let dominantMood = moods.isEmpty ? nil : moods.reduce(into: [:]) { counts, mood in
            counts[mood, default: 0] += 1
        }.max(by: { $0.value < $1.value })?.key

        // Theme analysis
        var allThemes: [String: Int] = [:]
        for entry in entries {
            for theme in entry.getAIThemes() {
                allThemes[theme, default: 0] += 1
            }
        }
        let frequentThemes = allThemes.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }

        // Writing streak
        let writingStreak = calculateWritingStreak(entries: entries)

        // Average word count
        let totalWords = entries.reduce(0) { $0 + $1.wordCount }
        let averageWordCount = entries.isEmpty ? 0 : totalWords / entries.count

        // Generate insights
        var insights: [String] = []

        if let mood = dominantMood {
            insights.append("Your dominant mood recently has been \(mood.displayName.lowercased()).")
        }

        if !frequentThemes.isEmpty {
            let themesString = frequentThemes.prefix(3).joined(separator: ", ")
            insights.append("Common themes in your writing: \(themesString).")
        }

        if writingStreak > 3 {
            insights.append("You've been journaling for \(writingStreak) days in a row!")
        }

        if averageWordCount > 200 {
            insights.append("Your entries are thoughtful and detailed, averaging \(averageWordCount) words.")
        }

        return PatternAnalysis(
            dominantMood: dominantMood,
            frequentThemes: frequentThemes,
            writingStreak: writingStreak,
            averageWordCount: averageWordCount,
            insights: insights
        )
    }

    private func calculateWritingStreak(entries: [JournalEntry]) -> Int {
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date > $1.date }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.date)

            if calendar.isDate(entryDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if entryDate < currentDate {
                break
            }
        }

        return streak
    }

    // MARK: - Processing Entry

    /// Process a journal entry with all AI features
    func processEntry(_ entry: JournalEntry) async {
        isProcessing = true
        defer { isProcessing = false }

        let text = entry.plainText
        guard !text.isEmpty else { return }

        // Analyze sentiment
        let sentiment = analyzeSentiment(text: text)
        entry.aiSentiment = sentiment.score

        // Suggest mood if not set
        if entry.mood == nil, let suggestedMood = suggestMood(from: sentiment) {
            entry.mood = suggestedMood
        }

        // Detect themes
        let themes = detectThemes(text: text)
        entry.setAIThemes(themes)

        // Generate summary
        if text.count > 200 {
            let summary = generateSummary(text: text)
            entry.aiSummary = summary
        }

        entry.aiProcessedAt = Date()
    }

    // MARK: - Common Words (to filter)

    private let commonWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
        "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
        "be", "have", "has", "had", "do", "does", "did", "will", "would",
        "could", "should", "may", "might", "must", "shall", "can", "need",
        "this", "that", "these", "those", "i", "you", "he", "she", "it",
        "we", "they", "what", "which", "who", "when", "where", "why", "how",
        "all", "each", "every", "both", "few", "more", "most", "other",
        "some", "such", "no", "not", "only", "own", "same", "so", "than",
        "too", "very", "just", "also", "now", "here", "there", "then"
    ]

    private let significantVerbs: Set<String> = [
        "achieve", "accomplish", "learn", "grow", "improve", "create",
        "build", "develop", "overcome", "succeed", "fail", "struggle",
        "feel", "think", "believe", "hope", "dream", "imagine",
        "love", "hate", "fear", "worry", "celebrate", "appreciate"
    ]
}

// MARK: - Supporting Types

struct SentimentResult {
    let score: Double
    let label: SentimentLabel
    let confidence: Double
}

enum SentimentLabel {
    case positive
    case negative
    case neutral
}

struct PatternAnalysis {
    let dominantMood: JournalMood?
    let frequentThemes: [String]
    let writingStreak: Int
    let averageWordCount: Int
    let insights: [String]
}
