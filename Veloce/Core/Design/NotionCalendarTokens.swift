//
//  NotionCalendarTokens.swift
//  Veloce
//
//  Notion Calendar-Inspired Design Tokens
//  Clean, modern, minimal aesthetic with generous whitespace
//

import SwiftUI

// MARK: - Notion Calendar Design Tokens

enum NotionCalendarTokens {

    // MARK: - Timeline

    enum Timeline {
        /// Height of each hour slot in day view
        static let hourHeight: CGFloat = 72

        /// Width of the time gutter (hour labels)
        static let timeGutterWidth: CGFloat = 48

        /// First visible hour (6 AM)
        static let startHour: Int = 6

        /// Last visible hour (11 PM)
        static let endHour: Int = 23

        /// Grid line opacity (whisper thin)
        static let gridLineOpacity: Double = 0.06

        /// Grid line width
        static let gridLineWidth: CGFloat = 0.5

        /// Snap interval for drag operations (15 min)
        static let snapIntervalMinutes: Int = 15

        /// Total scrollable height
        static var totalHeight: CGFloat {
            CGFloat(endHour - startHour) * hourHeight
        }

        /// Inset for event blocks from edges
        static let blockInset: CGFloat = 4
    }

    // MARK: - Event Block

    enum EventBlock {
        /// Minimum height for event blocks
        static let minHeight: CGFloat = 36

        /// Corner radius
        static let cornerRadius: CGFloat = 10

        /// Left color bar width (for tasks)
        static let colorBarWidth: CGFloat = 3

        /// Internal padding
        static let padding: CGFloat = 10

        /// Horizontal padding between blocks
        static let horizontalSpacing: CGFloat = 4

        /// Pressed scale
        static let pressedScale: CGFloat = 0.98

        /// Shadow radius
        static let shadowRadius: CGFloat = 6
    }

    // MARK: - Header

    enum Header {
        /// Header height
        static let height: CGFloat = 56

        /// Month/year font size
        static let monthYearFontSize: CGFloat = 26

        /// Today button padding
        static let todayButtonPadding: CGFloat = 14

        /// Toggle button padding
        static let togglePadding: CGFloat = 12
    }

    // MARK: - Week View

    enum WeekView {
        /// Day header height
        static let headerHeight: CGFloat = 64

        /// Compact hour height
        static let hourHeight: CGFloat = 40

        /// Minimum day column width
        static let dayColumnMinWidth: CGFloat = 44

        /// Event capsule height
        static let eventCapsuleHeight: CGFloat = 20

        /// Maximum visible events per hour
        static let maxVisibleEvents: Int = 3
    }

    // MARK: - Month View

    enum MonthView {
        /// Cell size
        static let cellSize: CGFloat = 44

        /// Cell height (includes room for dots)
        static let cellHeight: CGFloat = 56

        /// Cell spacing
        static let cellSpacing: CGFloat = 4

        /// Event dot size
        static let dotSize: CGFloat = 5

        /// Selected circle size
        static let selectedCircleSize: CGFloat = 36

        /// Today ring width
        static let todayRingWidth: CGFloat = 2

        /// Maximum event dots shown
        static let maxDots: Int = 3
    }

    // MARK: - Now Indicator

    enum NowIndicator {
        /// Dot size
        static let dotSize: CGFloat = 10

        /// Line height
        static let lineHeight: CGFloat = 1.5

        /// Glow radius
        static let glowRadius: CGFloat = 8

        /// Label font size
        static let labelFontSize: CGFloat = 9
    }

    // MARK: - Animations

    enum Animation {
        /// Day swipe transition
        static let daySwipe = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.85)

        /// View mode change
        static let viewModeChange = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.75)

        /// Block press feedback
        static let blockPress = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.7)

        /// Now indicator pulse
        static let nowPulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)

        /// Quick interaction
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)

        /// Scroll to now
        static let scrollToNow = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }

    // MARK: - Typography

    enum Typography {
        /// Month/Year header
        static let monthYear = Font.system(size: 26, weight: .bold)

        /// Today button
        static let todayButton = Font.system(size: 14, weight: .semibold)

        /// View toggle
        static let viewToggle = Font.system(size: 13, weight: .medium)

        /// Hour labels
        static let hourLabel = Font.system(size: 11, weight: .regular, design: .monospaced)

        /// Day of week header
        static let dayOfWeek = Font.system(size: 12, weight: .medium)

        /// Date number (large)
        static let dateNumberLarge = Font.system(size: 24, weight: .semibold)

        /// Date number (normal)
        static let dateNumber = Font.system(size: 18, weight: .regular)

        /// Event title
        static let eventTitle = Font.system(size: 13, weight: .medium)

        /// Event time
        static let eventTime = Font.system(size: 11, weight: .regular, design: .monospaced)

        /// Now label
        static let nowLabel = Font.system(size: 9, weight: .bold)
    }

    // MARK: - Colors

    enum Colors {
        /// Grid line color
        static let gridLine = Color.white.opacity(0.06)

        /// Hour label color
        static let hourLabel = Color.white.opacity(0.4)

        /// Secondary text
        static let secondaryText = Color.white.opacity(0.6)

        /// Today highlight background
        static let todayHighlight = Theme.Colors.aiPurple.opacity(0.08)

        /// Selected date background
        static let selectedDate = LinearGradient(
            colors: [Theme.Colors.aiPurple.opacity(0.7), Theme.Colors.aiBlue.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Now indicator
        static let nowIndicator = Theme.Colors.aiCyan

        /// Apple Calendar event default
        static let appleEventDefault = Theme.Colors.aiBlue
    }

    // MARK: - Spacing

    enum Spacing {
        /// Screen horizontal padding
        static let screenPadding: CGFloat = 16

        /// Section spacing
        static let sectionSpacing: CGFloat = 16

        /// Component spacing
        static let componentSpacing: CGFloat = 12

        /// Tight spacing
        static let tight: CGFloat = 8
    }
}
