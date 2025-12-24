//
//  TiimoDesignTokens.swift
//  Veloce
//
//  Tiimo-Inspired Visual Planner Design System
//  Vertical timeline with calming, ADHD-friendly design
//

import SwiftUI

// MARK: - Tiimo Design Tokens

/// Design constants for the Tiimo-style vertical visual planner
enum TiimoDesignTokens {

    // MARK: - Timeline Configuration
    enum Timeline {
        /// Height of each hour block in the vertical timeline
        static let hourHeight: CGFloat = 80
        /// Compact hour height for week view
        static let compactHourHeight: CGFloat = 50
        /// Width of the time label gutter on the left
        static let timeGutterWidth: CGFloat = 50
        /// Start hour of the day view (6 AM)
        static let startHour: Int = 6
        /// End hour of the day view (11 PM)
        static let endHour: Int = 23
        /// Snap interval for drag-and-drop (15 minutes)
        static let snapIntervalMinutes: Int = 15
        /// Padding between blocks and edge
        static let blockInset: CGFloat = 12
        /// Total number of hours displayed
        static var totalHours: Int { endHour - startHour }
        /// Total height of the scrollable area
        static var totalHeight: CGFloat { CGFloat(totalHours) * hourHeight }
    }

    // MARK: - Block Sizing
    enum Block {
        /// Corner radius for task blocks
        static let cornerRadius: CGFloat = 16
        /// Minimum height for short duration tasks
        static let minHeight: CGFloat = 44
        /// Icon container size
        static let iconSize: CGFloat = 32
        /// Internal padding
        static let padding: CGFloat = 12
        /// Space between stacked blocks
        static let stackSpacing: CGFloat = 4
    }

    // MARK: - Date Carousel
    enum DateCarousel {
        /// Width of each date pill
        static let pillWidth: CGFloat = 52
        /// Height of each date pill
        static let pillHeight: CGFloat = 70
        /// Corner radius for pills
        static let pillCornerRadius: CGFloat = 14
        /// Spacing between pills
        static let spacing: CGFloat = 8
        /// Total carousel height
        static let height: CGFloat = 80
        /// Days before today to show
        static let daysBefore: Int = 7
        /// Days after today to show
        static let daysAfter: Int = 14
    }

    // MARK: - Week View
    enum WeekView {
        /// Width of each day column
        static let dayWidth: CGFloat = 90
        /// Height of the day header row
        static let headerHeight: CGFloat = 60
        /// Hour height in week view
        static let hourHeight: CGFloat = 50
        /// Time gutter width
        static let timeGutterWidth: CGFloat = 44
    }

    // MARK: - Month View
    enum MonthView {
        /// Height of day cells
        static let cellHeight: CGFloat = 48
        /// Spacing between cells
        static let cellSpacing: CGFloat = 4
    }

    // MARK: - Current Time Indicator
    enum NowIndicator {
        /// Diameter of the pulsing dot
        static let dotSize: CGFloat = 10
        /// Outer glow diameter
        static let glowSize: CGFloat = 20
        /// Line height
        static let lineHeight: CGFloat = 2
    }

    // MARK: - Gentle Reminders (No Guilt Language)
    /// Tiimo-inspired gentle, non-anxiety-inducing copy
    enum GentleLanguage {
        /// Instead of "OVERDUE" - used when time has passed
        static let pastTime = "Earlier today"
        /// Friendly nudge for pending tasks
        static let gentleNudge = "Ready when you are"
        /// Prompt to move task
        static let reschedulePrompt = "Want to move this?"
        /// Completion encouragement
        static let completedMessage = "Nice work!"
        /// No tasks scheduled
        static let emptyDay = "A clear day ahead"
        /// Greeting for empty state
        static let emptyDaySubtitle = "Drag tasks here or tap + to plan"
    }

    // MARK: - Task Type Colors (Using existing theme)
    /// Maps TaskType to colors from the existing design system
    enum TaskColors {
        static let create = Theme.TaskCardColors.create
        static let communicate = Theme.TaskCardColors.communicate
        static let consume = Theme.TaskCardColors.consume
        static let coordinate = Theme.TaskCardColors.coordinate

        /// Get color for a task type string
        static func color(for taskType: String?) -> Color {
            guard let type = taskType?.lowercased() else { return coordinate }
            switch type {
            case "create": return create
            case "communicate": return communicate
            case "consume": return consume
            case "coordinate": return coordinate
            default: return coordinate
            }
        }
    }

    // MARK: - Calming Palette (Low Dopamine Design)
    /// Soft, calming colors for reduced anxiety
    enum CalmColors {
        static let softPurple = Color(red: 0.65, green: 0.55, blue: 0.85)
        static let softBlue = Color(red: 0.55, green: 0.70, blue: 0.90)
        static let softCyan = Color(red: 0.50, green: 0.80, blue: 0.85)
        static let softGreen = Color(red: 0.55, green: 0.80, blue: 0.65)
        static let softOrange = Color(red: 0.90, green: 0.70, blue: 0.50)
        static let softPink = Color(red: 0.85, green: 0.60, blue: 0.70)
    }

    // MARK: - Icon Categories (SF Symbols)
    /// Curated SF Symbols for task personalization
    enum IconCategories {
        static let productivity: [String] = [
            "checkmark.circle", "star.fill", "flag.fill", "bookmark.fill",
            "doc.text", "folder", "tray.full", "archivebox"
        ]

        static let communication: [String] = [
            "envelope", "phone", "video", "message",
            "bubble.left", "person.2", "hand.wave", "megaphone"
        ]

        static let creative: [String] = [
            "paintbrush", "pencil", "doc.on.doc", "scissors",
            "camera", "photo", "music.note", "wand.and.stars"
        ]

        static let learning: [String] = [
            "book", "graduationcap", "lightbulb", "brain",
            "text.book.closed", "doc.richtext", "newspaper", "globe"
        ]

        static let wellness: [String] = [
            "figure.walk", "heart", "leaf", "sun.max",
            "moon", "cup.and.saucer", "bed.double", "lungs"
        ]

        static let errands: [String] = [
            "cart", "creditcard", "bag", "gift",
            "house", "car", "airplane", "mappin"
        ]

        static let time: [String] = [
            "calendar", "clock", "timer", "alarm",
            "hourglass", "stopwatch", "bell", "bell.badge"
        ]

        static let entertainment: [String] = [
            "gamecontroller", "tv", "film", "popcorn",
            "headphones", "guitars", "ticket", "party.popper"
        ]

        /// All icons flattened
        static var all: [String] {
            productivity + communication + creative + learning +
            wellness + errands + time + entertainment
        }
    }

    // MARK: - Popular Emojis
    enum EmojiCategories {
        static let productivity: [String] = ["📝", "✅", "⭐", "🔥", "💡", "🎯"]
        static let communication: [String] = ["📧", "📞", "💬", "🤝", "👋", "💼"]
        static let creative: [String] = ["🎨", "✏️", "📸", "🎬", "🎵", "🎮"]
        static let learning: [String] = ["📚", "🧠", "💻", "🔬", "📊", "📈"]
        static let wellness: [String] = ["🏃", "🧘", "💪", "❤️", "🌱", "☀️"]
        static let errands: [String] = ["🛒", "💳", "🎁", "🏠", "🚗", "✈️"]
        static let time: [String] = ["📅", "⏰", "🔔", "📌", "🏆", "🎉"]
        static let food: [String] = ["🍎", "☕", "🍽️", "💊", "🧹", "🛠️"]

        /// All emojis flattened
        static var all: [String] {
            productivity + communication + creative + learning +
            wellness + errands + time + food
        }
    }

    // MARK: - Animation Timing
    enum Animation {
        /// Spring for view transitions
        static let viewTransition = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        /// Spring for button presses
        static let buttonPress = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.7)
        /// Spring for drag and drop
        static let dragDrop = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        /// Breathing pulse for NOW indicator
        static let breathingPulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        /// Scroll animation duration
        static let scrollDuration: Double = 0.5
    }
}

// MARK: - TaskType Color Extension

extension TaskType {
    /// Color for this task type (Tiimo palette)
    var tiimoColor: Color {
        switch self {
        case .create: return TiimoDesignTokens.TaskColors.create
        case .communicate: return TiimoDesignTokens.TaskColors.communicate
        case .consume: return TiimoDesignTokens.TaskColors.consume
        case .coordinate: return TiimoDesignTokens.TaskColors.coordinate
        }
    }

    /// Default SF Symbol icon for this task type
    var defaultIcon: String {
        switch self {
        case .create: return "paintbrush.fill"
        case .communicate: return "bubble.left.fill"
        case .consume: return "book.fill"
        case .coordinate: return "person.2.fill"
        }
    }
}
