//
//  PomodoroTimerWidget.swift
//  Veloce
//

import SwiftUI

struct PomodoroTimerWidget: View {
    let taskId: UUID
    let taskTitle: String
    @State private var service = PomodoroTimerService.shared
    @Environment(\.responsiveLayout) private var layout

    // MARK: - Responsive Sizes

    private var ringSize: CGFloat {
        switch layout.deviceType {
        case .iPhoneSE: return 100
        case .iPhoneStandard: return 120
        case .iPhoneProMax: return 140
        case .iPadMini: return 160
        case .iPad, .iPadPro11: return 180
        case .iPadPro13: return 200
        }
    }

    private var ringLineWidth: CGFloat {
        layout.deviceType.isTablet ? 10 : 8
    }

    private var primaryButtonSize: CGFloat {
        layout.deviceType.isTablet ? 60 : 50
    }

    private var secondaryButtonSize: CGFloat {
        layout.deviceType.isTablet ? 52 : 44
    }

    var body: some View {
        VStack(spacing: layout.spacing) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.red)
                Text("Pomodoro Timer")
                    .dynamicTypeFont(base: 17, weight: .semibold)
                    .foregroundStyle(.white)
                Spacer()
                if let session = service.currentSession {
                    Text("Session \(session.sessionsCompleted + 1)")
                        .dynamicTypeFont(base: 12, weight: .regular)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Timer ring
            ZStack {
                SwiftUI.Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: ringLineWidth)
                    .frame(width: ringSize, height: ringSize)

                if let session = service.currentSession {
                    SwiftUI.Circle()
                        .trim(from: 0, to: session.progress)
                        .stroke(
                            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                        )
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text(session.formattedTime)
                            .dynamicTypeFont(base: layout.deviceType.isTablet ? 32 : 28, weight: .bold, design: .monospaced)
                            .foregroundStyle(.white)
                        Text(session.state == .breakTime ? "Break" : "Focus")
                            .dynamicTypeFont(base: 12, weight: .regular)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .dynamicTypeFont(base: 24, weight: .regular)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("25:00")
                            .dynamicTypeFont(base: 12, weight: .regular)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            // Controls with premium haptics
            HStack(spacing: layout.spacing * 1.5) {
                if service.currentSession == nil {
                    Button {
                        HapticsService.shared.gravityDrop() // Heavy satisfying start
                        service.startSession(taskId: taskId, taskTitle: taskTitle)
                    } label: {
                        Image(systemName: "play.fill")
                            .dynamicTypeFont(base: 20, weight: .medium)
                            .frame(width: primaryButtonSize, height: primaryButtonSize)
                            .background(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(SwiftUI.Circle())
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .iPadHoverEffect(.lift)
                } else if service.isRunning {
                    Button {
                        HapticsService.shared.magneticSnap() // Click pause
                        service.pauseSession()
                    } label: {
                        Image(systemName: "pause.fill")
                            .dynamicTypeFont(base: 18, weight: .medium)
                            .frame(width: secondaryButtonSize, height: secondaryButtonSize)
                            .background(.ultraThinMaterial)
                            .clipShape(SwiftUI.Circle())
                    }
                    .buttonStyle(SoftButtonStyle())
                    .iPadHoverEffect(.highlight)
                    Button {
                        HapticsService.shared.notification(.warning) // Warning for stop
                        service.stopSession()
                    } label: {
                        Image(systemName: "stop.fill")
                            .dynamicTypeFont(base: 18, weight: .medium)
                            .frame(width: secondaryButtonSize, height: secondaryButtonSize)
                            .background(.ultraThinMaterial)
                            .clipShape(SwiftUI.Circle())
                    }
                    .buttonStyle(SoftButtonStyle())
                    .iPadHoverEffect(.highlight)
                } else {
                    Button {
                        HapticsService.shared.heartbeatPulse() // Resume pulse
                        service.resumeSession()
                    } label: {
                        Image(systemName: "play.fill")
                            .dynamicTypeFont(base: 18, weight: .medium)
                            .frame(width: secondaryButtonSize, height: secondaryButtonSize)
                            .background(.ultraThinMaterial)
                            .clipShape(SwiftUI.Circle())
                    }
                    .buttonStyle(SoftButtonStyle())
                    .iPadHoverEffect(.highlight)
                    Button {
                        HapticsService.shared.notification(.warning)
                        service.stopSession()
                    } label: {
                        Image(systemName: "stop.fill")
                            .dynamicTypeFont(base: 18, weight: .medium)
                            .frame(width: secondaryButtonSize, height: secondaryButtonSize)
                            .background(.ultraThinMaterial)
                            .clipShape(SwiftUI.Circle())
                    }
                    .buttonStyle(SoftButtonStyle())
                    .iPadHoverEffect(.highlight)
                }
            }
            .foregroundStyle(.white)
        }
        .padding(layout.cardPadding)
        .voidCard(borderColor: .red.opacity(0.3))
    }
}
