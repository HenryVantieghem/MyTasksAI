//
//  GoalColorfulComponents.swift
//  MyTasksAI
//
//  Colorful, animated components inspired by Interactive Snippets
//

import SwiftUI

// MARK: - Animated Progress Ring

struct AnimatedProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            color,
                            color.opacity(0.8),
                            color,
                            color.opacity(0.6),
                            color
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 1.0, bounce: 0.3), value: animatedProgress)
            
            // Center content
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                
                Text("%")
                    .font(.caption)
                    .foregroundStyle(color.opacity(0.7))
            }
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            animatedProgress = newValue
        }
    }
}

// MARK: - Gradient Progress Bar

struct GradientProgressBar: View {
    let progress: Double
    let height: CGFloat
    let cornerRadius: CGFloat
    let gradient: LinearGradient
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        height: CGFloat = 12,
        cornerRadius: CGFloat = 6,
        colors: [Color]
    ) {
        self.progress = progress
        self.height = height
        self.cornerRadius = cornerRadius
        self.gradient = LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.white.opacity(0.2))
                
                // Progress fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .frame(width: geometry.size.width * animatedProgress)
                    .overlay {
                        // Shimmer effect
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 50)
                            .offset(x: shimmerOffset(for: geometry.size.width))
                    }
                    .animation(.spring(duration: 0.8, bounce: 0.2), value: animatedProgress)
            }
        }
        .frame(height: height)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            animatedProgress = newValue
        }
    }
    
    private func shimmerOffset(for width: CGFloat) -> CGFloat {
        return (width * animatedProgress) - 50
    }
}

// MARK: - Pulsing Badge

struct PulsingBadge: View {
    let icon: String
    let color: Color
    let size: CGFloat
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size + 20, height: size + 20)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0 : 1)
            
            // Main badge
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.8),
                            color.opacity(0.6)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size, height: size)
                .glassEffect(.regular.tint(color).interactive(), in: .circle)
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: size * 0.5))
                .foregroundStyle(.white)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                    isPressed = false
                }
                action()
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.5), radius: 12, y: 6)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .glassEffect(.regular.tint(color).interactive(), in: .circle)
        }
    }
}

// MARK: - Animated Milestone Badge

struct MilestoneBadge: View {
    let completed: Int
    let total: Int
    let color: Color
    
    @State private var animatedCompleted: Int = 0
    @State private var showCelebration = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Flag icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "flag.fill")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(color)
            }
            .glassEffect(.regular, in: .circle)
            
            // Progress text
            VStack(alignment: .leading, spacing: 2) {
                Text("Milestones")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(animatedCompleted)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                        .contentTransition(.numericText())
                    
                    Text("/ \(total)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Confetti on completion
            if showCelebration {
                Image(systemName: "party.popper.fill")
                    .font(.title3)
                    .foregroundStyle(color)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        }
        .glassEffect(.regular.tint(color), in: .rect(cornerRadius: 12))
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                animatedCompleted = completed
            }
            
            if completed == total && total > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showCelebration = true
                    }
                }
            }
        }
        .onChange(of: completed) { oldValue, newValue in
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                animatedCompleted = newValue
            }
            
            if newValue == total && total > 0 {
                withAnimation {
                    showCelebration = true
                }
            } else {
                showCelebration = false
            }
        }
    }
}

// MARK: - Goal Streak Badge

struct GoalStreakBadge: View {
    let streak: Int
    let color: Color
    
    @State private var isFlaming = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isFlaming ? 1.1 : 1.0)
            
            Text("\(streak)")
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            
            Text("day streak")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.2),
                            Color.red.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .glassEffect(.regular.tint(.orange).interactive(), in: .rect(cornerRadius: 16))
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
            ) {
                isFlaming = true
            }
        }
    }
}

// MARK: - Category Tag

struct CategoryTag: View {
    let category: GoalCategory
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.caption)
            
            Text(category.displayName)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            category.color,
                            category.color.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .glassEffect(.regular.tint(category.color), in: .capsule)
    }
}

// MARK: - Preview

#Preview("Progress Ring") {
    VStack(spacing: 40) {
        AnimatedProgressRing(
            progress: 0.67,
            color: .blue,
            lineWidth: 12
        )
        .frame(width: 120, height: 120)
        
        AnimatedProgressRing(
            progress: 0.34,
            color: .green,
            lineWidth: 10
        )
        .frame(width: 100, height: 100)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Progress Bar") {
    VStack(spacing: 24) {
        GradientProgressBar(
            progress: 0.67,
            colors: [.blue, .cyan]
        )
        
        GradientProgressBar(
            progress: 0.45,
            height: 16,
            cornerRadius: 8,
            colors: [.purple, .pink]
        )
        
        GradientProgressBar(
            progress: 0.89,
            height: 8,
            colors: [.green, .yellow]
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Badges") {
    VStack(spacing: 24) {
        PulsingBadge(icon: "star.fill", color: .orange, size: 60)
        
        MilestoneBadge(completed: 5, total: 8, color: .blue)
        
        GoalStreakBadge(streak: 12, color: .orange)
        
        CategoryTag(category: .health)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Action Button") {
    FloatingActionButton(icon: "plus", color: .blue) {
        print("Button tapped!")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
