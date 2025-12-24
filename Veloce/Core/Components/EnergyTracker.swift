//
//  EnergyTracker.swift
//  Veloce
//

import SwiftUI

enum EnergyLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .medium: return "battery.50"
        case .high: return "battery.100"
        }
    }

    var color: Color {
        switch self {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return Theme.Colors.success
        }
    }

    var recommendation: String {
        switch self {
        case .low: return "Focus on quick wins and admin tasks"
        case .medium: return "Good for routine work and follow-ups"
        case .high: return "Perfect for complex tasks and deep work"
        }
    }
}

struct EnergyTrackerView: View {
    @Binding var selectedEnergy: EnergyLevel?
    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill").foregroundStyle(Theme.Colors.aiGold)
                Text("How's your energy?").font(.headline).foregroundStyle(.white)
                Spacer()
                if let energy = selectedEnergy {
                    HStack(spacing: 4) {
                        Image(systemName: energy.icon).foregroundStyle(energy.color)
                        Text(energy.rawValue).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            if showingPicker || selectedEnergy == nil {
                HStack(spacing: 12) {
                    ForEach(EnergyLevel.allCases, id: \.self) { level in
                        Button {
                            withAnimation(.spring()) { selectedEnergy = level; showingPicker = false }
                            HapticsService.shared.selectionFeedback()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: level.icon).font(.title2)
                                Text(level.rawValue).font(.caption)
                            }
                            .foregroundStyle(selectedEnergy == level ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedEnergy == level ? level.color.opacity(0.3) : .white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedEnergy == level ? level.color : .clear, lineWidth: 2))
                        }
                    }
                }

                if let energy = selectedEnergy {
                    Text(energy.recommendation)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .voidCard()
        .onTapGesture { withAnimation(.spring()) { showingPicker.toggle() } }
    }
}

struct EnergyMeter: View {
    let currentEnergy: Double // 0-1
    let tasksCompleted: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                SwiftUI.Circle().stroke(Color.white.opacity(0.1), lineWidth: 4).frame(width: 44, height: 44)
                SwiftUI.Circle().trim(from: 0, to: currentEnergy).stroke(LinearGradient(colors: [Theme.Colors.success, .yellow, .orange], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 44, height: 44).rotationEffect(.degrees(-90))
                Image(systemName: "bolt.fill").font(.caption).foregroundStyle(.white)
            }
            VStack(alignment: .leading) {
                Text("Energy").font(.caption).foregroundStyle(.white.opacity(0.6))
                Text("\(Int(currentEnergy * 100))%").font(.headline).foregroundStyle(.white)
            }
        }
    }
}
