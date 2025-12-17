//
//  PaperBackground.swift
//  MyTasksAI
//
//  Paper-style Background Effects
//  Subtle textures and paper-like backgrounds
//

import SwiftUI

// MARK: - Paper Background
struct PaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Base color
            Theme.Colors.background

            // Paper texture overlay
            GeometryReader { geometry in
                Canvas { context, size in
                    // Create subtle noise pattern
                    for _ in 0..<200 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let opacity = Double.random(in: 0.01...0.03)

                        let color = colorScheme == .dark ?
                            Color.white.opacity(opacity) :
                            Color.black.opacity(opacity)

                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                            with: .color(color)
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Lined Paper Background
struct LinedPaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let lineSpacing: CGFloat
    let marginLine: Bool

    init(lineSpacing: CGFloat = 28, marginLine: Bool = false) {
        self.lineSpacing = lineSpacing
        self.marginLine = marginLine
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Paper base
                Theme.Colors.background

                // Horizontal lines
                Path { path in
                    var y: CGFloat = lineSpacing
                    while y < geometry.size.height {
                        path.move(to: CGPoint(x: marginLine ? 60 : 20, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width - 20, y: y))
                        y += lineSpacing
                    }
                }
                .stroke(
                    colorScheme == .dark ?
                        Color.gray.opacity(0.15) :
                        Color.blue.opacity(0.1),
                    lineWidth: 0.5
                )

                // Margin line
                if marginLine {
                    Path { path in
                        path.move(to: CGPoint(x: 60, y: 0))
                        path.addLine(to: CGPoint(x: 60, y: geometry.size.height))
                    }
                    .stroke(
                        Color.red.opacity(0.2),
                        lineWidth: 1
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Grid Paper Background
struct GridPaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let gridSize: CGFloat

    init(gridSize: CGFloat = 20) {
        self.gridSize = gridSize
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.Colors.background

                // Grid pattern
                Path { path in
                    // Vertical lines
                    var x: CGFloat = gridSize
                    while x < geometry.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        x += gridSize
                    }

                    // Horizontal lines
                    var y: CGFloat = gridSize
                    while y < geometry.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        y += gridSize
                    }
                }
                .stroke(
                    colorScheme == .dark ?
                        Color.gray.opacity(0.1) :
                        Color.gray.opacity(0.15),
                    lineWidth: 0.5
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Dot Grid Background
struct DotGridBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let spacing: CGFloat
    let dotSize: CGFloat

    init(spacing: CGFloat = 20, dotSize: CGFloat = 2) {
        self.spacing = spacing
        self.dotSize = dotSize
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.Colors.background

                Canvas { context, size in
                    let color = colorScheme == .dark ?
                        Color.gray.opacity(0.2) :
                        Color.gray.opacity(0.3)

                    var x: CGFloat = spacing
                    while x < size.width {
                        var y: CGFloat = spacing
                        while y < size.height {
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: x - dotSize/2,
                                    y: y - dotSize/2,
                                    width: dotSize,
                                    height: dotSize
                                )),
                                with: .color(color)
                            )
                            y += spacing
                        }
                        x += spacing
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Gradient Background
struct GradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let style: GradientStyle

    enum GradientStyle {
        case subtle
        case warm
        case cool
        case ai

        var colors: [Color] {
            switch self {
            case .subtle:
                return [
                    Theme.Colors.background,
                    Theme.Colors.backgroundSecondary
                ]
            case .warm:
                return [
                    Color(red: 1.0, green: 0.95, blue: 0.9),
                    Color(red: 1.0, green: 0.9, blue: 0.85)
                ]
            case .cool:
                return [
                    Color(red: 0.9, green: 0.95, blue: 1.0),
                    Color(red: 0.85, green: 0.9, blue: 1.0)
                ]
            case .ai:
                return [
                    Theme.Colors.aiPurple.opacity(0.1),
                    Theme.Colors.aiBlue.opacity(0.05),
                    Theme.Colors.background
                ]
            }
        }
    }

    var body: some View {
        LinearGradient(
            colors: style.colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Background Modifier
struct BackgroundStyleModifier: ViewModifier {
    let style: BackgroundStyle

    enum BackgroundStyle {
        case plain
        case paper
        case lined
        case grid
        case dots
        case gradient
        case iridescent
    }

    func body(content: Content) -> some View {
        content
            .background {
                switch style {
                case .plain:
                    Theme.Colors.background
                case .paper:
                    PaperBackground()
                case .lined:
                    LinedPaperBackground()
                case .grid:
                    GridPaperBackground()
                case .dots:
                    DotGridBackground()
                case .gradient:
                    GradientBackground(style: .subtle)
                case .iridescent:
                    IridescentBackground(intensity: 0.3)
                }
            }
    }
}

extension View {
    func backgroundStyle(_ style: BackgroundStyleModifier.BackgroundStyle) -> some View {
        modifier(BackgroundStyleModifier(style: style))
    }
}
