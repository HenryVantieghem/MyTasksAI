//
//  EnhancedCustomTimerView.swift
//  Veloce
//
//  Tiimo-inspired custom timer picker with beautiful visual design
//  Preset grid + fine-tune controls + duration up to 8 hours
//

import SwiftUI

// MARK: - Enhanced Custom Timer View

struct EnhancedCustomTimerView: View {
    @Binding var selectedMinutes: Int
    let accentColor: Color
    let onStart: () -> Void
    let onDismiss: () -> Void

    @State private var wheelMinutes: Int = 30
    @State private var showingFullPresets = false
    @State private var previewProgress: Double = 0.75

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Design tokens
    private let previewRingSize: CGFloat = 180
    private let strokeWidth: CGFloat = 10

    init(
        selectedMinutes: Binding<Int>,
        accentColor: Color = Theme.Colors.success,
        onStart: @escaping () -> Void,
        onDismiss: @escaping () -> Void = {}
    ) {
        self._selectedMinutes = selectedMinutes
        self.accentColor = accentColor
        self.onStart = onStart
        self.onDismiss = onDismiss
        self._wheelMinutes = State(initialValue: selectedMinutes.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                VoidBackground.focus
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Duration Preview Ring
                        durationPreviewRing
                            .padding(.top, 20)

                        // Quick Adjustment Buttons
                        adjustmentControls
                            .padding(.horizontal, 24)

                        // Preset Grid
                        presetSection
                            .padding(.horizontal, 20)

                        // Fine-Tune Wheel
                        fineTuneSection
                            .padding(.horizontal, 24)

                        Spacer(minLength: 100)
                    }
                }
                .scrollIndicators(.hidden)

                // Start Button (Fixed at bottom)
                VStack {
                    Spacer()
                    startButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Custom Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
        .onAppear {
            wheelMinutes = selectedMinutes
        }
        .onChange(of: wheelMinutes) { _, newValue in
            selectedMinutes = newValue
        }
    }

    // MARK: - Duration Preview Ring

    private var durationPreviewRing: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.2),
                            accentColor.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: previewRingSize + 40, height: previewRingSize + 40)
                .blur(radius: 20)

            // Background ring
            Circle()
                .stroke(.white.opacity(0.1), lineWidth: strokeWidth)
                .frame(width: previewRingSize, height: previewRingSize)

            // Progress ring (shows visual representation of duration)
            Circle()
                .trim(from: 0, to: durationVisualization)
                .stroke(
                    AngularGradient(
                        colors: [
                            accentColor,
                            accentColor.opacity(0.7),
                            accentColor.opacity(0.4)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: previewRingSize, height: previewRingSize)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: wheelMinutes)

            // Center content
            VStack(spacing: 4) {
                Text(formattedDuration)
                    .font(.system(size: 42, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: wheelMinutes)

                Text(durationDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(height: previewRingSize + 60)
    }

    // Visual representation of duration (fills more for longer sessions)
    private var durationVisualization: Double {
        // Map 5-480 minutes to 0.1-1.0 arc
        let minMinutes: Double = 5
        let maxMinutes: Double = 480
        let normalized = (Double(wheelMinutes) - minMinutes) / (maxMinutes - minMinutes)
        return 0.1 + (normalized * 0.9)
    }

    private var formattedDuration: String {
        let hours = wheelMinutes / 60
        let mins = wheelMinutes % 60

        if hours == 0 {
            return "\(mins)m"
        } else if mins == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(mins)m"
        }
    }

    private var durationDescription: String {
        if wheelMinutes <= 15 {
            return "Quick focus"
        } else if wheelMinutes <= 30 {
            return "Short session"
        } else if wheelMinutes <= 60 {
            return "Standard focus"
        } else if wheelMinutes <= 120 {
            return "Deep work"
        } else if wheelMinutes <= 240 {
            return "Extended focus"
        } else {
            return "Marathon session"
        }
    }

    // MARK: - Adjustment Controls

    private var adjustmentControls: some View {
        HStack(spacing: 16) {
            // -15 min
            adjustmentButton(
                delta: -15,
                label: "-15m",
                isEnabled: wheelMinutes > 15
            )

            // -5 min
            adjustmentButton(
                delta: -5,
                label: "-5m",
                isEnabled: wheelMinutes > 5
            )

            Spacer()

            // +5 min
            adjustmentButton(
                delta: 5,
                label: "+5m",
                isEnabled: wheelMinutes < 480
            )

            // +15 min
            adjustmentButton(
                delta: 15,
                label: "+15m",
                isEnabled: wheelMinutes < 465
            )
        }
    }

    private func adjustmentButton(delta: Int, label: String, isEnabled: Bool) -> some View {
        Button {
            let newValue = max(5, min(480, wheelMinutes + delta))
            if !reduceMotion {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    wheelMinutes = newValue
                }
            } else {
                wheelMinutes = newValue
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                .frame(width: 56, height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial.opacity(isEnabled ? 0.5 : 0.2))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(isEnabled ? 0.15 : 0.05), lineWidth: 0.5)
                        }
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    // MARK: - Preset Section

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Select")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showingFullPresets.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showingFullPresets ? "Less" : "More")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: showingFullPresets ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
            }

            if showingFullPresets {
                // Full 4x4 preset grid
                TimerPresetGrid(
                    selectedMinutes: $wheelMinutes,
                    accentColor: accentColor
                ) { _ in }
            } else {
                // Compact horizontal scroll
                CompactPresetRow(
                    selectedMinutes: $wheelMinutes,
                    accentColor: accentColor
                ) { _ in }
            }
        }
    }

    // MARK: - Fine Tune Section

    private var fineTuneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fine Tune")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            // Slider with minute markers
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(wheelMinutes) },
                        set: { wheelMinutes = Int($0) }
                    ),
                    in: 5...480,
                    step: 5
                )
                .tint(accentColor)
                .onChange(of: wheelMinutes) { _, _ in
                    // Light haptic on value change
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.3)
                }

                // Min/Max labels
                HStack {
                    Text("5 min")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()

                    Text("8 hours")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.4))
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            HapticsService.shared.impact(.medium)
            onStart()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text("Start Focus")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: accentColor.opacity(0.4), radius: 12, y: 6)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Void Background Extension

extension VoidBackground {
    static var focus: some View {
        LinearGradient(
            colors: [
                Theme.CelestialColors.voidDeep,
                Theme.CelestialColors.void,
                Theme.CelestialColors.abyss
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Preview

#Preview("Enhanced Custom Timer") {
    EnhancedCustomTimerView(
        selectedMinutes: .constant(45),
        accentColor: Theme.Colors.success,
        onStart: {
            print("Starting timer")
        }
    )
    .preferredColorScheme(.dark)
}
