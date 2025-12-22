//
//  AnimatedSettingsGear.swift
//  Veloce
//

import SwiftUI

struct AnimatedSettingsGear: View {
    @State private var rotation: Double = 0
    @State private var glowOpacity: Double = 0.2
    @State private var isPressed = false

    var body: some View {
        Button(action: {}) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(LinearGradient(colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(rotation))

                // Glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)

                // Gear icon
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LinearGradient(colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue], startPoint: .top, endPoint: .bottom))
                    .rotationEffect(.degrees(rotation * 0.5))

                // Glow
                Circle()
                    .fill(Theme.Colors.aiPurple)
                    .frame(width: 44, height: 44)
                    .blur(radius: 15)
                    .opacity(glowOpacity)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) { rotation = 360 }
            withAnimation(.easeInOut(duration: 3).repeatForever()) { glowOpacity = 0.4 }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.3)) { isPressed = true } }
            .onEnded { _ in withAnimation(.spring(response: 0.3)) { isPressed = false } })
    }
}
