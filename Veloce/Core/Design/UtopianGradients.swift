import SwiftUI

// MARK: - Utopian Gradient System
// Time-aware mesh gradients for background layer
// 5 zones: Dawn, Noon, Dusk, Night, Achievement

struct UtopianGradients {

    // MARK: - Time-Based Background Selection
    static func background(for date: Date = Date()) -> LinearGradient {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11:  return dawn    // Morning warmth (5am-11am)
        case 11..<15: return noon    // Peak productivity (11am-3pm)
        case 15..<20: return dusk    // Creative energy (3pm-8pm)
        default:      return night   // Deep focus (8pm-5am)
        }
    }

    // MARK: - Gradient Zone
    enum GradientZone: String, CaseIterable {
        case dawn = "Dawn"
        case noon = "Noon"
        case dusk = "Dusk"
        case night = "Night"
        case achievement = "Achievement"

        static func current(for date: Date = Date()) -> GradientZone {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<11:  return .dawn
            case 11..<15: return .noon
            case 15..<20: return .dusk
            default:      return .night
            }
        }

        var gradient: LinearGradient {
            switch self {
            case .dawn: return UtopianGradients.dawn
            case .noon: return UtopianGradients.noon
            case .dusk: return UtopianGradients.dusk
            case .night: return UtopianGradients.night
            case .achievement: return UtopianGradients.achievementLinear
            }
        }

        var description: String {
            switch self {
            case .dawn: return "Good morning! Start your day strong."
            case .noon: return "Peak productivity hours. Let's focus!"
            case .dusk: return "Wind down time. Finish strong."
            case .night: return "Deep focus mode. Minimize distractions."
            case .achievement: return "Celebration time!"
            }
        }
    }

    // MARK: - DAWN (5am-11am) - Warm, energizing start
    static let dawn = LinearGradient(
        colors: [
            Color(hex: "#FF6B9D"),  // Warm rose
            Color(hex: "#FF9B71"),  // Soft orange
            Color(hex: "#FFC145")   // Gold
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dawnColors: [Color] = [
        Color(hex: "#FF6B9D"),
        Color(hex: "#FF9B71"),
        Color(hex: "#FFC145")
    ]

    // MARK: - NOON (11am-3pm) - Peak productivity
    static let noon = LinearGradient(
        colors: [
            Color(hex: "#00D9FF"),  // Vibrant cyan
            Color(hex: "#5B7FFF"),  // Electric blue
            Color(hex: "#7C3AED")   // Purple
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let noonColors: [Color] = [
        Color(hex: "#00D9FF"),
        Color(hex: "#5B7FFF"),
        Color(hex: "#7C3AED")
    ]

    // MARK: - DUSK (3pm-8pm) - Creative energy
    static let dusk = LinearGradient(
        colors: [
            Color(hex: "#7C3AED"),  // Purple
            Color(hex: "#FF3CAC"),  // Magenta
            Color(hex: "#FF6B6B")   // Coral
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let duskColors: [Color] = [
        Color(hex: "#7C3AED"),
        Color(hex: "#FF3CAC"),
        Color(hex: "#FF6B6B")
    ]

    // MARK: - NIGHT (8pm-5am) - Deep focus
    static let night = LinearGradient(
        colors: [
            Color(hex: "#2D1B69"),  // Deep indigo
            Color(hex: "#5B21B6"),  // Violet
            Color(hex: "#1A1A2E")   // Midnight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let nightColors: [Color] = [
        Color(hex: "#2D1B69"),
        Color(hex: "#5B21B6"),
        Color(hex: "#1A1A2E")
    ]

    // MARK: - ACHIEVEMENT - Rainbow celebration burst
    static let achievement = AngularGradient(
        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
        center: .center
    )

    static let achievementLinear = LinearGradient(
        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let achievementColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple
    ]

    // MARK: - Mesh Gradient (for richer backgrounds)
    @available(iOS 18.0, *)
    static func meshBackground(for zone: GradientZone) -> MeshGradient {
        let colors: [Color]
        switch zone {
        case .dawn:
            colors = dawnColors + [Color(hex: "#FFE4C4")]
        case .noon:
            colors = noonColors + [Color(hex: "#E0E7FF")]
        case .dusk:
            colors = duskColors + [Color(hex: "#FED7AA")]
        case .night:
            colors = nightColors + [Color(hex: "#0F0F23")]
        case .achievement:
            colors = achievementColors + [Color.white, Color.white]
        }

        // 3x3 mesh grid
        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                colors[0], colors[1], colors[2],
                colors[1], colors[0], colors[1],
                colors[2], colors[1], colors[0]
            ]
        )
    }

    // MARK: - Focus Mode Gradient (always night for focus)
    static let focusMode = night

    // MARK: - Gradient for Task Types
    enum TaskTypeGradient {
        case create      // Purple - creative tasks
        case communicate // Blue - communication tasks
        case consume     // Teal - learning/reading
        case coordinate  // Gold - planning/organizing

        var gradient: LinearGradient {
            switch self {
            case .create:
                return LinearGradient(
                    colors: [Color(hex: "#7C3AED"), Color(hex: "#A78BFA")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .communicate:
                return LinearGradient(
                    colors: [Color(hex: "#3B82F6"), Color(hex: "#60A5FA")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .consume:
                return LinearGradient(
                    colors: [Color(hex: "#14B8A6"), Color(hex: "#2DD4BF")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .coordinate:
                return LinearGradient(
                    colors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }

        var primaryColor: Color {
            switch self {
            case .create: return Color(hex: "#7C3AED")
            case .communicate: return Color(hex: "#3B82F6")
            case .consume: return Color(hex: "#14B8A6")
            case .coordinate: return Color(hex: "#F59E0B")
            }
        }
    }
}

// MARK: - Gradient Background View
struct UtopianGradientBackground: View {
    @State private var currentZone: UtopianGradients.GradientZone = .current()
    @State private var animateGradient = false

    var body: some View {
        currentZone.gradient
            .hueRotation(.degrees(animateGradient ? 10 : 0))
            .animation(
                Animation.easeInOut(duration: 8).repeatForever(autoreverses: true),
                value: animateGradient
            )
            .ignoresSafeArea()
            .onAppear {
                animateGradient = true
                startTimeCheck()
            }
    }

    private func startTimeCheck() {
        // Check every minute for time zone changes
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let newZone = UtopianGradients.GradientZone.current()
            if newZone != currentZone {
                withAnimation(.easeInOut(duration: 2)) {
                    currentZone = newZone
                }
            }
        }
    }
}

// MARK: - Static Gradient Background (no animation)
struct StaticGradientBackground: View {
    let zone: UtopianGradients.GradientZone

    init(_ zone: UtopianGradients.GradientZone = .current()) {
        self.zone = zone
    }

    var body: some View {
        zone.gradient
            .ignoresSafeArea()
    }
}

// MARK: - Achievement Celebration Background
struct AchievementBackground: View {
    @State private var rotation: Double = 0

    var body: some View {
        UtopianGradients.achievement
            .rotationEffect(.degrees(rotation))
            .animation(
                Animation.linear(duration: 4).repeatForever(autoreverses: false),
                value: rotation
            )
            .ignoresSafeArea()
            .onAppear {
                rotation = 360
            }
    }
}

#Preview("Dawn") {
    StaticGradientBackground(.dawn)
}

#Preview("Noon") {
    StaticGradientBackground(.noon)
}

#Preview("Dusk") {
    StaticGradientBackground(.dusk)
}

#Preview("Night") {
    StaticGradientBackground(.night)
}

#Preview("Achievement") {
    AchievementBackground()
}
