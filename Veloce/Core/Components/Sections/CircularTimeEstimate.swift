//
//  CircularTimeEstimate.swift
//  Veloce
//

import SwiftUI

struct CircularTimeEstimate: View {
    let estimatedMinutes: Int
    let elapsedMinutes: Int

    private var progress: Double {
        guard estimatedMinutes > 0 else { return 0 }
        return min(1.0, Double(elapsedMinutes) / Double(estimatedMinutes))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 6)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(estimatedMinutes - elapsedMinutes)")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                Text("min")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

struct TimeEstimateCard: View {
    let estimatedMinutes: Int
    @State private var elapsedMinutes: Int = 0

    var body: some View {
        HStack(spacing: 16) {
            CircularTimeEstimate(estimatedMinutes: estimatedMinutes, elapsedMinutes: elapsedMinutes)

            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated Time")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("\(estimatedMinutes) minutes")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                if elapsedMinutes > 0 {
                    Text("\(elapsedMinutes) min elapsed")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            Spacer()
        }
        .padding()
        .voidCard()
    }
}
