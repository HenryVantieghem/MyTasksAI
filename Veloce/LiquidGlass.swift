import SwiftUI

public struct LiquidGlassBackground: View {
    public var cornerRadius: CGFloat
    public var tint: LinearGradient
    public var strokeColors: [Color]
    public var lineWidth: CGFloat

    public init(
        cornerRadius: CGFloat = 20,
        tint: LinearGradient = LinearGradient(colors: [.white.opacity(0.06), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
        strokeColors: [Color] = [.white.opacity(0.28), .white.opacity(0.08), .clear],
        lineWidth: CGFloat = 0.75
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.strokeColors = strokeColors
        self.lineWidth = lineWidth
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(colors: strokeColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: lineWidth
                    )
            )
            .overlay(
                // Inner highlight for depth
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.04), .clear], startPoint: .top, endPoint: .center),
                        lineWidth: 1
                    )
                    .padding(1)
            )
    }
}

public struct LiquidGlassCapsule: View {
    public var tint: LinearGradient
    public var strokeColors: [Color]
    public var lineWidth: CGFloat

    public init(
        tint: LinearGradient = LinearGradient(colors: [.white.opacity(0.06), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
        strokeColors: [Color] = [.white.opacity(0.28), .white.opacity(0.08), .clear],
        lineWidth: CGFloat = 0.75
    ) {
        self.tint = tint
        self.strokeColors = strokeColors
        self.lineWidth = lineWidth
    }

    public var body: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .background(
                Capsule()
                    .fill(tint)
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(colors: strokeColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: lineWidth
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.04), .clear], startPoint: .top, endPoint: .center),
                        lineWidth: 1
                    )
                    .padding(1)
            )
    }
}

public extension View {
    func liquidGlassContainer(
        cornerRadius: CGFloat = 20,
        tint: LinearGradient = LinearGradient(colors: [.white.opacity(0.06), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
        strokeColors: [Color] = [.white.opacity(0.28), .white.opacity(0.08), .clear],
        lineWidth: CGFloat = 0.75,
        shape: RoundedCornerStyle = .continuous
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: shape)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: shape)
                        .fill(tint)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: shape)
                        .stroke(
                            LinearGradient(colors: strokeColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: lineWidth
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: shape)
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.04), .clear], startPoint: .top, endPoint: .center),
                            lineWidth: 1
                        )
                        .padding(1)
                )
        )
    }
}
