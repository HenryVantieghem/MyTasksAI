//
//  ParallaxMotion.swift
//  Veloce
//
//  Living Cosmos - Device Motion Parallax System
//  Creates depth layers that respond to device tilt for immersive card experience
//

import SwiftUI
import CoreMotion
import Combine

// MARK: - Parallax Motion Manager

/// Singleton manager for device motion updates
/// Provides pitch and roll values for parallax effects
final class ParallaxMotionManager: ObservableObject {
    static let shared = ParallaxMotionManager()

    @Published private(set) var pitch: Double = 0  // Forward/back tilt
    @Published private(set) var roll: Double = 0   // Left/right tilt

    private let motionManager = CMMotionManager()
    private var referenceAttitude: CMAttitude?
    private var isCalibrated = false

    /// Maximum offset for parallax effect (in points)
    let maxOffset: CGFloat = 15

    /// Sensitivity multiplier for motion response
    var sensitivity: CGFloat = 1.0

    private init() {}

    /// Start receiving motion updates
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }

            // Calibrate on first reading
            if !self.isCalibrated {
                self.referenceAttitude = motion.attitude.copy() as? CMAttitude
                self.isCalibrated = true
            }

            // Calculate relative attitude from reference
            if let reference = self.referenceAttitude {
                motion.attitude.multiply(byInverseOf: reference)
            }

            // Update published values (clamped to reasonable range)
            let clampedPitch = max(-0.5, min(0.5, motion.attitude.pitch))
            let clampedRoll = max(-0.5, min(0.5, motion.attitude.roll))

            // Smooth the values
            self.pitch = self.pitch * 0.7 + clampedPitch * 0.3
            self.roll = self.roll * 0.7 + clampedRoll * 0.3
        }
    }

    /// Stop motion updates
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isCalibrated = false
        referenceAttitude = nil
    }

    /// Recalibrate to current device orientation
    func recalibrate() {
        isCalibrated = false
    }

    /// Get offset for a specific depth layer
    /// - Parameters:
    ///   - depth: Layer depth (0 = background, 1 = foreground)
    ///   - axis: Which axis to calculate (.horizontal, .vertical, .both)
    /// - Returns: CGSize offset to apply
    func offset(for depth: CGFloat, axis: ParallaxAxis = .both) -> CGSize {
        let multiplier = depth * maxOffset * sensitivity

        switch axis {
        case .horizontal:
            return CGSize(width: roll * multiplier, height: 0)
        case .vertical:
            return CGSize(width: 0, height: pitch * multiplier)
        case .both:
            return CGSize(width: roll * multiplier, height: pitch * multiplier)
        }
    }
}

// MARK: - Parallax Axis

enum ParallaxAxis {
    case horizontal
    case vertical
    case both
}

// MARK: - Parallax Layer

/// Defines a parallax depth layer with associated visual properties
struct ParallaxLayer {
    let depth: CGFloat        // 0 = background, 1 = foreground
    let scale: CGFloat        // Size multiplier
    let opacity: Double       // Layer opacity
    let blur: CGFloat         // Background blur amount

    // Preset layers
    static let background = ParallaxLayer(depth: 0.3, scale: 1.02, opacity: 0.6, blur: 2)
    static let content = ParallaxLayer(depth: 0.6, scale: 1.0, opacity: 1.0, blur: 0)
    static let foreground = ParallaxLayer(depth: 1.0, scale: 0.98, opacity: 1.0, blur: 0)
    static let floating = ParallaxLayer(depth: 1.2, scale: 0.96, opacity: 0.9, blur: 0)
}

// MARK: - Parallax View Modifier

/// Apply parallax motion effect to a view
struct ParallaxModifier: ViewModifier {
    @ObservedObject private var motion = ParallaxMotionManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let layer: ParallaxLayer
    let axis: ParallaxAxis
    let enabled: Bool

    init(layer: ParallaxLayer = .content, axis: ParallaxAxis = .both, enabled: Bool = true) {
        self.layer = layer
        self.axis = axis
        self.enabled = enabled
    }

    func body(content: Content) -> some View {
        content
            .offset(reduceMotion || !enabled ? .zero : motion.offset(for: layer.depth, axis: axis))
            .scaleEffect(reduceMotion || !enabled ? 1.0 : layer.scale)
            .blur(radius: layer.blur)
            .opacity(layer.opacity)
            .animation(Theme.Animation.parallaxShift, value: motion.pitch)
            .animation(Theme.Animation.parallaxShift, value: motion.roll)
            .onAppear {
                if enabled && !reduceMotion {
                    motion.startUpdates()
                }
            }
    }
}

// MARK: - Parallax Container

/// Container view that manages multiple parallax layers
struct ParallaxContainer<Background: View, Content: View, Foreground: View>: View {
    @ObservedObject private var motion = ParallaxMotionManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let background: Background
    let content: Content
    let foreground: Foreground
    let enabled: Bool

    init(
        enabled: Bool = true,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> Content,
        @ViewBuilder foreground: () -> Foreground
    ) {
        self.enabled = enabled
        self.background = background()
        self.content = content()
        self.foreground = foreground()
    }

    var body: some View {
        ZStack {
            // Background layer - moves opposite to create depth
            background
                .modifier(ParallaxModifier(layer: .background, enabled: shouldAnimate))

            // Content layer - primary content
            content
                .modifier(ParallaxModifier(layer: .content, enabled: shouldAnimate))

            // Foreground layer - floats above
            foreground
                .modifier(ParallaxModifier(layer: .foreground, enabled: shouldAnimate))
        }
        .onAppear {
            if shouldAnimate {
                motion.startUpdates()
            }
        }
        .onDisappear {
            motion.stopUpdates()
        }
    }

    private var shouldAnimate: Bool {
        enabled && !reduceMotion
    }
}

// MARK: - Simple Parallax Container (2 layers)

struct SimpleParallaxContainer<Background: View, Content: View>: View {
    let background: Background
    let content: Content
    let enabled: Bool

    init(
        enabled: Bool = true,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> Content
    ) {
        self.enabled = enabled
        self.background = background()
        self.content = content()
    }

    var body: some View {
        ParallaxContainer(enabled: enabled) {
            background
        } content: {
            content
        } foreground: {
            EmptyView()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply parallax motion effect
    /// - Parameters:
    ///   - layer: The depth layer for this view
    ///   - axis: Which axis to apply parallax
    ///   - enabled: Whether parallax is active
    func parallax(
        layer: ParallaxLayer = .content,
        axis: ParallaxAxis = .both,
        enabled: Bool = true
    ) -> some View {
        modifier(ParallaxModifier(layer: layer, axis: axis, enabled: enabled))
    }

    /// Apply parallax with custom depth
    /// - Parameters:
    ///   - depth: Custom depth value (0 = background, 1 = foreground)
    ///   - enabled: Whether parallax is active
    func parallax(depth: CGFloat, enabled: Bool = true) -> some View {
        let customLayer = ParallaxLayer(depth: depth, scale: 1.0, opacity: 1.0, blur: 0)
        return modifier(ParallaxModifier(layer: customLayer, enabled: enabled))
    }
}

// MARK: - Parallax Card Background

/// Specialized parallax background for task cards with nebula layers
struct ParallaxCardBackground: View {
    let taskTypeColor: Color
    let isHighPriority: Bool

    @ObservedObject private var motion = ParallaxMotionManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Deep void layer (furthest back)
            Theme.CelestialColors.voidDeep
                .parallax(layer: .background)

            // Nebula glow layer
            RadialGradient(
                colors: [
                    taskTypeColor.opacity(0.15),
                    taskTypeColor.opacity(0.05),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 200
            )
            .parallax(depth: 0.4)

            // Aurora tendrils (for high priority)
            if isHighPriority && !reduceMotion {
                AuroraTendrils(color: taskTypeColor)
                    .parallax(layer: .floating)
            }

            // Glass surface (closest)
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
                .parallax(layer: .content)
        }
    }
}

// MARK: - Aurora Tendrils

/// Animated aurora effect for high-priority cards
struct AuroraTendrils: View {
    let color: Color

    @State private var phase: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            // Draw flowing aurora lines
            for i in 0..<3 {
                let yOffset = CGFloat(i) * size.height / 3
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: yOffset))

                    for x in stride(from: 0, to: size.width, by: 4) {
                        let y = yOffset + sin((x / 30) + phase + CGFloat(i)) * 15
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            color.opacity(0.3),
                            color.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: 0, y: size.height / 2),
                        endPoint: CGPoint(x: size.width, y: size.height / 2)
                    ),
                    lineWidth: 2
                )
            }
        }
        .blur(radius: 4)
        .onAppear {
            withAnimation(Theme.Animation.auroraWave) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Preview

#Preview("Parallax Card") {
    ZStack {
        Theme.CelestialColors.void
            .ignoresSafeArea()

        VStack(spacing: 20) {
            // Parallax card demo
            ParallaxContainer {
                // Background
                ParallaxCardBackground(
                    taskTypeColor: Theme.TaskCardColors.create,
                    isHighPriority: true
                )
            } content: {
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Write quarterly report")
                        .font(Theme.Typography.cosmosTitle)
                        .foregroundStyle(.white)

                    Text("15 min • High Priority")
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } foreground: {
                // Floating elements
                HStack {
                    Spacer()
                    Text("+25")
                        .font(Theme.Typography.cosmosPoints)
                        .foregroundStyle(Theme.CelestialColors.solarFlare)
                        .padding(8)
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Text("Tilt device to see parallax effect")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}
