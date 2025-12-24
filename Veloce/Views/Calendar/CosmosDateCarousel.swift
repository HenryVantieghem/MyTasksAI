//
//  CosmosDateCarousel.swift
//  Veloce
//
//  Living Cosmos Date Carousel
//  Horizontal scrollable date navigation with plasma indicators
//

import SwiftUI

struct CosmosDateCarousel: View {
    @Binding var selectedDate: Date
    let viewMode: CosmosViewMode
    let hasEvents: (Date) -> Bool
    let onSwipe: (SwipeDirection) -> Void

    @State private var appeared = false
    @GestureState private var dragOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let calendar = Calendar.current
    private let pillWidth: CGFloat = 48
    private let pillSpacing: CGFloat = 8

    // MARK: - Computed Properties

    private var visibleDates: [Date] {
        // Show 7 days centered on selected date
        (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: selectedDate)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: pillSpacing) {
                    ForEach(visibleDates, id: \.self) { date in
                        CosmosDatePill(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEvents: hasEvents(date),
                            onTap: {
                                HapticsService.shared.selectionFeedback()
                                withAnimation(LivingCosmos.Animations.spring) {
                                    selectedDate = date
                                }
                            }
                        )
                        .id(date)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .offset(x: dragOffset * 0.3)
            .gesture(swipeGesture)
            .onChange(of: selectedDate) { _, newDate in
                withAnimation(LivingCosmos.Animations.spring) {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
        }
        .frame(height: 72)
        .onAppear {
            withAnimation(LivingCosmos.Animations.stellarBounce.delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                if value.translation.width > threshold {
                    onSwipe(.right)
                } else if value.translation.width < -threshold {
                    onSwipe(.left)
                }
            }
    }
}

// MARK: - Date Pill

struct CosmosDatePill: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let onTap: () -> Void

    @State private var glowPhase: CGFloat = 0
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Day name
                Text(dayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starDim)

                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(dayNumberColor)

                // Event indicator
                SwiftUI.Circle()
                    .fill(hasEvents ? Theme.CelestialColors.plasmaCore : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 48, height: 56)
            .background(pillBackground)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(pressGesture)
        .onAppear {
            if isSelected && !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue && !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
            } else {
                glowPhase = 0
            }
        }
    }

    // MARK: - Components

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var dayNumberColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Theme.CelestialColors.plasmaCore
        } else {
            return .white.opacity(0.9)
        }
    }

    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.CelestialColors.nebulaEdge.opacity(0.2 + glowPhase * 0.15))
                    .blur(radius: 6)
                    .scaleEffect(1.1)

                // Glass fill
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.CelestialColors.nebulaCore.opacity(0.4),
                                        Theme.CelestialColors.nebulaGlow.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.CelestialColors.nebulaEdge.opacity(0.4), lineWidth: 1)
                    }
            }
        } else if isToday {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.CelestialColors.plasmaCore.opacity(0.5), lineWidth: 1.5)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.CelestialColors.plasmaCore.opacity(0.08))
                }
        }
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                withAnimation(LivingCosmos.Animations.quick) {
                    isPressed = true
                }
            }
            .onEnded { _ in
                withAnimation(LivingCosmos.Animations.quick) {
                    isPressed = false
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.calendar

        VStack {
            CosmosDateCarousel(
                selectedDate: .constant(Date()),
                viewMode: .day,
                hasEvents: { _ in Bool.random() },
                onSwipe: { _ in }
            )
        }
    }
}
