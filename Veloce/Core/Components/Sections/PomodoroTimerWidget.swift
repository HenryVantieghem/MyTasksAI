//
//  PomodoroTimerWidget.swift
//  Veloce
//

import SwiftUI

struct PomodoroTimerWidget: View {
    let taskId: UUID
    let taskTitle: String
    @State private var service = PomodoroTimerService.shared

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.red)
                Text("Pomodoro Timer")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if let session = service.currentSession {
                    Text("Session \(session.sessionsCompleted + 1)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Timer ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 120, height: 120)

                if let session = service.currentSession {
                    Circle()
                        .trim(from: 0, to: session.progress)
                        .stroke(
                            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text(session.formattedTime)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text(session.state == .breakTime ? "Break" : "Focus")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("25:00")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            // Controls
            HStack(spacing: 24) {
                if service.currentSession == nil {
                    Button { service.startSession(taskId: taskId, taskTitle: taskTitle) } label: {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                    }
                } else if service.isRunning {
                    Button { service.pauseSession() } label: {
                        Image(systemName: "pause.fill")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Button { service.stopSession() } label: {
                        Image(systemName: "stop.fill")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                } else {
                    Button { service.resumeSession() } label: {
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Button { service.stopSession() } label: {
                        Image(systemName: "stop.fill")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
            .foregroundStyle(.white)
        }
        .padding()
        .voidCard(borderColor: .red.opacity(0.3))
    }
}
