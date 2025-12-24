//
//  CelestialTransition.swift
//  Veloce
//
//  Living Cosmos - Cinematic Portal Transition
//  Matched geometry expansion from card to full-screen detail view
//  Features: radial blur, staggered content reveal, parallax star shift
//

import SwiftUI

// MARK: - Celestial Transition Namespace

enum CelestialTransition {
    /// Namespace ID for matched geometry
    static let namespace = "celestialCardTransition"
}

// MARK: - Portal Transition View

/// Wraps a view in the portal transition system
struct PortalTransitionView<Content: View>: View {
    let isExpanded: Bool
    let taskId: String
    let taskTypeColor: Color
    let namespace: Namespace.ID
    let content: Content

    @State private var contentOpacity: Double = 0
    @State private var backgroundBlur: CGFloat = 0
    @State private var starShift: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        isExpanded: Bool,
        taskId: String,
        taskTypeColor: Color,
        namespace: Namespace.ID,
        @ViewBuilder content: () -> Content
    ) {
        self.isExpanded = isExpanded
        self.taskId = taskId
        self.taskTypeColor = taskTypeColor
        self.namespace = namespace
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Cinematic dimmed background with radial blur
            if isExpanded {
                portalBackground
            }

            // Main content with matched geometry
            content
                .matchedGeometryEffect(
                    id: "card_\(taskId)",
                    in: namespace,
                    properties: .frame,
                    isSource: !isExpanded
                )
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                animatePortalOpen()
            } else {
                animatePortalClose()
            }
        }
    }

    // MARK: - Portal Background

    private var portalBackground: some View {
        ZStack {
            // Deep void
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()

            // Radial blur emanating from center
            RadialGradient(
                colors: [
                    Color.clear,
                    Theme.CelestialColors.void.opacity(0.5),
                    Theme.CelestialColors.void
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .blur(radius: backgroundBlur)
            .ignoresSafeArea()

            // Shifting star field
            StarFieldView(shift: starShift, density: .sparse)
                .ignoresSafeArea()

            // Task type nebula glow
            RadialGradient(
                colors: [
                    taskTypeColor.opacity(0.15),
                    taskTypeColor.opacity(0.05),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
        .opacity(contentOpacity)
    }

    // MARK: - Animations

    private func animatePortalOpen() {
        guard !reduceMotion else {
            contentOpacity = 1
            backgroundBlur = 0
            return
        }

        // Staggered reveal
        withAnimation(Theme.Animation.portalOpen) {
            contentOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.6)) {
            backgroundBlur = 20
        }

        // Star parallax shift
        withAnimation(.easeOut(duration: 0.8)) {
            starShift = 30
        }
    }

    private func animatePortalClose() {
        guard !reduceMotion else {
            contentOpacity = 0
            backgroundBlur = 0
            starShift = 0
            return
        }

        withAnimation(.easeIn(duration: 0.3)) {
            contentOpacity = 0
            backgroundBlur = 0
            starShift = 0
        }
    }
}

// MARK: - Star Field View

/// Ambient star field that shifts during transitions
struct StarFieldView: View {
    let shift: CGFloat
    let density: StarDensity

    enum StarDensity {
        case sparse, medium, dense

        var count: Int {
            switch self {
            case .sparse: return 30
            case .medium: return 60
            case .dense: return 100
            }
        }
    }

    @State private var stars: [CelestialStar] = []
    @State private var twinklePhases: [UUID: CGFloat] = [:]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ForEach(stars) { star in
                SwiftUI.Circle()
                    .fill(star.color)
                    .frame(width: star.size, height: star.size)
                    .position(
                        x: star.position.x + (shift * star.parallaxFactor),
                        y: star.position.y
                    )
                    .opacity(star.baseOpacity + (Double(twinklePhases[star.id] ?? 0) * 0.3))
                    .blur(radius: star.size > 2 ? 0.5 : 0)
            }
            .onAppear {
                generateStars(in: geometry.size)
                if !reduceMotion {
                    startTwinkling()
                }
            }
        }
    }

    private func generateStars(in size: CGSize) {
        stars = (0..<density.count).map { _ in
            CelestialStar(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1...3),
                color: [
                    Color.white,
                    Theme.CelestialColors.nebulaEdge.opacity(0.8),
                    Theme.CelestialColors.plasmaCore.opacity(0.6)
                ].randomElement() ?? .white,
                baseOpacity: Double.random(in: 0.3...0.8),
                parallaxFactor: CGFloat.random(in: 0.2...1.0)
            )
        }
    }

    private func startTwinkling() {
        for star in stars {
            let delay = Double.random(in: 0...2)
            let duration = Double.random(in: 1.5...3.0)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    twinklePhases[star.id] = 1
                }
            }
        }
    }
}

struct CelestialStar: Identifiable {
    let id: UUID
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let baseOpacity: Double
    let parallaxFactor: CGFloat
}

// MARK: - Celestial Staggered Content Reveal

/// Modifier for staggered entry animation on content with direction support
struct CelestialStaggeredRevealModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double
    let direction: StaggerDirection

    @State private var hasAppeared = false

    enum StaggerDirection {
        case fromBottom, fromTop, fromLeft, fromRight, scale

        var offset: CGSize {
            switch self {
            case .fromBottom: return CGSize(width: 0, height: 30)
            case .fromTop: return CGSize(width: 0, height: -30)
            case .fromLeft: return CGSize(width: -30, height: 0)
            case .fromRight: return CGSize(width: 30, height: 0)
            case .scale: return .zero
            }
        }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(offsetValue)
            .scaleEffect(scaleValue)
            .opacity(opacityValue)
            .onAppear {
                guard !reduceMotion else {
                    hasAppeared = true
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(Theme.Animation.stellarBounce) {
                        hasAppeared = true
                    }
                }
            }
            .onChange(of: isVisible) { _, visible in
                if !visible {
                    hasAppeared = false
                }
            }
    }

    private var offsetValue: CGSize {
        if reduceMotion || hasAppeared {
            return .zero
        }
        return direction.offset
    }

    private var scaleValue: CGFloat {
        if reduceMotion || hasAppeared {
            return 1.0
        }
        return direction == .scale ? 0.9 : 1.0
    }

    private var opacityValue: Double {
        if reduceMotion {
            return 1.0
        }
        return hasAppeared ? 1.0 : 0.0
    }
}

// MARK: - View Extensions

extension View {
    /// Apply staggered reveal animation with direction
    func staggeredReveal(
        isVisible: Bool,
        delay: Double,
        direction: CelestialStaggeredRevealModifier.StaggerDirection = .fromBottom
    ) -> some View {
        modifier(CelestialStaggeredRevealModifier(
            isVisible: isVisible,
            delay: delay,
            direction: direction
        ))
    }

    /// Convenience for section-based staggering
    func sectionReveal(isVisible: Bool, index: Int) -> some View {
        staggeredReveal(
            isVisible: isVisible,
            delay: Theme.Animation.staggerDelay * Double(index),
            direction: .fromBottom
        )
    }
}

// MARK: - Portal Container

/// Container for managing card-to-fullscreen transitions
struct PortalContainer<Card: View, Detail: View>: View {
    @Binding var isExpanded: Bool
    let taskId: String
    let taskTypeColor: Color
    let card: Card
    let detail: Detail

    @Namespace private var portalNamespace

    init(
        isExpanded: Binding<Bool>,
        taskId: String,
        taskTypeColor: Color,
        @ViewBuilder card: () -> Card,
        @ViewBuilder detail: () -> Detail
    ) {
        self._isExpanded = isExpanded
        self.taskId = taskId
        self.taskTypeColor = taskTypeColor
        self.card = card()
        self.detail = detail()
    }

    var body: some View {
        ZStack {
            if !isExpanded {
                card
                    .matchedGeometryEffect(
                        id: "portal_\(taskId)",
                        in: portalNamespace,
                        properties: .frame
                    )
            } else {
                PortalTransitionView(
                    isExpanded: isExpanded,
                    taskId: taskId,
                    taskTypeColor: taskTypeColor,
                    namespace: portalNamespace
                ) {
                    detail
                        .matchedGeometryEffect(
                            id: "portal_\(taskId)",
                            in: portalNamespace,
                            properties: .frame
                        )
                }
            }
        }
    }
}

// MARK: - Dismiss Gesture

/// Drag-to-dismiss gesture handler for expanded views
struct PortalDismissGesture: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dismissThreshold: CGFloat = 150
    private let velocityThreshold: CGFloat = 1000

    func body(content: Content) -> some View {
        content
            .offset(y: dragOffset)
            .gesture(dismissGesture)
            .animation(
                isDragging ? nil : Theme.Animation.stellarBounce,
                value: dragOffset
            )
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                // Only allow dragging down
                if value.translation.height > 0 {
                    // Apply resistance as drag increases
                    let resistance = 1 - (value.translation.height / 600)
                    dragOffset = value.translation.height * max(0.3, resistance)
                }
            }
            .onEnded { value in
                isDragging = false

                let shouldDismiss =
                    value.translation.height > dismissThreshold ||
                    value.velocity.height > velocityThreshold

                if shouldDismiss {
                    // Animate off screen
                    withAnimation(Theme.Animation.fast) {
                        dragOffset = 500
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss?()
                        isPresented = false
                    }
                } else {
                    // Snap back
                    dragOffset = 0
                }
            }
    }
}

extension View {
    /// Apply portal dismiss gesture
    func portalDismiss(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(PortalDismissGesture(isPresented: isPresented, onDismiss: onDismiss))
    }
}

// MARK: - Preview

#Preview("Portal Transition") {
    struct PreviewContainer: View {
        @State private var isExpanded = false

        var body: some View {
            ZStack {
                Theme.CelestialColors.void.ignoresSafeArea()

                VStack {
                    Button("Toggle Portal") {
                        withAnimation(Theme.Animation.portalOpen) {
                            isExpanded.toggle()
                        }
                    }
                    .padding()
                    .background(Theme.CelestialColors.nebulaCore)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                    PortalContainer(
                        isExpanded: $isExpanded,
                        taskId: "preview",
                        taskTypeColor: Theme.TaskCardColors.create
                    ) {
                        // Card view
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Theme.CelestialColors.abyss)
                            .frame(height: 120)
                            .overlay {
                                Text("Task Card")
                                    .foregroundStyle(.white)
                            }
                            .padding()
                    } detail: {
                        // Detail view
                        VStack(spacing: 20) {
                            Text("Expanded Detail")
                                .font(Theme.Typography.cosmosTitleLarge)
                                .foregroundStyle(.white)
                                .sectionReveal(isVisible: isExpanded, index: 0)

                            Text("Section 1")
                                .foregroundStyle(.white)
                                .sectionReveal(isVisible: isExpanded, index: 1)

                            Text("Section 2")
                                .foregroundStyle(.white)
                                .sectionReveal(isVisible: isExpanded, index: 2)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(Theme.CelestialColors.abyss)
                        .portalDismiss(isPresented: $isExpanded)
                    }
                }
            }
        }
    }

    return PreviewContainer()
}
