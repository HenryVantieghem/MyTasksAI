//
//  CosmicWidgetDesignSystem.swift
//  MyTasksAI
//
//  "Cosmic Superpower" Design System
//  Dark Aurora Void + Apple Widget-Level Saturated Colors + iOS 26 Liquid Glass
//
//  Design Philosophy:
//  - Bold colors FLOAT on dark void backgrounds
//  - Each task category OWNS a distinct vibrant color
//  - Liquid Glass on NAVIGATION only (tab bars, floating buttons)
//  - Content layer uses SOLID dark with color accents
//

import SwiftUI

// MARK: - Cosmic Widget Design System

/// Unified design system blending dark cosmic void with Apple Widget-level saturated colors
enum CosmicWidget {

    // MARK: - Void Backgrounds (Dark Cosmic Aurora)

    /// Deep space backgrounds - keep the aurora aesthetic
    enum Void {
        /// Ultimate void - deepest background (RGB: 0.01, 0.01, 0.03)
        static let deepSpace = Color(red: 0.01, green: 0.01, blue: 0.03)

        /// Standard void - main app background (RGB: 0.02, 0.02, 0.04)
        static let cosmos = Color(red: 0.02, green: 0.02, blue: 0.04)

        /// Card surface - elevated over void (RGB: 0.04, 0.04, 0.06)
        static let nebula = Color(red: 0.04, green: 0.04, blue: 0.06)

        /// Elevated surfaces - modal backgrounds (RGB: 0.06, 0.06, 0.10)
        static let elevated = Color(red: 0.06, green: 0.06, blue: 0.10)

        /// Interactive surface - hover/active states (RGB: 0.08, 0.08, 0.12)
        static let interactive = Color(red: 0.08, green: 0.08, blue: 0.12)
    }

    // MARK: - Widget Colors (ULTRA SATURATED - Apple Widget Inspired)

    /// Bold, saturated colors that POP against the dark void
    enum Widget {
        /// Teal - Like Apple's "5 min" timer widget (SUPER BRIGHT)
        /// Use for: Work tasks, professional actions
        static let teal = Color(red: 0.0, green: 0.85, blue: 0.85)

        /// Electric Cyan - AI accent (ULTRA BRIGHT)
        /// Use for: AI features, focus mode, primary CTAs
        static let electricCyan = Color(red: 0.0, green: 0.95, blue: 1.0)
        
        /// Electric Cyan Gradient (for backgrounds)
        static var electricCyanGradient: LinearGradient {
            LinearGradient(
                colors: [electricCyan, Color(red: 0.0, green: 0.75, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Sunset Orange - Like Apple's photo widget (WARM)
        /// Use for: Personal tasks, warmth
        static let sunsetOrange = Color(red: 1.0, green: 0.55, blue: 0.20)

        /// Sunset Pink - Gradient companion to orange
        static let sunsetPink = Color(red: 1.0, green: 0.40, blue: 0.60)

        /// Violet - Like Apple's water tracker (VIBRANT)
        /// Use for: Learning, growth, premium features
        static let violet = Color(red: 0.70, green: 0.35, blue: 1.0)
        
        /// Violet Secondary - for backgrounds
        static let violetSecondary = Color(red: 0.58, green: 0.25, blue: 0.98)
        
        /// Violet Gradient (for backgrounds)
        static var violetGradient: LinearGradient {
            LinearGradient(
                colors: [violet, violetSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Magenta - Hot pink for creativity
        /// Use for: Creative tasks, celebrations
        static let magenta = Color(red: 1.0, green: 0.30, blue: 0.65)

        /// Mint - Like Apple's activity rings (FRESH GREEN)
        /// Use for: Health, wellness, success states
        static let mint = Color(red: 0.20, green: 1.0, blue: 0.70)

        /// Gold - Achievement color (WARM PREMIUM)
        /// Use for: Achievements, warnings, streaks
        static let gold = Color(red: 1.0, green: 0.80, blue: 0.25)

        /// Coral - Energetic action (VIBRANT RED-ORANGE)
        /// Use for: Urgent tasks, energy
        static let coral = Color(red: 1.0, green: 0.45, blue: 0.40)
    }

    // MARK: - Task Category Colors

    /// Each task category OWNS a distinct bold color
    enum Category {
        /// Work/Professional - Confident teal
        static let work = Widget.teal

        /// Personal/Life - Warm sunset orange
        static let personal = Widget.sunsetOrange

        /// Health/Wellness - Fresh mint green
        static let health = Widget.mint

        /// Learning/Growth - Vibrant violet
        static let learning = Widget.violet

        /// Creative/Projects - Hot magenta
        static let creative = Widget.magenta

        /// Focus/Deep Work - Electric cyan
        static let focus = Widget.electricCyan

        /// Urgent/Important - Energetic coral
        static let urgent = Widget.coral

        /// Get color for category name
        static func color(for category: String) -> Color {
            switch category.lowercased() {
            case "work", "professional", "career":
                return work
            case "personal", "life", "home":
                return personal
            case "health", "wellness", "fitness":
                return health
            case "learning", "study", "education", "growth":
                return learning
            case "creative", "project", "art":
                return creative
            case "focus", "deep work":
                return focus
            case "urgent", "important", "priority":
                return urgent
            default:
                return Widget.electricCyan // Default to AI accent
            }
        }
    }

    // MARK: - Semantic Colors

    /// Semantic meaning colors
    enum Semantic {
        static let success = Widget.mint
        static let warning = Widget.gold
        static let error = Color(red: 1.0, green: 0.35, blue: 0.40)
        static let info = Widget.electricCyan
        static let ai = Widget.electricCyan
        static let premium = Widget.violet
    }

    // MARK: - Text Colors

    /// Text colors on dark void backgrounds
    enum Text {
        /// Primary text - 95% white
        static let primary = Color.white.opacity(0.95)

        /// Secondary text - 70% white
        static let secondary = Color.white.opacity(0.70)

        /// Tertiary text - 50% white
        static let tertiary = Color.white.opacity(0.50)

        /// Disabled text - 30% white
        static let disabled = Color.white.opacity(0.30)

        /// Inverse text - for colored backgrounds
        static let inverse = Color.black.opacity(0.90)
    }

    // MARK: - Gradients

    /// Bold gradient presets
    enum Gradient {
        /// Primary AI gradient (Cyan → Violet)
        static var ai: LinearGradient {
            LinearGradient(
                colors: [Widget.electricCyan, Widget.violet],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Sunset gradient (Orange → Pink)
        static var sunset: LinearGradient {
            LinearGradient(
                colors: [Widget.sunsetOrange, Widget.sunsetPink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Success gradient (Mint → Teal)
        static var success: LinearGradient {
            LinearGradient(
                colors: [Widget.mint, Widget.teal],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        /// Premium gradient (Violet → Magenta)
        static var premium: LinearGradient {
            LinearGradient(
                colors: [Widget.violet, Widget.magenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Achievement gradient (Gold → Orange)
        static var achievement: LinearGradient {
            LinearGradient(
                colors: [Widget.gold, Widget.sunsetOrange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Category gradient for any color
        static func category(_ color: Color) -> LinearGradient {
            LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Typography

    /// Typography system with Apple Widget-style numbers
    enum Typography {
        // MARK: Display (Hero & Stats)

        /// Hero text - Ultra-thin for elegance (48pt)
        static let displayHero = Font.system(size: 48, weight: .ultraLight)

        /// Stat numbers - MASSIVE bold rounded (56pt)
        static let displayStat = Font.system(size: 56, weight: .black, design: .rounded)

        // MARK: Widget Numbers (Apple Widget Style)

        /// Widget primary number - HUGE (64pt)
        static let widgetNumber = Font.system(size: 64, weight: .black, design: .rounded)

        /// Widget secondary number - Large (48pt)
        static let widgetNumberMedium = Font.system(size: 48, weight: .bold, design: .rounded)

        /// Widget label - Small caps (13pt)
        static let widgetLabel = Font.system(size: 13, weight: .semibold)

        // MARK: Stat Numbers (Apple Widget Inspired)

        /// Large stat numbers - BOLD for cards (36pt)
        static let statLarge = Font.system(size: 36, weight: .bold, design: .rounded)

        /// Small stat numbers - For inline stats (24pt)
        static let statSmall = Font.system(size: 24, weight: .bold, design: .rounded)

        // MARK: Titles (Rounded Bold)

        /// Headline - Section headers (17pt)
        static let headline = Font.system(size: 17, weight: .semibold)

        /// Title 1 - Page titles (28pt)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)

        /// Title 2 - Section titles (22pt)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)

        /// Title 3 - Card titles (18pt)
        static let title3 = Font.system(size: 18, weight: .semibold, design: .rounded)

        // MARK: Body

        /// Body regular (16pt)
        static let body = Font.system(size: 16, weight: .regular)

        /// Body bold (16pt)
        static let bodyBold = Font.system(size: 16, weight: .semibold)

        /// Callout (15pt)
        static let callout = Font.system(size: 15, weight: .regular)

        // MARK: Supporting

        /// Caption (13pt)
        static let caption = Font.system(size: 13, weight: .medium)

        /// Caption medium (13pt semibold)
        static let captionMedium = Font.system(size: 13, weight: .semibold)

        /// Caption 2 (11pt)
        static let caption2 = Font.system(size: 11, weight: .regular)
        
        /// Meta text - small metadata labels (11pt)
        static let meta = Font.system(size: 11, weight: .medium)

        // MARK: Special

        /// AI whisper - Distinctive serif italic (14pt)
        static let aiWhisper = Font.system(size: 14, weight: .regular, design: .serif).italic()

        /// Code/monospace (13pt)
        static let code = Font.system(size: 13, weight: .regular, design: .monospaced)

        /// Tab label (10pt)
        static let tabLabel = Font.system(size: 10, weight: .medium, design: .rounded)
    }

    // MARK: - Spacing (8pt Grid)

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48

        // Semantic
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let relaxed: CGFloat = 20
        static let formField: CGFloat = 16
        static let comfortable: CGFloat = 20
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let large: CGFloat = 16  // Alias for lg
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999

        // Semantic
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let input: CGFloat = 12
        static let pill: CGFloat = 9999
    }

    // MARK: - Category Color Bar Width

    /// Width of the category color bar on task cards
    static let categoryBarWidth: CGFloat = 4
}

// MARK: - View Extensions

extension View {

    // MARK: - Content Layer (Solid Dark - NO GLASS)

    /// Apply solid void card background with optional category color bar
    func cosmicCard(
        category: Color? = nil,
        cornerRadius: CGFloat = CosmicWidget.Radius.card
    ) -> some View {
        self
            .padding(CosmicWidget.Spacing.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(CosmicWidget.Void.nebula)
            }
            .overlay(alignment: .leading) {
                if let category = category {
                    // Category color bar on left edge
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: cornerRadius,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                    .fill(category)
                    .frame(width: CosmicWidget.categoryBarWidth)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Apply category glow halo effect
    func cosmicGlow(
        color: Color,
        radius: CGFloat = 16,
        intensity: Double = 0.35
    ) -> some View {
        self.shadow(color: color.opacity(intensity), radius: radius, x: 0, y: 0)
    }

    /// Apply AI glow (electric cyan)
    func aiGlow(
        radius: CGFloat = 20,
        intensity: Double = 0.4
    ) -> some View {
        self.cosmicGlow(color: CosmicWidget.Widget.electricCyan, radius: radius, intensity: intensity)
    }

    /// Screen padding
    func cosmicScreenPadding() -> some View {
        self.padding(.horizontal, CosmicWidget.Spacing.screenPadding)
    }
}

// MARK: - Color Extensions

extension Color {
    /// Create gradient from this color
    func cosmicGradient(to endColor: Color? = nil) -> LinearGradient {
        LinearGradient(
            colors: [self, endColor ?? self.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview("Cosmic Widget Colors") {
    ScrollView {
        VStack(spacing: 24) {
            // Widget Colors
            Text("Widget Colors")
                .font(CosmicWidget.Typography.title2)
                .foregroundStyle(CosmicWidget.Text.primary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                colorSwatch("Teal", CosmicWidget.Widget.teal)
                colorSwatch("Cyan", CosmicWidget.Widget.electricCyan)
                colorSwatch("Orange", CosmicWidget.Widget.sunsetOrange)
                colorSwatch("Violet", CosmicWidget.Widget.violet)
                colorSwatch("Magenta", CosmicWidget.Widget.magenta)
                colorSwatch("Mint", CosmicWidget.Widget.mint)
                colorSwatch("Gold", CosmicWidget.Widget.gold)
            }

            // Category Cards
            Text("Category Cards")
                .font(CosmicWidget.Typography.title2)
                .foregroundStyle(CosmicWidget.Text.primary)

            VStack(spacing: 12) {
                taskCardPreview("Work Task", CosmicWidget.Category.work)
                taskCardPreview("Personal Task", CosmicWidget.Category.personal)
                taskCardPreview("Health Task", CosmicWidget.Category.health)
                taskCardPreview("Learning Task", CosmicWidget.Category.learning)
            }

            // Widget Numbers
            Text("Widget Numbers")
                .font(CosmicWidget.Typography.title2)
                .foregroundStyle(CosmicWidget.Text.primary)

            HStack(spacing: 24) {
                statCard("7", "Day Streak", CosmicWidget.Widget.coral)
                statCard("24", "Tasks Done", CosmicWidget.Widget.teal)
                statCard("3h", "Focus Time", CosmicWidget.Widget.violet)
            }
        }
        .padding(24)
    }
    .background(CosmicWidget.Void.cosmos)
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 6) {
        Circle()
            .fill(color)
            .frame(width: 50, height: 50)
            .shadow(color: color.opacity(0.5), radius: 10)
        Text(name)
            .font(.caption2)
            .foregroundStyle(Color.white.opacity(0.7))
    }
}

private func taskCardPreview(_ title: String, _ category: Color) -> some View {
    HStack(spacing: 12) {
        Circle()
            .stroke(category, lineWidth: 2)
            .frame(width: 24, height: 24)

        Text(title)
            .font(CosmicWidget.Typography.bodyBold)
            .foregroundStyle(CosmicWidget.Text.primary)

        Spacer()
    }
    .cosmicCard(category: category)
    .cosmicGlow(color: category, radius: 12, intensity: 0.25)
}

private func statCard(_ number: String, _ label: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
        Text(number)
            .font(CosmicWidget.Typography.widgetNumberMedium)
            .foregroundStyle(color)
        Text(label)
            .font(CosmicWidget.Typography.widgetLabel)
            .foregroundStyle(CosmicWidget.Text.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(CosmicWidget.Void.nebula)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .cosmicGlow(color: color, radius: 16, intensity: 0.3)
}
