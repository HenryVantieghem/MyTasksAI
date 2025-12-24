//
//  AIScheduleSuggestion.swift
//  Veloce
//

import SwiftUI

struct AIScheduleSuggestionView: View {
    let suggestedTime: Date
    let duration: Int
    var onAccept: () -> Void = {}
    var onReschedule: () -> Void = {}

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Theme.Colors.aiBlue)
                Text("AI Schedule Suggestion")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            // Mini week calendar
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { day in
                    let date = Calendar.current.date(byAdding: .day, value: day - Calendar.current.component(.weekday, from: Date()) + 2, to: Date())!
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: suggestedTime)

                    VStack(spacing: 4) {
                        Text(weekdays[day])
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.caption.bold())
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .background(isSelected ? Theme.Colors.aiBlue : .clear)
                            .clipShape(SwiftUI.Circle())
                    }
                }
            }

            // Time slot
            HStack {
                VStack(alignment: .leading) {
                    Text(suggestedTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("\(duration) min focus block")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                HStack(spacing: 8) {
                    Button("Reschedule", action: onReschedule)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Button("Accept", action: onAccept)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.aiBlue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .voidCard(borderColor: Theme.Colors.aiBlue.opacity(0.3))
    }
}
