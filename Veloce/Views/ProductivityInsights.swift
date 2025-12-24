//
//  ProductivityInsights.swift
//  Veloce
//

import SwiftUI
import Charts

struct ProductivityInsights: View {
    @State private var weeklyData: [DayData] = (0..<7).map { i in
        DayData(day: Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!, completed: Int.random(in: 2...8))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weekly Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Progress").font(.headline).foregroundStyle(.white)
                    Chart(weeklyData) { data in
                        BarMark(x: .value("Day", data.day, unit: .day), y: .value("Tasks", data.completed))
                            .foregroundStyle(LinearGradient(colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue], startPoint: .bottom, endPoint: .top))
                            .cornerRadius(4)
                    }
                    .frame(height: 150)
                    .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated)) } }
                    .chartYAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(.white.opacity(0.1)) } }
                }
                .padding()
                .voidCard()

                // Best Hours Heatmap
                VStack(alignment: .leading, spacing: 12) {
                    Text("Best Productive Hours").font(.headline).foregroundStyle(.white)
                    HStack(spacing: 4) {
                        ForEach(8..<20, id: \.self) { hour in
                            let intensity = Double.random(in: 0.1...1.0)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.aiPurple.opacity(intensity))
                                .frame(height: 40)
                                .overlay(Text("\(hour)").font(.caption2).foregroundStyle(.white.opacity(0.7)))
                        }
                    }
                }
                .padding()
                .voidCard()

                // Streak Calendar
                VStack(alignment: .leading, spacing: 12) {
                    Text("Streak Calendar").font(.headline).foregroundStyle(.white)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                        ForEach(0..<28, id: \.self) { day in
                            SwiftUI.Circle()
                                .fill(Bool.random() ? Theme.Colors.success : Color.white.opacity(0.1))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .padding()
                .voidCard()
            }
            .padding()
        }
        .background(VoidBackground())
        .navigationTitle("Insights")
    }
}

struct DayData: Identifiable {
    let id = UUID()
    let day: Date
    let completed: Int
}
