import SwiftUI

// MARK: - Utopian Design System
// Master design tokens for MyTasksAI
// Replaces: Theme.swift, VeloceDesignSystem, VoidDesignSystem, Aurora/*, LivingCosmosTokens
// Target: ~200 lines (down from 7,800+ lines of chaos)

@available(iOS 26.0, *)
struct UtopianDesign {

    // MARK: - Typography Scale (8 styles only)
    struct Typography {
        // Display
        static let display = Font.system(size: 34, weight: .bold)

        // Titles
        static let titleLarge = Font.system(size: 22, weight: .bold)
        static let titleMedium = Font.system(size: 17, weight: .semibold)
        static let titleSmall = Font.system(size: 15, weight: .semibold)

        // Body
        static let body = Font.system(size: 17, weight: .regular)
        static let bodySmall = Font.system(size: 15, weight: .regular)

        // Caption
        static let caption = Font.system(size: 13, weight: .regular)
        static let captionSmall = Font.system(size: 11, weight: .medium)
    }

    // MARK: - Spacing Scale (8pt Grid)
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius (3 values only)
    struct Radius {
        static let sm: CGFloat = 8    // Small elements (chips, badges)
        static let md: CGFloat = 12   // Cards, buttons
        static let lg: CGFloat = 20   // Sheets, large containers
    }

    // MARK: - Semantic Colors
    struct Colors {
        // Gamification - GOLD theme (consistent across app)
        static let xpGold = Color(hex: "#FFD700")
        static let starGold = Color(hex: "#FFC145")
        static let streakFire = Color(hex: "#FF6B35")

        // Status - Clear semantic meaning
        static let completed = Color(hex: "#10B981")    // Green = done
        static let inProgress = Color(hex: "#7C3AED")   // Purple = active
        static let overdue = Color(hex: "#EF4444")      // Red = urgent
        static let scheduled = Color(hex: "#5B7FFF")    // Blue = planned

        // Focus Mode
        static let focusActive = Color(hex: "#00D9FF")  // Cyan ring = focusing
        static let focusPaused = Color(hex: "#F59E0B")  // Amber = paused

        // Text (for glass cards over gradients)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)

        // Backgrounds (for content layer - solid, not glass)
        static let cardBackground = Color.white.opacity(0.1)
        static let cardBackgroundElevated = Color.white.opacity(0.15)
    }

    // MARK: - Gamification Tokens
    struct Gamification {
        // XP System
        static let xpPerTask = 25
        static let xpPerStreak = 50
        static let xpPerGoal = 100

        // Star Rating Logic:
        // ★ = Task completed
        // ★★ = Completed on time
        // ★★★ = Completed early + notes added

        // Velocity Tiers
        enum VelocityTier: String {
            case warmingUp = "Warming Up"   // 0-20
            case cruising = "Cruising"       // 21-50
            case flying = "Flying"           // 51-80
            case onFire = "On Fire"          // 81-100

            static func tier(for score: Int) -> VelocityTier {
                switch score {
                case 0..<21: return .warmingUp
                case 21..<51: return .cruising
                case 51..<81: return .flying
                default: return .onFire
                }
            }

            var color: Color {
                switch self {
                case .warmingUp: return Color(hex: "#7C3AED")
                case .cruising: return Color(hex: "#5B7FFF")
                case .flying: return Color(hex: "#00D9FF")
                case .onFire: return Color(hex: "#FFD700")
                }
            }
        }

        // Visual tokens
        static let starSize: CGFloat = 16
        static let xpBadgeRadius: CGFloat = 8
        static let velocityRingWidth: CGFloat = 8
    }

    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let slow = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers for Consistent Styling
@available(iOS 26.0, *)
extension View {
    // Standard card styling (solid background for content layer)
    func utopianCard() -> some View {
        self
            .padding(UtopianDesign.Spacing.md)
            .background(UtopianDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: UtopianDesign.Radius.md))
    }

    // Elevated card styling
    func utopianCardElevated() -> some View {
        self
            .padding(UtopianDesign.Spacing.md)
            .background(UtopianDesign.Colors.cardBackgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: UtopianDesign.Radius.md))
    }
}

// MARK: - Fallback for pre-iOS 26
struct UtopianDesignFallback {
    // Same tokens, available on all iOS versions
    struct Typography {
        static let display = Font.system(size: 34, weight: .bold)
        static let titleLarge = Font.system(size: 22, weight: .bold)
        static let titleMedium = Font.system(size: 17, weight: .semibold)
        static let titleSmall = Font.system(size: 15, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let bodySmall = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        static let captionSmall = Font.system(size: 11, weight: .medium)
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
    }
}
